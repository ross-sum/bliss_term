separate (Gtk.Terminal)
   procedure Process(the_input : in UTF8_String; for_buffer : Gtk_Terminal_Buffer) is
   use Gtk.Text_Iter, Gtk.Text_Mark;
   use Ada.Strings.Maps;
   use Gtk.Terminal.CInterface;
   Tab_length : constant natural := 8;
   subtype Tab_range is natural range 0..Tab_length;
   CR_str  : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.CR);
   LF_str  : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.LF);
   FF_str  : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.FF);
   Esc_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.Esc);
   Tab_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.HT);
   BS_str  : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.BS);
   Bel_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.BEL);
   St_chr  : constant character := character'Val(16#9C#);
   Esc_num : constant UTF8_String := Esc_str & "[01;";
   Tab_chr : constant UTF8_String(1..Tab_length) := (1..Tab_length => ' ');
   Esc_Rng : constant Character_Ranges := (('@','K'),('M','P'),('S','T'),
                                           ('c','c'),('f','i'),('l','n'),
                                           ('r','u'),('#','#'),('=','='), -- ('%','%'),
                                           ('^','^'),('_','_'),('>','>'));
   Esc_Term: constant Character_Set := To_Set(Esc_Rng);
   Osc_Rng : constant Character_Ranges := ((Bel_str(1),Bel_str(1)),
                                           (st_chr,st_chr));
   Osc_Term: constant Character_Set := To_Set(Osc_Rng);
   procedure Append_To_Markup(for_buffer : Gtk_Terminal_Buffer;
                              for_modifier : in font_modifiers;
                              the_value : in UTF8_String := ""; 
                              or_rgb_colour: Gdk.RGBA.Gdk_RGBA:=null_rgba) is
      -- If the markup string is empty, initiate it, otherwise just append the
      -- supplied text.
      procedure Set_Max(of_modifier_array : in out font_modifier_array; 
                        for_modifier : in font_modifiers) is
         procedure Insert(the_number : in positive; 
                          into : in out linked_list_ptr) is
         begin
            if into = null
            then
               into := new linked_list;
               into.item := the_number;
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Append_To_Markup: executing Set_Max(Insert) at value" & into.item'Wide_Image & "...");
            else
               Insert(the_number, into.next);
            end if;
         end Insert;
         modifier_array : font_modifier_array renames of_modifier_array;
         max_modifier : natural := 0;
         current_item : linked_list_ptr;
      begin  -- calculate the order of the modifier being set
         -- First find the maximum
         for modifier in font_modifiers loop
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
         Insert(the_number => max_modifier + 1,
                into => modifier_array(for_modifier).o);
         Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Append_To_Markup: executed Set_Max for_modifier '" & for_modifier'Wide_Image & "'.");
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
                       at_pos : in font_modifiers) return UTF8_String is
      begin
         if for_mods(at_pos).n > 0
         then
            case at_pos is
               when none            => -- ignore
                  return "";
               when normal          => 
                  return "";
               when bold            => 
                  return "<b>";
               when italic          => 
                  return "<i>";
               when underline       => 
                  return "<u>";
               when strikethrough   => 
                  return "<s>";
               when mono            => 
                  return "<tt>";
               when span            => 
                  return "<span>";
            end case;
         else
            return "";
         end if;
      end The_Mod;
      temp_markup : Gtkada.Types.Chars_Ptr;
      mkTxt : Gtkada.Types.Chars_Ptr renames for_buffer.markup_text;
   begin  -- Append_To_Markup
      if for_modifier = span
      then  -- check if already in <span
          -- Here, we assume all the <span ...> commands are given together!
          -- Nearly always, they should be.
         if for_buffer.markup_text /= Null_Ptr and then
            Ada.Strings.Fixed.Count(Value(for_buffer.markup_text),"<span") = 1
            and then Ada.Strings.Fixed.Count(Value(mkTxt),"</span>") = 0
            and then Ada.Strings.Fixed.Tail(Value(mkTxt),1) = ">"
         then  -- insert this text just prior to the '>' on "<span ...>"
            temp_markup:= 
                     New_String(Value(mkTxt)
                                    (Value(mkTxt)'First..Value(mkTxt)'Last-1) &
                                the_value & To_RGB_String(or_rgb_colour)&" >");
            Free(for_buffer.markup_text);
            for_buffer.markup_text := temp_markup;
         else  -- treat as a new entry for <span ...>
            for_buffer.modifier_array(span).n := 
                                   for_buffer.modifier_array(span).n + 1;
            Set_Max(of_modifier_array => for_buffer.modifier_array,
                    for_modifier => span);
            Insert_At_Cursor (into=>for_buffer,the_text=>"<span " & the_value &
                                          To_RGB_String(or_rgb_colour) & " >");
         end if;
      else -- this is not setting up mark-up text for a span, just append
         for_buffer.modifier_array(for_modifier).n := 
                                 for_buffer.modifier_array(for_modifier).n + 1;
         Set_Max(of_modifier_array => for_buffer.modifier_array,
                 for_modifier => for_modifier);
         Insert_At_Cursor(into => for_buffer, 
                           the_text => The_Mod(for_buffer.modifier_array, 
                                               at_pos => for_modifier) & 
                                       the_value);
      end if;
   end Append_To_Markup;
   procedure Finish_Markup(for_buffer: Gtk_Terminal_Buffer;
                           for_modifier : font_modifiers := none) is
      -- Close off the mark-up string, then write it out to the buffer, and
      -- finally reset the mark-up string to empty.
      function The_Mod(for_mods: font_modifier_array; 
                       at_pos : in font_modifiers) return UTF8_String is
      begin
         if for_mods(at_pos).n > 0
         then
            case at_pos is
               when none            => -- ignore
                  return "";
               when normal          => 
                  return "";
               when bold            => 
                  return "</b>";
               when italic          => 
                  return "</i>";
               when underline       => 
                  return "</u>";
               when strikethrough   => 
                  return "</s>";
               when mono            => 
                  return "</tt>";
               when span            => 
                  return "</span>";
            end case;
         else
            return "";
         end if;
      end The_Mod;
      procedure Clear_Last(from_modifier_array : in out font_modifier_array; 
                           for_modifier : in font_modifiers) is
         procedure Delete(from : in out linked_list_ptr) is
         begin
            if from.next = null
            then
               from := null;  -- clear it out
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Finish_Markup: executed Clear_Last(Delete) at modifier '" & for_modifier'Wide_Image & "'.");
            else
               Delete(from.next);
            end if;
         end Delete;
         modifier_array : font_modifier_array renames from_modifier_array;
      begin  -- calculate the order of the modifier being set
         -- Now set the maximum + 1 to the requested modifier
         if  modifier_array(for_modifier).o /= null
         then  -- some processing to do (otherwise nothing to process)
            Delete(from => modifier_array(for_modifier).o);
         end if;
      end Clear_Last;
      function Maximum(from_modifier_array : in font_modifier_array) 
      return font_modifiers is
         modifier_array : font_modifier_array renames from_modifier_array;
         current_item   : linked_list_ptr;
         result         : font_modifiers := none;
         max_modifier   : natural := 0;
      begin
         for modifier in font_modifiers loop
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
      modifier : font_modifiers;
   begin  -- Finish_Markup
      if for_modifier /= none
      then  -- Just close off that modifier
         Insert_At_Cursor(into => for_buffer, 
                          the_text=>The_Mod(for_mods=>for_buffer.modifier_array,
                                            at_pos => for_modifier));
         Clear_Last(from_modifier_array => for_buffer.modifier_array,
                    for_modifier => for_modifier);
         for_buffer.modifier_array(for_modifier).n := 
                                 for_buffer.modifier_array(for_modifier).n - 1;
         if Maximum(from_modifier_array=>for_buffer.modifier_array) = none
         then  -- mark-up has ended, flush the mark-up text buffer
            Insert_At_Cursor(into => for_buffer, the_text => "");
         end if;
      else
         -- First, close off any outstanding modifiers.  This needs to be done
         -- in reverse order for the modifier order number (in its linked list)
         modifier := Maximum(from_modifier_array => for_buffer.modifier_array);
         Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Finish_Markup: working with modifier '" & modifier'Wide_Image & "'.");
         while modifier /= none loop
            if for_buffer.modifier_array(modifier).n > 0
            then  -- this is a sanity check (to be sure, to be sure)
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Finish_Markup: executing Insert_At_Cursor on '" & Ada.Characters.Conversions.To_Wide_String(The_Mod(for_mods => for_buffer.modifier_array, at_pos => modifier)) & "'.");
               Insert_At_Cursor(into => for_buffer, the_text =>
                             The_Mod(for_mods => for_buffer.modifier_array,
                                     at_pos => modifier));
               Clear_Last(from_modifier_array => for_buffer.modifier_array,
                          for_modifier => modifier);
               for_buffer.modifier_array(modifier).n := 
                                     for_buffer.modifier_array(modifier).n - 1;
            else  -- Something is out of wack!
               Handle_The_Error(the_error => 1, 
                                error_intro => "Finish_Markup: Modifier error",
                                error_message => "Mis-match in number of " &
                                                 "modifiers. Got a modifier " &
                                                 "of '" & modifier'Wide_Image &
                                                 "' but there are 0 of those "&
                                                 "modifiers left!");
            end if;
            modifier:= Maximum(from_modifier_array=>for_buffer.modifier_array);
         end loop;
         -- Second, flush the mark-up text
         Insert_At_Cursor(into => for_buffer, the_text => "");
      end if;
   end Finish_Markup;
   procedure Copy(from : in font_modifier_array; to : out font_modifier_array)
   is
      -- Do a deep copy of 'from' to 'to'
      procedure Insert(the_number : in positive; into : in out linked_list_ptr)
      is
      begin
         if into = null
         then
            into := new linked_list;
            into.item := the_number;
         else
            Insert(the_number, into.next);
         end if;
      end Insert;
      current_item : linked_list_ptr;
   begin
      for item in font_modifiers loop
         -- Load the modifier count (number)
         to(item).n := from(item).n;
         -- Load the modifier's sequence number(s)
         current_item := from(item).o;
         while current_item /= null loop  -- walk the list
            Insert(current_item.item, into => to(item).o);
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
         if in_string'Length > starting_at
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
                      Find_Markup(in_string(last_char..in_string'Last), 
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
   function "*" (mult : integer; val : character) return string is
      result : string(1..mult) := (others => val);
   begin
      return result;
   end "*";
   procedure Process_Escape(for_sequence : in UTF8_String;
                            on_buffer  :Gtk_Terminal_Buffer) is
     -- Information sourced from https://en.wikipedia.org/wiki/ANSI_escape_code
     -- (as at 10 April 2024) and from st.c as well as from GitHub at
     -- https://github.com/MicrosoftDocs/Console-Docs/blob/main/docs/console-
     --                                           virtual-terminal-sequences.md
     -- This stuff is also available here:
     --    http://xtermjs.org/docs/api/vtfeatures/
     --    https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
     --    man 4 console_codes
     --    msn 1 xterm
      use Gtk.Enums, Gdk.Color, Gdk.RGBA;
      -- use Modifier_Sets;
      the_sequence : UTF8_String := for_sequence;
      ist : constant integer := for_sequence'First;
      num_params : constant natural := 5;
      type params is array(1..num_params) of integer;
      chr_pos : natural;
      param   : params  := (1..num_params => 0);
      pnum    : natural := 1;  -- param number
      count   : natural := 1;  -- current parameter
      res     : boolean;  -- result
      cursor_iter : aliased Gtk.Text_Iter.Gtk_Text_Iter;
      dest_iter   : aliased Gtk.Text_Iter.Gtk_Text_Iter;
      buf_x   : Glib.Gint := 0;
      buf_y   : Glib.Gint := 0;
      column  : natural;
      the_buf : Gtk.Text_Buffer.Gtk_Text_Buffer;
   begin  -- Process_Escape
      -- First up, work out which buffer, the main or the alternative buffer
      -- that the display input/output will operate on
      if on_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         the_buf := on_buffer.alt_buffer;
      else  -- using the main buffer for display
         the_buf := Gtk.Text_Buffer.Gtk_Text_Buffer(on_buffer);
      end if;
      if for_sequence'Length<2
      then  -- this cannot be a valid control sequence
         Handle_The_Error(the_error => 2, 
                          error_intro=> "Process_Escape: Control string error",
                          error_message => "Not a valid control sequence for '" 
                                           & Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                           "'.");
         null;
      elsif on_buffer.pass_through_characters and then
            (for_sequence'Length >= 6 and then
             for_sequence(ist..ist+5) /= Esc_str & "[201~")
      then  -- write it out
         Get_Iter_At_Mark(the_buf, cursor_iter, Get_Insert(the_buf));
         Insert(on_buffer, at_iter=>cursor_iter, the_text=> for_sequence);
      else  -- for_sequence(ist)=Esc_str and rest is control sequence
         if for_sequence(ist+1) = '[' or for_sequence(ist+1) = ']'
         then  -- extract the number(s), if any
            if for_sequence(ist+2) = '>' or for_sequence(ist+2) = '?'
            then
               chr_pos := ist + 3;
            else
               chr_pos := ist + 2;
            end if;
            loop
               while for_sequence'Length > chr_pos + ist - 1 and then
                        for_sequence(chr_pos) in '0'..'9' loop
                  param(pnum) := param(pnum) * 10 + 
                                    Character'Pos(for_sequence(chr_pos)) -
                                    Character'Pos('0');
                  chr_pos := chr_pos + 1;
               end loop;
               exit when (for_sequence'Length > chr_pos + ist - 1 and then
                             for_sequence(chr_pos) /= ';') or
                            pnum >= num_params or  -- run out of sequence
                            chr_pos + ist - 1 >= for_sequence'Length; -- too far
               pnum := pnum + 1;
               -- The following check was inserted because for vi, there is a
               -- sequence of the form <ESC> [ 0 % m (without the spaces).
               -- Can only assume it means reset the colour.
               if for_sequence(chr_pos) = '%' then  -- skip past it
                  chr_pos := chr_pos + 1;
               end if;
               chr_pos := chr_pos + 1;  -- get past the ';'
            end loop;
         end if;
         case the_sequence(ist+1) is
            when '[' =>  -- it is a Control Sequence Introducer (CSI) sequence
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI sequence - there are" & pnum'Wide_Image & " parameters, being " & param(1)'Wide_Image & "," & param(2)'Wide_Image & "," & param(3)'Wide_Image & " and next sequence is the_sequence(" & chr_pos'wide_image & ")= '" & Ada.Characters.Conversions.To_Wide_String(the_sequence(chr_pos..chr_pos)) & "'.");
               if the_sequence(ist+2) = '>'
               then  -- It is an evil variation for xterm
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '[>...x' - evil sequence.");
                  case the_sequence(chr_pos) is
                     when 'c' =>  -- Send device attributes (Secondary DA)
                        Write(fd => on_buffer.master_fd, 
                              Buffer => Esc_str & "[>1;10;1c");
                     when 'm' => null;  -- key modifier options XTMODKEYS
                        case param(1) is
                           when 0 =>   -- modifyKeyboard
                              case param(2) is
                                 when 0 =>   -- interpret only control modifier
                                    on_buffer.modifiers.
                                              modify_keyboard := ctrl_on_fn;
                                 when 1 =>   -- numeric keypad modify allowed
                                    on_buffer.modifiers.
                                              modify_keyboard := numeric_kp;
                                 when 2 =>   -- editing keypad modify allowed
                                    on_buffer.modifiers.
                                              modify_keyboard := editing_kp;
                                 when 4 =>   -- function keys modify allowed
                                    on_buffer.modifiers. 
                                              modify_keyboard :=fn_keys;
                                 when 8 =>   -- enable without exceptions
                                    on_buffer.modifiers.
                                              modify_keyboard := other_special;
                                 when others => null;  -- ignore
                              end case;
                           when 1 => null;  -- modifyCursorKeys
                              case param(2) is
                                 when -1 =>   -- disable the feature
                                    on_buffer.modifiers.
                                         modify_cursor_keys := disabled;
                                 when 0 =>   -- modifier is first parameter
                                    on_buffer.modifiers.
                                         modify_cursor_keys := first_param;
                                 when 1 =>   -- prefix sequence with CSI
                                    on_buffer.modifiers.
                                         modify_cursor_keys := prefix_with_CSI;
                                 when 2 =>   -- modifier is forced to second
                                    on_buffer.modifiers.
                                         modify_cursor_keys := second_param;
                                 when 3 =>   -- hint sequence is private with >
                                    on_buffer.modifiers.
                                         modify_cursor_keys := is_private;
                                 when others => null;  -- ignore
                              end case;
                           when 2 => null;  -- modifyFunctionKeys
                              case param(2) is
                                 when -1 =>   -- use shift + ctrl modifiers
                                    on_buffer.modifiers.
                                       modify_function_keys := shift_ctl;
                                 when 0 =>   -- modifier is first parameter
                                    on_buffer.modifiers.
                                       modify_function_keys := first_param;
                                 when 1 =>   -- prefix sequence with CSI
                                    on_buffer.modifiers.
                                       modify_function_keys := prefix_with_CSI;
                                 when 2 =>   -- modifier is forced to second
                                    on_buffer.modifiers.
                                       modify_function_keys := second_param;
                                 when 3 =>   -- hint sequence is private with >
                                    on_buffer.modifiers.
                                       modify_cursor_keys := is_private;
                                 when others => null;  -- ignore
                              end case;
                           when 4 => null;  -- modifyOtherKeys
                              case param(2) is
                                 when 0 =>   -- disable the feature
                                    on_buffer.modifiers.modify_other_keys := 
                                                                      disabled;
                                 when 1 =>   -- enable with exceptions
                                    on_buffer.modifiers.modify_other_keys := 
                                                            all_except_special;
                                 when 2 =>   -- enable without exceptions
                                    on_buffer.modifiers.modify_other_keys := 
                                                         all_including_special;
                                 when others => null;  -- ignore
                              end case;
                           when others => null;  -- ignore
                        end case;
                        Log_Data(at_level => 9, 
                                 with_details=>"Process_Escape: Escape '"&
                                               Ada.Characters.Conversions.
                                                  To_Wide_String(the_sequence)&
                                               "' not yet fully implemented.");
                     when 'n' => null;  -- Disable key modifier options
                        Log_Data(at_level => 9, 
                                 with_details=>"Process_Escape: Escape '"&
                                               Ada.Characters.Conversions.
                                                  To_Wide_String(the_sequence)&
                                               "' not yet implemented.");
                     when others => null;  -- Otherwise not yet implemented
                        Log_Data(at_level => 9, 
                                 with_details=>"Process_Escape: Escape '"&
                                               Ada.Characters.Conversions.
                                                  To_Wide_String(the_sequence)&
                                               "' not yet implemented.");
                  end case;
                  the_sequence(chr_pos) := '!';  -- Dummy to exit further ops
               elsif the_sequence(ist+2) = '='
               then  -- It is an evil variation for xterm
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '[=...x' - evil sequence.");
                  case the_sequence(chr_pos) is
                     when 'c' =>  -- Send Device Attributes (Tertiary DA)
                        Write(fd => on_buffer.master_fd, 
                              Buffer => Esc_str & "P!|00000000" & Esc_str & "\");
                        the_sequence(chr_pos) := '!';  -- Dummy to exit further ops
                     when others => null;
                  end case;
               elsif the_sequence(ist+2) = '?'
               then  -- It is an evil variation for xterm
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '[?...x' - evil sequence.");
                  case the_sequence(chr_pos) is
                     when 'm' =>   -- query key modifier options XTQMODKEYS
                        declare
                           id : UTF8_String (1..1) := "0";
                        begin
                           case param(1) is
                              when 0 =>   -- modifyKeyboard
                                 id:=As_String(keyboard_modifier_options'Enum_Rep
                                        (on_buffer.modifiers.modify_keyboard));
                              when 1 =>   -- modifyCursorKeys
                                 id:=As_String(cursor_key_modifier_options'Enum_Rep
                                        (on_buffer.modifiers.modify_cursor_keys));
                              when 2 =>   -- modifyFunctionKeys
                                 id:=As_String(function_key_modifier_options'Enum_Rep
                                        (on_buffer.modifiers.modify_function_keys));
                              when 4 =>   -- modifyOtherKeys
                                 id:=As_String(other_key_modifier_options'Enum_Rep
                                        (on_buffer.modifiers.modify_other_keys));
                              when others => null;  -- ignore
                           end case;
                           Log_Data(at_level => 9, 
                              with_details => "Process_Escape: Escape '"&
                                           Ada.Characters.Conversions.
                                                  To_Wide_String(the_sequence)&
                                           "' not yet properly implemented. " &
                                           "Responding to query on " & 
                                           param(1)'Wide_Image & ", with id " &
                                           Ada.Characters.Conversions.
                                                  To_Wide_String(id) & ".");
                           if (param(1) >=0 and param(1) <= 2) or param(1) = 4
                           then  -- output + set to Dummy to exit further ops
                              Write(fd => on_buffer.master_fd, 
                                    Buffer => Esc_str & "[>" & 
                                              As_String(param(1)) & ";" & id &
                                              "m");
                              the_sequence(chr_pos) := '!';
                           end if;
                        end;
                     when 'n' => null;  -- Device Status Report
                        if param(1) = 6
                        then  -- Report Cursor Position (DECXCPR)
                           Get_Iter_At_Mark(the_buf, cursor_iter,
                                         Get_Insert(the_buf));
                           declare
                              CSI : UTF8_string(1..1) := "[";
                              utf8_line: UTF8_String := 
                                         Get_Line_From_Start
                                                  (for_buffer => on_buffer, 
                                                   up_to_iter => cursor_iter);
                              cur_line : wide_string :=
                                         Ada.Strings.UTF_Encoding.Wide_Strings.
                                         Decode(utf8_line);
                           begin
                              Write(fd => on_buffer.master_fd, 
                                 Buffer => Esc_str & CSI & "?" &
                                        As_String(Get_Line_Number
                                           (for_terminal=> on_buffer.parent, 
                                            at_iter => cursor_iter)) & ";" & 
                                        -- As_String(cur_line'Length) & 
                                        As_String(UTF8_Length(utf8_line)) & 
                                        "R");
                           end;
                        else
                           Log_Data(at_level => 9, 
                                    with_details=>"Process_Escape: Escape '"&
                                               Ada.Characters.Conversions.
                                                  To_Wide_String(the_sequence)&
                                              "' not yet implemented.");
                        end if;
                        the_sequence(chr_pos) := '!';  -- Dummy to exit further ops
                     when others => -- processed below, so
                        chr_pos := ist + 2;  -- reset back for furthur processing
                        -- Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '[?...x' - evil sequence resetting chr_pos to the_sequence(" & chr_pos'wide_image & ")= '" & Ada.Characters.Conversions.To_Wide_String(the_sequence(chr_pos..chr_pos)) & "'.");
                  end case;
                  null;  -- Not yet implemented
               end if;
               case the_sequence(chr_pos) is
                  when '!' => null;  -- Ignore (to exit further operations)
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '[>/?...x' - evil sequence bail signal given.");
                  when '?' => -- private sequences
                     if param(1) = 0 then
                        Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?...' - Private sequence extracting param(1).");
                        -- extract the number, if any
                        chr_pos := ist + 3;
                        while for_sequence'Length > chr_pos + ist - 1 and then
                        for_sequence(chr_pos) in '0'..'9' loop
                           param(1) := param(1) * 10 + 
                                       Character'Pos(for_sequence(chr_pos)) -
                                       Character'Pos('0');
                           chr_pos := chr_pos + 1;
                        end loop;
                     elsif chr_pos + ist - 1 < for_sequence'Length
                     then  -- advance to the end character
                        chr_pos := for_sequence'Length - ist + 1;
                        Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?...' - Private sequence chr_pos set to" & chr_pos'wide_image & ".");
                     end if;
                     for param_num in 1..num_params loop
                        case param(param_num) is
                           when 0 => null;  -- ignore this
                           when 1 =>   -- DECCKM Cursor Keys App Mode
                              -- Enable Cursor Keys Application Mode where 
                              -- Keypad keys will emit their Application Mode
                              -- sequences (on=h) or their Numeric Mode
                              -- sequences (off=l).
                              if for_sequence(chr_pos) = 'h'
                              then  -- Application Mode
                                 on_buffer.cursor_keys_in_app_mode := true;
                              elsif for_sequence(chr_pos) = 'l'
                              then  -- Numeric Mode
                                 on_buffer.cursor_keys_in_app_mode := false;
                              end if;
                           when 12 => null;  -- cursor blinking/not blinking
                              if for_sequence(chr_pos) = 'h'
                              then  -- switch on blinking
                                 Reset_Cursor_Blink(on_buffer.parent);
                              elsif for_sequence(chr_pos) = 'l'
                              then  -- switch off blinking
                                 null;  -- gtk_text_view_stop_cursor_blink not
                                 Log_Data(at_level => 9,  --  found in GTK Ada.
                                         with_details=>"Process_Escape: Escape '"&
                                                     Ada.Characters.Conversions.
                                                     To_Wide_String(for_sequence)&
                                                     "' not yet implemented." &
                                                       " Missing " & 
                                                       "stop_cursor_blink in" &
                                                       " GtkAda");
                              end if;
                           when 25 =>   -- show/hide cursor
                              if for_sequence(chr_pos) = 'h'
                              then
                                 on_buffer.cursor_is_visible := true;
                              elsif for_sequence(chr_pos) = 'l'
                              then
                                 on_buffer.cursor_is_visible := false;
                              end if;
                              Set_Cursor_Visible(on_buffer.parent, 
                                                 on_buffer.cursor_is_visible);
                              if on_buffer.cursor_is_visible then
                                 -- ensure cursor is on screen if made visible
                                 Scroll_Mark_Onscreen(on_buffer.parent, 
                                                      Get_Insert(the_buf));
                                 -- Scroll_To_Mark(on_buffer.parent,
                                    --             Get_Insert(the_buf), 0.0, 
                                    --             false, 0.0, 0.0);
                              end if;
                           when 1000 => null;  -- Send Mouse X & Y on button
                                               -- press and release
                              on_buffer.mouse_config.x10_mouse := 
                                                   for_sequence(chr_pos) = 'h';
                              Log_Data(at_level => 9, 
                                       with_details=>"Process_Escape: Escape "&
                                                     "SET_X10_MOUSE ;" &
                                                     Ada.Characters.Conversions.
                                                     To_Wide_String(for_sequence)&
                                                     "' not yet fully implemented.");
                           when 1002 => null;  --Use Cell Motion Mouse Tracking
                              on_buffer.mouse_config.btn_event := 
                                                   for_sequence(chr_pos) = 'h';
                              Log_Data(at_level => 9, 
                                       with_details=>"Process_Escape: Escape "&
                                                     "SET_BTN_EVENT_MOUSE ;" &
                                                     Ada.Characters.Conversions.
                                                     To_Wide_String(for_sequence)&
                                                     "' not yet fully implemented.");
                           when 1004 =>  -- reporting focus enable/disable
                              Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?1004' - Setting on_buffer.reporting_focus_enabled.");
                              on_buffer.reporting_focus_enabled := 
                                                   for_sequence(chr_pos) = 'h';
                           when 1006 => null;  -- SGR Mouse Mode enable/disable
                              on_buffer.mouse_config.ext_mode := 
                                                   for_sequence(chr_pos) = 'h';
                              Log_Data(at_level => 9, 
                                       with_details=>"Process_Escape: Escape "&
                                                     "SET_EXT_MODE_MOUSE ;" &
                                                     Ada.Characters.Conversions.
                                                     To_Wide_String(for_sequence)&
                                                     "' not yet fully implemented.");
                           when 1049 =>  -- alternative screen buffer
                              declare
                                 the_term : Gtk_Terminal := 
                                    Gtk_Terminal(Get_Parent(on_buffer.parent));
                              begin
                                 if for_sequence(chr_pos) = 'h'
                                 then  -- switch to the alternate screen buffer
                                    -- Set the flags to indicate which buffer
                                    on_buffer.alternative_screen_buffer:= true;
                                     -- Clear out the alternate buffer
                                    Get_Start_Iter(on_buffer.alt_buffer,
                                                   cursor_iter);
                                    Get_End_Iter(on_buffer.alt_buffer,dest_iter);
                                    Delete(on_buffer.alt_buffer,
                                           cursor_iter, dest_iter);
                                     -- Switch to the alternate buffer
                                    Gtk.Text_View.Set_Buffer
                                               (view  => the_term.terminal,
                                                buffer=> on_buffer.alt_buffer);
                                    Switch_The_Light(on_buffer, 1, false);
                                    Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?1049' - Switched to Alternative Screen Buffer.");
                                 elsif for_sequence(chr_pos) = 'l'
                                 then  -- switch back to the regular buffer
                                    -- Set the flags to indicate which buffer
                                    on_buffer.alternative_screen_buffer:=false;
                                     -- Switch to the main regular buffer
                                    Gtk.Text_View.Set_Buffer
                                               (view  => the_term.terminal,
                                                buffer=> on_buffer);
                                    -- reset key values to no value (i.e. 0)
                                    on_buffer.scroll_region_top    := 0;
                                    on_buffer.scroll_region_bottom := 0;
                                    -- and make sure we are at the cursor point
                                    Scroll_Mark_Onscreen(the_term.terminal, 
                                                        Get_Insert(on_buffer));
                                    Switch_The_Light(on_buffer, 1, true);
                                    Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?1049' - Switched to Normal Screen Buffer.");
                                 end if;
                              end;
                           when 2004 =>  -- bracketed paste mode, text pasted in
                              if for_sequence(chr_pos) = 'h'
                              then  -- switch on echo if config allows
                                 on_buffer.bracketed_paste_mode := true;
                                 on_buffer.cmd_prompt_check.Start_Looking;
                                 Switch_The_Light(on_buffer, 3, true);
                              elsif for_sequence(chr_pos) = 'l'
                              then  -- switch off keyboard echo + paste in
                                 on_buffer.bracketed_paste_mode := false;
                                 on_buffer.cmd_prompt_check.Stop_Looking;
                                 Get_End_Iter(the_buf, cursor_iter);
                                 Move_Mark_By_Name(the_buf, "end_paste", 
                                                   cursor_iter);
                                 Switch_The_Light(on_buffer, 3, false);
                              end if;
                              Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?2004' - Setting on_buffer.bracketed_paste_mode to " & on_buffer.bracketed_paste_mode'Wide_Image & ".");
                           when others =>  -- not valid and not interpreted
                              Handle_The_Error(the_error => 3, 
                                      error_intro=> "Process_Escape: " & 
                                                    "Control string error",
                                      error_message => "Unrecognised private "&
                                                       "sequence for '" & 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                                       "'.");
                        end case;
                     end loop;
                  when '@' =>   -- Insert (param) space chars ahead of cursor
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     -- Insert the spaces, leaving the cursor where it is:
                     -- Use the Text_Buffer's insert to insert whether in
                     -- overwrite or not
                     Gtk.Text_Buffer.Insert_At_Cursor(the_buf, 
                                                      text => (param(1)*' '));
                     -- Get the current cursor position
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     -- Move the cursor back to the starting point
                     Backward_Chars(cursor_iter, Glib.Gint(param(1)), res);
                     Place_Cursor(the_buf, where => cursor_iter);
                  when 'A' =>   -- Cursor Up (param spaces)
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     -- Get the column number (to preserve it)
                     column := UTF8_Length(Get_Line_From_Start(on_buffer, 
                                                               cursor_iter));
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape [ A : Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", going up by" & param(1)'Wide_Image & " lines.  Current column =" & column'Wide_Image & ".");
                     -- Move the cursor up
                     for line_num in 1 .. param(1) loop
                        if Backward_Display_Line(on_buffer.parent,cursor_iter)
                        then  -- Successfully gone one line back
                           if line_num = param(1) then -- at desired line
                              for col in 1 .. column loop
                                 Forward_Char(cursor_iter, res);
                                 if not res then  -- no more characters right
                                    if Starts_Display_Line(on_buffer.parent, 
                                                           cursor_iter)
                                    then  -- go back to previous position
                                       Backward_Char(cursor_iter, res);
                                    end if;
                                    -- Pad out with a space character
                                    Insert(on_buffer, at_iter=>cursor_iter,
                                           the_text=>" ");
                                 end if;
                              end loop;
                           end if;
                           Place_Cursor(the_buf, where => cursor_iter);
                        end if;
                     end loop;
                  when 'B' | 'e' =>   -- Cursor Down (param spaces)
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     -- Get the column number (to preserve it)
                     column := UTF8_Length(Get_Line_From_Start(on_buffer, 
                                                               cursor_iter));
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", going down by" & param(1)'Wide_Image & " lines.  Current column =" & column'Wide_Image & ".");
                     -- Move the cursor down
                     for line_num in 1 .. param(1) loop
                        if Forward_Display_Line(on_buffer.parent, cursor_iter)
                        then  -- Successfully gone one line forward
                           if line_num = param(1) then -- at desired line
                              for col in 1 .. column loop
                                 Forward_Char(cursor_iter, res);
                                 if not res then  -- no more characters right
                                    if Starts_Display_Line(on_buffer.parent, 
                                                           cursor_iter)
                                    then  -- go back to previous position
                                       Backward_Char(cursor_iter, res);
                                    end if;
                                    -- Pad out with a space character
                                    Insert(on_buffer, at_iter=>cursor_iter,
                                           the_text=>" ");
                                 end if;
                              end loop;
                           end if;
                           Place_Cursor(the_buf, where => cursor_iter);
                        end if;
                     end loop;
                  when 'C' | 'a' =>   -- Cursor Forward (param spaces)
                     -- Move  the cursor forwards (without deleting characters)
                     -- First, get the cursor location
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     -- Then move forward one or more characters
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : [" & param(1)'Wide_Image & "C - Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", going forward by" & param(1)'Wide_Image & " characters.  Line Length =" & Get_Chars_In_Line(cursor_iter)'Wide_Image & ", current column =" & UTF8_Length(Get_Line_From_Start(on_buffer, cursor_iter))'Wide_Image & ".");
                     res := true;  -- Initial value
                     for col in 1 .. param(1) loop
                        Get_End_Iter(the_buf, dest_iter);
                        if Equal(cursor_iter, dest_iter) or not res
                        then  -- already at the end of the line
                              -- Pad out with a space character
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : [" & param(1)'Wide_Image & "C: Either NOT Res (" & res'Wide_Image & ") or cursor_iter = End of Line.");
                           Insert(on_buffer, at_iter=>cursor_iter,
                                  the_text=>" ");
                           Backward_Char(cursor_iter, res);
                        end if;
                        Forward_Char(cursor_iter, res);
                     end loop;
                     -- Now make this the cursor location
                     Place_Cursor(the_buf, where => cursor_iter);
                  when 'D' =>   -- Cursor Back (param spaces)
                     -- Move  the cursor backwards (without deleting characters)
                     -- First, get the cursor location
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     -- Then move back one or more characters
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", going backward by" & param(1)'Wide_Image & " characters.  Line Length =" & Get_Chars_In_Line(cursor_iter)'Wide_Image & ", current column =" & UTF8_Length(Get_Line_From_Start(on_buffer, cursor_iter))'Wide_Image & ".");
                     Backward_Chars(cursor_iter, Glib.Gint(param(1)), res);
                     if res then
                        Place_Cursor(the_buf, where => cursor_iter);
                     end if;
                  when 'E' =>   -- Cursor Next Line start (param num of lines)
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     Backward_Line(cursor_iter, res);  -- go to last line start
                     if res then  -- did go back
                        Forward_Line(cursor_iter, res); -- return to current line
                     end if;
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                      -- go to desired line
                     Forward_Lines(cursor_iter, Glib.Gint(param(1)), res);
                     Place_Cursor(the_buf, where => cursor_iter);
                  when 'F' =>   -- Cursor Previous Line start (1/param spaces)
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     Backward_Line(cursor_iter, res);  -- go to last line start
                      -- go to desired line
                     if param(1) > 1
                     then
                        Backward_Lines(cursor_iter, Glib.Gint(param(1)), res);
                     end if;
                     Place_Cursor(the_buf, where => cursor_iter);
                  when 'G' | '`' =>   -- Move cursor to column <param>
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     Backward_Line(cursor_iter, res);  -- go to last line start
                     if res then  -- did go back
                        Forward_Line(cursor_iter, res); -- return to current line
                     end if;
                     if param(1) > 1
                     then
                        Forward_Chars(cursor_iter, Glib.Gint(param(1)-1), res);
                     end if;
                     Place_Cursor(the_buf, where => cursor_iter);
                  when 'H' | 'f' =>   -- Move cursor to row <param>, column <param>
                     declare
                        the_term       : Gtk_Text_View := on_buffer.parent;
                        the_terminal   : Gtk_Terminal := 
                                            Gtk_Terminal(Get_Parent(the_term));
                        saved_markup   : Gtkada.Types.Chars_Ptr;
                        saved_modifiers: font_modifier_array;
                        in_markup_state: boolean;
                        home_line_num  : Glib.Gint;
                     begin
                        -- If a modifier string is in progress, then need to
                        -- clear it before moving, so dump out what is there
                        -- first, saving what is there to restore post-
                        -- relocation of the cursor.
                        if on_buffer.markup_text /= Null_Ptr
                        then  -- a string to dump
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - Saving mark-up.");
                           -- Rebuild the mark-up (but not text) from modifier
                           -- array
                           saved_markup := 
                              Regenerate_Markup(from=> on_buffer.markup_text);
                                    --New_String(Value(on_buffer.markup_text));
                           -- Save a copy of the modifier array
                           Copy(from => on_buffer.modifier_array, 
                                to => saved_modifiers);
                           -- and hte mark-up state for later restoration
                           in_markup_state := on_buffer.in_markup;
                           -- (close off, but the closure is temporary)
                           Finish_Markup(for_buffer => on_buffer);
                        else
                           saved_markup := Null_Ptr;
                        end if;
                        if on_buffer.scroll_region_bottom > 0
                        then  -- the top of the buffer is the correct home
                              -- position in this case
                           Get_Start_Iter(the_buf, cursor_iter);
                           -- Also, can't go past the bottom of screen, wrap it
                           -- if needs be
                           if param(1) > on_buffer.scroll_region_bottom -
                                         on_buffer.scroll_region_top + 1
                           then
                              param(1) := (on_buffer.scroll_region_bottom -
                                           on_buffer.scroll_region_top + 1) mod
                                          param(1);
                           end if;
                        else  -- Get the home position
                           cursor_iter := 
                                     Home_Iterator(for_terminal=>the_terminal);
                        end if;
                        home_line_num := Get_Line(cursor_iter);
                     -- Get the start of the last line for checking if we need
                     -- to add in more lines
                        Get_End_Iter(the_buf, dest_iter);
                        if not Starts_Line(dest_iter) then
                           Set_Line_Offset(dest_iter, 0);
                        end if;
                     -- now move to the offset from the top left corner
                        Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - moving from top LH corner (col" & GInt'Wide_Image(Get_Line_Index(cursor_iter)+1) & ", row" & GInt'Wide_Image(Get_Line(cursor_iter)+1) & ") to (row,col) position (" & param(1)'Wide_Image & "," & param(2)'Wide_Image & ").  Cursor is at (row" & GInt'Wide_Image(Get_Line(cursor_iter)+1) & ", col" & GInt'Wide_Image(Get_Line_Index(cursor_iter)+1) & ").");
                        if param(1) > 1 then
                           Set_Line_Offset(cursor_iter, 0);  -- to be sure to be sure
                           for line in 2 .. param(1) loop
                              Forward_Line(cursor_iter, res);
                              if not res and then 
                                 Compare(cursor_iter, dest_iter) >= 0 and then
                                 Get_Line(cursor_iter) - home_line_num + 1 <
                                                            Glib.Gint(param(1))
                              then -- no more lines + need one, so add one in
                                 Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - No more lines, adding one in...");
                                 Gtk.Text_Buffer.Insert(the_buf, 
                                                         cursor_iter, LF_str);
                                 Get_End_Iter(the_buf, dest_iter);
                              end if;
                           end loop;
                        end if;
                        if param(2) > 1 then
                           for col in 2 .. param(2) loop
                              if not Ends_Line(cursor_iter)
                              then  -- line long enough - move forward
                                 Forward_Char(cursor_iter, res);
                              else  -- line not long enough
                              -- Pad out with a space character
                                 Insert(on_buffer, at_iter=>cursor_iter,
                                     the_text=>" ");
                              end if;
                           end loop;
                        end if;
                        -- Now make this the new cursor location in the current
                        -- buffer
                        Place_Cursor(the_buf, where => cursor_iter);
                        if on_buffer.cursor_is_visible
                        then  -- only move if the cursor is made visible
                           Scroll_Mark_Onscreen(on_buffer.parent, 
                                                Get_Insert(the_buf));
                           Scroll_To_Mark(on_buffer.parent,Get_Insert(the_buf),
                                          0.0, false, 0.0, 0.0);
                        end if;
                        Get_Iter_At_Mark(the_buf,cursor_iter,
                                         Get_Insert(the_buf));
                        if saved_markup /= Null_Ptr
                        then  -- mark-up to restore, do a complete restore
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - Restoring mark-up.");
                           Free(on_buffer.markup_text);
                           on_buffer.markup_text := 
                                            New_String(Value(saved_markup));
                           Copy(from => saved_modifiers, 
                                to => on_buffer.modifier_array);
                           on_buffer.in_markup := in_markup_state;
                        end if;
                        Free(saved_markup);
                     end;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - moved to (row" & GInt'Wide_Image(Get_Line(cursor_iter)+1) & ", col" & GInt'Wide_Image(Get_Line_Index(cursor_iter)+1) & ").");
                  when 'I' => null;  -- Cursor Horizontal (Forward) Tab
                     -- Advance the cursor to the next column (in the same row)
                     -- with a tab stop. If there are no more tab stops, move
                     -- to the last column in the row. If the cursor is in the
                     -- last column, move to the first column of the next row.
                     Log_Data(at_level => 9, 
                              with_details => "Process_Escape: Escape '" & 
                                              Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                              "' not yet implemented.");
                  when 'J' =>   -- Erase in Display <param> type of erase
                     Window_To_Buffer_Coords(on_buffer.parent, 
                                             Gtk.Enums.Text_Window_Text, 
                                             0, 0, buf_x, buf_y);
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'J' - top LH corner = (" & buf_x'Wide_Image & "," & buf_y'Wide_Image & ").");
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     case param(1) is
                        when 0 =>   -- Clear from cursor to end of screen
                           Get_End_Iter(the_buf, dest_iter);
                           Delete(the_buf, cursor_iter, dest_iter);
                        when 1 =>   -- Clear from TLH corner to cursor
                           res:= Get_Iter_At_Position(on_buffer.parent,
                                                      dest_iter'access, null,
                                                      buf_x, buf_y);
                           Delete(the_buf, dest_iter, cursor_iter);
                        when 2 =>   -- Clear the screen
                           res:= Get_Iter_At_Position(on_buffer.parent,
                                                      dest_iter'access, null,
                                                      buf_x, buf_y);
                           Get_End_Iter(the_buf, cursor_iter);
                           Delete(the_buf, dest_iter, cursor_iter);
                           -- Now scroll the cursor to the top
                           Get_Iter_At_Mark(the_buf, cursor_iter,
                                            Get_Insert(the_buf));
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'J' - cursor pos (i.e. line-1) =" & Get_Line(cursor_iter)'Wide_Image & ", Scrolling to ensure the screen is clear.");
                            -- Put the cursor position at the top of the screen
                           declare  -- NO METHOD SEEMS TO WORK IF SCREEN NOT COMPLETELY CLEAR
                              use Gtk.Text_Mark;
                              end_mark : Gtk.Text_Mark.Gtk_Text_Mark;
                           begin
                              Set_Line_Offset(cursor_iter, 0);  -- move to start of line
                              -- res := Scroll_To_Iter(on_buffer.parent, cursor_iter, 0.0, true, 0.0, 0.0);
                              Gtk.Text_Mark.Gtk_New(end_mark, "End", false);
                              Add_Mark(the_buf, end_mark, cursor_iter);
                              Scroll_To_Mark(on_buffer.parent, end_mark, 0.0, true, 0.0, 0.0);
                              Delete_Mark(the_buf, end_mark);
                           end;
                        when 3 =>   -- Clear the entire buffer
                           Get_Start_Iter(the_buf, dest_iter);
                           Get_End_Iter(the_buf, cursor_iter);
                           Delete(the_buf, dest_iter, cursor_iter);
                        when others => null; -- invalid erase type, just ignore
                     end case;
                  when 'K' =>   -- Erase in Line <param> type of erase
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     -- use a large offset to point to the end of this line
                     Get_Iter_At_Line_Offset(the_buf, dest_iter,
                                             Get_Line(cursor_iter), 20000);
                     case param(1) is
                        when 0 =>   -- Clear from cursor to end of line
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 0 'K' - cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", Deleting from cursor to end of line '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(the_buf, cursor_iter, dest_iter)) & "'.");
                           Delete(the_buf, cursor_iter, dest_iter);
                        when 1 =>   -- Clear from cursor to beginning of line
                           Get_Iter_At_Line_Offset(the_buf, dest_iter,
                                                   Get_Line(cursor_iter), 0);
                           Delete(the_buf, dest_iter, cursor_iter);
                        when 2 =>   -- Clear the entire line
                           Get_Iter_At_Line_Offset(the_buf, cursor_iter,
                                                   Get_Line(cursor_iter), 0);
                           Delete(the_buf, cursor_iter, dest_iter);
                        when others => null; -- invalid clear type, just ignore
                     end case;
                  when 'L' =>  -- Insert (param) blank lines
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     Insert_At_Cursor(on_buffer, the_text=>(param(1) * 
                                                  Ada.Characters.Latin_1.LF));
                  when 'P' => null;  --DCH -- Delete <param> characters
                     if param(1) = 0
                      then
                        param(1) := 1;
                     end if;
                     -- get the start point to delete from
                     Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
                     -- Get the end point to delete to (param(1) characters)
                     Get_Iter_At_Mark(the_buf, dest_iter, Get_Insert(the_buf));
                     -- dest_iter -> just past the last char to delete
                     Forward_Chars(dest_iter, Glib.Gint(param(1)), res);
                     -- N.B. res=false if dest_iter is at end iterator
                     -- Delete requested number of characters
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI " & param(1)'Wide_Image & " 'P' - cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", Deleting '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(the_buf, cursor_iter, dest_iter)) & "'.");
                     Delete(the_buf, cursor_iter, dest_iter);
                  when 'S' =>   -- Scroll Up <param> lines
                        -- Get the top left hand corner of the screen
                     Window_To_Buffer_Coords(on_buffer.parent, 
                                                Gtk.Enums.Text_Window_Text, 
                                                0, 0, buf_x, buf_y);
                     res:= Get_Iter_At_Position(on_buffer.parent,
                                                   dest_iter'access, null,
                                                   buf_x, buf_y);
                     -- Scroll forward requested number of lines + page size
                     if param(1) = 0
                      then
                        param(1) := 1;
                     end if;
                     Forward_Lines(dest_iter, 
                                   Glib.Gint(param(1)+Gtk_Terminal(
                                           Get_Parent(on_buffer.parent)).rows),
                                   res);
                     res := Scroll_To_Iter(on_buffer.parent, dest_iter, 0.0, 
                                           true, 0.0, 0.0);
                  when 'T' =>   -- Scroll Down <param> lines
                      -- Get the top left hand corner to scroll down from
                     Window_To_Buffer_Coords(on_buffer.parent, 
                                             Gtk.Enums.Text_Window_Text, 
                                             0, 0, buf_x, buf_y);
                     res:= Get_Iter_At_Position(on_buffer.parent,
                                                dest_iter'access, null,
                                                buf_x, buf_y);
                     -- set the iter down the requesten number of lines
                     if param(1) = 0
                      then
                        param(1) := 1;
                     end if;
                     Backward_Lines(dest_iter, Glib.Gint(param(1)), res);
                     res := Scroll_To_Iter(on_buffer.parent, dest_iter, 0.0, 
                                           true, 0.0, 0.0);
                  when 'Z' => null; -- CBT Cursor Backward Tabulation <n> tab stops
                     -- Move the cursor to the previous column (in the same
                     -- row) with a tab stop. If there are no more tab stops,
                     -- moves the cursor to the first column. If the cursor is
                     -- in the first column, doesn’t move the cursor.
                     Log_Data(at_level => 9, 
                               with_details=> "Process_Escape: Escape '" & 
                                              Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                              "' not yet implemented.");
                  when 'c' =>   -- Send Device Attributes (Primary DA)
                     Write(fd => on_buffer.master_fd, 
                              Buffer => Esc_str & "[?1;0c");
                  when 'g' => null;  -- Tab Clear
                     -- Clear tab stops at current position (0) or all (3)
                     -- (default=0)
                     Log_Data(at_level => 9, 
                              with_details=> "Process_Escape: Escape '" & 
                                             Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                             "' not yet implemented.");
                  when 'i' => null;  -- Serial port control (media copy)
                     Log_Data(at_level => 9, 
                              with_details=> "Process_Escape : Escape '" &
                                             Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                             "' not yet implemented.");
                  when 'm' =>   -- set or reset font colouring and styles
                     while count <= pnum loop
                        case param(count) is
                           when 0 =>   -- reset to normal
                              Finish_Markup(on_buffer);
                           when 1 =>   -- bold
                              Append_To_Markup(on_buffer, bold);
                           when 2 => null;  -- dim/faint
                           when 3 =>   -- italic
                              Append_To_Markup(on_buffer, italic);
                           when 4 =>   -- underline
                              Append_To_Markup(on_buffer, underline);
                           when 5 => null;  -- show blink
                           when 6 => null;  -- rapid blink
                           when 7 =>   -- reverse video
                              Append_To_Markup(on_buffer, span, "foreground=", 
                                               on_buffer.background_colour);
                              Append_To_Markup(on_buffer, span, "background=", 
                                               on_buffer.text_colour);
                           when 8 =>   -- conceal or hide
                              -- by setting foreground to background colour
                              Append_To_Markup(on_buffer, span, "foreground=", 
                                               on_buffer.background_colour);
                           when 9 =>   -- crossed out or strike-through
                              Append_To_Markup(on_buffer, strikethrough);
                           when 10 => null;  -- primary font
                           when 11 .. 19 => null; -- alternative font number n-10
                           when 20 => null; -- Fraktur (Gothic)
                           when 21 =>  -- Doubly underlined
                              Append_To_Markup(on_buffer, span, 
                                               "underline=""double"" ");
                           when 22 =>  -- Normal intensity
                              if on_buffer.modifier_array(bold).n > 0
                              then
                                 Finish_Markup(on_buffer, bold);
                              end if;
                           when 23 => null; -- Neither italic, nor blackletter
                              if on_buffer.modifier_array(italic).n > 0
                              then
                                 Finish_Markup(on_buffer, italic);
                              end if;
                           when 24 =>  -- Not underlined
                              if on_buffer.modifier_array(underline).n > 0 then
                                 Finish_Markup(on_buffer, underline);
                              end if;
                           when 25 => null; -- Not blinking
                           when 26 =>  -- Proportional spacing
                              if on_buffer.modifier_array(mono).n > 0 then
                                 Finish_Markup(on_buffer, mono);
                              end if;
                           when 27 =>  -- Not reversed
                              if on_buffer.markup_text /= Null_Ptr
                              and then -- check for '<span' already being there
                                 Ada.Strings.Fixed.Count
                                       (Value(on_buffer.markup_text),"<span")>0
                              and then -- check for "foreground" already  there
                                 Ada.Strings.Fixed.Count
                                  (Value(on_buffer.markup_text),"foreground")>0
                              then
                                 Finish_Markup(on_buffer, span);
                              else  -- define the Not reversed state
                                 Append_To_Markup(on_buffer,span,"foreground=",
                                                  on_buffer.text_colour);
                                 Append_To_Markup(on_buffer,span,"background=",
                                                  on_buffer.background_colour);
                              end if;
                           when 28 =>  -- Reveal (not invisible)
                              -- by setting foreground to foreground colour
                              Append_To_Markup(on_buffer, span, "foreground=", 
                                               on_buffer.text_colour);
                           when 29 =>  -- Not crossed out
                              if on_buffer.modifier_array(strikethrough).n > 0
                              then
                                 Finish_Markup(on_buffer, strikethrough);
                              end if;
                           when 30 | 90 =>  -- Set foreground colour to black
                              Append_To_Markup(on_buffer, span, "foreground=""black""");
                           when 31 | 91 =>  -- Set foreground colour to red
                              Append_To_Markup(on_buffer, span, "foreground=""red""");
                           when 32 | 92 =>  -- Set foreground colour to green
                              Append_To_Markup(on_buffer, span, "foreground=""green""");
                           when 33 | 93 =>  -- Set foreground colour to yellow
                              Append_To_Markup(on_buffer, span, "foreground=""yellow""");
                           when 34 | 94 =>  -- Set foreground colour to blue
                              Append_To_Markup(on_buffer, span, "foreground=""blue""");
                           when 35 | 95 =>  -- Set foreground colour to magenta
                              Append_To_Markup(on_buffer, span, "foreground=""magenta""");
                           when 36 | 96  =>  -- Set foreground colour to cyan
                              Append_To_Markup(on_buffer, span, "foreground=""cyan""");
                           when 37 | 97 =>  -- Set foreground colour to white
                              Append_To_Markup(on_buffer, span, "foreground=""white""");
                           when 38 =>  -- Set foreground colour to number
                              count := count + 1;
                              if param(count) = 5 then  -- colour chart colour
                                 count := count + 1;
                                 null;
                                 count := count + 1;
                              elsif param(count) = 2 then -- RGB
                                 count := count + 1;
                                 Append_To_Markup(on_buffer, span, "foreground=",
                                                  (GDouble(param(count))/255.0,
                                                   GDouble(param(count+1))/255.0,
                                                   GDouble(param(count+2))/255.0,
                                                   1.0));
                                 count := count + 2;
                              end if;
                           when 39 =>  -- Default foreground colour
                              Append_To_Markup(on_buffer, span, "foreground=""white""");
                           when 40 | 100 =>  -- Set background colour to black
                              Append_To_Markup(on_buffer, span, "background=""black""");
                           when 41 | 101 =>  -- Set background colour to red
                              Append_To_Markup(on_buffer, span, "background=""red""");
                           when 42 | 102 =>  -- Set background colour to green
                              Append_To_Markup(on_buffer, span, "background=""green""");
                           when 43 | 103 =>  -- Set background colour to yellow
                              Append_To_Markup(on_buffer, span, "background=""yellow""");
                           when 44 | 104 =>  -- Set background colour to blue
                              Append_To_Markup(on_buffer, span, "background=""blue""");
                           when 45 | 105 =>  -- Set background colour to magenta
                              Append_To_Markup(on_buffer, span, "background=""magenta""");
                           when 46 | 106 =>  -- Set background colour to cyan
                              Append_To_Markup(on_buffer, span, "background=""cyan""");
                           when 47 | 107 =>  -- Set background colour to white
                              Append_To_Markup(on_buffer, span, "background=""white""");
                           when 48 =>  -- Set background colour to number
                              count := count + 1;
                              if param(count) = 5 then  -- colour chart colour
                                 null;
                              elsif param(count) = 2 then -- RGB
                                 count := count + 1;
                                 Append_To_Markup(on_buffer, span, "background=", 
                                                  (GDouble(param(count))/255.0,
                                                   GDouble(param(count+1))/255.0,
                                                   GDouble(param(count+2))/255.0,
                                                   1.0));
                                 count := count + 2;
                              end if;
                           when 49 =>  -- Default background colour
                              Append_To_Markup(on_buffer, span,"background=""black""");
                           when 50 =>  -- Disable proportional spacing
                              Append_To_Markup(on_buffer, mono);
                           when others => null;  -- style or colour not recognised
                              Handle_The_Error(the_error => 4, 
                                               error_intro=>"Process_Escape: " &
                                                            "Control string error",
                                               error_message=> 
                                                  "Unrecognised control sequence " &
                                                  " with font or colour not " & 
                                                  "recognised for '" & 
                                                  Ada.Characters.Conversions.
                                                     To_Wide_String(for_sequence)&
                                                  "'.");
                        end case;
                        count := count + 1;
                     end loop;
                  when 'n' =>   -- Device status request
                     if param(1) = 5
                     then  -- Status Report "OK" '0n'
                        Write(fd => on_buffer.master_fd,
                              Buffer => Esc_str & "[0n");
                     elsif param(1) = 6
                     then  -- Report Cursor Position (CPR) "<row>;<column>R"
                        Get_Iter_At_Mark(the_buf, cursor_iter,
                                         Get_Insert(the_buf));
                        declare
                           CSI : UTF8_string(1..1) := "[";
                           utf8_line: UTF8_String := 
                                         Get_Line_From_Start
                                                  (for_buffer => on_buffer, 
                                                   up_to_iter => cursor_iter);
                        begin
                           Write(fd => on_buffer.master_fd, 
                              Buffer => Esc_str & CSI &
                                        As_String(Get_Line_Number
                                           (for_terminal=> on_buffer.parent, 
                                            at_iter => cursor_iter)) & ";" & 
                                        As_String(UTF8_Length(utf8_line)) & 
                                        "R");
                        end;
                     end if;
                  when 'r' =>  -- Set scrolling region DECSTBM
                     -- parameters are top and bottom row.
                     on_buffer.scroll_region_top    := param(1);
                     on_buffer.scroll_region_bottom := param(2);
                  when 's' =>  -- Save cursor position
                     on_buffer.saved_cursor_pos:= Get_Mark(on_buffer,"insert");
                  when 't' => null;  -- Window manipulation (XTWINOPS)
                     -- format is <Esc>[nn;a;0t (e.g. nn=22 or nn=23)
                     -- nn=21;0 : Report terminal's title
                     -- nn=22;0 : Save xterm icon and window title on stack.
                     -- nn=23;0 : Restore xterm icon + window title from stack.
                     -- a=0     : both xterm icon and window title
                     -- a=1     : xterm icon title
                     -- a=2     : xterm window title
                     declare
                        the_term : Gtk_Terminal := 
                                    Gtk_Terminal(Get_Parent(on_buffer.parent));
                     begin
                        if param(1) = 21 and (param(2) = 0 or param(2) = 2) and
                           param(3) = 0
                        then
                           Write(fd => on_buffer.master_fd, 
                                 Buffer=>Esc_str& "]l"& Value(the_term.title) &
                                          Esc_str & "\");
                        elsif param(1) = 22 and (param(2) = 0 or param(2) = 2)
                              and  param(3) = 0
                        then
                           Free(the_term.saved_title);
                           the_term.saved_title := 
                                             New_String(Value(the_term.title));
                        elsif param(1) = 23 and (param(2) = 0 or param(2) = 2)
                              and param(3) = 0
                        then
                           Free(the_term.title);
                           the_term.title :=
                                       New_String(Value(the_term.saved_title));
                        else
                           Log_Data(at_level => 9, 
                              with_details=>"Process_Escape: Escape XTWINOPS '"&
                                            Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                            "' not yet implemented.");
                        end if;
                     end;
                  when 'u' =>  -- Restore cursor position
                     Get_Iter_At_Mark(the_buf, cursor_iter, 
                                      on_buffer.saved_cursor_pos);
                     Move_Mark_By_Name(the_buf, "insert", cursor_iter);
                  when '~' =>  -- Non-standard, but used for going to end (VT)
                     case param(1) is
                        when 2 => -- VT sequence for Insert/Overwrite [non-standard]
                           null;
                           Log_Data(at_level => 9, 
                                    with_details => "Process_Escape: Escape '"&
                                                    Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                                    "' not yet implemented.");
                        when 4 => -- VT sequence for End [non-standard]
                           Get_Iter_At_Mark(the_buf, cursor_iter,
                                            Get_Insert(the_buf));
                           Forward_To_Line_End(cursor_iter, res);
                           Place_Cursor(the_buf, where => cursor_iter);
                        when 5 => -- VT sequence for Page Up [non-standard]
                           Get_Iter_At_Mark(the_buf, cursor_iter,
                                            Get_Insert(the_buf));
                           Backward_Lines(cursor_iter, 
                                          Glib.Gint(Gtk_Terminal(
                                           Get_Parent(on_buffer.parent)).rows/
                                           2 + 1),  -- half a screen
                                          res);
                           Place_Cursor(the_buf, where => cursor_iter);
                           Scroll_Mark_Onscreen(on_buffer.parent, 
                                                Get_Insert(the_buf));
                        when 6 => -- VT sequence for Page Down [non-standard]
                           Get_Iter_At_Mark(the_buf, cursor_iter,
                                            Get_Insert(the_buf));
                           Forward_Lines(cursor_iter, 
                                         Glib.Gint(Gtk_Terminal(
                                           Get_Parent(on_buffer.parent)).rows/
                                           2 + 1),  -- half a screen
                                         res);
                           Place_Cursor(the_buf, where => cursor_iter);
                           Scroll_Mark_Onscreen(on_buffer.parent, 
                                                Get_Insert(the_buf));
                        when 7 => -- VT sequence for Home [non-standard]
                           Get_Iter_At_Mark(the_buf, cursor_iter,
                                            Get_Insert(the_buf));
                           Set_Line_Index(cursor_iter, 0);  -- byte offset 0
                           Place_Cursor(the_buf, where => cursor_iter);
                        when 200 => -- may not treat characters as command?
                           if on_buffer.bracketed_paste_mode
                           then  -- sequence following not commands
                              on_buffer.pass_through_characters := true;
                              on_buffer.cmd_prompt_check.Stop_Looking;
                              Switch_The_Light(on_buffer, 4, true);
                           end if;
                        when 201 => -- may not treat characters as command?
                           if on_buffer.bracketed_paste_mode
                           then  -- start reinterpreting sequences as commands
                              on_buffer.pass_through_characters := false;
                              Switch_The_Light(on_buffer, 4, false);
                           end if;
                        when others => -- not yet implemented
                           Handle_The_Error(the_error => 5, 
                                      error_intro=> "Process_Escape: " & 
                                                    "Control string error",
                                      error_message=>"Unrecognised VT non-" &
                                                     "standard sequence for '"& 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                                     "'.");
                     end case;
                  when others => 
                     Handle_The_Error(the_error => 6, 
                                      error_intro=> "Process_Escape: " & 
                                                    "Control string error",
                                      error_message => "Unrecognised control " &
                                              "sequence for CSI sequence '" & 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                              "'.");
               end case;
            when 'H' => null;  -- Horizontal Tab Set
               -- Sets a tab stop in the current column the cursor is in.
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape : Escape HTS '" & 
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when 'M' => null;  -- Reverse Index
               -- move the cursor up one line, maintaining horizontal position,
               -- scrolling the buffer if necessary
               Get_Iter_At_Mark(the_buf, cursor_iter, Get_Insert(the_buf));
               -- Get the column number (to preserve it)
               column := natural(Get_Line_Index(cursor_iter));
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape M : Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & " (line='" & Ada.Characters.Conversions.To_Wide_String(Get_Whole_Line(on_buffer,cursor_iter)) & "'), going up by 1 line.  Current column =" & column'Wide_Image & ".");
               -- Move the cursor up
               if Backward_Display_Line(on_buffer.parent,cursor_iter)
               then  -- Successfully gone one line back
                  res := true;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape M : Success.  Current line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & " (line='" & Ada.Characters.Conversions.To_Wide_String(Get_Whole_Line(on_buffer,cursor_iter)) & "'), current column =" & column'Wide_Image & ".");
               else  -- Must be already at the first line
                  -- Insert a new line at the beginning
                  res := 
                     Backward_Display_Line_Start(on_buffer.parent,cursor_iter);
                  Gtk.Text_Buffer.Insert(the_buf, cursor_iter, LF_str);
                  -- then go back a line
                  res := Backward_Display_Line(on_buffer.parent,cursor_iter);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape M : Failed.  Inserted line with cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & " (line='" & Ada.Characters.Conversions.To_Wide_String(Get_Whole_Line(on_buffer,cursor_iter)) & "'), going up by 1 line.  Current column =" & column'Wide_Image & ".");
               end if;
               -- Ensure cursor_iter starts at the first column (column 0)
               if Get_Line_Offset(cursor_iter) > 0
               then  -- not at the start of the line
                  Set_Line_Offset(cursor_iter, 0);
               end if;
               if res and column > 0
               then  -- Successfully gone one line back (+ not at right column)
                  -- now go to the correct (i.e. original) column number
                  for col in 1 .. column loop
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape M :going forward a character.");
                     Forward_Char(cursor_iter, res);
                     if not res then  -- no more characters right
                        if Starts_Display_Line(on_buffer.parent, cursor_iter)
                        then  -- go back to previous position
                           Backward_Char(cursor_iter, res);
                        end if;
                         -- Pad out with a space character
                        Insert(on_buffer, at_iter=>cursor_iter, the_text=>" ");
                     end if;
                  end loop;
               end if;
               Place_Cursor(the_buf, where => cursor_iter);
               -- Scroll buffer if necessary
               Scroll_Mark_Onscreen(on_buffer.parent, Get_Insert(the_buf));
               Get_Iter_At_Mark(the_buf, cursor_iter, Get_Insert(the_buf));
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape M : Done. Cursor cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & " (line='" & Ada.Characters.Conversions.To_Wide_String(Get_Whole_Line(on_buffer,cursor_iter)) & "'), current column =" & Get_Line_Index(cursor_iter)'Wide_Image & ".");
            when 'N' => null;  -- Single Shift Two
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape (SSTwo) : Escape '" & 
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when 'O' => null;  -- Single Shift Three
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape (SSThree) : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when 'P' => null;  -- Device Control String (terminated by <Esc> \
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape (DCS) : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when 'X' => null;  -- Start of String
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when '\' => null;  -- String Terminator (terminates other commands)
               -- Handled elsewhere
            when ']' =>   -- Operating System Command (seems terminate by ^G)
               -- chr_pos := ist + 2;
               if param(1) = 0 and param(2) = 0 
               then  -- Terminal title
                  -- chr_pos := chr_pos + 2;
                  Free(Gtk_Terminal(Get_Parent(on_buffer.parent)).title);
                  Gtk_Terminal(Get_Parent(on_buffer.parent)).title := 
                        New_String(for_sequence(chr_pos..for_sequence'Last-1));
                  Gtk_Terminal(Get_Parent(on_buffer.parent)).title_callback(
                                   Gtk_Terminal(Get_Parent(on_buffer.parent)),
                                   for_sequence(chr_pos..for_sequence'Last-1));
               elsif param(1) = 8 and param(2) =0 and param(3) = 0 
               then  -- hyperlink
                  Get_Iter_At_Mark(the_buf, cursor_iter, Get_Insert(the_buf));
                  Insert_At_Cursor(into => on_buffer, the_text =>
                                   for_sequence(chr_pos..for_sequence'Last-2));
                  Get_Iter_At_Mark(the_buf, dest_iter, Get_Insert(the_buf));
                  Apply_Tag_By_Name(the_buf,"hyperlink",cursor_iter,dest_iter);
                  Log_Data(at_level => 9, 
                           with_details=>"Process_Escape (hyperlink): Escape '"&
                                         Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                         "' not yet fully implemented.");
               elsif param(1)  = 10 and param(2) = 0 and param(3) = 0
               then  -- set or query the foreground colour
                  if for_sequence(chr_pos) = '?'
                  then  -- query the foreground colour
                     -- The colour is held in on_buffer.text_colour
                     Write(fd => on_buffer.master_fd,
                              Buffer => Esc_str & "]10;" & 
                                -- Buffer => Esc_str & "[38;2;" & 
                                As_String(natural(on_buffer.text_colour.Red)) &
                                ";" & 
                                As_String(natural(on_buffer.text_colour.Green))
                                & ";" & 
                                As_String(natural(on_buffer.text_colour.Blue))&
                                Bel_str);
                                -- "m");
                  else  -- set the foreground colour
                     Log_Data(at_level => 9, 
                              with_details=>"Process_Escape " & 
                                            "(foregound colour): Escape '"&
                                            Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                            "' not yet implemented.");
                  end if;
               elsif param(1)  = 11 and param(2) = 0 and param(3) = 0
               then  -- set or query the background colour
                  if for_sequence(chr_pos) = '?'
                  then  -- query the background colour
                     -- The colour is held in on_buffer.background_colour
                     Write(fd => on_buffer.master_fd,
                              Buffer => Esc_str & "]11;" & 
                                -- Buffer => Esc_str & "[48;2;" & 
                                As_String(natural(on_buffer.background_colour.Red)) &
                                ";" & 
                                As_String(natural(on_buffer.background_colour.Green))
                                & ";" & 
                                As_String(natural(on_buffer.background_colour.Blue))&
                                Bel_str);
                                -- "m");
                  else  -- set the background colour
                     Log_Data(at_level => 9, 
                              with_details=>"Process_Escape " & 
                                            "(backgound colour): Escape '"&
                                            Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                            "' not yet implemented.");
                  end if;
               elsif for_sequence(chr_pos) = 'P'
               then  -- change the Linux Console's palette
                  -- palette is of the form 'RRGGBB'
                  null;
                  Log_Data(at_level => 9, 
                           with_details=> "Process_Escape (palette): Escape '"&
                                          Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                          "' not yet implemented.");
               end if;
            when '^' => null;  -- Privacy Message
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when '_' => null;  -- Application Program Command
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when '#' => null;  -- Test
               -- If for_sequence(chr_pos) = '8' then -- DEC screen alignment test.
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when '%' => null;  -- UTF8  !!!!!!!! CHECK THIS  !!!!!!!!!!!  NOT YET CATERED FOR
               Log_Data(at_level => 9, 
                        with_details=> "Process_Escape : Escape '" &
                                       Ada.Characters.Conversions.
                                                 To_Wide_String(for_sequence) &
                                       "' not yet implemented.");
            when '=' =>   -- DECPAM -- Application keypad
               -- Keypad keys will emit their Application Mode sequences.
               -- This means the virtual terminal client gets control sequences
               on_buffer.keypad_keys_in_app_mode := true;
            when '>' =>   -- DECPNM -- Normal keypad
               -- Keypad keys will emit their Numeric Mode sequences.
               -- This means the virtual terminal client gets normal numbers.
               on_buffer.keypad_keys_in_app_mode := false;
            when others =>   -- unrecognised control sequence - log and ignore
               Handle_The_Error(the_error => 7, 
                          error_intro=> "Process_Escape: Control string error",
                            error_message => "Unrecognised control sequence " &
                                              "for '" & 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                              "'.");
         end case;  -- control sequence type
      end if;
   end Process_Escape;
   tab_stop: Tab_range := Tab_length;
   start_iter : Gtk.Text_Iter.Gtk_Text_Iter;
   end_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
   cursor_mark: Gtk.Text_Mark.Gtk_Text_Mark;
   ist        : constant integer := the_input'First;
   res        : boolean;
   the_buf : Gtk.Text_Buffer.Gtk_Text_Buffer;
begin  -- Process
   for_buffer.in_response := true;
   if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
      the_buf := for_buffer.alt_buffer;
   else  -- using the main buffer for display
      the_buf := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
   end if;
   Get_End_Iter(the_buf, end_iter);
   Error_Log.Debug_Data(at_level => 9, with_details => "Process : '" & Ada.Characters.Conversions.To_Wide_String(the_input) & ''');
   for_buffer.cmd_prompt_check.Check(the_character => the_input(ist));
   if for_buffer.escape_sequence(escape_str_range'First) = Esc_str(1) and then
      the_input /= LF_str
   then
      -- add in and process the escape sequence
      for_buffer.escape_sequence(for_buffer.escape_position) := the_input(ist);
      if Is_In(element => the_input(ist), set => Osc_Term) or else
         (the_input(ist)='\' and 
          for_buffer.escape_sequence(for_buffer.escape_position-1)=Esc_str(1))
          or else
         (for_buffer.escape_sequence(escape_str_range'First+1) /= ']' and then
          (Is_In(element => the_input(ist), set => Esc_Term) and not
           ((the_input(ist) = '>' and 
             for_buffer.escape_sequence(1..for_buffer.escape_position) = Esc_str & "[>")
            or -- also not <Esc>P, which must be terminated by <Esc>\ or ST
            (the_input(ist) = 'P' and 
             for_buffer.escape_sequence(for_buffer.escape_position-1)=Esc_str(1)))))
      then  -- escape sequence is complete - process it
         Error_Log.Debug_Data(at_level => 9, with_details => "Process : Escape sequence finished with '" & Ada.Characters.Conversions.To_Wide_String(for_buffer.escape_sequence(1..for_buffer.escape_position)) & "'; Set_Overwrite(for_buffer.parent) to true");
         -- Make sure that terminal is in overwrite mode as the escape sequence
         -- is from the system's virtual terminal and it assumes that it is
         -- always in some form of overwrite mode
         Set_Overwrite(for_buffer.parent, true);
         Switch_The_Light(for_buffer, 5, false);
         -- process it
         Process_Escape(for_sequence => 
                     for_buffer.escape_sequence(1..for_buffer.escape_position),
                        on_buffer => for_buffer);
         -- reset the buffer and pointer
         for_buffer.escape_sequence := (escape_str_range => ' ');
         for_buffer.escape_position := escape_str_range'First;
         -- reset the flag that says we are in an escape sequence to 'off'
         for_buffer.in_esc_sequence := false;
         Switch_The_Light(for_buffer, 7, false);
         -- And reset the terminal back to being in 'Insert' mode
         if (not for_buffer.history_review) and 
            (not for_buffer.alternative_screen_buffer)
         then  -- but only if not searching through history
            Set_Overwrite(for_buffer.parent, false);
            Switch_The_Light(for_buffer, 5, true);
         end if;
      elsif for_buffer.escape_position < escape_length 
      then --else  -- escape sequence is incomplete - keep capturing it
         for_buffer.escape_position := for_buffer.escape_position + 1;
      else  -- faulty escape sequence
         -- Output that faulty escape sequence to the terminal
         Insert_At_Cursor(for_buffer, the_text=>for_buffer.escape_sequence);
         Insert_At_Cursor(for_buffer, the_text=>the_input);
         -- Reset the escape sequence (i.e. clear it)
         for_buffer.escape_sequence := (escape_str_range => ' ');
         for_buffer.escape_position := escape_str_range'First;
         -- Switch overwrite off if not searching history
         if (not for_buffer.history_review) and
            (not for_buffer.alternative_screen_buffer) then
            Set_Overwrite(for_buffer.parent, false);
            Switch_The_Light(for_buffer, 5, true);
         end if;
         -- And note we are exiting the escape sequence
         for_buffer.in_esc_sequence := false;
         Switch_The_Light(for_buffer, 7, false);
      end if;
   elsif the_input = Esc_str then
      -- Starting a new escape string sequence
      -- (which don't do if in bracketed paste mode and then have received the
      --  bracket sequence, although still need to work out if we switch off
      --  that mode, so capture, then maybe just pass through)
      for_buffer.escape_position := escape_str_range'First;
      for_buffer.escape_sequence(for_buffer.escape_position) := Esc_str(1);
      for_buffer.escape_position := for_buffer.escape_position + 1;
      -- Switch the flag to say that we are now in an escape sequence
      for_buffer.in_esc_sequence := true;
      Switch_The_Light(for_buffer, 7, true);
      -- Once escape sequence is initiated, need to be in overwrite mode
      Set_Overwrite(for_buffer.parent, true);
      Switch_The_Light(for_buffer, 5, false);
   elsif the_input = CR_str then
      Get_Iter_At_Mark(the_buf, start_iter, Get_Insert(the_buf));
      Get_Iter_At_Line_Offset(the_buf, start_iter, Get_Line(start_iter), 0);
      -- It appears that Linux may require a line feed operation also be done
      Get_Iter_At_Line_Offset(the_buf, end_iter, Get_Line(end_iter), 0);
      if not Equal(start_iter, end_iter) and
         not for_buffer.alternative_screen_buffer
      then  -- not at last line already
         Error_Log.Debug_Data(at_level => 9, with_details => "Process : CR - cursor going forward one line");
         Forward_Line(start_iter, res);
      end if;
      Place_Cursor(the_buf, where => start_iter);
   elsif the_input = LF_str then
      if not for_buffer.just_wrapped
      then  -- do a new line
         if for_buffer.alternative_screen_buffer
         then  -- in Alternative buffer, do  the LF at the end of current line
            if for_buffer.scroll_region_bottom = 0 or else
               (for_buffer.scroll_region_bottom > 0 and then
                natural(Get_Line_Count(for_buffer)) <
                                            (for_buffer.scroll_region_bottom - 
                                             for_buffer.scroll_region_top + 1))
            then  -- but only if within range of the screen
               Get_Iter_At_Mark(the_buf, end_iter, Get_Insert(the_buf));
               if not Ends_Line(end_iter)
               then -- (don't want to go to next line)
                  Forward_To_Line_End(end_iter, res);
               end if;
               res := true;
            else 
               res := false;
            end if;
         else  -- otherwise as we only place cursor at the line end if not in
            res := true;  --  alternative buffer, do nothing here
         end if;
         if res  then  -- only do if allowed
            Place_Cursor(the_buf, where => end_iter);
            Insert(for_buffer, at_iter=>end_iter, the_text=>the_input);
         end if;
         for_buffer.line_number := line_numbers(Get_Line_Count(for_buffer));
         for_buffer.buf_line_num := line_numbers(Get_Line_Count(the_buf));
         Switch_The_Light(for_buffer, 8, false, for_buffer.line_number'Image);
         Switch_The_Light(for_buffer, 9, false, for_buffer.buf_line_num'Image);
      else  -- Just wrapped, so ignore this LF and reset just_wrapped
         for_buffer.just_wrapped := false;
      end if;
   elsif the_input = FF_str then
      null;
   elsif the_input = Bel_str then
      null;
   elsif the_input = Tab_str then
       -- work out the tab stop point
      cursor_mark := Get_Insert(the_buf);   
      Get_Iter_At_Mark(the_buf, end_iter, cursor_mark);
         -- here, end_iter is where the cursor is
      -- Get_Start_Iter(for_buffer, start_iter);
      Get_Iter_At_Line(the_buf,start_iter,Glib.Gint(for_buffer.buf_line_num-1));
      tab_stop := Tab_length - 
                   (UTF8_Length(Get_Text(the_buf, start_iter, end_iter)) rem
                                                               Tab_length);
      Ada.Wide_Text_IO.Put_Line("Process : Tab - line length =" & Natural'Wide_Image(UTF8_Length(Get_Text(for_buffer, start_iter, end_iter))) & ", tab stop =" & Natural'Wide_Image(tab_stop) & ".");
       -- insert the tab stop by inserting spaces
      Insert_At_Cursor(for_buffer, the_text=>Tab_chr(1..tab_stop));
   elsif the_input = BS_str then
      -- Move the cursor back one character (without deleting the character)
      -- We use the Process_Escape procedure as that works (but doing it here
      -- doesn't for some very strange reason).
      Process_Escape(for_sequence => esc_str & "[D", on_buffer => for_buffer);
   else  -- An ordinary character
      if for_buffer.markup_text = Null_Ptr
      then  -- not in some kind of mark-up so just add the text
         -- First, if in overwrite, then if the_input is > 1 characters (i.e.
         -- it is a multi-byte UTF-8), then insert those characters
         if Get_Overwrite(for_buffer.parent) and then
            the_input'Length > 1
         then  -- this is the case
            Gtk.Text_Buffer.Insert_At_Cursor(the_buf, 
                                             text=>((the_input'Length-1)*' '));
            -- Get the current cursor position
            Get_Iter_At_Mark(the_buf,start_iter,Get_Insert(the_buf));
            -- Move the cursor back to the starting point
            Backward_Chars(start_iter, Glib.Gint(the_input'Length-1), res);
            Place_Cursor(the_buf, where => start_iter);
         end if;
         -- Now Insert/Overwrite the_input into the buffer
         Insert_At_Cursor(for_buffer, the_text=>the_input);
      else  -- in some kind of mark-up - append it to the mark-up string
         Insert_At_Cursor(for_buffer, the_text=>the_input);
         -- Append_To_Markup(for_buffer, the_text => the_input);
      end if;
      for_buffer.just_wrapped := false;
      null;
   end if;
   -- If we are not in an app and the output is not a consequence of
   -- being at a command prompt and we are navigating through Bash history,
   -- then adjust the editing of the displayed text and adjust the anchor
   -- point.  If we are in an app, we still want to know the anchor point.
     -- So, set anchor_point
   Get_Iter_At_Mark(the_buf, end_iter, Get_Insert(the_buf));
   Get_Iter_At_Line(the_buf, start_iter,
                       Glib.Gint(for_buffer.buf_line_num-1));
   for_buffer.anchor_point:=
            UTF8_Length(Get_Line_From_Start(for_buffer, up_to_iter=>end_iter));  -- UTF8_Length(Get_Text(the_buf,start_iter,end_iter));
   Switch_The_Light(for_buffer, 10, false, for_buffer.anchor_point'Image);
   Error_Log.Debug_Data(at_level => 9, with_details => "Process : NOT for_buffer.history_review. for_buffer.anchor_point =" & for_buffer.anchor_point'Wide_Image & ".");
   if for_buffer.alternative_screen_buffer and
      then  -- am in the alternative screen bufer
           for_buffer.cmd_prompt_check.Is_Looking
   then  -- shouldn't be looking
      for_buffer.cmd_prompt_check.Stop_Looking;
   end if;
   -- Check for history_text end point
   if for_buffer.cmd_prompt_check.Is_Looking and then
      for_buffer.cmd_prompt_check.Found_Prompt_End
   then  -- at command prompt end (and not in alternative buffer)
      Error_Log.Debug_Data(at_level => 9, with_details => "Process : for_buffer.cmd_prompt_check.Is_Looking AND for_buffer.cmd_prompt_check.Found_Prompt_End. for_buffer.anchor_point =" & for_buffer.anchor_point'Wide_Image & ".");
      declare
         unedit_mark : Gtk.Text_Mark.Gtk_Text_Mark;  -- End of uneditable zone
         unedit_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      begin
         -- First, make certain that not in mark-up mode
         if for_buffer.in_markup then
            Finish_Markup(for_buffer);
         end if;
         -- Work out the history span and set it
         Get_Start_Iter(for_buffer, start_iter);
         Get_Iter_At_Mark(for_buffer, end_iter, Get_Insert(for_buffer));
         Apply_Tag_By_Name(for_buffer, "history_text", start_iter, end_iter);
         -- and note where un-edit stops
         unedit_mark := Get_Mark(for_buffer, "end_unedit");
         Move_Mark(for_buffer, unedit_mark, end_iter);
         -- then set flags accordingly
         for_buffer.entering_command := true;  -- this is now the case
         Switch_The_Light(for_buffer, 6, true);
         for_buffer.in_esc_sequence := false;
         Switch_The_Light(for_buffer, 7, false);
         for_buffer.cmd_prompt_check.Stop_Looking;
      end;
   end if;
   -- Scroll if required to make it visible
   if for_buffer.cursor_is_visible and not for_buffer.in_esc_sequence then
      Scroll_Mark_Onscreen(for_buffer.parent, Get_Insert(the_buf));
   end if;
   -- Check if we didn't get told to exit
   Get_Iter_At_Mark(for_buffer, start_iter,
                    Get_Mark(for_buffer, "end_paste"));
   if (not for_buffer.bracketed_paste_mode) and then
      Get_Text(for_buffer, start_iter, end_iter) = "exit" & LF_str and then
      Get_Environment(New_String("SHLVL")) /= Null_Ptr and then
      Value(Get_Environment(New_String("SHLVL"))) = "1"
   then  -- got an exit command?
      Gtk_Terminal(Get_Parent(for_buffer.parent)).closed_callback(
                                  Gtk_Terminal(Get_Parent(for_buffer.parent)));
   elsif not for_buffer.bracketed_paste_mode then
      null;  -- Error_Log.Debug_Data(at_level => 9, with_details => "Process : line ='" & Ada.Characters.Conversions.To_Wide_String(Get_Text(for_buffer, start_iter, end_iter)) & "'");
   end if;
   -- Set_Cursor_Visible(for_buffer.parent, true);
   Reset_Cursor_Blink(for_buffer.parent);
   for_buffer.in_response := false;
end Process;
