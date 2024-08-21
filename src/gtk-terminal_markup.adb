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
with Ada.Strings.Fixed;
with Ada.Characters.Conversions;
with Gtk.Text_Iter;
with Error_Log;  -----------------------------------------*********DELETE ME*********----------------------------
with Ada.Strings.UTF_Encoding.Wide_Strings;  -------------*********DELETE ME*********----------------------------

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
      return s.all;
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
   begin
      return the_markup.markup_text = Null_Ptr or else
             Value(the_markup.markup_text)'Length = 0;
   end Is_Empty;

   function Count(of_modifier : in font_modifier;
                  for_markup : in markup_management) return natural is
       -- returns the number of the specified modifier in the currently loaded
       -- mark-up text (0 if there is none).
      use Ada.Strings.Fixed;
   begin
      if for_markup.markup_text /= Null_Ptr
       then  -- some mark-up to check
         case of_modifier is
            when none            =>
               return 0;  -- always the case!
            when normal          => 
               if Count(bold, for_markup) = 0 and
                   Count(italic, for_markup) = 0 and
                   Count(underline, for_markup) = 0 and
                   Count(strikethrough, for_markup) = 0 and
                   Count(mono, for_markup) = 0
               then   -- normal really means none of most others
                  return 1;
               else
                  return 0;
               end if;
            when bold          => 
               return Count(Value(for_markup.markup_text),"<b>") -
                            Count(Value(for_markup.markup_text),"</b>");
            when italic        => 
               return Count(Value(for_markup.markup_text),"<i>") -
                            Count(Value(for_markup.markup_text),"</i>");
            when underline     => 
               return Count(Value(for_markup.markup_text),"<u>") -
                            Count(Value(for_markup.markup_text),"</u>");
            when strikethrough => 
               return Count(Value(for_markup.markup_text),"<s>") -
                            Count(Value(for_markup.markup_text),"</s>");
            when mono          => 
               return Count(Value(for_markup.markup_text),"<tt>") -
                            Count(Value(for_markup.markup_text),"</tt>");
            when span          => 
               return Count(Value(for_markup.markup_text),"<span") -
                            Count(Value(for_markup.markup_text),"</span>");
         end case;
      else  -- no mark-up to check, so obviously none
         return 0;
      end if;
   end Count;
    
   function Count_Of_Span(attribute : in span_types; -- UTF8_String; 
                           for_markup : in markup_management) return natural is
       -- Count the number of speicified attribute entries in a span tag
      use Ada.Strings.Fixed;
   begin
      if for_markup.markup_text /= Null_Ptr and then
         Count(Value(for_markup.markup_text),"<span") > 0
       then  -- '<span' exists, so see if it holds the specified attribute
         return Count(Value(for_markup.markup_text), -attribute);
      else
         return 0;
      end if;
   end Count_Of_Span;

   procedure Append_To_Markup(in_markup    : in out markup_management;
                              for_modifier : in font_modifier := none;
                              span_type    : in span_types := none;
                              the_value    : in UTF8_String := ""; 
                              or_rgb_colour: Gdk.RGBA.Gdk_RGBA := null_rgba) is
      -- If the markup string is empty, initiate it, otherwise just append the
      -- supplied text.
      procedure Set_Max(of_modifier_array : in out font_modifier_array; 
                        for_modifier : in font_modifier) is
         procedure Insert(the_number : in positive;
                          into : in out linked_list_ptr) is
         begin
            if into = null
            then
               into := new linked_list;
               if for_modifier = span
               then  -- do a complete record assignment including span_type
                  into.all := (mod_type=>span, item=>the_number, 
                               insertion_point=>0, next=>null, 
                               span_type=>span_type, value=>+the_value);
               else
                  into.item := the_number;
               end if;
               -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: executing Set_Max(Insert) at value" & into.item'Wide_Image & "...");
            else
               Insert(the_number, into.next);
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
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: executing Set_Max for_modifier '" & for_modifier'Wide_Image & "' with the_number =" & positive'Wide_Image(max_modifier + 1) & " and span_type = " & span_type'Wide_Image & ".");
         Insert(the_number => max_modifier + 1,
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
      function The_Mod(for_mods: font_modifier_array; 
                       at_pos : in font_modifier) return UTF8_String is
      begin
         if for_mods(at_pos).n > 0
         then
            case at_pos is
               when none          => -- ignore
                  return "";
               when normal        => 
                  return "";
               when bold          => 
                  return "<b>";
               when italic        => 
                  return "<i>";
               when underline     => 
                  return "<u>";
               when strikethrough => 
                  return "<s>";
               when mono          => 
                  return "<tt>";
               when span          => 
                  return "<span>";
            end case;
         else
            return "";
         end if;
      end The_Mod;
      temp_markup : Gtkada.Types.Chars_Ptr;
      mkTxt : Gtkada.Types.Chars_Ptr renames in_markup.markup_text;
   begin  -- Append_To_Markup
      if for_modifier = none and or_rgb_colour = null_rgba
      then  -- append to the modifier string
         temp_markup := New_String(Value(in_markup.markup_text) & the_value);
         Free(in_markup.markup_text);
         in_markup.markup_text := temp_markup;
      elsif for_modifier = span
      then  -- check if already in <span
          -- Here, we assume all the <span ...> commands are given together!
          -- Nearly always, they should be.
          -- In the process, check for brain dead Nano repeating a foreground
          -- or background request.
         if in_markup.markup_text /= Null_Ptr and then
            Ada.Strings.Fixed.Count(Value(in_markup.markup_text),"<span") = 1
            and then Ada.Strings.Fixed.Count(Value(mkTxt),"</span>") = 0
            and then Ada.Strings.Fixed.Tail(Value(mkTxt),1) = ">"
            and then Ada.Strings.Fixed.Count(Value(mkTxt), -span_type) = 0
         then  -- insert this text just prior to the '>' on "<span ...>"
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: Inserting into existing markup_text with <" & for_modifier'Wide_Image & ">: '" & Ada.Characters.Conversions.To_Wide_String(Value(mkTxt)(Value(mkTxt)'First..Value(mkTxt)'Last-1) &the_value & To_RGB_String(or_rgb_colour)&" >") & "'.");
            temp_markup:= 
                     New_String(Value(mkTxt)
                                    (Value(mkTxt)'First..Value(mkTxt)'Last-1) &
                                (-span_type) & the_value & 
                                To_RGB_String(or_rgb_colour)&" >");
            Free(in_markup.markup_text);
            in_markup.markup_text := temp_markup;
         elsif in_markup.markup_text /= Null_Ptr and then
            Ada.Strings.Fixed.Count(Value(in_markup.markup_text),"<span") = 1
            and then Ada.Strings.Fixed.Count(Value(mkTxt),"</span>") = 0
            and then Ada.Strings.Fixed.Tail(Value(mkTxt),1) = ">"
            and then Ada.Strings.Fixed.Count(Value(mkTxt), -span_type) = 1
            and then the_value'Length > 0
            and then Ada.Strings.Fixed.Count(Value(mkTxt), 
                                             (-span_type) & the_value) = 1
         then  -- this is a duplicate
            null;  -- ignore it as it causes trouble
         else  -- treat as a new entry for <span ...>
            in_markup.modifier_array(span).n := 
                                          in_markup.modifier_array(span).n + 1;
            Set_Max(of_modifier_array => in_markup.modifier_array, 
                    for_modifier => span);
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: Inserting new markup via Insert_The_Markup with the_text=>'<span " & Ada.Characters.Conversions.To_Wide_String(the_value & To_RGB_String(or_rgb_colour)) & " >'.");
            Insert_The_Markup(for_markup=>in_markup,
                              the_text=>"<span " & (-span_type) & the_value &
                                          To_RGB_String(or_rgb_colour) & " >");
         end if;
      else -- this is not setting up mark-up text for a span, just append
         in_markup.modifier_array(for_modifier).n := 
                                 in_markup.modifier_array(for_modifier).n + 1;
         Set_Max(of_modifier_array => in_markup.modifier_array,
                 for_modifier => for_modifier);
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Append_To_Markup: Appending markup text via Insert_The_Markup with the_text=>'" & Ada.Characters.Conversions.To_Wide_String(The_Mod(in_markup.modifier_array, at_pos => for_modifier) & (-span_type) & the_value) & "'.");
         Insert_The_Markup(for_markup=>in_markup, 
                           the_text => The_Mod(in_markup.modifier_array, 
                                               at_pos => for_modifier) & 
                                       (-span_type) & the_value);
      end if;
   end Append_To_Markup;
   
   procedure Finish(on_markup    : in out markup_management;
                    for_modifier : font_modifier := none) is
      -- Close off the mark-up string, then write it out to the buffer, and
      -- finally reset the mark-up string to empty.
      function The_Mod(for_mods: font_modifier_array; 
                       at_pos : in font_modifier) return UTF8_String is
      begin
         if for_mods(at_pos).n > 0
         then
            case at_pos is
               when none          => -- ignore
                  return "";
               when normal        => 
                  return "";
               when bold          => 
                  return "</b>";
               when italic        => 
                  return "</i>";
               when underline     => 
                  return "</u>";
               when strikethrough => 
                  return "</s>";
               when mono          => 
                  return "</tt>";
               when span          => 
                  return "</span>";
            end case;
         else
            return "";
         end if;
      end The_Mod;
      procedure Clear_Last(from_modifier_array : in out font_modifier_array; 
                           for_modifier : in font_modifier) is
         procedure Delete_Last(from : in out linked_list_ptr) is
         begin
            if from.next = null
            then  -- it is the last
               -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: executing Clear_Last(Delete_Last) at modifier '" & for_modifier'Wide_Image & "' which has value " & from.item'Wide_Image & ".");
               if from.mod_type = span then  -- clear it's value
                  Clear(from.value);
               end if;
               from := null;  -- clear it out
            else
               Delete_Last(from.next);
            end if;
         end Delete_Last;
         modifier_array : font_modifier_array renames from_modifier_array;
      begin  -- Clear out the last modifier number in the list
         -- Now set the maximum + 1 to the requested modifier
         if  modifier_array(for_modifier).o /= null
         then  -- some processing to do (otherwise nothing to process)
            Delete_Last(from => modifier_array(for_modifier).o);
         end if;
      end Clear_Last;
      function Maximum(from_modifier_array : in font_modifier_array) 
      return font_modifier is
         modifier_array : font_modifier_array renames from_modifier_array;
         current_item   : linked_list_ptr;
         result         : font_modifier := none;
         max_modifier   : natural := 0;
      begin
         for modifier in font_modifier loop
            current_item := modifier_array(modifier).o;
            while current_item /= null loop
               if current_item.item > max_modifier
               then
                  max_modifier := current_item.item;
                  result := modifier;
               end if;
               current_item := current_item.next; 
            end loop;
         end loop;
         return result;
      end Maximum;
      modifier    : font_modifier;
      loop_counter : natural := 0;
   begin  -- Finish
      if on_markup.markup_text = Null_Ptr
      then
         null;  -- nothing to do here!
      elsif Value(on_markup.markup_text)'Length = 0
      then  -- Nothing to mark up.  Make sure markup_text is null (empty)
         Free(on_markup.markup_text);
         on_markup.markup_text := Null_Ptr;
      elsif for_modifier /= none
      then  -- Just close off that modifier
         Insert_The_Markup(for_markup=>on_markup, 
                          the_text=>The_Mod(for_mods=>on_markup.modifier_array,
                                            at_pos => for_modifier));
         Clear_Last(from_modifier_array => on_markup.modifier_array,
                    for_modifier => for_modifier);
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: exited from Clear_Last on for_modifier '" & for_modifier'Wide_Image & "'.");
         on_markup.modifier_array(for_modifier).n := 
                                 on_markup.modifier_array(for_modifier).n - 1;
         if Maximum(from_modifier_array=>on_markup.modifier_array) = none
         then  -- mark-up has ended, flush the mark-up text buffer
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: Maximum(from_modifier_array=>on_markup.modifier_array) = none, doing Insert_The_Markup on the_text => ''....");
            Insert_The_Markup(for_markup=>on_markup, the_text => "");
         end if;
      else  -- Finish up on all modifiers and therefore the entire mark-up
         -- First, close off any outstanding modifiers.  This needs to be done
         -- in reverse order for the modifier order number (in its linked list)
         modifier := Maximum(from_modifier_array => on_markup.modifier_array);
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: working with modifier '" & modifier'Wide_Image & "'.");
         while modifier /= none loop
            if on_markup.modifier_array(modifier).n > 0
            then  -- this is a sanity check (to be sure, to be sure)
               -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: at modifier " & modifier'Wide_Image & " of" & on_markup.modifier_array(modifier).n'Wide_Image & " modifiers, executing Insert_The_Markup on '" & Ada.Characters.Conversions.To_Wide_String(The_Mod(for_mods => on_markup.modifier_array, at_pos => modifier)) & "'.");
               Insert_The_Markup(for_markup=>on_markup, the_text =>
                             The_Mod(for_mods => on_markup.modifier_array,
                                     at_pos => modifier));
               Clear_Last(from_modifier_array => on_markup.modifier_array,
                          for_modifier => modifier);
               -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Finish: exited from Clear_Last on modifier '" & for_modifier'Wide_Image & "'.");
               on_markup.modifier_array(modifier).n := 
                                     on_markup.modifier_array(modifier).n - 1;
            else  -- Something is out of wack!
               loop_counter := loop_counter + 1;
               Handle_The_Error(the_error => 1, 
                                error_intro => "Finish: Modifier error",
                                error_message => "Mis-match in number of " &
                                                 "modifiers. Got a modifier " &
                                                 "of '" & modifier'Wide_Image &
                                                 "' but there are 0 of those "&
                                                 "modifiers left!");
               -- Flush it out to stop the error reoccurrence
               Clear_Last(from_modifier_array => on_markup.modifier_array,
                          for_modifier => modifier);
               if loop_counter > too_many_times
               then  -- This error has repeated too many times already!
                  exit;  -- quit the loop
               end if;
            end if;
            modifier:= Maximum(from_modifier_array=>on_markup.modifier_array);
         end loop;
         -- Second, flush the mark-up text
         Insert_The_Markup(for_markup=>on_markup, the_text => "");
      end if;
   end Finish;
   
   procedure Copy(from : in font_modifier_array; to : out font_modifier_array)
   is
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
               into.all :=  (mod_type=>span, item=>the_number,
                             insertion_point=> 0, next=>null, 
                             span_type=>and_span_type, value =>+with_value);
            else
               into.item := the_number;
            end if;
         else
            Insert(the_number, into.next, for_modifier, at_insertion,
                    and_span_type, with_value);
         end if;
      end Insert;
      current_item : linked_list_ptr;
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
            if item = span
            then  -- include the span type
               Insert(current_item.item, into=> to(item).o, 
                      for_modifier=>item, 
                      at_insertion => current_item.insertion_point,
                      and_span_type=> current_item.span_type,
                      with_value   => -current_item.value);
            else  -- span type is not required
               Insert(current_item.item, into=>to(item).o, 
                      at_insertion=>current_item.insertion_point, 
                      for_modifier=>item);
            end if;
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Copy: Inserted" & current_item.item'Wide_Image & " into to(" & item'Wide_Image & ").o.");
            current_item := current_item.next;
         end loop;
      end loop;
   end Copy;
   
   function Regenerate_Markup(from : in  Gtkada.Types.Chars_Ptr) 
   return Gtkada.Types.Chars_Ptr is
      -- Scrub the old line, extracting the mark-up instructions.  We know that
      -- mark-up is enclosed in '<' and '>'
      function Find_Markup(in_string : UTF8_String; starting_at : in natural)
      return UTF8_String is
         first_char : natural := starting_at;
         last_char  : natural := starting_at;
      begin
         if in_string'Last >= starting_at
         then  -- sanity check
            while first_char < in_string'Length and then 
                  in_string(first_char) /= '<' loop
               first_char := first_char + 1;
            end loop;
            last_char := first_char;
            while last_char < in_string'Length and then
                  in_string(last_char) /= '>' loop
               last_char := last_char + 1;
            end loop;
            if first_char < last_char
            then
               return in_string(first_char .. last_char) & 
                      Find_Markup(in_string, --(last_char..in_string'Last), 
                                  starting_at => last_char + 1);
            else
               return "";
            end if;
         else
            return "";
         end if;
      end Find_Markup;
      old_markup : UTF8_String := Value(from);
   begin
      if old_markup'Length > 0
      then  -- Sanity check: there is something to search for mark-up on
         return New_String(Find_Markup(in_string => old_markup, 
                                       starting_at => old_markup'First));
      else  -- Nothing to find the mark-up on
         return Null_Ptr;
      end if;
   end Regenerate_Markup;

   procedure Save(the_markup : in out markup_management) is
       -- Save away the markup modifiers for future use (in a 1 item deep stack)
   begin
      Free(the_markup.saved_markup);
      the_markup.saved_markup:=Regenerate_Markup(from=>the_markup.markup_text);
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Save(the_markup) - the_markup.saved_markup = '" & Ada.Characters.Conversions.To_Wide_String(Value(the_markup.saved_markup)) & "' from the_markup.markup_text = '" & Ada.Characters.Conversions.To_Wide_String(Value(the_markup.markup_text)) & "'.");
      -- Save a copy of the modifier array
      Copy(from=> the_markup.modifier_array, to=> the_markup.saved_modifiers);
   end Save;
    
   procedure Restore(the_markup  : in out markup_management) is
       -- Restore the saved away (in a 1 deep stack) mark-up modofiers into
       -- a clean mark-up text ready to have mark-up added.
   begin
      Free(the_markup.markup_text);
      the_markup.markup_text := New_String(Value(the_markup.saved_markup));
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Gtk.Terminal_Markup : Restore(the_markup) - the_markup.markup_text = '" & Ada.Characters.Conversions.To_Wide_String(Value(the_markup.markup_text)) & "'.");
      Copy(from=> the_markup.saved_modifiers, to=> the_markup.modifier_array);
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

   function Modifier_In_Markup (for_array : font_modifier_array)
      return boolean is
      -- Indicate whether any mark-up exists within the specified modifier
      -- array.
   begin
      -- The manual way:
      -- for modifier in font_modifier loop
         -- if for_array(modifier).n > 0 then
            -- return true;
         -- end if;
      -- end loop;
      -- return false;  -- If we got here then nothing found
      -- The one-liner way:
      return (for some modifier in 
                          font_modifier'Range => for_array(modifier).n>0);
   end Modifier_In_Markup;
   
   function Length(of_markup_text : Gtkada.Types.Chars_Ptr) return Gint is
      -- Return the length of the mark-up text less the modifiers
      -- (i.e. less tags)
      function At_a_Modifier(for_markup : in Wide_String) return natural is
       -- returns whether the next characters in the mark-up text are a
       -- modifier, by specifying it's length (0 = no modifier).
      begin
         if for_markup(for_markup'First) /= '<'
         then  -- not start of mark-up
            return 0;
         elsif for_markup'Length >= 3 and then
            (for_markup(for_markup'First..for_markup'First+2) = "<b>" or
             for_markup(for_markup'First..for_markup'First+2) = "<i>" or
             for_markup(for_markup'First..for_markup'First+2) = "<u>" or
             for_markup(for_markup'First..for_markup'First+2) = "<s>")
         then 
            return 3;
         elsif for_markup'Length >= 4 and then
               (for_markup(for_markup'First..for_markup'First+3) = "</b>" or
                for_markup(for_markup'First..for_markup'First+3) = "</i>" or
                for_markup(for_markup'First..for_markup'First+3) = "</u>" or
                for_markup(for_markup'First..for_markup'First+3) = "</s>" or
                for_markup(for_markup'First..for_markup'First+3) = "<tt>")
         then
            return 4;
         elsif for_markup'Length >= 5 and then
               (for_markup(for_markup'First..for_markup'First+4) = "</tt>")
         then
            return 5;
         elsif for_markup'Length >= 5 and then
               (for_markup(for_markup'First..for_markup'First+5) = "<span ")
         then
            return 6;
         elsif for_markup'Length >= 7 and then
               (for_markup(for_markup'First..for_markup'First+6) = "</span>")
         then
            return 7;
         else  -- no mark-up
            return 0;
         end if;
      end At_a_Modifier;
      the_length : Gint := 0;
      the_markup : Wide_String := 
           Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(of_markup_text));
      in_tag     : boolean := false;
      item       : integer := the_markup'First;
      mod_count  : natural;
   begin
      while item <= the_markup'Last loop
         mod_count := At_a_Modifier(the_markup(item .. the_markup'Last));
         if mod_count > 0
         then  -- in a tag of some kind
            if mod_count = 6
            then  -- this is a <span ... tag
               item := item + 6;
               while the_markup(item) /= '>' loop
                  item := item + 1;  -- Get to the end of the <span statement
               end loop;
               item := item + 1;  -- get past the '>'
            else  -- not a span tag, some other kind, so get past it
               item := item + mod_count;
            end if;
         else  -- not in a tag
            the_length := the_length + 1;
            item := item + 1;
         end if;
      end loop;
      return the_length;
   end Length;
   
   procedure  Insert_The_Markup(for_markup : in out markup_management; 
                                the_text   : UTF8_String) is
      -- Insert the markup into the currently active text buffer at the current
      -- cursor point for that buffer.  This procedure assumes that the mark-up
      -- is all on the one line and does not transgress line ends.  Handling
      -- mark-up that transgresses line ends needs to be handled externally to
      -- this procedure.
      use Gtk.Text_View, Gtk.Text_Buffer, Gtk.Text_Iter;
      cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter  : Gtk.Text_Iter.Gtk_Text_Iter;
      delete_ch : Gtk.Text_Iter.Gtk_Text_Iter;
      result    : boolean;
   begin
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: Start.");
      if not Modifier_In_Markup(for_array => for_markup.modifier_array) and
         (not Is_Empty(for_markup))
      then  -- no longer in mark-up, dispense the buffer's contents
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: no longer in mark-up, dispense the buffer's contents Mark-up is" & Length(of_markup_text=>for_markup.markup_text)'Wide_Image & " characters long.");
         -- First, set up the cursor_iter
         Get_Iter_At_Mark(for_markup.buffer, cursor_iter, 
                          Get_Insert(for_markup.buffer));
         -- Assumption is if the line has no length (left), then you set
         -- end_iter to this position. This is the default situation (i.e.
         -- cursor is at the end of the line).
         end_iter := cursor_iter;
         if not Ends_Line(end_iter)
         then  -- Not at end, so set up the end_iter to be the end of the line
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: Executing Forward_To_Line_End(end_iter, result)...");
            Forward_To_Line_End(end_iter, result);
         end if;
            -- First, delete the length of the mark-up text if in overwrite
         if Get_Overwrite(for_markup.view)  -- if in 'overwrite' mode
         then  -- delete the characters at the iter before inserting the new one
            delete_ch := cursor_iter;
            Forward_Chars(delete_ch, 
                          Length(of_markup_text=>for_markup.markup_text),
                          result);
            if Compare(delete_ch, end_iter) < 0
            then  -- more than enough characters to delete
               end_iter := delete_ch;
            end if;  -- (otherwise delete as many as possible)
            if not Equal(cursor_iter, end_iter)
            then  -- there is something to be deleted
               Delete(for_markup.buffer, cursor_iter, end_iter);
            end if;
         end if;
         -- Then output the mark-up text
         Insert_Markup(for_markup.buffer, cursor_iter, 
                       Value(for_markup.markup_text), -1);
         Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: executing Insert_Markup on '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(Value(for_markup.markup_text)) & "'.");
         -- Then clean up
         Free(for_markup.markup_text);
         for_markup.markup_text := Null_Ptr;
         if the_text'Length > 0
         then  -- need to output that as well
            Insert(for_markup.buffer, cursor_iter, the_text);
         end if;
      else  -- there is a modifier being specified in the mark-up
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: there is a modifier being specified in the mark-up.");
         declare
            temp_markup : Gtkada.Types.Chars_Ptr;
         begin
            if for_markup.markup_text /= Null_Ptr
            then  -- append
               temp_markup:= New_String(Value(for_markup.markup_text) & the_text);
               Free(for_markup.markup_text);
               for_markup.markup_text := temp_markup;
            else  -- new text
               Free(for_markup.markup_text);
               for_markup.markup_text := New_String(the_text);
            end if;
            -- Error_Log.Debug_Data(at_level => 9, with_details => "Insert_The_Markup: Added mark-up to markup_text so it is now '" & Ada.Characters.Conversions.To_Wide_String(Value(for_markup.markup_text)) & "'.");
         end;
      end if;
   end Insert_The_Markup;

   procedure Finalise(the_markup : in out markup_management) is
      -- Clean up ready for shut-down of the terminal
   begin
      Free(the_markup.markup_text);
   end Finalise;

end Gtk.Terminal_Markup;
