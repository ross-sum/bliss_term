-----------------------------------------------------------------------
--                                                                   --
--                    C S S   M A N A G E M E N T                    --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2022  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  manages the syle sheet and the colours  for  the  --
--  Bliss  Terminal application.  The default style sheet  for  the  --
--  application  can be different to the system-wide  style  sheet,  --
--  thus  enabling particular customisations for  the  application.  --
--  On top of that, the application allows the setting of different  --
--  colours  and fonts.  This means that this application, being  a  --
--  universal access application (that is, an assistive technology), --
--  can  be  specifically customised so that the user  can  readily  --
--  differentiate it from all other applications on screen.          --
--                                                                   --
--  Version History:                                                 --
--  $Log$
--                                                                   --
--  Bliss_Term  is free software; you can  redistribute  it  and/or  --
--  modify  it under terms of the GNU  General  Public  Licence  as  --
--  published by the Free Software Foundation; either version 2, or  --
--  (at your option) any later version.  Bliss_Term is  distributed  --
--  in  hope  that  it will be useful, but  WITHOUT  ANY  WARRANTY;  --
--  without even the implied warranty of MERCHANTABILITY or FITNESS  --
--  FOR  A PARTICULAR PURPOSE.  See the GNU General Public  Licence  --
--  for  more details.  You should have received a copy of the  GNU  --
--  General  Public Licence distributed with Bliss_Term.   If  not,  --
--  write  to  the Free Software Foundation,  51  Franklin  Street,  --
--  Fifth Floor, Boston, MA 02110-1301, USA.                         --
--                                                                   --
-----------------------------------------------------------------------
with Gtk.CSS_Provider, Gdk.RGBA, 
     Gtk.Widget, Gtk.Button, Gtk.Toggle_Button, Gtk.Tool_Button, Gtk.Window,
     Gtk.Text_View;
with dStrings;
package CSS_Management is

   procedure Set_Up_CSS(for_file : string);
      -- Set up the CSS file so that the colours of the buttons can be adjusted.

   procedure Load(the_button : in out Gtk.Button.gtk_button);
   procedure Load(the_button : in out Gtk.Tool_Button.gtk_tool_button);
   procedure Load(the_button : in out Gtk.Toggle_Button.gtk_toggle_button);
   procedure Load(the_window : in out Gtk.Window.gtk_window);
   procedure Load(the_view   : in out Gtk.Text_View.gtk_text_view);

    -- Load and save the CSS to a physical disk
   function Get_Text(from_file : in string) return dStrings.text;
   procedure Set_Text(for_file : in string; to : in dStrings.text);
 
private

   the_provider: Gtk.CSS_Provider.Gtk_Css_Provider;
   
   procedure CSS_Set(the_widget : in out GTK.Widget.gtk_widget;
                     to_provider: in out Gtk.CSS_Provider.Gtk_Css_Provider);

end CSS_Management;
