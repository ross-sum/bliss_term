-----------------------------------------------------------------------
--                                                                   --
--               G T K . T E R M I N A L _ M A R K U P               --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2024  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  provides  the mark-up management  for  a  simple  --
--  virtual   terminal  interface.   It  contains   the   necessary  --
--  components  to manage the format of mark-up, including  loading  --
--  mark-up  in  and  indicating  whether  there  is  any   mark-up  --
--  available,  so  that  the  Gtk.Terminal.Insert  can   determine  --
--  whether  to  insert text or mark-up.  It also  contains  enough  --
--  information  to  be able to simulate overwrite  (for  a  Text_-  --
--  Buffer, there is only an Insert and an Insert_Markup operation,  --
--  no overwrite operation).                                         --
--  It  was  built  as a part of the Bliss  Terminal  (Bliss  Term)  --
--  software  construction.   But it really could be  considered  a  --
--  part of the Gtk Ada software suite as, other than allowing  for  --
--  the capability of using languages like Blissymbolics, there  is  --
--  nothing in it that specifically alligns it to Blissymbolics.     --
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
--  General Public Licence distributed with  Bliss Term.             --
--  If  not,  write to the Free Software  Foundation,  51  Franklin  --
--  Street, Fifth Floor, Boston, MA 02110-1301, USA.                 --
--                                                                   --
-----------------------------------------------------------------------
with Glib;                    use Glib;
with Gdk.RGBA;                use Gdk.RGBA;
with Gtkada.Types;            use Gtkada.Types;
with Gtk.Text_Buffer;
with Gtk.Text_View;

package Gtk.Terminal_Markup is
   
   -- Error handling for what are mostly non-destructive errors can be via a
   -- call-back.  In the absence of a call-back, the error details will be
   -- written to the Standard Error output device.
   -- This error handler works package wide, for all terminals created and in
   -- operation.
   type error_handler is access 
   procedure (the_error:in integer; error_intro,error_message:in wide_string);
   procedure Set_The_Error_Handler(to : error_handler);
   -- Logging for key pieces of information, almost exclusively around
   -- unhandled ANSI escape codes can be via a call-back.  In the absence of a
   -- call-back, no logging will occur.
   -- This logging handler works package wide, for all terminals creatated and
   -- in operation.
   type log_handler is access
   procedure (at_level : in natural; with_details : in wide_string);
   procedure Set_The_Log_Handler(to : log_handler);

   -- Font modifiers:
   -- Font modifiers are used within the mark-up string to indicate how the
   -- font should be presented.
   type font_modifier is (none, normal, bold, italic, underline, 
                           strikethrough, mono, span);
   type markup_management is private;
   -- Usage: with the consuming record, e.g. Gtk_Terminal_Buffer_Record, insert
   --        something like the following entry:
   --           markup_mgt : markup_management;
   --        Then, during Gtk_Terminal_Buffer_Record's construction, run up
   --        Set_The_Buffer and also Set_The_View in order to ensure that
   --        output can take place correctly.

   procedure Set_The_Buffer(to : Gtk.Text_Buffer.Gtk_Text_Buffer;
                            for_markup : in out markup_management);
      -- Set_The_Buffer is required so that Gtk.Terminal_Markup knows what
      -- buffer to write to when writing out the mark-up text.  Writing out the
      -- mark-up text is done when the mark-up around some text is complete.
   procedure Set_The_View(for_markup : in out markup_management; 
                           to : Gtk.Text_View.Gtk_Text_View);
      -- This is required so that, when writing out the mark-up text, this
      -- package knows whether to simulate 'overwrite' (by deleting text that
      -- it is supposed to overwrite) or to insert the text at the cursor.

   function Markup_Text(from : in markup_management)
   return Gtkada.Types.Chars_Ptr;
   function Is_Set(the_markup : in markup_management; 
                   to : font_modifier) return boolean;
   function Is_Empty(the_markup : in markup_management) return boolean;
      -- Indicates whether the mark-up text is empty or not
    
   procedure Save(the_markup : in out markup_management);
       -- Save away the markup modifiers for future use (in a 1 item deep stack)
   procedure Restore(the_markup  : in out markup_management);
       -- Restore the saved away (in a 1 deep stack) mark-up modifiers into
       -- a clean mark-up text ready to have mark-up added.
   function Saved_Markup_Exists(for_markup : in markup_management)
    return boolean;
   procedure Clear_Saved(markup : in out markup_management);
       -- Clear the saved markup
       
   function Count(of_modifier : in font_modifier;
                  for_markup : in markup_management) return natural;
       -- returns the number of the specified modifier in the currently loaded
       -- mark-up text (0 if there is none).
   function Count_Of_Span(attribute : in UTF8_String; 
                          for_markup : in markup_management) return natural;
       -- Count the number of speicified attribute entries in a span tag

   procedure Append_To_Markup(in_markup    : in out markup_management;
                              for_modifier : in font_modifier := none;
                              the_value    : in UTF8_String := ""; 
                              or_rgb_colour: Gdk.RGBA.Gdk_RGBA := null_rgba);
      -- If the markup string is empty, initiate it, otherwise just append the
      -- supplied text.
   procedure Finish(on_markup    : in out markup_management;
                    for_modifier : font_modifier := none);
      -- Close off the mark-up string, then write it out to the buffer, and
      -- finally reset the mark-up string to empty.
     
   procedure Finalise(the_markup : in out markup_management);
      -- Clean up ready for shut-down of the terminal
      
private
   too_many_times    : constant natural := 100;  -- Finish's error loop counter
   the_error_handler : error_handler := null;
   the_log_handler   : log_handler := null;
   procedure Handle_The_Error(the_error : in integer;
                              error_intro, error_message : in wide_string);
       -- For the error display, if the_error_handler is assigned, then call
       -- that function with the three parameters, otherwise formulate an
       -- output and write it out to Standard Error using the Write procedure.
   procedure Log_Data(at_level : in natural; with_details : in wide_string);
       -- For the logging display, if the_log_handler is assigned, then call
       -- that function with the two parameters, otherwise ignore the message.

   type linked_list;
   type linked_list_ptr is access linked_list;
   type linked_list is record
         item : natural;
         next : linked_list_ptr;
      end record;
   type font_modifier_detail is record
         n : natural := 0;  -- number of modifiers in the list 'o'
         o : linked_list_ptr;
      end record;
   type font_modifier_array is array (font_modifier) of font_modifier_detail;
   type markup_management is record
         buffer         : Gtk.Text_Buffer.Gtk_Text_Buffer;
         view           : Gtk.Text_View.Gtk_Text_View;
         markup_text    : Gtkada.Types.Chars_Ptr := Null_Ptr;
         modifier_array : font_modifier_array;
         saved_markup   : Gtkada.Types.Chars_Ptr := Null_Ptr;
         saved_modifiers: font_modifier_array;
      end record;

   function Modifier_In_Markup (for_array: font_modifier_array) return boolean;
      -- Indicate whether any mark-up exists within the specified modifier
      -- array.
   function Length(of_markup_text : Gtkada.Types.Chars_Ptr) return Gint;
      -- Return the length of the mark-up text less the modifiers
      -- (i.e. less tags)
   procedure Copy(from : in font_modifier_array; to : out font_modifier_array);
      -- Do a deep copy of 'from' to 'to'
   function Regenerate_Markup(from : in  Gtkada.Types.Chars_Ptr) 
   return Gtkada.Types.Chars_Ptr;
      -- Scrub the old line, extracting the mark-up instructions.  We know that
      -- mark-up is enclosed in '<' and '>'
   procedure  Insert_The_Markup(for_markup : in out markup_management; 
                                the_text   : UTF8_String);
      -- Insert the markup into the currently active text buffer at the current
      -- cursor point for that buffer.  This procedure assumes that the mark-up
      -- is all on the one line and does not transgress line ends.  Handling
      -- mark-up that transgresses line ends needs to be handled externally to
      -- this procedure.

end Gtk.Terminal_Markup;
