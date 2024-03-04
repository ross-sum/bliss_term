-----------------------------------------------------------------------
--                                                                   --
--                             S E T U P                             --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2024  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package displays the setup dialogue box,  which  contains  --
--  the configuration controls, specifically the interface  details  --
--  for  dimensions, window control, status icon and  colours,  the  --
--  language (i.e. Unicode group) being used for input and display,  --
--  options around the language, and input and output  management.   --
--                                                                   --
--  Version History:                                                 --
--  $Log$
--                                                                   --
--  Bliss Term  is free software; you can  redistribute  it  and/or  --
--  modify  it under terms of the GNU  General  Public  Licence  as  --
--  published by the Free Software Foundation; either version 2, or  --
--  (at your option) any later version.  Bliss Term is  distributed  --
--  in  hope  that  it will be useful, but  WITHOUT  ANY  WARRANTY;  --
--  without even the implied warranty of MERCHANTABILITY or FITNESS  --
--  FOR  A PARTICULAR PURPOSE. See the GNU General  Public  Licence  --
--  for  more details.  You should have received a copy of the  GNU  --
--  General Public Licence distributed with  Cell Writer.            --
--  If  not,  write to the Free Software  Foundation,  51  Franklin  --
--  Street, Fifth Floor, Boston, MA 02110-1301, USA.                 --
--                                                                   --
-----------------------------------------------------------------------
-- with Gtkada.Builder;  use Gtkada.Builder;
-- with Glib.Object, Gdk.RGBA, Pango.Font;
-- with dStrings;        use dStrings;
-- with Vte.Terminal, VTE.Enums;
-- with Glib.Error, Glib.Spawn;
with System;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Characters.Conversions;
with GNAT.Strings;
with Gtk.Widget; with Gtk.Main;
with Gtk.Label, Gtk.Check_Button, Gtk.Color_Button;
with Gtk.Tool_Button, Gtk.Font_Button, Gtk.Spin_Button;
with Gtk.Combo_Box;
with Gtk.Notebook;
with Error_Log;
with Host_Functions;
with String_Conversions;
with Blobs, Blobs.Base_64;
with Config_File_Manager;
with Help_About;
with Bliss_Term_Version;  -- , CSS_Management;
package body Setup is

   the_builder : Gtkada_Builder;
   the_config_file_name : text;
   config_data : Config_File_Manager.config_file;
   
   procedure Initialise_Setup(Builder : in out Gtkada_Builder;
                              from_configuration_file : in text;
                              usage : in text) is
      use Gtk.Label;
   begin
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Initialise_Setup: Start.");
      the_builder := Builder;  -- save for later use
      the_config_file_name := from_configuration_file;
      Register_Handler(Builder      => Builder,
                       Handler_Name => "setup_close_clicked_cb",
                       Handler      => Setup_Close_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "setup_cancel_clicked_cb",
                       Handler      => Setup_Cancel_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "setup_help_clicked_cb",
                       Handler      => Setup_Show_Help'Access);
                       
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_setup_delete_event_cb",
                       Handler      => Setup_Hide_On_Delete'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "dialogue_setup_destroy_cb",
                       Handler      => Setup_Close_CB'Access);
      
      -- set up: load the fields from the configuration file
      Load_Data_From(config_file_name=>the_config_file_name, Builder=>Builder,
                     with_initially_setup => false);
   end Initialise_Setup;

   function Adjust_Configuration_Path(from : in text) return text is
      use Ada.Directories;
   begin
      if (Length(from) > 0) and then
         (Wide_Element(from, 1) /= '/') then
         if Wide_Element(from, 1) = '~' then -- user's home directory
            return Host_Functions.Get_Environment_Value(for_variable=>"HOME") &
                   Sub_String(from, starting_at => 2, 
                              for_characters => Length(from) - 1);
         else  -- current directory
            return Value(Current_Directory) & "/" & from;
         end if;
      else
         return from;
      end if;
   end Adjust_Configuration_Path;

   procedure Child_Ready(terminal: Vte.Terminal.Vte_Terminal; 
                         pid : Glib.Spawn.GPid;
                         error : Glib.Error.GError) is --; 
                         -- user_data : System.Address) is
      -- Depending on which terminal (i.e. whether there is one or more left),
      -- either delete the current tab or kill the application.
      use Glib.Spawn;
      use Vte.Terminal;
   begin
      if terminal /= null
      then
         if (pid = -1)
         then  -- Execute the quit operation (by injecting the relevant signal)
            Gtk.Main.Main_Quit;    -- *********FIX ME************
         end if;
      end if;
   end Child_Ready;
   
   procedure Child_Ready_CB(Object : access Gtkada_Builder_Record'Class) is
      use Glib, Glib.Spawn, Glib.Error;
      use Vte.Terminal;
      the_terminal : Vte.Terminal.Vte_Terminal;
      term_id : UTF8_string := "Term1";         -- ********FIX ME**********
      null_error : Glib.Error.GError := Error_New(Unknown_Quark, 0, "");
   begin
      the_terminal := Vte_Terminal(Get_Object(Gtkada_Builder(Object),term_id));
      Child_Ready(the_terminal, -1, null_error);
   end Child_Ready_CB;
            
   procedure Load_Data_From(config_file_name : text;
                            Builder  : in Gtkada_Builder;
                            with_initially_setup : boolean := true) is
      use Glib;  -- , Glib.Object, Glib.Application;
      use Gdk.RGBA;
      use Gtk.Check_Button, Gtk.Color_Button;
      use Gtk.Font_Button;
      use Gtk.Spin_Button;
      use String_Conversions, dStrings;
      use Config_File_Manager;
      use Blobs, Blobs.Base_64;
      procedure Load_Colour(to_colour_button : in UTF8_string; 
                            with_id : in wide_string;
                            from_config_data: in config_file) is
         config_data: Config_File_Manager.config_file renames from_config_data;
         colour_btn : Gtk.Color_Button.gtk_color_button;
         the_colour : Gdk.RGBA.Gdk_RGBA;
         succeeded  : boolean;
      begin
         colour_btn := gtk_color_button(Get_Object(Builder, to_colour_button));
         Parse(the_colour, 
               To_UTF8_String(Read_Parameter(config_data, 
                                             in_section => "COLOUR", 
                                             with_id => with_id)), 
               succeeded);
         if succeeded then
            Set_Rgba(colour_btn, the_colour);
         end if;
      end Load_Colour;
      procedure Load_Spin(to_spin_entry : in UTF8_string; 
                          with_id : in wide_string;
                          from_config_data: in config_file) is
         config_data: Config_File_Manager.config_file renames from_config_data;
         spin_entry : Gtk.Spin_Button.gtk_spin_button;
         entry_value: integer;
      begin
         spin_entry := gtk_spin_button(Get_Object(Builder, to_spin_entry));
         entry_value:= Read_Parameter(config_data, in_section => "TERMINAL", 
                                                with_id => with_id);
         Set_Value(spin_entry, Glib.GDouble(Float(entry_value)));
      end Load_Spin;
      function Get_Env(with_name : in UTF8_String; 
                       from_list : in GNAT.Strings.String_List) 
      return UTF8_String is
         -- Get the specified environment variable from the string list.
         -- This function is included here to extract the strings from
         -- Glib.Spawn, not Glib.Application since there is a missing creator
         -- for the command line environment in Glib.Application.
         use Ada.Strings.Fixed;
      begin
         for item in from_list'Range loop
            if from_list(item).all(1..with_name'Length) = with_name
            then  -- found what we are looking form
               return from_list(item).all(Index(from_list(item).all,"=",1)+1 .. 
                                          from_list(item).all'Last);
            end if;
         end loop;
         return "/bin/bash";  -- Shouldn't get here unless it wasn't found
      end Get_Env;
      procedure Free_String_List(env_list : in out GNAT.Strings.String_List) is
         -- GNAT.Strings.String_List needs to be manually freed at the end of
         -- its life :-(
         -- This is done by freeing each string in the list (each string is
         -- actually a pointer to a string).  The list itself is not a pointer,
         -- so Ada automatically frees it (therefore it is not done here).
      begin
         for item in env_list'Range loop
            GNAT.Strings.Free(env_list(item));
         end loop;
      end Free_String_List;
      check_box   : Gtk.Check_Button.gtk_check_button;
      font_btn    : Gtk.Font_Button.gtk_font_button;
      start_value : integer;
      the_environment : GNAT.Strings.String_List := Glib.Spawn.Get_Environ;
      the_terminal: Vte.Terminal.Vte_Terminal;
      current_dir : text;
      num_tabs    : positive := 1;
      the_notebook: Gtk.Notebook.Gtk_Notebook;
      the_buffer  : text;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Load_Data_From: Start");
      -- Check that the configuration file global variable is set
      if Length(the_config_file_name) = 0 then  -- set if not
         the_config_file_name := config_file_name;
      end if;
      -- Open and operate on the configuraiton file
      if Is_Config_File_Loaded(for_config => config_data)
      then  -- already done a load - just reload
         Error_Log.Debug_Data(at_level => 9, 
                              with_details => "Load_Data_From: Reloading config");
         Load(into_the_configuration_details => config_data);
      else  -- not yet loaded - set up and load
         Error_Log.Debug_Data(at_level => 9, 
                              with_details => "Load_Data_From: Loading new config");
         Load(the_file_with_name => To_String(the_config_file_name),
              into_the_configuration_details => config_data);
      end if;
      -- Work through the configuration file parameters, loading as we go
      -- a. Colours and Font
      check_box:=gtk_check_button(Get_Object(Builder, 
                                            "checkbtn_theme_colours_default"));
      Set_Active(check_box, Read_Parameter(config_data, 
                                           in_section => "COLOUR", 
                                           with_id => "UseThemeColours"));
      Load_Colour(to_colour_button =>  "colour_text", 
                  with_id => "Text", from_config_data => config_data);
      Load_Colour(to_colour_button =>  "colour_background", 
                  with_id => "Background", from_config_data => config_data);
      Load_Colour(to_colour_button =>  "colour_highlight", 
                  with_id => "Highlight", from_config_data => config_data);
      Load_Colour(to_colour_button =>  "colour_bold", 
                  with_id => "Bold", from_config_data => config_data);
      -- a.1 (Font)
      font_btn := gtk_font_button(Get_Object(Builder, "terminal_font"));
      Set_Font(font_btn, Value(Read_Parameter(config_data, 
                                              in_section => "FONT", 
                                              with_id => "Name")));
      start_value := Read_Parameter(config_data, in_section => "FONT", 
                                                 with_id => "Start");
      font_start_char := wide_character'Val(start_value);
      -- b. Terminal Details
      Load_Spin(to_spin_entry => "setup_dimension_rows", 
                with_id  => "Rows", from_config_data => config_data);
      Load_Spin(to_spin_entry => "setup_dimension_columns", 
                with_id  => "Columns", from_config_data => config_data);
      
      Load_Spin(to_spin_entry => "setup_scrollback", 
                with_id  => "ScrollBack", from_config_data => config_data);
      check_box := gtk_check_button(Get_Object(Builder, 
                                               "checkbtn_save_terminals"));
      Set_Active(check_box, Read_Parameter(config_data, 
                                           in_section => "TERMINAL", 
                                           with_id => "SaveTerminals"));
      -- Terminal Configuration
      -- Get the current directory (as the default starting point)
      current_dir := Value(Ada.Directories.Current_Directory);
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Load_Data_From: current directory = '" & current_dir & "'.");
      -- Get the number of tabs to load (default is 1 if none are specified)
      if Read_Parameter(config_data, 
                        in_section => "TABS", with_id => "TabCount") > 0
      then
         num_tabs := Read_Parameter(config_data, 
                                    in_section=>"TABS", with_id=>"TabCount");
      end if;
      -- Get a pointer to the notebook into which the terminal(s) are inserted
      the_notebook := Gtk.Notebook.gtk_notebook(Get_Object(Builder, 
                                                         "notebook_terminal"));
      -- load the set-up configuration data to each terminal on each tab
      for term_num in 1 .. num_tabs loop
         Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Load_Data_From: Setting up terminal at tab '" & "label_term" & Value(term_num'Image(2..term_num'Image'Length)) & "'.");
         if term_num = 1
          then  -- first one exists in the GLADE file
            the_terminal := Vte.Terminal.Vte_Terminal(Get_Object(Builder,"Term"
                                  & term_num'Image(2..term_num'Image'Length)));
            if not with_initially_setup then
               Register_Handler(Builder      => Builder,
                                Handler_Name => "child_exited_handler",
                                Handler      => Child_Ready_CB'Access);
            end if;
         elsif ((not with_initially_setup) or else
                (term_num > positive(Gtk.Notebook.Get_N_Pages(the_notebook))))
         then  -- need to create the tab and the terminal
            -- Create the terminal
            if Read_Parameter(config_data, in_section => "TERMINAL", 
                                           with_id => "SaveTerminals")
             then
               the_buffer := Read_Parameter(config_data, in_section=>"TABS", 
                                            with_id => "Term" & Ada.Characters.
                                    Conversions.To_Wide_String(term_num'Image
                                                   (2..term_num'Image'Length)));
               Vte.Terminal.Vte_New_With_Buffer(the_terminal, 
                                                Decode(Value(the_buffer)));
            else
               the_terminal := Vte.Terminal.Vte_Terminal_New;
            end if;
            -- Create the tab
            Gtk.Notebook.Append_Page(the_notebook,  the_terminal);
            Gtk.Notebook.Set_Current_Page(the_notebook);  -- set to last page
            Gtk.Notebook.Set_Tab_Label_Text(the_notebook, the_terminal,
                            "Term" & term_num'Image(2..term_num'Image'Length));
            -- Connect the terminal to its handler
            null;
         end if;
         -- Load the setup for the tab's window
         Load_Setup(to_terminal_window => the_terminal, 
                    is_preconfigured => with_initially_setup);
         -- Start the new shell
         if not with_initially_setup then
            Vte.Terminal.Spawn_Async(terminal => the_terminal,
                                pty_flags => VTE_PTY_DEFAULT,
                                working_directory=>"", -- To_UTF8_String(current_dir),
                                argv => Get_Env(with_name => "SHELL", --command
                                                 from_list => the_environment),
                                envv => "",  -- environment
                                spawn_flags => 0,
                                child_setup => null,
                                child_setup_data => System.Null_Address,
                                child_setup_data_destroy => null,
                                timeout => Vte.Terminal.timeout_period(-1),
                                cancellable => null,
                                callback => Child_Ready'Access,
                                user_data => System.Null_Address);
         end if;
         Free_String_List(the_environment);
      end loop;
   end Load_Data_From;
    
   procedure Load_Data_To(config_file_name : text;
                          Builder  : in Gtkada_Builder) is
      use Glib;
      use Gdk.RGBA;
      use Gtk.Check_Button, Gtk.Color_Button;
      use Gtk.Font_Button;
      use Gtk.Spin_Button;
      use String_Conversions, dStrings;
      use Config_File_Manager;
      use Blobs, Blobs.Base_64;
      procedure Save_Colour(from_colour_button : in UTF8_string; 
                            with_id : in wide_string;
                            to_config_data: in out config_file) is
         config_data: Config_File_Manager.config_file renames to_config_data;
         colour_btn : Gtk.Color_Button.gtk_color_button;
         the_colour : Gdk.RGBA.Gdk_RGBA;
      begin
         colour_btn:= gtk_color_button(Get_Object(Builder,from_colour_button));
         Get_Rgba(colour_btn, the_colour);
         Put(parameter => From_UTF8_String(To_String(the_colour)),
             into => config_data, in_section => "COLOUR", with_id => with_id);
      end Save_Colour;
      procedure Save_Spin(from_spin_entry : in UTF8_string; 
                          with_id : in wide_string;
                          to_config_data: in out config_file) is
         config_data: Config_File_Manager.config_file renames to_config_data;
         spin_entry : Gtk.Spin_Button.gtk_spin_button;
      begin
         spin_entry := gtk_spin_button(Get_Object(Builder, from_spin_entry));
         Put(parameter=>integer(Get_Value_As_Int(spin_entry)),into=>config_data,
             in_section => "TERMINAL", with_id => with_id);
      end Save_Spin;
      check_box   : Gtk.Check_Button.gtk_check_button;
      font_btn    : Gtk.Font_Button.gtk_font_button;
      the_terminal: Vte.Terminal.Vte_Terminal;
      num_tabs    : positive := 1;
      the_notebook: Gtk.Notebook.Gtk_Notebook;
      the_buffer  : text;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Load_Data_To: Start");
      -- Open and operate on the configuraiton file
      if config_file_name /= the_config_file_name
      then  -- Desired file not yet open so open it
         Error_Log.Debug_Data(at_level => 9, 
                              with_details => "Load_Data_To: Loading new file");
         Load(the_file_with_name => To_String(the_config_file_name),
              into_the_configuration_details => config_data);
      end if;
      -- Work through the configuration file parameters, saving as we go
      -- a. Colours and Font
      check_box:=gtk_check_button(Get_Object(Builder, 
                                            "checkbtn_theme_colours_default"));
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Load_Data_To: Put UseThemeColours...");
      Put(parameter => Get_Active(check_box), into => config_data,
          in_section => "COLOUR", with_id => "UseThemeColours");
      Save_Colour(from_colour_button =>  "colour_text", 
                  with_id => "Text", to_config_data => config_data);
      Save_Colour(from_colour_button =>  "colour_background", 
                  with_id => "Background", to_config_data => config_data);
      Save_Colour(from_colour_button =>  "colour_highlight", 
                  with_id => "Highlight", to_config_data => config_data);
      Save_Colour(from_colour_button =>  "colour_bold", 
                  with_id => "Bold", to_config_data => config_data);
      -- a.1 (Font)
      font_btn := gtk_font_button(Get_Object(Builder, "terminal_font"));
      Put(parameter=> From_UTF8_String(Get_Font(font_btn)), into=> config_data,
          in_section => "FONT", with_id => "Name");
      Put(parameter=> wide_character'Pos(font_start_char), into => config_data,
          in_section => "FONT", with_id => "Start");
      -- b. Terminal Details
      Save_Spin(from_spin_entry => "setup_dimension_rows", 
                with_id  => "Rows", to_config_data => config_data);
      Save_Spin(from_spin_entry => "setup_dimension_columns", 
                with_id  => "Columns", to_config_data => config_data);
      Save_Spin(from_spin_entry => "setup_scrollback", 
                with_id  => "ScrollBack", to_config_data => config_data);
      check_box := gtk_check_button(Get_Object(Builder, 
                                               "checkbtn_save_terminals"));
      Put(parameter => Get_Active(check_box), into => config_data,
          in_section => "TERMINAL", with_id => "SaveTerminals");
      -- Get a pointer to the notebook into which the terminal(s) are inserted
      the_notebook := Gtk.Notebook.gtk_notebook(Get_Object(Builder, 
                                                         "notebook_terminal"));
      -- Terminal Configuration
      num_tabs := positive(Gtk.Notebook.Get_N_Pages(the_notebook));
      if Read_Parameter(config_data, in_section => "TERMINAL", 
                                     with_id => "SaveTerminals")
      then
         Put(parameter => num_tabs, 
             into => config_data, in_section => "TABS", with_id => "TabCount");
      else
         Put(parameter => 1, 
             into => config_data, in_section => "TABS", with_id => "TabCount");
      end if;
      -- Load the set-up configuration data to each terminal on each tab to
      -- ensure that it complies with any changes made to the configuration
      for term_num in 1 .. num_tabs loop
         the_terminal := Vte.Terminal.Vte_Terminal(Get_Object(Builder, "Term" &
                                    term_num'Image(2..term_num'Image'Length)));
         Load_Setup(to_terminal_window => the_terminal);
         -- For comleteness, save out the terminal history (if specified) to
         -- the configuration file
         if Read_Parameter(config_data, in_section => "TERMINAL", 
                                        with_id => "SaveTerminals")
         then  -- history should be kept, so update it for this terminal
            the_buffer := Value(Encode(Vte.Terminal.Get_Text(the_terminal)));
            Put(parameter => the_buffer, 
                into => config_data, in_section => "TABS", 
                with_id => "Term" & Ada.Characters.Conversions.
                                    To_Wide_String(term_num'Image
                                                  (2..term_num'Image'Length)));  -- *** THIS (AND ELSEWHERE) SHOULD BE TAB NAME ***
         end if;
      end loop;
      -- Finally, save the configuration details to file
      Save(the_configuration_details => config_data);
   end Load_Data_To;

   procedure Load_Setup(to_terminal_window : in Vte.Terminal.Vte_Terminal;
                        is_preconfigured   : in boolean := false) is
      -- Load the set-up configuration to the specified terminal
      -- Terminal Configuration for the specified window
      use Gdk.RGBA;
      use Gtk.Spin_Button;
      -- use Gtk.Check_Button;
      use Gtk.Color_Button;
      use Vte.Terminal;
      the_terminal: Vte.Terminal.Vte_Terminal renames to_terminal_window;
      cols : natural := 80;
      row  : natural := 25;
      spin_entry  : Gtk.Spin_Button.gtk_spin_button;
      the_colour  : Gdk.RGBA.Gdk_RGBA;
      colour_btn  : Gtk.Color_Button.gtk_color_button;
      scroll_back : natural := 0;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Load_Setup: Start");
      -- Terminal rows and columns
      spin_entry := 
         gtk_spin_button(Get_Object(the_builder, "setup_dimension_columns"));
      cols := Natural(Get_Value_As_Int(spin_entry));
      spin_entry := 
         gtk_spin_button(Get_Object(the_builder, "setup_dimension_rows"));
      row  := Natural(Get_Value_As_Int(spin_entry));
      Vte.Terminal.Set_Size(terminal=>the_terminal, columns=>cols, rows=>row);
      -- Terminal font
      Vte.Terminal.Set_Font(terminal => the_terminal,
                            to_font_desc => Setup.The_Font_Description);
      if Setup.The_Font_Name = "Blissymbolics"
      then  -- Ensure encoding and variable character width is correctly set
         begin
            Vte.Terminal.Set_Encoding(for_terminal=>the_terminal, to=>"UTF8");
            Vte.Terminal.Set_Character_Width(for_terminal => the_terminal,
                                             to =>narrow);
            exception
               when Encoding_Error =>  -- just silently log the error
                  Error_Log.Put(the_error => 1,
                                error_intro => "Load_Setup error", 
                                error_message=>"Could not set encoding for " &
                                               "the terminal");
         end;
      end if;
      -- Terminal colours
      colour_btn := 
         gtk_color_button(Get_Object(the_builder,"colour_background"));
      Get_Rgba(colour_btn, the_colour);
      Vte.Terminal.Set_Colour_Background(terminal => the_terminal, 
                                         background => the_colour);
      colour_btn := gtk_color_button(Get_Object(the_builder, "colour_text"));
      Get_Rgba(colour_btn, the_colour);
      Vte.Terminal.Set_Colour_Text(terminal => the_terminal, 
                                   text_colour => the_colour);
      colour_btn := gtk_color_button(Get_Object(the_builder, "colour_bold"));
      Get_Rgba(colour_btn, the_colour);
      Vte.Terminal.Set_Colour_Bold(terminal => the_terminal, 
                                   bold_colour => the_colour);
      colour_btn:=gtk_color_button(Get_Object(the_builder,"colour_highlight"));
      Get_Rgba(colour_btn, the_colour);
      Vte.Terminal.Set_Colour_Bold(terminal => the_terminal, 
                                   bold_colour => the_colour);
      -- Scroll-back line count requested
      spin_entry := 
         gtk_spin_button(Get_Object(the_builder, "setup_scrollback"));
      scroll_back := Natural(Get_Value_As_Int(spin_entry));
      Vte.Terminal.Set_Scrollback_Lines(terminal => the_terminal, 
                                        lines => scroll_back);
   end Load_Setup;

   procedure Show_Setup(Builder : in Gtkada_Builder) is
   begin
      Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Builder,"dialogue_setup")));
   end Show_Setup;
      
   procedure Setup_Cancel_CB (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Cancel_CB: Start");
      -- reset the data
      Load_Data_From(config_file_name => the_config_file_name, 
                     Builder => Gtkada_Builder(Object));
      -- and hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
   end Setup_Cancel_CB;
   
   procedure Setup_Close_CB (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Close_CB: Start");
      -- save the data
      Load_Data_To(config_file_name => the_config_file_name, 
                   Builder => Gtkada_Builder(Object));
      -- and hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
   end Setup_Close_CB;

   function Setup_Hide_On_Delete
           (Object : access Glib.Object.GObject_Record'Class) return Boolean is
      use Gtk.Widget, Glib.Object;
      result : boolean;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Hide_On_Delete: Start");
      result := Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record(Object.all)'Access);
      -- Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         --             (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
      return result;
      -- return Gtk.Widget.Hide_On_Delete(Gtk_Widget_Record( 
         --               (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup").all))'Access);
   end Setup_Hide_On_Delete;

   procedure Setup_Show_Help (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Show_Help: Start");
      -- Firstly hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
      -- Secondly, show the Help dialogue box
      Help_About.Show_Help_About(Gtkada_Builder(Object));
   end Setup_Show_Help;

    -- Setup/Configuration page controls
    -- Selected font management:
   function The_Font return UTF8_string is
      -- The currently selected font for the system
      use Gtk.Font_Button;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "terminal_font"));
      return Get_Font(font_btn);
   end The_Font;
  
   function The_Font_Name return UTF8_string is
      -- The currently selected font for the system
      use Gtk.Font_Button, Pango.Font;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "terminal_font"));
      return Get_Family(Get_Font_Desc(font_btn));
   end The_Font_Name;
   
   function Font_Size return gDouble is
      -- The currently selected font size for the system.
      use Gtk.Font_Button;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "terminal_font"));
      return gDouble(Get_Font_Size(font_btn));
   end Font_Size;
   
   function The_Font_Description return Pango.Font.Pango_Font_Description is
      -- The currently selected font in Pango font description format
      use Gtk.Font_Button, Pango.Font;
      font_btn   : Gtk.Font_Button.gtk_font_button;
   begin
      font_btn := gtk_font_button(Get_Object(the_builder, "terminal_font"));
      return Get_Font_Desc(font_btn);
   end The_Font_Description;
   
   function Font_Start_Character return wide_character is
      -- The character to start switching from the default font to the
      -- specified font.
   begin
      return font_start_char;
   end Font_Start_Character;
   
    -- Terminal colour management:
   function Text_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected text colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:= gtk_color_button(Get_Object(the_builder,"colour_text"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Text_Colour;
   
   function Background_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected background colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:= gtk_color_button(Get_Object(the_builder,"colour_backgrounbd"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Background_Colour;
    
   function Highlight_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected highlight colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:=gtk_color_button(Get_Object(the_builder,"colour_highlight"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Highlight_Colour;
   
   function Bold_Colour return Gdk.RGBA.Gdk_RGBA is
      -- The currently selected bold colour for the system
      use Gtk.Color_Button, Gdk.RGBA;
      colour_btn : Gtk.Color_Button.gtk_color_button;
      the_colour : Gdk.RGBA.Gdk_RGBA;
   begin
      colour_btn:=gtk_color_button(Get_Object(the_builder,"colour_bold"));
      Get_Rgba(colour_btn, the_colour);
      return the_colour;
   end Bold_Colour;
   
begin
   Bliss_Term_Version.Register(revision => "$Revision: v1.0.0$",
                              for_module => "Setup");
end Setup;
