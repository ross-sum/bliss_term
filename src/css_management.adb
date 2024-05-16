-----------------------------------------------------------------------
--                                                                   --
--                    C S S   M A N A G E M E N T                    --
--                                                                   --
--                              B o d y                              --
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
-- with Gtk.CSS_Provider, Gdk.RGBA,
--      Gtk.Widget, Gtk.Button, Gtk.Toggle_Button, Gtk.Tool_Button, Gtk.Window,
--      Gtk.Text_View;
-- with dStrings;
with Error_Log;
with Bliss_Term_Version;
with Ada.Characters.Wide_Latin_1;
with Glib, Glib.Error, Gdk.Display, Gdk.Screen, 
     Gtk.Style_Context, Gtk.Style_Provider;
with String_Conversions;
with dStrings.IO;
package body CSS_Management is
   use Gtk.Widget;

   procedure Set_Up_CSS(for_file : string) is
     -- Load up the CSS file and get it hooked in.
      use Gdk.Display, Gdk.Screen, Gtk.CSS_Provider, Gtk.Style_Provider,
          Gtk.Style_Context;
      use String_Conversions;
      type GError_Access is access Glib.Error.GError;
      with_error  : GError_Access := null;
      -- the_display : Gdk.Display.gdk_display;
      -- the_screen  : Gdk.Screen.gdk_screen;
   begin
      the_provider := Gtk_Css_Provider_New;
      if Load_From_Path(the_provider, for_file, with_error) then
         if with_error /= null then
            Error_Log.Put(the_error    => 11, 
                          error_intro  => "Set_Up_CSS: file name error",
                          error_message=> "Error in " & 
                                          To_Wide_String(for_file) & " : "&
                                          To_Wide_String(Glib.Error.Get_Message
                                                            (with_error.all)));
            Glib.Error.Error_Free (with_error.all);
         else  -- if we wanted to, we could apply to the whole application viz:
            -- the_display := Get_Default;
            -- the_screen  := Get_Default_Screen(the_display);
            -- Add_Provider_For_Screen(the_screen, +the_provider, Priority_User);
            null;  -- If the above is done, the below is not needed.
         end if;
      end if;
   end Set_Up_CSS;

   procedure Load(the_button : in out Gtk.Button.gtk_button) is
      use Gtk.CSS_Provider;
      use Gtk.Style_Context, Gtk.Style_Provider;
      use Gtk.Button; use dStrings;
      context : Gtk.Style_Context.Gtk_Style_Context;
   begin
      context := Get_Style_Context(the_button);
      Gtk.Style_Context.Add_Provider(context, +the_provider,
                                     Priority_User);
   end Load;

   procedure Load(the_button : in out Gtk.Tool_Button.gtk_tool_button) is
      use Gtk.CSS_Provider;
      use Gtk.Style_Context, Gtk.Style_Provider;
      use Gtk.Tool_Button; use dStrings;
      context : Gtk.Style_Context.Gtk_Style_Context;
   begin
      context := Get_Style_Context(the_button);
      Gtk.Style_Context.Add_Provider(context, +the_provider,
                                     Priority_User);
   end Load;
 
   procedure Load(the_button : in out Gtk.Toggle_Button.gtk_toggle_button) is
      use Gtk.CSS_Provider;
      use Gtk.Style_Context, Gtk.Style_Provider;
      context : Gtk.Style_Context.Gtk_Style_Context;
   begin
      context := Get_Style_Context(the_button);
      Gtk.Style_Context.Add_Provider(context, +the_provider,
                                     Priority_User);
   end Load;
   
   procedure Load(the_window : in out Gtk.Window.gtk_window) is
      use Gtk.CSS_Provider;
      use Gtk.Style_Context, Gtk.Style_Provider;
      context : Gtk.Style_Context.Gtk_Style_Context;
   begin
      context := Get_Style_Context(the_window);
      Gtk.Style_Context.Add_Provider(context, +the_provider,
                                     Priority_User);
   end Load;
   
   procedure Load(the_view : in out Gtk.Text_View.gtk_text_view) is
      use Gtk.CSS_Provider;
      use Gtk.Style_Context, Gtk.Style_Provider;
      context : Gtk.Style_Context.Gtk_Style_Context;
   begin
      context := Get_Style_Context(the_view);
      Gtk.Style_Context.Add_Provider(context, +the_provider,
                                     Priority_User);
   end Load;

   procedure CSS_Set(the_widget : in out GTK.Widget.gtk_widget;
                     to_provider: in out Gtk.CSS_Provider.Gtk_Css_Provider) is
      use Gtk.Style_Context, Gtk.Style_Provider, Gtk.CSS_Provider;
      the_context : gtk_style_context;
   begin
      the_context := Get_Style_Context(the_widget);
      Add_Provider(the_context, +to_provider, Priority_User);
      Save(the_context);
   end CSS_Set;

   function Get_Text(from_file : in string) return dStrings.text is
      use dStrings, dStrings.IO;
      use String_Conversions;
      LF_str: constant wide_string(1..1):= (1=>Ada.Characters.Wide_Latin_1.LF);
      result   : text;
      the_line : text;
      css_file : file_type;
   begin
      Clear(result);
      Open(css_file, in_file, from_file, "WCEM=8");
      while not End_of_File(css_file) loop
         Get_Line(css_file, the_line);
         Append(the_line & LF_str, to => result);
      end loop;
      Close(css_file);
      return result;
      exception
         when Name_Error =>
            Error_Log.Put(the_error    => 12, 
                          error_intro  => "Get_Text: file name error",
                          error_message=> "Error in " & 
                                          To_Wide_String(from_file) & " : "&
                                          "Name Error for CSS file.");
            raise;
   end Get_Text;

   procedure Set_Text(for_file : in string; to : in dStrings.text) is
      use dStrings, dStrings.IO;
      use String_Conversions;
      css_file : file_type;
   begin
      Open(css_file, out_file, for_file, "WCEM=8");
      Put(css_file, to);
      Close(css_file);
      exception
         when Name_Error =>
            Error_Log.Put(the_error    => 13, 
                          error_intro  => "Get_Text: file name error",
                          error_message=> "Error in " & 
                                          To_Wide_String(for_file) & " : "&
                                          "Name Error for CSS file.");
            raise;
   end Set_Text;

begin
   Bliss_Term_Version.Register(revision => "$Revision: v1.0.2$",
                               for_module => "CSS_Management");
end CSS_Management;
