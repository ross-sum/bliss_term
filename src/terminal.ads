-----------------------------------------------------------------------
--                                                                   --
--                          T E R M I N A L                          --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
with Gtkada.Builder;  use Gtkada.Builder;
with Gtk.Button, Gtk.Menu_Item, Gtk.Widget;
with dStrings;        use dStrings;
with VTE;
with Glib;
package Terminal is


   procedure Initialise_Terminal(usage : in text;
                                 path_to_temp  : text:= Value("/tmp/");
                                 glade_filename: text:= Value("bliss_term.glade");
                                 at_config_path: text:= Value(".config/bliss_term.conf"));

private
   use Glib, Gtk.Widget;

    -- Main toolbar buttons
   procedure Terminal_Help_About_Select_CB 
                (Object : access Gtkada_Builder_Record'Class);
   procedure Btn_Add_Clicked_CB  
                (Object : access Gtkada_Builder_Record'Class);
      -- Adds a terminal to the tabs
   procedure Btn_Remove_Clicked_CB  
                (Object : access Gtkada_Builder_Record'Class);
      -- Removes the current terminal from the tabs.  If there is only one
      -- terminal, then it closes the application.
   procedure Btn_Setup_Clicked_CB  
                (Object : access Gtkada_Builder_Record'Class);
      -- Configure the terminal properties
   
    -- Window destruction management
   procedure Terminal_File_Exit_Select_CB  
                (Object : access Gtkada_Builder_Record'Class);
      -- Respond to the request to close the application
   procedure On_Window_Destroy(Widget : access Gtk.Widget.Gtk_Widget_Record'Class);
   procedure On_Window_Close_Request(the_window: access Gtk_Widget_Record'Class);
      -- Called when the X in the top right hand corner is clicked
    
end Terminal;