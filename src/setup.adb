-----------------------------------------------------------------------
--                                                                   --
--                             S E T U P                             --
--                                                                   --
--                              B o d y                              --
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
--  General Public Licence distributed with  Bliss_Term.             --
--  If  not,  write to the Free Software  Foundation,  51  Franklin  --
--  Street, Fifth Floor, Boston, MA 02110-1301, USA.                 --
--                                                                   --
-----------------------------------------------------------------------
-- with Gtkada.Builder;  use Gtkada.Builder;
-- with Glib.Object, Gdk.RGBA, Pango.Font;
-- with dStrings;        use dStrings;
-- with Gtk.Terminal;
with System;
with Ada.Directories;
with Ada.Characters.Conversions;
with Ada.Strings.UTF_Encoding.Wide_Strings;
with Gtk.Widget; with Gtk.Main;
with Gtk.Window;
with Gtk.Label, Gtk.Check_Button, Gtk.Color_Button;
with Gtk.Tool_Button, Gtk.Font_Button, Gtk.Spin_Button;
with Gtk.Combo_Box;
with Gtk.Notebook;
with Gtk.Text_Buffer, Gtk.Text_Iter;
with Gtk.Terminal.CInterface;
with Error_Log;
with Host_Functions;
with String_Conversions;
with Blobs, Blobs.Base_64;
with Config_File_Manager;
with Help_About;
with Bliss_Term_Version, CSS_Management;
package body Setup is

   the_builder          : Gtkada_Builder;
   the_config_file_name : text;
   config_data          : Config_File_Manager.config_file;
   css_file_name        : text;
   
   procedure Initialise_Setup(Builder : in out Gtkada_Builder;
                              from_configuration_file : in text;
                              using_css : in text;
                              usage : in text) is
      use Gtk.Label, Gtk.Text_Buffer, Gtk.Tool_Button;
      text_buffer: Gtk.Text_Buffer.gtk_text_buffer;
      the_button : Gtk.Tool_Button.gtk_tool_button;
   begin  -- Initialise_Setup
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
      -- set up: load the CSS file into the setup dialogue box
      css_file_name := using_css;
      text_buffer := gtk_text_buffer(Get_Object(the_builder,"textbuffer_css"));
      Set_Text(text_buffer, 
               To_UTF8_String(CSS_Management.Get_Text(Value(css_file_name))));
      -- set up: load the buttons' CSS data
      the_button:=gtk_tool_button(Get_Object(Builder, "button_add"));
      CSS_Management.Load(the_button => the_button);
      the_button:=gtk_tool_button(Get_Object(Builder, "button_delete"));
      CSS_Management.Load(the_button => the_button);
      the_button:=gtk_tool_button(Get_Object(Builder, "button_setup"));
      CSS_Management.Load(the_button => the_button);
      the_button:=gtk_tool_button(Get_Object(Builder, "button_help_about"));
      CSS_Management.Load(the_button => the_button);
      
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Initialise_Setup: End.");
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

   procedure Title_Changed(terminal : Gtk.Terminal.Gtk_Terminal; 
                           title    : UTF8_String := "";
                           icon_name: UTF8_String := "") is
      -- Called whenever the title is changed for the terminal by the
      -- underlying terminal driver (usually to set it to the full path name).
      use Gtk.Window;
      main_window : Gtk.Window.Gtk_Window;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Title_Changed: Start." & " Title ='" & Ada.Characters.Conversions.To_Wide_String(title) & "'.");
      main_window:= Gtk.Window.Gtk_Window(
                         Get_Object(Gtkada_Builder(the_builder),"bliss_term"));
      Error_Log.Debug_Data(at_level => 9, with_details => "Title_Changed: Got main window.");
      if main_window /= null then
         if title'Length > 0 then
            Gtk.Window.Set_Title(main_window, title);
         end if;
         if icon_name'Length > 0 then
            Gtk.Window.Set_Wmclass(main_window, icon_name, icon_name);
         end if;
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Title_Changed: Finish.");
   end Title_Changed;

   procedure Child_Closed(terminal: Gtk.Terminal.Gtk_Terminal) is
      -- Depending on which terminal (i.e. whether there is one or more left),
      -- either delete the current tab or kill the application.
      use Gtk.Terminal;
      use Config_File_Manager;
      use Blobs, Blobs.Base_64;
      the_notebook  : Gtk.Notebook.Gtk_Notebook;
      the_buffer    : text;
      term_num      : natural;
   begin
      Error_Log.Debug_Data(at_level=> 7, with_details=> "Child_Closed: Start");
      -- Get the notebook to work out this tab number and the number of tabs
      the_notebook := Gtk.Notebook.gtk_notebook(
                  Get_Object(Gtkada_Builder(the_builder),"notebook_terminal"));
      -- Issue shutdown command to this terminal's task(s)
      Error_Log.Debug_Data(at_level=> 9, with_details=> "Child_Closed: Issuing Gtk.Terminal.Shut_Down command for the terminal");
      Gtk.Terminal.Shut_Down(the_terminal => terminal);
      -- If required, save the terminal data for this terminal
      if Read_Parameter(config_data, in_section => "TERMINAL", 
                                        with_id => "SaveTerminals")
      then  -- history should be kept, so update it for this terminal
         term_num := Gtk.Terminal.Get_ID(for_terminal => terminal);
         Error_Log.Debug_Data(at_level => 9, with_details => "Child_Closed: Saving terminal's buffer at terminal number" & term_num'Wide_Image & ".");
         the_buffer := Value(Encode(Gtk.Terminal.Get_Text(terminal)));
         Put(parameter => the_buffer, 
             into => config_data, in_section => "TABS", 
             with_id => "Term" & Ada.Characters.Conversions.
                                    To_Wide_String(term_num'Image
                                                  (2..term_num'Image'Length)));
         Put(parameter => Value(Gtk.Terminal.Get_Path(for_terminal=>terminal)),
             into => config_data, in_section => "PATHS", 
             with_id => "Term" & Ada.Characters.Conversions.
                                    To_Wide_String(term_num'Image
                                                  (2..term_num'Image'Length)));
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Child_Closed: Gtk.Notebook.Get_N_Pages(the_notebook)" & Gtk.Notebook.Get_N_Pages(the_notebook)'Wide_Image & ".");
      if Gtk.Notebook.Get_N_Pages(the_notebook) = 1
      then  -- Last tab - execute the quit applicaton operation
          -- First, save the configuration details to file if necessary
         if Read_Parameter(config_data, in_section => "TERMINAL", 
                                        with_id => "SaveTerminals")
         then  -- history should be kept, so save it to the configuration file
            Error_Log.Debug_Data(at_level => 9, with_details => "Child_Closed: Save(the_configuration_details}.");
            Save(the_configuration_details => config_data);
         end if;
         -- Now exit the application
         Gtk.Main.Main_Quit;
      end if;
   end Child_Closed;
   
   procedure Close_The_Terminal(at_number : in natural) is
      -- Close the terminal at the specified terminal number (which is actually
      -- the tab number, where the first tab is 1 (not 0)).
      -- This does not remove or delete the tab.
      use Gtk.Terminal;
      the_notebook : Gtk.Notebook.Gtk_Notebook;
      the_terminal : Gtk.Terminal.Gtk_Terminal;
   begin
      Error_Log.Debug_Data(at_level => 6, 
                           with_details => "Close_The_Terminal: Start" & ". At number " & at_number'Wide_Image & ".");
      the_notebook:= Gtk.Notebook.gtk_notebook(
                  Get_Object(Gtkada_Builder(the_builder),"notebook_terminal"));
      the_terminal:= Gtk_Terminal(Gtk.Notebook.
                                    Get_Nth_Page(the_notebook,
                                                 page_num=>Gint(at_number-1)));
      if the_terminal /= null then
         Child_Closed(the_terminal);
      else  -- Some trouble with the terminal ID
         Error_Log.Put(the_error => 5,
                       error_intro => "Close_The_Terminal error", 
                       error_message=>"Could not get the termnal for term_id");
      end if;
   end Close_The_Terminal;

   function Set_User_Environment_Variables return text is
      -- Extract the user's environment variables, either from the
      -- configuration file or from the environment itself if not specified in
      -- that configuration file, and return as a string.
      use Config_File_Manager;
      environment : text;
   begin
         -- Load the enviornment variable
      Clear(environment);
      if Length(Read_Parameter(config_data, in_section => "ENVIRONMENT", 
                               with_id => "Term")) = 0
      then
         Append("TERM="&Gtk.Terminal.CInterface.terminal_name,to=>environment);
         Put(parameter=>Value_From_Wide(Gtk.Terminal.CInterface.terminal_name),
             into => config_data, in_section => "ENVIRONMENT", 
             with_id => "Term");
      else
         Append(tail => "TERM=" &
                        Read_Parameter(config_data,in_section=>"ENVIRONMENT",
                                       with_id => "Term"), 
                to => environment);
      end if;
      if Length(Read_Parameter(config_data, in_section => "ENVIRONMENT", 
                               with_id => "Home")) = 0
      then
         Append(wide_tail => ",HOME=" & 
                    Host_Functions.Get_Environment_Value(for_variable=>"HOME"),
                to => environment);
         Put(parameter=>Host_Functions.Get_Environment_Value(for_variable=>"HOME"),
             into => config_data, in_section => "ENVIRONMENT", 
             with_id => "Home");
      else
         Append(tail => ",HOME=" &
                        Read_Parameter(config_data,in_section=>"ENVIRONMENT",
                                       with_id => "Home"), 
                to => environment);
      end if;
      if Length(Read_Parameter(config_data, in_section => "ENVIRONMENT", 
                               with_id => "Shell")) = 0
      then
         Append(wide_tail => ",SHELL=" & 
                   Host_Functions.Get_Environment_Value(for_variable=>"SHELL"),
                to => environment);
         Put(parameter=>Host_Functions.Get_Environment_Value(for_variable=>"SHELL"),
             into => config_data, in_section => "ENVIRONMENT", 
             with_id => "Shell");
      else
         Append(tail => ",SHELL=" &
                        Read_Parameter(config_data,in_section=>"ENVIRONMENT",
                                       with_id => "Shell"), 
                to => environment);
      end if;
      if Length(Read_Parameter(config_data, in_section => "ENVIRONMENT", 
                               with_id => "User")) = 0
      then
         Append(wide_tail => ",USER=" & 
                   Host_Functions.Get_Environment_Value(for_variable=>"USER"),
                to => environment);
         Put(parameter=>Host_Functions.Get_Environment_Value(for_variable=>"USER"),
             into => config_data, in_section => "ENVIRONMENT", 
             with_id => "User");
      else
         Append(tail => ",USER=" &
                        Read_Parameter(config_data,in_section=>"ENVIRONMENT",
                                       with_id => "User"), 
                to => environment);
      end if;
      if Length(Read_Parameter(config_data, in_section => "ENVIRONMENT", 
                               with_id => "Logname")) = 0
      then
         Append(wide_tail => ",LOGNAME=" & 
                   Host_Functions.Get_Environment_Value(for_variable=>"LOGNAME"),
                to => environment);
         Put(parameter=>Host_Functions.Get_Environment_Value(for_variable=>"LOGNAME"),
             into => config_data, in_section => "ENVIRONMENT", 
             with_id => "Logname");
      else
         Append(tail => ",LOGNAME=" &
                        Read_Parameter(config_data,in_section=>"ENVIRONMENT",
                                       with_id => "Logname"), 
                to => environment);
      end if;
      return environment;
   end Set_User_Environment_Variables;
            
   procedure Load_Data_From(config_file_name : text;
                            Builder  : in Gtkada_Builder;
                            with_initially_setup : boolean := true) is
      use Ada.Strings.UTF_Encoding.Wide_Strings;
      use Glib;
      use Gdk.RGBA;
      use Gtk.Check_Button, Gtk.Color_Button;
      use Gtk.Font_Button;
      use Gtk.Spin_Button;
      use String_Conversions;
      use Config_File_Manager;
      use Blobs, Blobs.Base_64;
      initially_setup : boolean := with_initially_setup;
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
      check_box      : Gtk.Check_Button.gtk_check_button;
      font_btn       : Gtk.Font_Button.gtk_font_button;
      start_value    : integer;
      the_terminal   : Gtk.Terminal.Gtk_Terminal;
      the_notebook   : Gtk.Notebook.Gtk_Notebook;
      current_dir    : text;
      num_tabs       : positive := 1;
      the_buffer     : text;
   begin  -- Load_Data_From
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
      check_box := gtk_check_button(Get_Object(Builder, 
                                               "checkbtn_edit_method"));
      Set_Active(check_box, Read_Parameter(config_data, 
                                           in_section => "TERMINAL", 
                                           with_id => "EditMethod"));
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
         if ((not initially_setup) or else
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
               Gtk.Terminal.Gtk_New_With_Buffer(the_terminal, 
                                                Decode(Value(the_buffer)));
               current_dir := Read_Parameter(config_data, in_section=>"PATHS", 
                                            with_id => "Term" & Ada.Characters.
                                    Conversions.To_Wide_String(term_num'Image
                                                   (2..term_num'Image'Length)));
            else
               the_terminal := Gtk.Terminal.Gtk_Terminal_New;
               Clear(current_dir); 
            end if;
            -- Create the tab
            Gtk.Notebook.Append_Page(the_notebook,  the_terminal);
            Gtk.Notebook.Set_Current_Page(the_notebook);  -- set to last page
            Gtk.Notebook.Set_Tab_Label_Text(the_notebook, the_terminal,
                            "Term" & term_num'Image(2..term_num'Image'Length));
            -- and make sure the terminal is visible
            Gtk.Terminal.Show_All(the_terminal);
         else  -- terminal exists, so point to it
            the_terminal:= Gtk.Terminal.Gtk_Terminal(Gtk.Notebook.
                                     Get_Nth_Page(the_notebook,
                                                  page_num=>Gint(term_num-1)));
         end if;
         -- Start the new shell
         if not with_initially_setup then
            Error_Log.Debug_Data(at_level => 9, with_details => "Load_Data_From: Gtk.Terminal.Spawn_Shell with path='" & current_dir & " '.");
            Help_About.Switch_The_Light(the_terminal, 1, true);
            Help_About.Switch_The_Light(the_terminal, 5, true);
            Gtk.Terminal.Spawn_Shell(terminal => the_terminal,
                                working_directory=>To_UTF8_String(current_dir),
                                command => Encode(Host_Functions.
                                   Get_Environment_Value(for_variable=>"SHELL")),
                                environment => 
                                    Encode(To_String(Set_User_Environment_Variables)),
                                use_buffer_for_editing => 
                                       (Internal_Edit_Method = using_textview),
                                title_callback => Title_Changed'Access,
                                callback => Child_Closed'Access,
                                switch_light => Help_About.Switch_The_Light'Access);
            initially_setup := true;
            Error_Log.Debug_Data(at_level => 9, with_details => "Load_Data_From: Gtk.Terminal.Spawn_Shell done.");
         end if;
         Gtk.Terminal.Set_ID(for_terminal => the_terminal, to => term_num);
         -- Load the setup for the tab's window
         Load_Setup(to_terminal_window => the_terminal, 
                    is_preconfigured => initially_setup);
      end loop;
   end Load_Data_From;
    
   procedure Load_Data_To(config_file_name : text;
                          Builder  : in Gtkada_Builder) is
      use Glib;
      use Gdk.RGBA;
      use Gtk.Check_Button, Gtk.Color_Button;
      use Gtk.Font_Button;
      use Gtk.Spin_Button;
      use Gtk.Notebook;
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
      check_box     : Gtk.Check_Button.gtk_check_button;
      font_btn      : Gtk.Font_Button.gtk_font_button;
      the_terminal  : Gtk.Terminal.Gtk_Terminal;
      num_tabs      : positive := 1;
      the_notebook  : Gtk.Notebook.Gtk_Notebook;
      the_buffer    : text;
   begin  -- Load_Data_To
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
      check_box := gtk_check_button(Get_Object(Builder, 
                                               "checkbtn_edit_method"));
      Put(parameter => Get_Active(check_box), into => config_data, 
          in_section => "TERMINAL", with_id => "EditMethod");
      -- Get a pointer to the notebook into which the terminal(s) are inserted
      the_notebook := Gtk.Notebook.gtk_notebook(Get_Object(Builder, 
                                                         "notebook_terminal"));
      -- Terminal Configuration
      num_tabs := positive(Gtk.Notebook.Get_N_Pages(the_notebook));
      if Read_Parameter(config_data, in_section => "TERMINAL", 
                                     with_id => "SaveTerminals")
      then
         null;
      --    num_tabs := Read_Parameter(config_data, in_section => "TABS", 
            --                          with_id => "TabCount");
      else
         Put(parameter => 1, 
             into => config_data, in_section => "TABS", with_id => "TabCount");
      end if;
      -- Load the set-up configuration data to each terminal on each tab to
      -- ensure that it complies with any changes made to the configuration
      for term_num in 1 .. num_tabs loop
         the_terminal:= Gtk.Terminal.Gtk_Terminal(Gtk.Notebook.
                                     Get_Nth_Page(the_notebook,
                                                  page_num=>Gint(term_num-1)));
         Load_Setup(to_terminal_window => the_terminal);
         -- For comleteness, save out the terminal history (if specified) to
         -- the configuration file
         if Read_Parameter(config_data, in_section => "TERMINAL", 
                                        with_id => "SaveTerminals")
         then  -- history should be kept, so update it for this terminal
            the_buffer := Value(Encode(Gtk.Terminal.Get_Text(the_terminal)));
            Put(parameter => the_buffer, 
                into => config_data, in_section => "TABS", 
                with_id => "Term" & Ada.Characters.Conversions.
                                    To_Wide_String(term_num'Image
                                                  (2..term_num'Image'Length)));
            Put(parameter => Value(Gtk.Terminal.
                                   Get_Path(for_terminal=>the_terminal)),
                into => config_data, in_section => "PATHS", 
                with_id => "Term" & Ada.Characters.Conversions.
                                    To_Wide_String(term_num'Image
                                                  (2..term_num'Image'Length)));
         end if;
      end loop;
      -- Finally, save the configuration details to file
      Save(the_configuration_details => config_data);
   end Load_Data_To;

   procedure Load_Setup(to_terminal_window : in Gtk.Terminal.Gtk_Terminal;
                        is_preconfigured   : in boolean := false) is
      -- Load the set-up configuration to the specified terminal
      -- Terminal Configuration for the specified window
      use Gdk.RGBA;
      use Gtk.Spin_Button;
      use Gtk.Color_Button;
      use Gtk.Terminal;
      use dStrings;  -- for logging 9
      the_terminal: Gtk.Terminal.Gtk_Terminal renames to_terminal_window;
      cols : natural := 80;
      row  : natural := 25;
      spin_entry  : Gtk.Spin_Button.gtk_spin_button;
      the_colour  : Gdk.RGBA.Gdk_RGBA;
      colour_btn  : Gtk.Color_Button.gtk_color_button;
      scroll_back : natural := 0;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Load_Setup: Start");
      -- Terminal CSS (may be overwritten by the below set-up)
      Set_CSS_View(for_terminal=>the_terminal, to=>CSS_Management.Load'access);
      -- Terminal font (needs to be dnoe before setting terminal size)
      Error_Log.Debug_Data(at_level => 9, with_details => "Load_Setup: setting terminal font to " & Value(Setup.The_Font_Name) & "...");
      Gtk.Terminal.Set_Font(for_terminal => the_terminal,
                            to_font_desc => Setup.The_Font_Description);
      if Setup.The_Font_Name = "Blissymbolics"
      then  -- Ensure encoding and variable character width is correctly set
         begin
            Gtk.Terminal.Set_Encoding(for_terminal=>the_terminal, to=>"UTF8");
            Gtk.Terminal.Set_Character_Width(for_terminal => the_terminal,
                                             to =>narrow);
            exception
               when Encoding_Error =>  -- just silently log the error
                  Error_Log.Put(the_error => 6,
                                error_intro => "Load_Setup error", 
                                error_message=>"Could not set encoding for " &
                                               "the terminal");
         end;
      end if;
      -- Terminal rows and columns
      spin_entry := 
         gtk_spin_button(Get_Object(the_builder, "setup_dimension_columns"));
      cols := Natural(Get_Value_As_Int(spin_entry));
      spin_entry := 
         gtk_spin_button(Get_Object(the_builder, "setup_dimension_rows"));
      row  := Natural(Get_Value_As_Int(spin_entry));
      Error_Log.Debug_Data(at_level => 9, with_details => "Load_Setup: setting terminal size to " & cols'Wide_Image & " columns by " & row'Wide_Image & " rows...");
      Gtk.Terminal.Set_Size(terminal=>the_terminal, columns=>cols, rows=>row);
      -- Terminal colours
      colour_btn := 
         gtk_color_button(Get_Object(the_builder,"colour_background"));
      Get_Rgba(colour_btn, the_colour);
      Gtk.Terminal.Set_Colour_Background(terminal => the_terminal, 
                                         background => the_colour);
      colour_btn := gtk_color_button(Get_Object(the_builder, "colour_text"));
      Get_Rgba(colour_btn, the_colour);
      Gtk.Terminal.Set_Colour_Text(terminal => the_terminal, 
                                   text_colour => the_colour);
      colour_btn := gtk_color_button(Get_Object(the_builder, "colour_bold"));
      Get_Rgba(colour_btn, the_colour);
      Gtk.Terminal.Set_Colour_Bold(terminal => the_terminal, 
                                   bold_colour => the_colour);
      colour_btn:=gtk_color_button(Get_Object(the_builder,"colour_highlight"));
      Get_Rgba(colour_btn, the_colour);
      Gtk.Terminal.Set_Colour_Highlight(terminal => the_terminal, 
                                   highlight_colour => the_colour);
      -- Scroll-back line count requested
      spin_entry := 
         gtk_spin_button(Get_Object(the_builder, "setup_scrollback"));
      scroll_back := Natural(Get_Value_As_Int(spin_entry));
      Gtk.Terminal.Set_Scrollback_Lines(terminal => the_terminal, 
                                        lines => scroll_back);
      Error_Log.Debug_Data(at_level => 9, 
                           with_details => "Load_Setup: End");
   end Load_Setup;

   procedure Show_Setup(Builder : in Gtkada_Builder) is
   begin
      Gtk.Widget.Show_All(Gtk.Widget.Gtk_Widget 
                        (Gtkada.Builder.Get_Object(Builder,"dialogue_setup")));
   end Show_Setup;
      
   procedure Setup_Cancel_CB (Object : access Gtkada_Builder_Record'Class) is
      -- Restore the set-up display to that on disk
      use Gtk.Text_Buffer;
      text_buffer: Gtk.Text_Buffer.gtk_text_buffer;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Cancel_CB: Start");
      -- reset the data
      Load_Data_From(config_file_name => the_config_file_name, 
                     Builder => Gtkada_Builder(Object));
      -- including the CSS data
      text_buffer := gtk_text_buffer(Get_Object(the_builder,"textbuffer_css"));
      Set_Text(text_buffer, 
               To_UTF8_String(CSS_Management.Get_Text(Value(css_file_name))));
      -- and hide ourselves
      Gtk.Widget.Hide(Gtk.Widget.Gtk_Widget 
         (Gtkada.Builder.Get_Object(Gtkada_Builder(Object),"dialogue_setup")));
   end Setup_Cancel_CB;
   
   procedure Setup_Close_CB (Object : access Gtkada_Builder_Record'Class) is
      -- Save the setup data to files on disk
      use Gtk.Text_Buffer, Gtk.Text_Iter;
      text_buffer: Gtk.Text_Buffer.gtk_text_buffer;
      start_iter,
      end_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Setup_Close_CB: Start");
      -- save the data
      Load_Data_To(config_file_name => the_config_file_name, 
                   Builder => Gtkada_Builder(Object));
      -- including save the CSS data out to file
      text_buffer := gtk_text_buffer(Get_Object(the_builder,"textbuffer_css"));
      Get_Bounds(text_buffer, start_iter, end_iter);
      CSS_Management.
         Set_Text(for_file => Value(css_file_name),
                  to => From_UTF8_String(
                           Get_Text(text_buffer, start_iter, end_iter, true)));
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
      return result;
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
   
   -- type editing_method is (using_textview, using_emulator);
   function Internal_Edit_Method return editing_method is
      -- Indicates whether the user wants to use the text view method whenever
      -- possible or always wants to use the terminal emulator's editing tools.
      use Gtk.Check_Button;
      check_box      : Gtk.Check_Button.gtk_check_button;
   begin
      check_box := gtk_check_button(Get_Object(the_builder, 
                                               "checkbtn_edit_method"));
      if Get_Active(check_box)
      then
         return using_emulator;
      else
         return using_textview;
      end if;
   end Internal_Edit_Method;

   procedure Save_Configuration_Data is
      -- Save the configuration data back to the configuration file on disk.
      use Config_File_Manager;
   begin
      Save(the_configuration_details => config_data);
   end Save_Configuration_Data;
   
   procedure Set_Tab_Count(to : in natural) is
      -- Set the tab count in the configuration file to that specified,
      -- providing that configuration data for terminals on tabs is specified
      -- to be saved.
      use Config_File_Manager;
   begin
      if Read_Parameter(config_data, in_section => "TERMINAL", 
                                     with_id => "SaveTerminals")
      then
         Error_Log.Debug_Data(at_level => 9, with_details => "Set_Tab_Count: Saving tab count of" & to'Wide_Image & ".");
         Put(parameter => to, 
             into => config_data, in_section => "TABS", with_id => "TabCount");
      end if;
   end Set_Tab_Count;

   function Get_Tab_Count return natural is
      -- Get the tab count as understood bhy the configuration data.
      use Config_File_Manager;
      num_tabs : positive := 1;
   begin
      num_tabs := Read_Parameter(config_data, in_section => "TABS", 
                                     with_id => "TabCount");
      return num_tabs;
   end Get_Tab_Count;
   
begin
   Bliss_Term_Version.Register(revision => "$Revision: v1.0.0$",
                              for_module => "Setup");
end Setup;
