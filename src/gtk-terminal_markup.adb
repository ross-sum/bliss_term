-----------------------------------------------------------------------
--                                                                   --
--               G T K . T E R M I N A L _ M A R K U P               --
--                                                                   --
--                              B o d y                              --
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
-- with Glib;                    use Glib;
-- with Gdk.RGBA;                use Gdk.RGBA;
-- with Gtkada.Types;            use Gtkada.Types;
-- with Gtk.Text_Buffer;
-- with Gtk.Text_View;
with Interfaces.C, Interfaces.C.Strings;
with Ada.Characters.Conversions;
with Ada.Strings.Fixed;
with Ada.Strings.UTF_Encoding.Wide_Strings;
with Glib.Convert;
with Gtk.Text_Iter;
with Error_Log;  -----------------------------------------*********DELETE ME*********----------------------------

package body Gtk.Terminal_Markup is
      
   -----------------------------
   -- Error and Debug Logging --
   -----------------------------
   function C_Write
     (fd : Interfaces.C.int;
      data : Interfaces.C.Strings.chars_ptr;
      len : Interfaces.C.int) return Interfaces.C.int;
   pragma Import (C, C_Write, "WriteFD");

   procedure Write(fd   : in out Interfaces.C.int; Buffer : in string) is
      use Interfaces.C, Interfaces.C.Strings;
      out_buffer: Interfaces.C.Strings.chars_ptr:=New_String(Buffer&ASCII.NUL);
      len       : constant natural := Buffer'Length;
      res       : Interfaces.C.int;
   
   begin
      if fd > 0 then
         res := C_Write(fd => fd, data => out_buffer, len => Interfaces.C.int(len));
      end if;
      Free (out_buffer);
   end Write;

   procedure Set_The_Error_Handler(to : error_handler) is
   begin
      the_error_handler := to;
   end Set_The_Error_Handler;

   procedure Handle_The_Error(the_error : in integer;
                              error_intro, error_message : in wide_string) is
       -- For the error display, if the_error_handler is assigned, then call
       -- that function with the three parameters, otherwise formulate an
       -- output and write it out to Standard Error using the Write procedure.
      use Interfaces.C;
      std_err : Interfaces.C.int := 2;
   begin
      if the_error_handler /= null
      then
         the_error_handler(the_error, error_intro, error_message);
      else
         Write(std_err, Ada.Characters.Conversions.To_String(
                        the_error'Wide_Image &  " - Error: " & error_intro & 
                        " - Message is " & error_message));
      end if;
   end Handle_The_Error;

   procedure Set_The_Log_Handler(to : log_handler) is
   begin
      the_log_handler := to;
   end Set_The_Log_Handler;

   procedure Log_Data(at_level : in natural; with_details : in wide_string) is
       -- For the logging display, if the_log_handler is assigned, then call
       -- that function with the two parameters, otherwise ignore the message.
   begin
      if the_log_handler /= null
      then
         the_log_handler(at_level, with_details);
      end if;
   end Log_Data;
   
   ------------------------------------------
   -- UTF8_String and Span Type Management --
   ------------------------------------------
   
   -- type A_UTF8_String is access UTF8_String;
   function "+" (s : UTF8_String) return A_UTF8_String is
      -- Returns an access UTF8_String for the specified UTF8_string.
   begin
      return new UTF8_String'(s);
   end "+";
   
   function "-" (s : A_UTF8_String) return UTF8_String is
      -- Returns the string for the specified Access UTF8_String
   begin
      if s /= null
      then
         return s.all;
      else
         return "";
      end if;
   end "-";
   
   procedure Clear (the_string : in out A_UTF8_String) is
      -- Ensures the string is empty
   begin
      the_string := null;
   end Clear;
   
   -- type span_type_array is array (span_types'range) of A_UTF8_String;
   span_word: constant span_type_array :=
              (+"", +"foreground=", +"background=", +"weight=", +"underline=");
   
   function "-" (s : span_types) return UTF8_String is
      -- Returns the string for the specified span type
   begin
      return span_word(s).all;
   end "-";
   
   ------------------------
   -- Mark-up Management --
   ------------------------
        
   procedure Add(the_text : in UTF8_String; to : in out Gtkada.Types.Chars_Ptr)
   is
      -- Add the_text string to the end of 'to', or if 'to' is a Null_Ptr, then
      -- set 'to' to the_text.
      temp_str : Gtkada.Types.Chars_Ptr;
   begin
      if to /= Null_Ptr
      then  -- some text exists, so append
         temp_str := New_String(Value(to) & the_text);
         Free(to);
         to := temp_str;
      else  -- to is empty, so set it to the_text
         to := New_String(the_text);
      end if;
   end Add;
                                               
   procedure Set_The_Buffer(to : Gtk.Text_Buffer.Gtk_Text_Buffer;
                            for_markup : in out markup_management) is 
   begin
      for_markup.buffer := to;
   end Set_The_Buffer;

   procedure Set_The_View(for_markup : in out markup_management; 
                          to : Gtk.Text_View.Gtk_Text_View) is
   begin
      for_markup.view := to;
   end Set_The_View;

   function Markup_Text(from : in markup_management) 
   return Gtkada.Types.Chars_Ptr is
   begin
      return from.markup_text;
   end Markup_Text;
   
   function Is_Set(the_markup : in markup_management; 
                   to : font_modifier) return boolean is
   begin
      return the_markup.modifier_array(to).n > 0;
   end Is_Set;

   function Is_Empty(the_markup : in markup_management) return boolean is
      -- Indicates whether the mark-up text is empty or not
      empty : boolean := true;
   begin
      for modifier in font_modifier'range loop
         if the_markup.modifier_array(modifier).n > 0 then
            empty := false;
         end if;
      end loop;
      return empty;
   end Is_Empty;

   function Count(of_modifier : in font_modifier;
                  for_markup : in markup_management) return natural is
       -- returns the number of the specified modifier in the currently loaded
       -- mark-up text (0 if there is none).
      use Ada.Strings.Fixed;
   begin
      return for_markup.modifier_array(of_modifier).n;
   end Count;

   function Number_of_Modifiers(in_markup : in markup_management) 
   return natural is
       -- returns the total number modifiers in the currently loaded mark-up
       -- text (0 if there is none).
      result : natural := 0;
   begin
      for modifier in  font_modifier'range loop
         -- If there are any modifiers, then work through the list + clear them
         result := result +  in_markup.modifier_array(modifier).n;
      end loop;
      return result;
   end Number_of_Modifiers;
    
   function Count_Of_Span(attribute : in span_types;
                          for_markup : in markup_management) return natural is
       -- Count the number of speicified attribute entries in a span tag
      result       : natural := 0;
      current_item : linked_list_ptr;
   begin
      if for_markup.modifier_array(span).n > 0
       then  -- '<span' exists, so see if it holds the specified attribute
         current_item := for_markup.modifier_array(span).o;
         while current_item /= null loop
            if current_item.span_type = attribute then
               result := result + 1;
            end if;
            current_item := current_item.next;
         end loop;
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Count_Of_Span: result =" & result'Wide_Image & ".");
      return result;
   end Count_Of_Span;
   
   function The_Value_Exists(for_attribute : in span_types; 
                             of_text : in UTF8_String;
                             for_markup : in markup_management) return boolean
   is
      result       : boolean := false;
      current_item : linked_list_ptr;
   begin
      if for_markup.modifier_array(span).n > 0
       then  -- '<span' exists, so see if it holds the specified attribute
         current_item := for_markup.modifier_array(span).o;
         while current_item /= null loop
            if current_item.span_type = for_attribute then
               if -current_item.value = of_text then
                  result := true;
               end if;
            end if;
            current_item := current_item.next;
         end loop;
      end if;
      return result;
   end The_Value_Exists;

   procedure Append_To_Markup(in_markup    : in out markup_management;
                              for_modifier : in font_modifier := none;
                              span_type    : in span_types := none;
                              the_value    : in UTF8_String := ""; 
                              or_rgb_colour: Gdk.RGBA.Gdk_RGBA := null_rgba) is
      -- If the markup string is empty, initiate it, otherwise just append the
      -- supplied text.
      procedure Set_Max(of_modifier_array : in out font_modifier_array; 
                        for_modifier : in font_modifier;
                        with_value : in UTF8_String) is
         procedure Insert(the_number : in positive;
                          for_modifier : in font_modifier;
                          with_value : in UTF8_String;
                          into : in out linked_list_ptr) is
            insertion_point : natural := 0;
         begin
            if into = null
            then
               into := new linked_list;
               if in_markup.markup_text /= Null_Ptr and then 
                     Value(in_markup.markup_text)'Length > 0
               then  -- some text, so insertion point isn't at the start
                  insertion_point:= Ada.Strings.UTF_Encoding.Wide_Strings.
                                   Decode(Value(in_markup.markup_text))'Length;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: executing Set_Max(Insert) to do the insert for <" & for_modifier'Wide_Image & "> at value" & the_number'Wide_Image & " with insertion_point =" & insertion_point'Wide_Image & " on string '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(in_markup.markup_text)) & "'.");
               end if;
               if for_modifier = span
               then  -- do a complete record assignment including span_type
                  Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: executing Set_Max(Insert) appending <span " & span_type'Wide_Image & "> at item" & the_number'Wide_Image & " with value '" & Ada.Characters.Conversions.To_Wide_String(with_value) & "'...");
                  into.all := (mod_type=>span, item=>the_number, 
                               insertion_point=>insertion_point,
                               finish_point=> 0,
                               loaded_to_markup=> false,
                               next=>null, 
                               span_type=>span_type, value=>+with_value);
               else
                  into.item := the_number;
                  into.mod_type := for_modifier;
                  into.insertion_point := insertion_point;
               end if;
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: executed Set_Max(Insert) <" & for_modifier'Wide_Image & "> at value" & into.item'Wide_Image & " with insertion_point =" & insertion_point'Wide_Image & ".");
            else
               Insert(the_number, for_modifier, with_value, into.next);
            end if;
         end Insert;
         modifier_array : font_modifier_array renames of_modifier_array;
         max_modifier : natural := 0;
         current_item : linked_list_ptr;
      begin  -- calculate the order of the modifier being set
         -- First find the maximum
         for modifier in font_modifier loop
            current_item := modifier_array(modifier).o;
            while current_item /= null loop
               if current_item.item > max_modifier
               then
                  max_modifier := current_item.item;
               end if;
               current_item := current_item.next; 
            end loop;
         end loop;
         -- Now set the maximum + 1 to the requested modifier
         current_item := modifier_array(for_modifier).o;
         while current_item  /= null loop
            -- go down to the linked list to create a new item
            current_item := current_item.next;
         end loop;
         Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: executing Set_Max for_modifier '" & for_modifier'Wide_Image & "' with the_number =" & positive'Wide_Image(max_modifier + 1) & " and span_type = " & span_type'Wide_Image & ".");
         Insert(the_number => max_modifier + 1, for_modifier => for_modifier,
                 with_value => with_value,
                into => modifier_array(for_modifier).o);
      end Set_Max;
      function To_RGB_String(for_rgb : Gdk.RGBA.Gdk_RGBA) return string is
         subtype Hex_Size is positive range 1..2;
         subtype Hex_String is string(Hex_Size'range);
         red_num   : constant natural := natural(for_rgb.red * 255.0);
         green_num : constant natural := natural(for_rgb.green * 255.0);
         blue_num  : constant natural := natural(for_rgb.blue * 255.0);
         red,
         green,
         blue      : Hex_String;
         function Put_Into_String(item : in natural) return Hex_String is
            subtype hex_range is natural range 16#0# .. 16#F#;
            type hex_array is array (hex_range) of character;
            zero  : constant character := '0';
            hexnum: constant hex_array := "0123456789ABCDEF";
            radix : constant natural := 16#10#;
            number_string : Hex_String;
            unit          : hex_range;
            strip_number  : natural;
            char_pos      : Hex_Size := 1;
         begin
            number_string := "00";
            if item /= 0
            then
               strip_number := item;
               -- place numbers on the right hand side of the decimal 
               -- point into the temporary string, number_string 
               -- (NB: actually no decimal point)
               while strip_number > 0 loop
                  unit:= hex_range(strip_number - (strip_number/radix)* radix);
                  strip_number := strip_number / radix;
                  number_string(char_pos) := hexnum(unit);
                  if char_pos < Hex_Size'last then
                     char_pos := char_pos + 1;
                  end if;
               end loop;
            end if;	-- check for a zero (0)
            -- return the result
            return number_string;
         end Put_Into_String;
      begin  -- To_RGB_String
         if for_rgb = null_rgba
         then  -- default is no string at all
            return "";
         else  -- output the RGB as '#RRGGBB'
            red   := Put_Into_String(red_num);
            green := Put_Into_String(green_num);
            blue  := Put_Into_String(blue_num);
            return """#" & red & green & blue & """";
         end if;
      end To_RGB_String;
   begin  -- Append_To_Markup
      if for_modifier = none and or_rgb_colour = null_rgba and 
         the_value'Length > 0
      then  -- just text to append to the string to be marked up
         Add(the_text => the_value, to => in_markup.markup_text);
      elsif for_modifier = span and then
               in_markup.modifier_array(span).n > 0 and then
               Count_Of_Span(attribute => span_type, for_markup => in_markup)>0
               and then The_Value_Exists(for_attribute => span_type, 
                                         of_text => the_value,
                                         for_markup => in_markup)
      then  -- this is a duplicate
         null;  -- ignore it as it causes trouble
      else -- this is not setting up mark-up text for a span, just append
         in_markup.modifier_array(for_modifier).n := 
                                 in_markup.modifier_array(for_modifier).n + 1;
         Set_Max(of_modifier_array => in_markup.modifier_array,
                 for_modifier => for_modifier,
                 with_value => the_value & To_RGB_String(or_rgb_colour));
         if or_rgb_colour /= null_rgba and the_value'Length > 0
         then  --there is also text to append to the string to be marked up
            Add(the_text => the_value, to => in_markup.markup_text);
            Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: Appending markup text so that in_markup.markup_text = '" & Ada.Characters.Conversions.To_Wide_String(Value(in_markup.markup_text)) & "'.");
         end if;
      end if;
   end Append_To_Markup;
   
   procedure Finish(on_markup    : in out markup_management;
                    for_modifier : font_modifier := none) is
      -- Close off the mark-up string, then write it out to the buffer, and
      -- finally reset the mark-up string to empty.
      use Gtk.Text_View, Gtk.Text_Buffer, Gtk.Text_Iter;
      function The_Mod(for_mods: linked_list_ptr; -- font_modifier_array; 
                       -- at_pos : in font_modifier;
                       closed_off : in boolean := false) return UTF8_String is
         function Close_It(off : in boolean) return UTF8_String is
         begin
            if off
            then
               return "/";
            else
               return "";
            end if;
         end Close_It;
      begin  -- The_Mod
         if for_mods /= null  --for_mods(at_pos).n > 0
         then
            case for_mods.mod_type is -- at_pos is
               when none          => -- ignore
                  return "";
               when normal        => 
                  return "";
               when bold          => 
                  return "<" & Close_It(off=>closed_off) & "b>";
               when italic        => 
                  return "<" & Close_It(off=>closed_off) & "i>";
               when underline     => 
                  return "<" & Close_It(off=>closed_off) & "u>";
               when strikethrough => 
                  return "<" & Close_It(off=>closed_off) & "s>";
               when mono          => 
                  return "<" & Close_It(off=>closed_off) & "tt>";
               when span          => 
                  if closed_off
                  then  -- closing - just add in the close off indicator
                     return "<" & Close_It(off=>closed_off) & "span>";
                  else  -- starting - add in the span type and value
                     return "<span " & (-for_mods.span_type) & " " &
                                       (-for_mods.value) & ">";
                  end if;
            end case;
         else
            return "";
         end if;
      end The_Mod;
      procedure Finish_Last(from_modifier_array : in out font_modifier_array; 
                           for_modifier : in font_modifier;
                           at_position  : in natural) is
         -- Set the finish point for the last modifier number in the list
         procedure Find_Last(from : in out linked_list_ptr) is
         begin
            if from.next = null or else from.next.finish_point > 0
            then  -- it is the last that is not finished
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: executing Finish_Last(Find_Last) at modifier '" & for_modifier'Wide_Image & "' which has value " & from.item'Wide_Image & ".");
               -- if from.mod_type = span then  -- clear it's value
                  -- Clear(from.value);
               -- end if;
               from.finish_point := at_position;  -- set it to finished
            else
               Find_Last(from.next);
            end if;
         end Find_Last;
         modifier_array : font_modifier_array renames from_modifier_array;
      begin
         -- if there are any modifiers to finish off, then do so
         if  modifier_array(for_modifier).o /= null
         then  -- some processing to do (otherwise nothing to process)
            Find_Last(from => modifier_array(for_modifier).o);
         end if;
      end Finish_Last;
      procedure Clear_Last(from_modifier_array : in out font_modifier_array; 
                           for_modifier : in font_modifier) is
         -- Clear out the last modifier number in the list
         procedure Delete_Last(from : in out linked_list_ptr) is
         begin
            if from.next /=null and then 
               (from.next.next = null and from.next.loaded_to_markup)
            then  -- This should no longer be here, clear it out too
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: executing Clear_Last(Delete_Last) at modifier '" & for_modifier'Wide_Image & "' to clear out child's child, which has from.next.loaded_to_markup=TRUE.");
               Delete_Last(from.next);
            end if;
            if from.next = null
            then  -- it is the last
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: executing Clear_Last(Delete_Last) at modifier '" & for_modifier'Wide_Image & "' which has value " & from.item'Wide_Image & ".");
               if from.mod_type = span then  -- clear it's value
                  Clear(from.value);
               end if;
               from := null;  -- clear it out
            else
               Delete_Last(from.next);
            end if;
         end Delete_Last;
         modifier_array : font_modifier_array renames from_modifier_array;
      begin
         -- If there are any modifiers, then work through the list + clear last
         if  modifier_array(for_modifier).o /= null
         then  -- some processing to do (otherwise nothing to process)
            Delete_Last(from => modifier_array(for_modifier).o);
         end if;
      end Clear_Last;
      type modifier_states is (closed_and_open, open, already_closed);
      function Maximum(from_modifier_array : in font_modifier_array;
                       that_is : modifier_states := closed_and_open) 
      return linked_list_ptr is
         modifier_array : font_modifier_array renames from_modifier_array;
         current_item   : linked_list_ptr;
         result         : linked_list_ptr := null;
         max_modifier   : natural := 0;
      begin
         for modifier in font_modifier loop
            current_item := modifier_array(modifier).o;
            while current_item /= null loop
               if (that_is = already_closed and then
                   current_item.finish_point > 0 and then
                   current_item.item > max_modifier) or else
                  (that_is = open and then
                   current_item.finish_point = 0 and then
                   current_item.item > max_modifier) or else
                  (that_is = closed_and_open and then
                   (not current_item.loaded_to_markup) and then
                   current_item.item > max_modifier)
               then
                  Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish (Maximum (" & that_is'Wide_Image & ")): at modifier " & current_item.mod_type'Wide_Image & " with item =" & current_item.item'Wide_Image & ".");
                  max_modifier := current_item.item;
                  result := current_item;
               end if;
               current_item := current_item.next; 
            end loop;
         end loop;
         return result;
      end Maximum;
      function Minimum(from_modifier_array : in font_modifier_array;
                       greater_than : in natural := 0) 
      return linked_list_ptr is
         modifier_array : font_modifier_array renames from_modifier_array;
         current_item   : linked_list_ptr;
         result         : linked_list_ptr := null;
         min_modifier   : natural := natural'Last;
      begin
         for modifier in font_modifier loop
            current_item := modifier_array(modifier).o;
            while current_item /= null loop
               if current_item.item < min_modifier and
                  current_item.item > greater_than
               then
                  min_modifier := current_item.item;
                  result := current_item;
               end if;
               current_item := current_item.next; 
            end loop;
         end loop;
         return result;
      end Minimum;
      function Closed_point(from_modifier_array : in font_modifier_array;
                            starting_from : natural := 0) 
      return linked_list_ptr is
         modifier_array : font_modifier_array renames from_modifier_array;
         current_item   : linked_list_ptr;
         result         : linked_list_ptr := null;
         min_modifier   : natural := natural'Last;
      begin
         for modifier in font_modifier loop
            current_item := modifier_array(modifier).o;
            while current_item /= null loop
               if current_item.finish_point > starting_from and then
                  current_item.item < min_modifier
               then
                  min_modifier := current_item.item;
                  result := current_item;
               end if;
               current_item := current_item.next; 
            end loop;
         end loop;
         return result;
      end Closed_point;
      markup_length : natural := 0;
      markup_text   : Gtkada.Types.Chars_Ptr := Null_Ptr;
      current_item  : linked_list_ptr;
      last_position : natural := 0;
      loop_counter  : natural := 0;
      cursor_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter      : Gtk.Text_Iter.Gtk_Text_Iter;
      delete_ch     : Gtk.Text_Iter.Gtk_Text_Iter;
      result        : boolean;
   begin  -- Finish
      if on_markup.markup_text = Null_Ptr
      then  -- maybe nothing to do here!
         if Number_of_Modifiers(in_markup=>on_markup) > 0
         then  -- clear them out as there is nothing to modify
            Clear_Modifiers(for_markup => on_markup);
         end if;
      elsif Value(on_markup.markup_text)'Length = 0
      then  -- Nothing to mark up.  Make sure markup_text is null (empty)
         Free(on_markup.markup_text);
         on_markup.markup_text := Null_Ptr;
      elsif for_modifier /= none
      then  -- Just close off that modifier
         markup_length := Ada.Strings.UTF_Encoding.Wide_Strings.Decode(
                                          Value(on_markup.markup_text))'Length;
         Finish_Last(from_modifier_array => on_markup.modifier_array,
                     for_modifier=> for_modifier, at_position=> markup_length);
         Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: exited from Finish_Last on for_modifier '" & for_modifier'Wide_Image & "'.");
         if Maximum(from_modifier_array=>on_markup.modifier_array,
                    that_is => open) = null
         then  -- mark-up has ended, flush the mark-up text buffer
            Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: Maximum(from_modifier_array=>on_markup.modifier_array) = null, doing Finish(on_markup=>on_markup)....");
            Finish(on_markup=>on_markup);
         end if;
      else  -- Finish up on all modifiers and therefore the entire mark-up
         markup_length := Ada.Strings.UTF_Encoding.Wide_Strings.Decode(
                                          Value(on_markup.markup_text))'Length;
         -- First, open up all modifiers before the those marked for closure at
         -- their closure points, closing off as required
         Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: Finish up on all modifiers and therefore the entire mark-up with markup_length=" & markup_length'Wide_Image & ".");
         declare
            char_pos     : natural := 0;
            last_item    : natural := 0;
            closed_item  : linked_list_ptr;
            closed_pos   : natural := 0;
            markup_string: Wide_String := 
                           Ada.Strings.UTF_Encoding.Wide_Strings.Decode(
                                                 Value(on_markup.markup_text));
         begin
            -- Work through the list, ensuring those items that are closed off
            -- have their closure points inserted in the correct location
            Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: markup_string = '" & markup_string & "'.");
            current_item := Minimum(from_modifier_array => on_markup.modifier_array,
                                    greater_than => last_item);
            while current_item /= null loop
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: at modifier " & current_item.mod_type'Wide_Image & " of" & on_markup.modifier_array(current_item.mod_type).n'Wide_Image & " modifiers.");
               closed_item := Closed_point(from_modifier_array => 
                                                      on_markup.modifier_array,
                                           starting_from => closed_pos);
               if closed_item /= null
               then  -- there is another closed off item
                  closed_pos := closed_item.finish_point;
               end if;
               -- Check whether there is a closing off in between char_pos and
               -- current_item.insertion_point
               if markup_text /= Null_Ptr and then --(Can't be the first thing!)
                  closed_item /= null and then 
                  closed_pos <= current_item.insertion_point
               then  -- dealing with a mark-up modifier closing off at this point
                  -- Add in marked-up text up to the closure point, if any
                  if closed_item.insertion_point > char_pos
                  then  -- need to add that text in, converting it as we go
                     Add(the_text => 
                            Glib.Convert.Escape_Text(Ada.Strings.UTF_Encoding.
                               Wide_Strings.Encode(markup_string
                                     (char_pos+markup_string'First..
                                               closed_item.insertion_point+
                                                     markup_string'First-1))), 
                         to => markup_text);
                  end if;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: closing off at current_item.insertion_point =" & current_item.insertion_point'Wide_Image & ", markup_text = '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
                  -- Add in the closure for the mark-up modifier
                  Add(the_text => The_Mod(for_mods => closed_item,
                                          closed_off => true),
                      to => markup_text);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: closed off with markup_text now = '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
                  -- Clear closed-off modifier out, so it isn't dealt with twice
                  closed_item.loaded_to_markup := true;            
                  -- And adjust the char_pos and the total open counter
                  char_pos := closed_item.insertion_point;
                  on_markup.modifier_array(current_item.mod_type).n := 
                         on_markup.modifier_array(current_item.mod_type).n - 1;
               end if;
               -- Now deal first with the preceeding mark-up text, if any
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: checking if current_item.insertion_point (" & current_item.insertion_point'Wide_Image & ") > char_pos (" & char_pos'Wide_Image & ") [NB markup_string'First = " & markup_string'First'Wide_Image & ", closed_pos =" & closed_pos'Wide_Image & ", markup_length =" & markup_length'Wide_Image & "].");
               if current_item.insertion_point > char_pos
               then  -- need to add that text in to the mix, converting it as we go
                  if markup_text /= Null_Ptr and then 
                     Value(markup_text)'Length > 0
                  then  -- some mark-up loaded, append the new text
                     Add(the_text => 
                            Glib.Convert.Escape_Text(Ada.Strings.UTF_Encoding.
                               Wide_Strings.Encode(markup_string
                                     (char_pos+markup_string'First..
                                              current_item.insertion_point+
                                                     markup_string'First-1))), 
                         to => markup_text);
                  else  -- No mark-up loaded yet
                     Add(the_text => 
                            Glib.Convert.Escape_Text(Ada.Strings.UTF_Encoding.
                               Wide_Strings.Encode(markup_string
                                     (char_pos+markup_string'First..
                                              current_item.insertion_point+
                                                     markup_string'First-1))),
                         to => markup_text);
                  end if;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: dealt with any preceeding markup_text ('" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "').");
               end if;
               -- Now add in the mark-up modifiers
               if markup_text /= Null_Ptr and then Value(markup_text)'Length >0
               then  -- Mark-up loaded, append the modifier
                  Add(the_text => The_Mod(for_mods => current_item,
                                          closed_off => false), 
                      to => markup_text);
               else  -- No mark-up loaded yet
                  Free(markup_text);
                  markup_text:= New_String(The_Mod(for_mods => current_item,
                                                   closed_off => false));
               end if;
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: after adding in the mark-up modifiers, markup_text = '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
               -- Update pointers and advance to the next mark-up text modifier
               last_item := current_item.item;
               char_pos := current_item.insertion_point;
               current_item := Minimum(from_modifier_array => on_markup.modifier_array,
                                       greater_than => last_item);
            end loop;
            -- Second, load any remaining text to be marked up
            if markup_length > char_pos
            then
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: loading any remaining text to be marked up, markup_text = '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
               Add(the_text => 
                            Glib.Convert.Escape_Text(Ada.Strings.UTF_Encoding.
                               Wide_Strings.Encode(markup_string
                                     (char_pos+markup_string'First..
                                                        markup_string'Last))),
                   to => markup_text);
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: loaded all remaining text to be marked up, markup_text now = '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
            end if;
         end;
         -- Third, close all remaining modifiers.  This needs to be done in
         -- reverse order for the modifier order number (in its linked list)
         current_item:= Maximum(from_modifier_array=>on_markup.modifier_array,
                                 that_is => closed_and_open);
         Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: working with modifier </" & current_item.mod_type'Wide_Image & ">, to apply to markup_text ('" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
         while current_item /= null and then current_item.mod_type /= none loop
            -- if on_markup.modifier_array(modifier).n > 0
            if on_markup.modifier_array(current_item.mod_type).n > 0
            then  -- this is a sanity check (to be sure, to be sure)
               Add(the_text => The_Mod(for_mods => current_item,
                                       closed_off => true), 
                   to => markup_text);
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: at modifier " & current_item.mod_type'Wide_Image & " of" & on_markup.modifier_array(current_item.mod_type).n'Wide_Image & " modifiers, set markup_text to '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
               Clear_Last(from_modifier_array => on_markup.modifier_array,
                          for_modifier => current_item.mod_type);
               Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: exited from Clear_Last on for_modifier = '" & current_item.mod_type'Wide_Image & "'.");
               on_markup.modifier_array(current_item.mod_type).n := 
                         on_markup.modifier_array(current_item.mod_type).n - 1;
            else  -- Something is out of wack!
               loop_counter := loop_counter + 1;
               Handle_The_Error(the_error => 1, 
                                error_intro => "Finish: Modifier error",
                                error_message => "Mis-match in number of " &
                                                 "modifiers. Got a modifier " &
                                                 "of '" & current_item.
                                                 mod_type'Wide_Image &
                                                 "' but there are 0 of those "&
                                                 "modifiers left!");
               -- Flush it out to stop the error reoccurrence
               Clear_Last(from_modifier_array => on_markup.modifier_array,
                          for_modifier => current_item.mod_type);
               if loop_counter > too_many_times
               then  -- This error has repeated too many times already!
                  exit;  -- quit the loop
               end if;
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: markup_text = '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "', getting next maximum...");
            current_item := Maximum(from_modifier_array=>on_markup.modifier_array,
                                    that_is => closed_and_open);
         end loop;
         -- Fourth, get the cursor_iter and the line's end_iter
         Get_Iter_At_Mark(on_markup.buffer, cursor_iter, 
                          Get_Insert(on_markup.buffer));
         -- Assumption is if the line has no length (left), then you set
         -- end_iter to this position. This is the default situation (i.e.
         -- cursor is at the end of the line).
         end_iter := cursor_iter;
         if not Ends_Line(end_iter)
         then  -- Not at end, so set up the end_iter to be the end of the line
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: Executing Forward_To_Line_End(end_iter, result)...");
            Forward_To_Line_End(end_iter, result);
         end if;
         -- Fifth, delete the length of the mark-up text if in overwrite
         if Get_Overwrite(on_markup.view)  -- if in 'overwrite' mode
         then  -- delete the characters at the iter before inserting the new one
            delete_ch := cursor_iter;
            Forward_Chars(delete_ch, Glib.Gint(markup_length), result);
            if Compare(delete_ch, end_iter) < 0
            then  -- more than enough characters to delete
               end_iter := delete_ch;
            end if;  -- (otherwise delete as many as possible)
            if not Equal(cursor_iter, end_iter)
            then  -- there is something to be deleted
               Delete(on_markup.buffer, cursor_iter, end_iter);
            end if;
         end if;
         -- Sixth, output the mark-up text
         Insert_Markup(on_markup.buffer, cursor_iter, Value(markup_text), -1);
         Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: executing Insert_Markup on '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(markup_text)) & "'.");
         -- Insert_The_Markup(for_markup=>on_markup, the_text => "");
         -- Finally, clear the text that has just been marked-up
         Free(on_markup.markup_text);
         on_markup.markup_text := Null_Ptr;
      end if;
   end Finish;
   
   procedure Copy(from : in font_modifier_array; to : out font_modifier_array;
                  reset_insertion_point : boolean := false) is
      -- Do a deep copy of 'from' to 'to'
      procedure Insert(the_number : in positive; into : in out linked_list_ptr;
                       for_modifier  : in font_modifier;
                       at_insertion  : in natural;
                       and_span_type : in span_types := none;
                       with_value    : in UTF8_String := "") is
      begin
         if into = null
         then
            into := new linked_list;
            if for_modifier = span 
            then  -- do a complete record assignment including span_type
               into.all :=  (mod_type => span, item => the_number,
                             insertion_point => at_insertion,
                             finish_point => 0,
                             loaded_to_markup => false,
                             next => null, 
                             span_type => and_span_type, value => +with_value);
            else
               into.item := the_number;
               into.insertion_point := at_insertion;
               into.finish_point := 0;
               into.loaded_to_markup := false;
            end if;
         else
            Insert(the_number, into.next, for_modifier, at_insertion,
                    and_span_type, with_value);
         end if;
      end Insert;
      current_item : linked_list_ptr;
      insertion_pt : natural;
   begin
      for item in font_modifier loop
         -- Make doubly sure that the result is empty to start with
         to(item).o := null;             ---------------------------------------------------CHECK FOR MEMORY LEAK HERE - MAY NEED TO CLEAR CHILDREN-------
         -- Load the modifier count (number)
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Copy: setting to(" & item'Wide_Image & ") := " & from(item).n'Wide_Image & ".");
         to(item).n := from(item).n;
         -- Load the modifier's sequence number(s) into to(item).o
         current_item := from(item).o;
         while current_item /= null loop  -- walk the list
            if reset_insertion_point
            then
               insertion_pt := 0;
            else
               insertion_pt := current_item.insertion_point;
            end if;
            -- Note: don't copy those with loaded_to_markup set to TRUE
            if (not current_item.loaded_to_markup) and then item = span
            then  -- include the span type
               Insert(current_item.item, into=> to(item).o, 
                      for_modifier=>item, 
                      at_insertion => insertion_pt,
                      and_span_type=> current_item.span_type,
                      with_value   => -current_item.value);
            elsif (not current_item.loaded_to_markup)
            then  -- span type is not required
               Insert(current_item.item, into=>to(item).o, 
                      at_insertion => insertion_pt, 
                      for_modifier => item);
            end if;
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Copy: Inserted" & current_item.item'Wide_Image & " into to(" & item'Wide_Image & ").o.");
            current_item := current_item.next;
         end loop;
      end loop;
   end Copy;
--    
   procedure Clear_Modifiers(for_markup : in out markup_management) is
      -- Delete all modifiers in the mark-up
      procedure Delete(the_modifier : in out linked_list_ptr) is
      begin
         if the_modifier.next /= null
            then  -- it is not the last, go down to the last
            Delete(the_modifier.next);
         end if;
         -- now delete this one
         if the_modifier.mod_type = span 
         then  -- clear it's string pointer value
            Clear(the_modifier.value);
         end if;
         the_modifier := null;  -- clear it out
      end Delete;
   begin
      for modifier in  font_modifier'range loop
         -- If there are any modifiers, then work through the list + clear them
         if  for_markup.modifier_array(modifier).o /= null
         then  -- some processing to do (otherwise nothing to process)
            Delete(the_modifier => for_markup.modifier_array(modifier).o);
         end if;
         -- And note that there are no modifiers
         for_markup.modifier_array(modifier).n := 0;
      end loop;
   end Clear_Modifiers;

   procedure Save(the_markup : in out markup_management) is
       -- Save away the markup modifiers for future use (in a 1 item deep stack)
   begin
      Free(the_markup.saved_markup);
      the_markup.saved_markup := Null_Ptr;
      -- the_markup.saved_markup:=Regenerate_Markup(from=>the_markup.markup_text);
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Save(the_markup) - the_markup.saved_markup = '" & Ada.Characters.Conversions.To_Wide_String(Value(the_markup.saved_markup)) & "' from the_markup.markup_text = '" & Ada.Characters.Conversions.To_Wide_String(Value(the_markup.markup_text)) & "'.");
      -- Save a copy of the modifier array
      Copy(from=> the_markup.modifier_array, to=> the_markup.saved_modifiers);
   end Save;
    
   procedure Restore(the_markup  : in out markup_management) is
       -- Restore the saved away (in a 1 deep stack) mark-up modofiers into
       -- a clean mark-up text ready to have mark-up added.
   begin
      Free(the_markup.markup_text);
      the_markup.markup_text := Null_Ptr;
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Restore(the_markup) - the_markup.markup_text = '" & Ada.Characters.Conversions.To_Wide_String(Value(the_markup.markup_text)) & "'.");
      Copy(from=> the_markup.saved_modifiers, to=> the_markup.modifier_array,
           reset_insertion_point => true);
      Free(the_markup.saved_markup);
      the_markup.saved_markup := Null_Ptr;
   end Restore;
   
   function Saved_Markup_Exists(for_markup : in markup_management)
    return boolean is
   begin
      return for_markup.saved_markup /= Null_Ptr;
   end Saved_Markup_Exists;

   procedure Clear_Saved(markup : in out markup_management) is
       -- Clear the saved markup
      procedure Delete(from : in out linked_list_ptr) is
      begin
         if from.next /= null
         then  -- Clear out the end of the list first
            Delete(from.next);
         end if;
         from := null;  -- at end now so clear it out
      end Delete;
   begin
      Free(markup.saved_markup);
      markup.saved_markup := Null_Ptr;
      for item in font_modifier'range loop
         markup.saved_modifiers(item).n := 0;
         if markup.saved_modifiers(item).o /= null then
            Delete(from => markup.saved_modifiers(item).o);
         end if;
      end loop;
   end Clear_Saved;

   procedure Finalise(the_markup : in out markup_management) is
      -- Clean up ready for shut-down of the terminal
   begin
      Free(the_markup.markup_text);
   end Finalise;

end Gtk.Terminal_Markup;
