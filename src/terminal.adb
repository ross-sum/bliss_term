-----------------------------------------------------------------------
--                                                                   --
--                          T E R M I N A L                          --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
  --  Copyright (C) 2024 Hyper Quantum Pty Ltd,                        --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package displays the terminal for, which contains the tabs  --
--  for all the terminals as well as the set-up tab.                 --
--  In  addition, the terminal contains the control buttons to  add  --
--  more  terminals  and to call on the Help|About  display  (which  --
--  also contains the application's manual).                         --
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
-- with Gtk.Button, Gtk.Menu_Item, Gtk.Widget;
-- with dStrings;        use dStrings;
-- with Glib;
with System;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Characters.Conversions;
with Glib, Glib.Error;
with Gtk.Widget, Gtk.Image;
with Gtk.Main, Gtk.Window;
with Gtk.Menu;
with Gtk.Notebook;
with Gtk.Terminal, Gtk.Terminal.CInterface;
with Error_Log;
with String_Conversions;
with Host_Functions;
with Bliss_Term_Version;
with CSS_Management;
with Setup;
with Help_About;
package body Terminal is

   Builder : Gtkada_Builder;

   procedure Initialise_Terminal(usage : in text;
                                 path_to_temp  : text:= Value("/tmp/");
                                 glade_filename: text:= Value("bliss_term.glade");
                                 css_filename  : text:= Value("bliss_term.css");
                                 at_config_path: text:= Value(".config/bliss_term.conf")) is
      -- Create the main terminal window, then set up the terminal(s) as per
      -- the requirements laid out in the configuration file.  Start the
      -- operation of the terminal.
      use Glib.Error, Ada.Characters.Conversions;
      Error   : Glib.Error.GError_Access := null;
      count   : Glib.Guint;
      main_window : Gtk.Window.Gtk_Window;
      css_file    : text;
   begin
      -- Set the locale specific data (e.g time and date format)
      -- Gtk.Main.Set_Locale;
      -- Create a Builder and add the XML data
      Gtk.Main.Init;
      -- Connect to the style sheet
      if Locate(fragment => '/', within => glade_filename) > 0
      then -- css file not located in /tmp or similar
         css_file := css_filename;
      else -- no path in glade file name, so assume it is in the temp directory
         css_file := path_to_temp & css_filename;
      end if;
      CSS_Management.Set_Up_CSS(for_file => Value(css_file));
      -- Set up the Builder with the Glade file
      Gtk_New (Builder);
      if Locate(fragment => '/', within => glade_filename) > 0
      then  -- glade file not located in /tmp or similar
         count := Add_From_File (Builder, Value(glade_filename), Error);
      else  -- no path in glade file name, so assume it is in the temp directory
         count := Add_From_File (Builder, Value(path_to_temp & glade_filename), Error);
      end if;
      if Error /= null then
         Error_Log.Put(the_error    => 2, 
                       error_intro  => "Initialise_Terminal: file name error",
                       error_message=> "Error in " & 
                                        To_String(glade_filename) & " : "&
                                        To_Wide_String(Glib.Error.Get_Message 
                                                                 (Error.all)));
         Glib.Error.Error_Free (Error.all);
      end if;
      
      -- Register window destruction
      main_window:= Gtk.Window.Gtk_Window(
                              Get_Object(Gtkada_Builder(Builder),"bliss_term"));
      main_window.On_Destroy (On_Window_Destroy'Access);
      
      -- Register the handlers
      Register_Handler(Builder      => Builder,
                       Handler_Name => "button_help_about_clicked_cb",
                       Handler      => Terminal_Help_About_Select_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "button_add_clicked_cb",
                       Handler      => Btn_Add_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "button_delete_clicked_cb",
                       Handler      => Btn_Remove_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "button_setup_clicked_cb",
                       Handler      => Btn_Setup_Clicked_CB'Access);
      Register_Handler(Builder      => Builder,
                       Handler_Name => "Change_Tab",
                       Handler      => Change_Terminal_Tab'Access);
      -- Register_Handler(Builder      => Builder,
         --               Handler_Name => "notebook_terminal_change_current_page_cb",
         --               Handler      => Testit'Access);
      
      -- Point images in Glade file to unloaded area in the temp directory
      declare
         use Gtk.Image;
         no_2_image : Gtk.Image.gtk_image;
         image_name : constant string := "chkbtn_no2_image";
         file_name  : constant text := path_to_temp & "bliss_term.jpeg";
      begin
         no_2_image := gtk_image(Get_Object(Builder, image_name));
         --Set(image => no_2_image, Filename=> file_name);
      end;
      
      -- Set up child forms
      Setup.Initialise_Setup(Builder, 
                             from_configuration_file => at_config_path,
                             using_css => css_file, 
                             usage => usage);
      Help_About.Initialise_Help_About(Builder, usage);
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialise_Terminal: Help_About initialised.");
      CSS_Management.Load(the_window => main_window);
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialise_Terminal: CSS_Management.Load run.");
      
      -- Initialise
      Do_Connect (Builder);
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialise_Terminal: Do_Connect done.");
      
      --  Find our main window, then display it and all of its children. 
      Gtk.Widget.Show_All (Gtk.Widget.Gtk_Widget 
                           (Gtkada.Builder.Get_Object(Builder, "bliss_term")));
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialise_Terminal: Show_All done.");
      Gtk.Main.Main;
      
      -- Clean up memory when done
      Unref (Builder);
      exception
         when Constraint_Error => 
            Error_Log.Put(the_error  => 3, 
                          error_intro=> "Initialise_Terminal: file name error",
                          error_message => "Error in " & 
                                           To_String(glade_filename) & 
                                           " : probably wrong path.");
            raise;
   end Initialise_Terminal;

   procedure Testit(Object : access Gtkada_Builder_Record'Class) is
   begin
      null;
   end ;

-- private
   -- use Gtk.Widget;

    -- Main toolbar buttons
   procedure Terminal_Help_About_Select_CB 
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=>"Terminal_Help_About_Select_CB: Start");
      Help_About.Show_Help_About(Gtkada_Builder(Object));
   end Terminal_Help_About_Select_CB;
   
   procedure Btn_Add_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      -- Adds a terminal to the tabs
      use Ada.Strings.UTF_Encoding.Wide_Strings;
      use Gtk.Terminal, Setup;
      the_notebook : Gtk.Notebook.Gtk_Notebook;
      the_terminal : Gtk.Terminal.Gtk_Terminal;
      term_num     : positive;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Add_Clicked_CB: Start");
      the_notebook := Gtk.Notebook.gtk_notebook(Get_Object(Gtkada_Builder(Object), 
                                                         "notebook_terminal"));
      -- Create the terminal
      the_terminal := Gtk.Terminal.Gtk_Terminal_New;
      -- Insert a new notebook tab at the end after all other pages
      Gtk.Notebook.Append_Page(the_notebook,  the_terminal);
      term_num := positive(Gtk.Notebook.Get_N_Pages(the_notebook));
      Gtk.Notebook.Set_Tab_Label_Text(the_notebook, the_terminal,
                            "Term" & term_num'Image(2..term_num'Image'Length));
            -- and make sure the terminal is visible
      Gtk.Terminal.Show_All(the_terminal);
      Gtk.Notebook.Set_Current_Page(the_notebook, -1);  -- set to last page
      -- Start the new shell
      Gtk.Terminal.Spawn_Shell(terminal => the_terminal,
                              working_directory=>"",
                              command => Encode(Host_Functions.
                                   Get_Environment_Value(for_variable=>"SHELL")),
                              environment => 
                                   Encode(To_String(Setup.Set_User_Environment_Variables)),
                              use_buffer_for_editing => 
                                       (Internal_Edit_Method = using_textview),
                              title_callback => Setup.Title_Changed'Access,
                              callback => Setup.Child_Closed'Access,
                               switch_light => Setup.Switch_The_Light'Access);
      -- Load the setup for the tab's window
      Setup.Load_Setup(to_terminal_window => the_terminal);
      Gtk.Terminal.Set_ID(for_terminal => the_terminal, to => term_num);
   end Btn_Add_Clicked_CB;
   
   procedure Btn_Remove_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      -- Removes the current terminal from the tabs.  If there is only one
      -- terminal, then it closes the application.
      use Gtk.Notebook;
      the_notebook : Gtk.Notebook.Gtk_Notebook;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Remove_Clicked_CB: Start");
      -- Pass on tab close request
      the_notebook:=Gtk.Notebook.gtk_notebook(Get_Object(Gtkada_Builder(Object),
                                                         "notebook_terminal"));
      if positive(Gtk.Notebook.Get_N_Pages(the_notebook)) > 1
      then  -- shut down the terminal and remove the tab
         Setup.Close_The_Terminal
                      (at_number => natural(Get_Current_Page(the_notebook))+1);
         Remove_Page(the_notebook, Get_Current_Page(the_notebook));
      else  -- close the application
         Terminal_File_Exit_Select_CB(Object);
      end if;
   end Btn_Remove_Clicked_CB;
   
   procedure Btn_Setup_Clicked_CB  
                (Object : access Gtkada_Builder_Record'Class) is
      -- Show the set-up dialogue box so as to be able to configure the
      -- terminal properties
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Setup_Clicked_CB: Start");
      Setup.Show_Setup(Gtkada_Builder(Object));
   end Btn_Setup_Clicked_CB;

   procedure Change_Terminal_Tab(Object: access Gtkada_Builder_Record'Class) is
      -- Change the title of the window to match the tab's title (as supplied
      -- by the underlying virtual terminal).
      use Gtk.Notebook, Gtk.Terminal;
      the_notebook : Gtk.Notebook.Gtk_Notebook;
      the_terminal : Gtk.Terminal.Gtk_Terminal;
      term_num      : Glib.Gint;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Change_Terminal_Tab: Start");
      -- Get the terminal for the current tab
      the_notebook:=Gtk.Notebook.gtk_notebook(Get_Object(Gtkada_Builder(Object),
                                                         "notebook_terminal"));
      term_num := Gtk.Notebook.Get_Current_Page(the_notebook);
      Error_Log.Debug_Data(at_level => 9, with_details => "Change_Terminal_Tab: got term_num  =" & term_num'Wide_Image & ".");
      the_terminal:= Gtk_Terminal(Gtk.Notebook.
                                    Get_Nth_Page(the_notebook,
                                                 page_num=>term_num));
      Error_Log.Debug_Data(at_level => 9, with_details => "Change_Terminal_Tab: Got the terminal.");
      if the_terminal /= null then
         Error_Log.Debug_Data(at_level => 9, with_details => "Change_Terminal_Tab: Setting the terminal's title.");
         Setup.Title_Changed(the_terminal, 
                             Get_Title(for_terminal => the_terminal));
      else  -- Some trouble with the terminal ID
         Error_Log.Put(the_error => 4,
                       error_intro => "Change_Terminal_Tab error", 
                       error_message=>"Could not get the termnal for this tab");
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Change_Terminal_Tab: Finish");
   end Change_Terminal_Tab;
    
    -- Window destruction management
   procedure Terminal_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
      -- Respond to the request to close the application
      the_notebook : Gtk.Notebook.Gtk_Notebook;
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details=>"Terminal_File_Exit_Select_CB: Start");
      -- Pass on shut-down request
      the_notebook:=Gtk.Notebook.gtk_notebook(Get_Object(Gtkada_Builder(Object), 
                                                         "notebook_terminal"));
      Setup.Set_Tab_Count(to=>positive(Gtk.Notebook.Get_N_Pages(the_notebook)));
      for term_num in reverse 
                     1 .. positive(Gtk.Notebook.Get_N_Pages(the_notebook)) loop
         Setup.Close_The_Terminal(at_number => term_num);
      end loop;
      Setup.Save_Configuration_Data;
      -- Shut ourselves down
      Gtk.Main.Main_Quit;
   end Terminal_File_Exit_Select_CB;

   procedure On_Window_Destroy(Widget : access Gtk.Widget.Gtk_Widget_Record'Class) is
   begin
      Terminal_File_Exit_Select_CB(Object=>Builder);
   end On_Window_Destroy;
   
   procedure On_Window_Close_Request(the_window: access Gtk_Widget_Record'Class)is
      -- Called when the X in the top right hand corner is clicked
   begin
      On_Window_Destroy(the_window);
   end On_Window_Close_Request;
    
begin
   Bliss_Term_Version.Register(revision => "$Revision: v1.0.0$",
                                 for_module => "Terminal");
end Terminal;