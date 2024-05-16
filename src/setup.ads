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
with Gtkada.Builder;  use Gtkada.Builder;
with Glib.Object, Gdk.RGBA, Pango.Font;
with dStrings;        use dStrings;
with Gtk.Terminal;
package Setup is
   use GLib;
   procedure Initialise_Setup(Builder : in out Gtkada_Builder;
                              from_configuration_file : in text;
                              using_css : in text;
                              usage : in text);
   procedure Show_Setup(Builder : in Gtkada_Builder);
   function Adjust_Configuration_Path(from : in text) return text;
   function Set_User_Environment_Variables return text;
      -- Extract the user's environment variables, either from the
      -- configuration file or from the environment itself if not specified in
      -- that configuration file, and return as a string.
   procedure Load_Setup(to_terminal_window : in Gtk.Terminal.Gtk_Terminal;
                        is_preconfigured   : in boolean := false);
      -- Load the set-up configuration to the specified terminal
   procedure Title_Changed(terminal : Gtk.Terminal.Gtk_Terminal; 
                           title    : UTF8_String);
      -- Called whenever the title is changed for the terminal by the
      -- underlying terminal driver (usually to set it to the full path name).
   type editing_method is (using_textview, using_emulator);
   function Internal_Edit_Method return editing_method;
      -- Indicates whether the user wants to use the text view method whenever
      -- possible or always wants to use the terminal emulator's editing tools.
   procedure Child_Closed(terminal: Gtk.Terminal.Gtk_Terminal); 
      -- Depending on which terminal (i.e. whether there is one or more left),
      -- either delete the current tab or kill the application.
   procedure Close_The_Terminal(at_number : in natural);
      -- Close the terminal at the specified terminal number (which is actually
      -- the tab number, where the first tab is 1 (not 0)).
      -- This does not remove or delete the tab.
   procedure Save_Configuration_Data;
      -- Save the configuration data back to the configuration file on disk.
   procedure Set_Tab_Count(to : in natural);
      -- Set the tab count in the configuration file to that specified,
      -- providing that configuration data for terminals on tabs is specified
      -- to be saved.
   function Get_Tab_Count return natural;
      -- Get the tab count as understood by the configuration data.

private
   use Gtk.Terminal;
   
   default_font_start_chr : constant wide_character := 
                                     wide_character'Val(16#A000#);
   font_start_char        : wide_character := default_font_start_chr;

    -- Setup/Configuration page controls
    -- Selected font management:
   function The_Font return UTF8_string;
      -- The currently selected font for the system
   function The_Font_Name return UTF8_string;
      -- The currently selected font name for the system
   function Font_Start_Character return wide_character;
      -- The character to start switching from the default font to the
      -- specified font.
   function Font_Size return gDouble;
      -- The currently selected font size for the system.
   function The_Font_Description return Pango.Font.Pango_Font_Description;
      -- The currently selected font in Pango font description format
    -- Terminal colour management:
   function Text_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected text colour for the system
   function Background_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected background colour for the system
   function Highlight_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected highlight colour for the system
   function Bold_Colour return Gdk.RGBA.Gdk_RGBA;
      -- The currently selected bold colour for the system
      
   procedure Setup_Show_Help (Object : access Gtkada_Builder_Record'Class);

   function Setup_Hide_On_Delete
            (Object : access Glib.Object.GObject_Record'Class) return Boolean;
   procedure Setup_Cancel_CB (Object : access Gtkada_Builder_Record'Class);
   procedure Setup_Close_CB (Object : access Gtkada_Builder_Record'Class);
            
   procedure Load_Data_From(config_file_name : text;
                            Builder  : in Gtkada_Builder;
                            with_initially_setup : boolean := true);
   procedure Load_Data_To(config_file_name : text;
                          Builder  : in Gtkada_Builder);

end Setup;
