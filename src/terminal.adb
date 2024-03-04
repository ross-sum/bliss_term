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
-- with VTE;
-- with Glib;
with Glib, Glib.Error;
with Gtk.Widget, Gtk.Image;
with Gtk.Main, Gtk.Window;
with Gtk.Menu;
with Vte.Terminal;
with Error_Log;
with String_Conversions;
with Ada.Strings.UTF_Encoding, Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Characters.Conversions;
with Bliss_Term_Version;
with Setup;
with Help_About;
package body Terminal is

   procedure Initialise_Terminal(usage : in text;
                                 path_to_temp  : text:= Value("/tmp/");
                                 glade_filename: text:= Value("bliss_term.glade");
                                 at_config_path: text:= Value(".config/bliss_term.conf")) is
      use Glib.Error, Ada.Characters.Conversions;
      Builder : Gtkada_Builder;
      Error   : Glib.Error.GError_Access := null;
      count   : Glib.Guint;
      main_window : Gtk.Window.Gtk_Window;
   begin
      -- exit_process_started := false;  -- initialise to sensible value
      -- Set the locale specific data (e.g time and date format)
      -- Gtk.Main.Set_Locale;
      -- Create a Builder and add the XML data
      Gtk.Main.Init;
      -- Connect to the style sheet
      -- CSS_Management.Set_Up_CSS(for_file => path_to_temp & "bliss_term.css");
      -- Set up the Builder with the Glade file
      Gtk_New (Builder);
      if Locate(fragment => '/', within => glade_filename) > 0
      then  -- glade file not located in /tmp or similar
         count := Add_From_File (Builder, Value(glade_filename), Error);
      else  -- no path in glade file name, so assume it is in the temp directory
         count := Add_From_File (Builder, Value(path_to_temp & glade_filename), Error);
      end if;
      if Error /= null then
         Error_Log.Put(the_error    => 1, 
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
                             usage => usage);
      Help_About.Initialise_Help_About(Builder, usage);
      
      -- Initialise
      Do_Connect (Builder);
      
      -- Set up the terminal
      
   
      --  Find our main window, then display it and all of its children. 
      Gtk.Widget.Show_All (Gtk.Widget.Gtk_Widget 
                           (Gtkada.Builder.Get_Object(Builder, "bliss_term")));
      Gtk.Main.Main;
      
      -- Clean up memory when done
      Unref (Builder);
   end Initialise_Terminal;

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
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Add_Clicked_CB: Start");
      null;
   end Btn_Add_Clicked_CB;
   
   procedure Btn_Remove_Clicked_CB
                (Object : access Gtkada_Builder_Record'Class) is
      -- Removes the current terminal from the tabs.  If there is only one
      -- terminal, then it closes the application.
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Remove_Clicked_CB: Start");
      null;
   end Btn_Remove_Clicked_CB;
   
   procedure Btn_Setup_Clicked_CB  
                (Object : access Gtkada_Builder_Record'Class) is
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Btn_Setup_Clicked_CB: Start");
      Setup.Show_Setup(Gtkada_Builder(Object));
      null;
   end Btn_Setup_Clicked_CB;
    
    -- Window destruction management
   procedure Terminal_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class) is
      -- Respond to the request to close the application
   begin
      Error_Log.Debug_Data(at_level => 5, 
                           with_details => "Terminal_File_Exit_Select_CB: Start");
         -- Shut ourselves down
      Gtk.Main.Main_Quit;
   end Terminal_File_Exit_Select_CB;

   procedure On_Window_Destroy(Widget : access Gtk.Widget.Gtk_Widget_Record'Class) is
   begin
      Terminal_File_Exit_Select_CB(Object=>null);
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