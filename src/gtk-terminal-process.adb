separate (Gtk.Terminal)
   procedure Process(the_input : in UTF8_String; for_buffer : Gtk_Terminal_Buffer) is
   use Gtk.Text_Iter, Gtk.Text_Mark;
   use Ada.Strings.Maps;
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
   Esc_Rng : constant Character_Ranges := (('@','H'),('J','K'),('N','P'),
                                           ('S','T'),('f','f'),('h','i'),
                                           ('l','n'),('s','u'));
   Esc_Term: constant Character_Set := To_Set(Esc_Rng);
   Osc_Rng : constant Character_Ranges := ((Bel_str(1),Bel_str(1)),
                                           (st_chr,st_chr));
   Osc_Term: constant Character_Set := To_Set(Osc_Rng);
   procedure Append_To_Markup(for_buffer : Gtk_Terminal_Buffer;
                              the_text : UTF8_String; 
                              or_rgb_colour: Gdk.RGBA.Gdk_RGBA:=null_rgba) is
      -- If the markup string is empty, initiate it, otherwise just append the
      -- supplied text.
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
            zero : constant character := '0';
            radix : constant integer := 16#10#;
            number_string : Hex_String;
            unit : natural;
            strip_number : natural;
            char_pos : Hex_Size := 1;
         begin
            number_string := "00";
            if item /= 0
            then
               strip_number := item;
               -- place numbers on the right hand side of the decimal 
               -- point into the temporary string, number_string 
               -- (NB: actually no decimal point)
               while strip_number > 0 loop
                  unit := (strip_number - (strip_number / radix) * radix) +
                                           character'Pos(zero);
                  strip_number := strip_number / radix;
                  number_string(char_pos) := character'Val(unit);
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
      temp_markup : Gtkada.Types.Chars_Ptr;
      mkTxt : Gtkada.Types.Chars_Ptr renames for_buffer.markup_text;
   begin  -- Append_To_Markup
      if the_text'Length > 4
      then  -- starting setting up the mark-up text - input must be <span xxx>
         if for_buffer.markup_text /= Null_Ptr
         then  -- check for '<span' already being there
            if Ada.Strings.Fixed.Count(Value(for_buffer.markup_text),"<span")=0
            then  -- not yet, add it in
               temp_markup:= New_String(Value(for_buffer.markup_text) & 
                                        "<span " & the_text &
                                        To_RGB_String(or_rgb_colour) & " >");
            else  -- it's there, delete the '>', add the_text + cap with ' >'
               temp_markup:= 
                  New_String(Value(mkTxt)(Value(mkTxt)'First..Value(mkTxt)'Last-1)&
                             the_text & To_RGB_String(or_rgb_colour) & " >");
            end if;
            Free(for_buffer.markup_text);
            for_buffer.markup_text := temp_markup;
         else
            Free(for_buffer.markup_text);
            for_buffer.markup_text := New_String("<span " & the_text & 
                                                 To_RGB_String(or_rgb_colour) &
                                                 " >");
         end if;
      else -- this is not setting up mark-up text for a span, just append
         if for_buffer.markup_text /= Null_Ptr
         then
            temp_markup:= New_String(Value(for_buffer.markup_text) & the_text);
            Free(for_buffer.markup_text);
            for_buffer.markup_text := temp_markup;
         else
            Free(for_buffer.markup_text);
            for_buffer.markup_text := New_String(the_text);
         end if;
      end if;
   end Append_To_Markup;
   procedure Finish_Markup(for_buffer: Gtk_Terminal_Buffer) is
      -- Close off the mark-up string, then write it out to the buffer, and
      -- finally reset the mark-up string to empty.
      function Mod_Terminators(for_mods: font_modifier_array; at_pos: font_modifiers)
      return UTF8_String is
         function The_Mod(for_pos : in font_modifiers) return UTF8_String is
         begin
            if for_mods(for_pos) > 0
            then
               case at_pos is
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
                  when span            => 
                     return "</span>";
                  -- when reversevideo    =>
                     -- return "";
               end case;
            else
               return "";
            end if;
         end The_Mod;
      begin
         if at_pos = font_modifiers'Last 
         then
            return The_Mod(at_pos);
         else
            if for_mods(at_pos) < for_mods(font_modifiers'Succ(at_pos))
            then
               return The_Mod(at_pos) & 
                       Mod_Terminators(for_mods, font_modifiers'Succ(at_pos));
            else
               return Mod_Terminators(for_mods, font_modifiers'Succ(at_pos)) &
                      The_Mod(at_pos);
            end if;
         end if;
      end Mod_Terminators;
      cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
   begin  -- Finish_Markup
      if for_buffer.markup_text /= Null_Ptr
      then  -- something to do with mark-up
         Get_Iter_At_Mark(for_buffer,cursor_iter,Get_Mark(for_buffer,"insert"));
         -- First, terminate the string and write it out
         Insert_Markup(for_buffer, cursor_iter, 
                       Value(for_buffer.markup_text) & 
                       Mod_Terminators(for_buffer.modifier_array, 
                                       font_modifiers'First), -1);
         -- Second, clear out the temporary text and reset it to null;
         Free(for_buffer.markup_text);
         for_buffer.markup_text := Null_Ptr;
         -- Third, clear the modifier array
         for modifier in font_modifiers loop
            for_buffer.modifier_array(modifier) := 0;
         end loop;
      end if;
   end Finish_Markup;
   procedure Max(modifier_array : in out font_modifier_array; 
                for_modifier : in font_modifiers) is
      max_modifier : natural := 0;
   begin
      if for_modifier = span and modifier_array(span) > 0
      then  -- already done it
         null;  -- do nothing
      else
         for modifier in font_modifiers loop
            if modifier_array(modifier) > max_modifier
            then
               max_modifier := modifier_array(modifier);
            end if;
         end loop;
         modifier_array(for_modifier) := max_modifier + 1;
      end if;
   end Max;
   procedure Process_Escape(for_sequence : in UTF8_String;
                            on_buffer  :Gtk_Terminal_Buffer) is
     -- Information sourced from https://en.wikipedia.org/wiki/ANSI_escape_code
     -- (as at 10 April 2024) and from st.c
      use Gtk.Enums, Gdk.Color, Gdk.RGBA;
      function "*" (mult : integer; val : character) return string is
         result : string(1..mult) := (others => val);
      begin
         return result;
      end "*";
      ist : constant integer := for_sequence'First;
      num_params : constant natural := 5;
      type params is array(1..num_params) of natural;
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
      if for_sequence'Length<=2
      then  -- this cannot be a valid control sequence
         Handle_The_Error(the_error => 1, 
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
         Get_Iter_At_Mark(on_buffer, cursor_iter, Get_Insert(on_buffer));
         Insert(on_buffer, at_iter=>cursor_iter, the_text=> for_sequence);
      else  -- for_sequence(ist)=Esc_str and rest is control sequence
         if for_sequence(ist+1) = '[' or for_sequence(ist+1) = ']'
         then  -- extract the number(s), if any
            chr_pos := ist + 2;
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
               chr_pos := chr_pos + 1;  -- get past the ';'
            end loop;
         end if;
         case for_sequence(ist+1) is
            when '[' =>  -- it is a Control Sequence Introducer (CSI) sequence
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI sequence - there are" & pnum'Wide_Image & " parameters, being " & param(1)'Wide_Image & "," & param(2)'Wide_Image & "," & param(3)'Wide_Image & " and next sequence is '" & Ada.Characters.Conversions.To_Wide_String(for_sequence(chr_pos..chr_pos)) & "'.");
               case for_sequence(chr_pos) is
                  when '@' =>   -- Insert (param) space chars ahead of cursor
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     -- Insert the spaces, leaving the cursor where it is
                     Gtk.Text_Buffer.Insert_At_Cursor(Gtk_Text_Buffer(on_buffer), 
                                                      text => (param(1)*' '));
                     -- Get the current cursor position
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     -- Move the cursor back to the starting point
                     Backward_Chars(cursor_iter, Glib.Gint(param(1)), res);
                     Place_Cursor(on_buffer, where => cursor_iter);
                  when '~' =>  -- Non-standard, but used for going to end (VT)
                     case param(1) is
                        when 4 => -- VT sequence for End [non-standard]
                           Get_Iter_At_Mark(on_buffer, cursor_iter,
                                            Get_Insert(on_buffer));
                           Forward_To_Line_End(cursor_iter, res);
                           Place_Cursor(on_buffer, where => cursor_iter);
                        when 200 => -- may not treat characters as command?
                           if on_buffer.bracketed_paste_mode
                           then  -- sequence following not commands
                              on_buffer.pass_through_characters := true;
                              Switch_The_Light(on_buffer, 4, true);
                           end if;
                        when 201 => -- may not treat characters as command?
                           if on_buffer.bracketed_paste_mode
                           then  -- start reinterpreting sequences as commands
                              on_buffer.pass_through_characters := false;
                              Switch_The_Light(on_buffer, 4, false);
                           end if;
                        when others => -- not yet implemented
                           Handle_The_Error(the_error => 2, 
                                      error_intro=> "Process_Escape: " & 
                                                    "Control string error",
                                      error_message=>"Unrecognised VT non-" &
                                                     "standard sequence for '"& 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                                     "'.");
                     end case;
                  when 'A' =>   -- Cursor Up (param spaces)
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(for_buffer));
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
                           Place_Cursor(on_buffer, where => cursor_iter);
                        end if;
                     end loop;
                  when 'B' | 'e' =>   -- Cursor Down (param spaces)
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
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
                           Place_Cursor(on_buffer, where => cursor_iter);
                        end if;
                     end loop;
                  when 'C' | 'a' =>   -- Cursor Forward (param spaces)
                     -- Move  the cursor forwards (without deleting characters)
                     -- First, get the cursor location
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     -- Then move forward one or more characters
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : [" & param(1)'Wide_Image & "C - Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", going forward by" & param(1)'Wide_Image & " characters.  Line Length =" & Get_Chars_In_Line(cursor_iter)'Wide_Image & ", current column =" & UTF8_Length(Get_Line_From_Start(on_buffer, cursor_iter))'Wide_Image & ".");
                     res := true;  -- Initial value
                     for col in 1 .. param(1) loop
                        Get_End_Iter(on_buffer, dest_iter);
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
                     Place_Cursor(on_buffer, where => cursor_iter);
                  when 'D' =>   -- Cursor Back (param spaces)
                     -- Move  the cursor backwards (without deleting characters)
                     -- First, get the cursor location
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     -- Then move back one or more characters
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Old cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", going backward by" & param(1)'Wide_Image & " characters.  Line Length =" & Get_Chars_In_Line(cursor_iter)'Wide_Image & ", current column =" & UTF8_Length(Get_Line_From_Start(on_buffer, cursor_iter))'Wide_Image & ".");
                     Backward_Chars(cursor_iter, Glib.Gint(param(1)), res);
                     if res then
                        Place_Cursor(on_buffer, where => cursor_iter);
                     end if;
                  when 'E' =>   -- Cursor Next Line start (param num of lines)
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
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
                     Place_Cursor(on_buffer, where => cursor_iter);
                  when 'F' =>   -- Cursor Previous Line start (1/param spaces)
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     Backward_Line(cursor_iter, res);  -- go to last line start
                      -- go to desired line
                     if param(1) > 1
                     then
                        Backward_Lines(cursor_iter, Glib.Gint(param(1)), res);
                     end if;
                     Place_Cursor(on_buffer, where => cursor_iter);
                  when 'G' | '`' =>   -- Move cursor to column <param>
                     Backward_Line(cursor_iter, res);  -- go to last line start
                     if res then  -- did go back
                        Forward_Line(cursor_iter, res); -- return to current line
                     end if;
                     if param(1) > 1
                     then
                        Forward_Chars(cursor_iter, Glib.Gint(param(1)-1), res);
                     end if;
                     Place_Cursor(on_buffer, where => cursor_iter);
                  when 'H' | 'f' =>   -- Move cursor to row <param>, column <param>
                     -- find top left corner
                     Window_To_Buffer_Coords(on_buffer.parent, 
                                                Gtk.Enums.Text_Window_Text, 
                                                0, 0, buf_x, buf_y);
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - top LH corner = (" & buf_x'Wide_Image & "," & buf_y'Wide_Image & ").");
                     res:= Get_Iter_At_Position(on_buffer.parent,
                                                cursor_iter'access, null, 
                                                buf_x, buf_y);
                     -- move to offset from top left corner
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'H' - moving to (row,col) position (" & param(1)'Wide_Image & "," & param(2)'Wide_Image & ").");
                     if param(2) > 1 then
                        Forward_Lines(cursor_iter, Gint(param(2)-1), res);
                     end if;
                     if param(1) > 1 then
                        for col in 1 .. param(1)-1 loop
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
                     -- Now make this the cursor location
                     Place_Cursor(on_buffer, where => cursor_iter);
                  when 'J' =>   -- Erase in Display <param> type of erase
                     Window_To_Buffer_Coords(on_buffer.parent, 
                                             Gtk.Enums.Text_Window_Text, 
                                             0, 0, buf_x, buf_y);
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'J' - top LH corner = (" & buf_x'Wide_Image & "," & buf_y'Wide_Image & ").");
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     case param(1) is
                        when 0 =>   -- Clear from cursor to end of screen
                           Get_End_Iter(on_buffer, dest_iter);
                           Delete(on_buffer, cursor_iter, dest_iter);
                        when 1 =>   -- Clear from TLH corner to cursor
                           res:= Get_Iter_At_Position(on_buffer.parent,
                                                      dest_iter'access, null,
                                                      buf_x, buf_y);
                           Delete(on_buffer, dest_iter, cursor_iter);
                        when 2 =>   -- Clear the screen
                           res:= Get_Iter_At_Position(on_buffer.parent,
                                                      dest_iter'access, null,
                                                      buf_x, buf_y);
                           Get_End_Iter(on_buffer, cursor_iter);
                           Delete(on_buffer, dest_iter, cursor_iter);
                           -- Now scroll the cursor to the top
                           Get_Iter_At_Mark(on_buffer, cursor_iter,
                                            Get_Insert(on_buffer));
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 'J' - cursor pos =" & Get_Line(cursor_iter)'Wide_Image & ", Scrolling to ensure the screen is clear.");
                            -- Put the cursor position at the top of the screen
                           declare  -- NO METHOD SEEMS TO WORK IF SCREEN NOT COMPLETELY CLEAR
                              use Gtk.Text_Mark;
                              end_mark : Gtk.Text_Mark.Gtk_Text_Mark;
                           begin
                              Set_Line_Offset(cursor_iter, 0);  -- move to start of line
                              -- res := Scroll_To_Iter(on_buffer.parent, cursor_iter, 0.0, true, 0.0, 0.0);
                              Gtk.Text_Mark.Gtk_New(end_mark, "End", false);
                              Add_Mark(on_buffer, end_mark, cursor_iter);
                              Scroll_To_Mark(on_buffer.parent, end_mark, 0.0, true, 0.0, 0.0);
                              Delete_Mark(on_buffer, end_mark);
                           end;
                        when 3 =>   -- Clear the entire buffer
                           Get_Start_Iter(on_buffer, dest_iter);
                           Get_End_Iter(on_buffer, cursor_iter);
                           Delete(on_buffer, dest_iter, cursor_iter);
                        when others => null; -- invalid erase type, just ignore
                     end case;
                  when 'K' =>   -- Erase in Line <param> type of erase
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     -- use a large offset to point to the end of this line
                     Get_Iter_At_Line_Offset(on_buffer, dest_iter,
                                             Get_Line(cursor_iter), 20000);
                     case param(1) is
                        when 0 =>   -- Clear from cursor to end of line
                           Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI 0 'K' - cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", Deleting '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(on_buffer, cursor_iter, dest_iter)) & "'.");
                           Delete(on_buffer, cursor_iter, dest_iter);
                        when 1 =>   -- Clear from cursor to beginning of line
                           Get_Iter_At_Line_Offset(on_buffer, dest_iter,
                                                   Get_Line(cursor_iter), 0);
                           Delete(on_buffer, dest_iter, cursor_iter);
                        when 2 =>   -- Clear the entire line
                           Get_Iter_At_Line_Offset(on_buffer, cursor_iter,
                                                   Get_Line(cursor_iter), 0);
                           Delete(on_buffer, cursor_iter, dest_iter);
                        when others => null; -- invalid clear type, just ignore
                     end case;
                  when 'P' => null;  --DCH -- Delete <param> characters
                     if param(1) = 0
                      then
                        param(1) := 1;
                     end if;
                     -- get the start point to delete from
                     Get_Iter_At_Mark(on_buffer, cursor_iter,
                                      Get_Insert(on_buffer));
                     -- Get the end point to delete to (param(1) characters)
                     Get_Iter_At_Mark(on_buffer, dest_iter,
                                      Get_Insert(on_buffer));
                     -- dest_iter -> just past the last char to delete
                     Forward_Chars(dest_iter, Glib.Gint(param(1)), res);
                     -- N.B. res=false if dest_iter is at end iterator
                     -- Delete requested number of characters
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI " & param(1)'Wide_Image & " 'P' - cursor line number in buffer =" & Get_Line(cursor_iter)'Wide_Image & ", Deleting '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(on_buffer, cursor_iter, dest_iter)) & "'.");
                     Delete(on_buffer, cursor_iter, dest_iter);
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
                  when 'Z' => null; -- CBT Cursor Backward Tabulation <n> tab stops */
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
                  when '?' => -- private sequences
                     if param(1) = 0 then
                        -- extract the number, if any
                        chr_pos := ist + 3;
                        while for_sequence'Length > chr_pos + ist - 1 and then
                        for_sequence(chr_pos) in '0'..'9' loop
                           param(1) := param(1) * 10 + 
                                       Character'Pos(for_sequence(chr_pos)) -
                                       Character'Pos('0');
                           chr_pos := chr_pos + 1;
                        end loop;
                        case param(1) is
                           when 1 => null;  -- ???
                              Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
                           when 25 =>   -- show/hide cursor
                              if for_sequence(chr_pos) = 'h'
                              then
                                 on_buffer.cursor_is_visible := true;
                              elsif for_sequence(chr_pos) = 'l'
                              then
                                 on_buffer.cursor_is_visible := false;
                              end if;
                           when 1004 =>  -- reporting focus enable/disable
                              Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?1004' - Setting on_buffer.reporting_focus_enabled.");
                              if for_sequence(chr_pos) = 'h'
                              then
                                 on_buffer.reporting_focus_enabled := true;
                              elsif for_sequence(chr_pos) = 'l'
                              then
                                 on_buffer.reporting_focus_enabled := false;
                              end if;
                           when 1049 =>  -- alternative screen buffer
                              declare
                                 the_term : Gtk_Terminal := 
                                    Gtk_Terminal(Get_Parent(on_buffer.parent));
                              begin
                                 Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?1049' - Switching between main and alternative screen buffer.");
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
                                 elsif for_sequence(chr_pos) = 'l'
                                 then  -- switch back to the regular buffer
                                    -- Set the flags to indicate which buffer
                                    on_buffer.alternative_screen_buffer:=false;
                                     -- Switch to the main regular buffer
                                    Gtk.Text_View.Set_Buffer
                                               (view  => the_term.terminal,
                                                buffer=> on_buffer);
                                    Switch_The_Light(on_buffer, 1, true);
                                 end if;
                              end;
                           when 2004 =>  -- bracketed paste mode, text pasted in
                              Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : CSI '?2004' - Setting on_buffer.bracketed_paste_mode.");
                              if for_sequence(chr_pos) = 'h'
                              then  -- switch on echo if config allows
                                 on_buffer.bracketed_paste_mode := true;
                                 Switch_The_Light(on_buffer, 3, true);
                              elsif for_sequence(chr_pos) = 'l'
                              then  -- switch off keyboard echo + paste in
                                 on_buffer.bracketed_paste_mode := false;
                                 Get_End_Iter(on_buffer, cursor_iter);
                                 Move_Mark_By_Name(on_buffer, "end_paste", 
                                                   cursor_iter);
                                 Switch_The_Light(on_buffer, 3, false);
                              end if;
                           when others =>  -- not valid and not interpreted
                              Handle_The_Error(the_error => 4, 
                                      error_intro=> "Process_Escape: " & 
                                                    "Control string error",
                                      error_message => "Unrecognised private "&
                                                       "sequence for '" & 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                                       "'.");
                        end case;
                     end if;
                  when 'm' => -- set or reset font colouring and styles
                     while count <= pnum loop
                        case param(count) is
                           when 0 =>   -- reset to normal
                              Finish_Markup(on_buffer);
                           when 1 =>   -- bold
                              Append_To_Markup(on_buffer, "<b>");
                              Max(on_buffer.modifier_array, bold);
                           when 2 => null;  -- dim/faint
                           when 3 =>   -- italic
                              Append_To_Markup(on_buffer, "<i>");
                              Max(on_buffer.modifier_array, italic);
                           when 4 =>   -- underline
                              Append_To_Markup(on_buffer, "<u>");
                              Max(on_buffer.modifier_array, underline);
                           when 5 => null;  -- show blink
                           when 6 => null;  -- rapid blink
                           when 7 => null;  -- reverse video
                              Append_To_Markup(on_buffer, "foreground=", 
                                               on_buffer.background_colour);
                              Append_To_Markup(on_buffer, "background=", 
                                               on_buffer.text_colour);
                           when 8 =>   -- conceal or hide
                              -- by setting foreground to background colour
                              Append_To_Markup(on_buffer, "foreground=", 
                                               on_buffer.background_colour);
                           when 9 =>   -- crossed out or strike-through
                              Append_To_Markup(on_buffer, "<s>");
                              Max(on_buffer.modifier_array, strikethrough);
                           when 10 => null;  -- primary font
                           when 11 .. 19 => null; -- alternative font number n-10
                           when 20 => null; -- Fraktur (Gothic)
                           when 21 =>  -- Doubly underlined
                              Append_To_Markup(on_buffer, "underline=""double"" ");
                              Max(on_buffer.modifier_array, span);
                           when 22 => null; -- Normal intensity
                           when 23 => null; -- Neither italic, nor blackletter
                           when 24 =>  -- Not underlined
                              if on_buffer.modifier_array(underline) > 0 then
                                 Append_To_Markup(on_buffer, "</u>");
                                 on_buffer.modifier_array(underline) := 0;
                              end if;
                           when 25 => null; -- Not blinking
                           when 26 => null; -- Proportional spacing
                           when 27 => null; -- Not reversed
                           when 28 => null; -- Reveal
                           when 29 => null; -- Not crossed out
                              if on_buffer.modifier_array(strikethrough) > 0 then
                                 Append_To_Markup(on_buffer, "</s>");
                                 on_buffer.modifier_array(strikethrough) := 0;
                              end if;
                           when 30 =>  -- Set foreground colour to black
                              Append_To_Markup(on_buffer, "foreground=""black""");
                              Max(on_buffer.modifier_array, span);
                           when 31 =>  -- Set foreground colour to red
                              Append_To_Markup(on_buffer, "foreground=""red""");
                              Max(on_buffer.modifier_array, span);
                           when 32 =>  -- Set foreground colour to green
                              Append_To_Markup(on_buffer, "foreground=""green""");
                              Max(on_buffer.modifier_array, span);
                           when 33 =>  -- Set foreground colour to yellow
                              Append_To_Markup(on_buffer, "foreground=""yellow""");
                              Max(on_buffer.modifier_array, span);
                           when 34 =>  -- Set foreground colour to blue
                              Append_To_Markup(on_buffer, "foreground=""blue""");
                              Max(on_buffer.modifier_array, span);
                           when 35 =>  -- Set foreground colour to magenta
                              Append_To_Markup(on_buffer, "foreground=""magenta""");
                              Max(on_buffer.modifier_array, span);
                           when 36 =>  -- Set foreground colour to cyan
                              Append_To_Markup(on_buffer, "foreground=""cyan""");
                              Max(on_buffer.modifier_array, span);
                           when 37 =>  -- Set foreground colour to white
                              Append_To_Markup(on_buffer, "foreground=""white""");
                              Max(on_buffer.modifier_array, span);
                           when 38 =>  -- Set foreground colour to number
                              count := count + 1;
                              if param(count) = 5 then  -- colour chart colour
                                 count := count + 1;
                                 null;
                                 count := count + 1;
                              elsif param(count) = 2 then -- RGB
                                 count := count + 1;
                                 Append_To_Markup(on_buffer, "foreground=",
                                                  (GDouble(param(count))/255.0,
                                                   GDouble(param(count+1))/255.0,
                                                   GDouble(param(count+2))/255.0,
                                                   1.0));
                                 count := count + 2;
                                 Max(on_buffer.modifier_array, span);
                              end if;
                           when 39 =>  -- Default foreground colour
                              Append_To_Markup(on_buffer, "foreground=""white""");
                              Max(on_buffer.modifier_array, span);
                           when 40 =>  -- Set background colour to black
                              Append_To_Markup(on_buffer, "background=""black""");
                              Max(on_buffer.modifier_array, span);
                           when 41 =>  -- Set background colour to red
                              Append_To_Markup(on_buffer, "background=""red""");
                              Max(on_buffer.modifier_array, span);
                           when 42 =>  -- Set background colour to green
                              Append_To_Markup(on_buffer, "background=""green""");
                              Max(on_buffer.modifier_array, span);
                           when 43 =>  -- Set background colour to yellow
                              Append_To_Markup(on_buffer, "background=""yellow""");
                              Max(on_buffer.modifier_array, span);
                           when 44 =>  -- Set background colour to blue
                              Append_To_Markup(on_buffer, "background=""blue""");
                              Max(on_buffer.modifier_array, span);
                           when 45 =>  -- Set background colour to magenta
                              Append_To_Markup(on_buffer, "background=""magenta""");
                              Max(on_buffer.modifier_array, span);
                           when 46 =>  -- Set background colour to cyan
                              Append_To_Markup(on_buffer, "background=""cyan""");
                              Max(on_buffer.modifier_array, span);
                           when 47 =>  -- Set background colour to white
                              Append_To_Markup(on_buffer, "background=""white""");
                              Max(on_buffer.modifier_array, span);
                           when 48 =>  -- Set background colour to number
                              count := count + 1;
                              if param(count) = 5 then  -- colour chart colour
                                 null;
                              elsif param(count) = 2 then -- RGB
                                 count := count + 1;
                                 Append_To_Markup(on_buffer, "background=", 
                                                  (GDouble(param(count))/255.0,
                                                   GDouble(param(count+1))/255.0,
                                                   GDouble(param(count+2))/255.0,
                                                   1.0));
                                 count := count + 2;
                              end if;
                              Max(on_buffer.modifier_array, span);
                           when 49 =>  -- Default background colour
                              Append_To_Markup(on_buffer,"background=""black""");
                              Max(on_buffer.modifier_array, span);
                           when 50 => null; -- Disable proportional spacing
                           when others => null;  -- style or colour not recognised
                              Handle_The_Error(the_error => 6, 
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
                  when 'i' => null;  -- Serial port control (media copy)
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
                  when 'n' =>   -- Device status request
                     if param(1) = 5
                     then  -- Status Report "OK" '0n'
                        Write(fd => on_buffer.master_fd, Buffer => Esc_str & "[0n");
                     elsif param(1) = 6
                     then  -- Report Cursor Position (CPR) "<row>;<column>R"
                        Get_Iter_At_Mark(on_buffer, cursor_iter,
                                            Get_Insert(on_buffer));
                        Write(fd => on_buffer.master_fd, 
                              Buffer => Esc_str & "[" & 
                                        As_String(Get_Line_Number
                                           (for_terminal=> on_buffer.parent, 
                                            at_iter => cursor_iter)) & ";" & 
                                        As_String(UTF8_Length(
                                           Get_Line_From_Start
                                              (for_buffer => on_buffer, 
                                               up_to_iter => cursor_iter))) & 
                                        "R");
                     end if;
                  when 's' =>  -- Save cursor position
                     on_buffer.saved_cursor_pos:= Get_Mark(on_buffer,"insert");
                  when 't' => null;  -- ??? format is <Esc>[nn;0;0t (e.g. nn=22)
                     Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
                  when 'u' =>  -- Restore cursor position
                     Get_Iter_At_Mark(on_buffer, cursor_iter, 
                                      on_buffer.saved_cursor_pos);
                     Move_Mark_By_Name(on_buffer, "insert", cursor_iter);
                  when 'L' => null;  -- Insert (param) blank lines
                     if param(1) = 0
                     then
                        param(1) := 1;
                     end if;
                     Insert_At_Cursor(on_buffer, the_text=>(param(1) * 
                                                  Ada.Characters.Latin_1.LF));
                  when others => 
                     Handle_The_Error(the_error => 5, 
                                      error_intro=> "Process_Escape: " & 
                                                    "Control string error",
                                      error_message => "Unrecognised control " &
                                              "sequence for CSI sequence '" & 
                                              Ada.Characters.Conversions.
                                                  To_Wide_String(for_sequence)&
                                              "'.");
               end case;
            when 'N' => null;  -- Single Shift Two
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when 'O' => null;  -- Single Shift Three
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when 'P' => null;  -- Device Control String 
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '\' => null;  -- String Terminator (terminates other commands)
               -- Handled elsewhere
            when ']' =>   -- Operating System Command (seems terminate by ^G)
               chr_pos := ist + 2;
               if param(1) = 0 and param(2) = 0 
               then  -- Terminal title
                  chr_pos := chr_pos + 2;
                  Free(Gtk_Terminal(Get_Parent(on_buffer.parent)).title);
                  Gtk_Terminal(Get_Parent(on_buffer.parent)).title := 
                        New_String(for_sequence(chr_pos..for_sequence'Last-1));
                  Gtk_Terminal(Get_Parent(on_buffer.parent)).title_callback(
                                   Gtk_Terminal(Get_Parent(on_buffer.parent)),
                                   for_sequence(chr_pos..for_sequence'Last-1));
               elsif param(1) = 8 and param(2) =0 and param(3) = 0 
               then  -- hyperlink
                  null;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
               elsif for_sequence(chr_pos) = 'P'
               then  -- change the Linux Console's palette
                  -- palette is of the form 'RRGGBB'
                  null;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
               end if;
            when 'X' => null;  -- Start of String
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '^' => null;  -- Privacy Message
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '_' => null;  -- Application Program Command
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '#' => null;  -- Test
               -- If for_sequence(chr_pos) = '8' then -- DEC screen alignment test.
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '%' => null;  -- UTF8
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '=' => null;  -- DECPAM -- Application keypad
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when '>' => null;  -- DECPNM -- Normal keypad
               Error_Log.Debug_Data(at_level => 9, with_details => "Process_Escape : Escape '" & Ada.Characters.Conversions.To_Wide_String(for_sequence) & "' not yet implemented.");
            when others =>  null; -- unrecognised control sequence - log+ignore
               Handle_The_Error(the_error => 3, 
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
   Get_End_Iter(for_buffer, end_iter);
   Error_Log.Debug_Data(at_level => 9, with_details => "Process : '" & Ada.Characters.Conversions.To_Wide_String(the_input) & ''');
   if for_buffer.escape_sequence(escape_str_range'First) = Esc_str(1) then
      -- add in and process the escape sequence
      for_buffer.escape_sequence(for_buffer.escape_position) := the_input(ist);
      if Is_In(element => the_input(ist), set => Osc_Term) or else
         (the_input(ist)='\' and 
          for_buffer.escape_sequence(for_buffer.escape_position-1)=Esc_str(1))
          or else
         (for_buffer.escape_sequence(escape_str_range'First+1) /= ']' and then
          Is_In(element => the_input(ist), set => Esc_Term))
      then  -- escape sequence is complete - process it
         Error_Log.Debug_Data(at_level => 9, with_details => "Process : Escape sequence finished with '" & Ada.Characters.Conversions.To_Wide_String(for_buffer.escape_sequence(1..for_buffer.escape_position)) & "'; Set_Overwrite(for_buffer.parent) to true");
         -- Make sure that terminal is in overwrite mode as the escape sequence
         -- is from the system's virtual terminal and it assumes that it is
         -- always in some form of overwrite mode
         Set_Overwrite(for_buffer.parent, true);
         -- process it
         Process_Escape(for_sequence => 
                     for_buffer.escape_sequence(1..for_buffer.escape_position),
                        on_buffer => for_buffer);
         -- reset the buffer and pointer
         for_buffer.escape_sequence := (escape_str_range => ' ');
         for_buffer.escape_position := escape_str_range'First;
      elsif for_buffer.escape_position < escape_length 
      then --else  -- escape sequence is incomplete - keep capturing it
         for_buffer.escape_position := for_buffer.escape_position + 1;
      else  -- faulty escape sequence
         Insert_At_Cursor(for_buffer, the_text=>for_buffer.escape_sequence);
         Insert_At_Cursor(for_buffer, the_text=>the_input);
         for_buffer.escape_sequence := (escape_str_range => ' ');
         for_buffer.escape_position := escape_str_range'First;
      end if;
   elsif the_input = Esc_str then
      -- Starting a new escape string sequence
      -- (which don't do if in bracketed paste mode and then have received the
      --  bracket sequence, although still need to work out if we switch off
      --  that mode, so capture, then maybe just pass through)
      for_buffer.escape_position := escape_str_range'First;
      for_buffer.escape_sequence(for_buffer.escape_position) := Esc_str(1);
      for_buffer.escape_position := for_buffer.escape_position + 1;
      for_buffer.in_esc_sequence := true;
   elsif the_input = CR_str then
      Get_Iter_At_Mark(for_buffer, start_iter, Get_Insert(for_buffer));
      Get_Iter_At_Line_Offset(for_buffer, start_iter, Get_Line(start_iter),0);
      -- It appears that Linux may require a line feed operation also be done
      Get_Iter_At_Line_Offset(for_buffer, end_iter, Get_Line(end_iter),0);
      if not Equal(start_iter, end_iter) then  -- not at last line already
         Error_Log.Debug_Data(at_level => 9, with_details => "Process : CR - going forward one line");
         Forward_Line(start_iter, res);
      end if;
      Place_Cursor(for_buffer, where => start_iter);
   elsif the_input = LF_str then
      if not for_buffer.just_wrapped
      then  -- do a new line
         Place_Cursor(for_buffer, where => end_iter);
         Insert(for_buffer, at_iter=>end_iter, the_text=>the_input);
         for_buffer.line_number := line_numbers(Get_Line_Count(for_buffer));
      else  -- Just wrapped, so ignore this LF and reset just_wrapped
         for_buffer.just_wrapped := false;
      end if;
   elsif the_input = FF_str then
      null;
   elsif the_input = Bel_str then
      null;
   elsif the_input = Tab_str then
       -- work out the tab stop point
      cursor_mark := Get_Insert(for_buffer);   
      Get_Iter_At_Mark(for_buffer, end_iter, cursor_mark);
         -- here, end_iter is where the cursor is
      -- Get_Start_Iter(for_buffer, start_iter);
      Get_Iter_At_Line(for_buffer,start_iter,Glib.Gint(for_buffer.line_number-1));
      tab_stop := Tab_length - 
                   (UTF8_Length(Get_Text(for_buffer, start_iter, end_iter)) rem
                                                               Tab_length);
      Ada.Wide_Text_IO.Put_Line("Process : Tab - line length =" & Natural'Wide_Image(UTF8_Length(Get_Text(for_buffer, start_iter, end_iter))) & ", tab stop =" & Natural'Wide_Image(tab_stop) & ".");
       -- insert the tab stop by inserting spaces
      Insert_At_Cursor(for_buffer, the_text=>Tab_chr(1..tab_stop));
   elsif the_input = BS_str then
      -- Move the cursor back one character (without deleting the character)
      -- We use the Process_Escape procedure as that works (but doing it here
      -- doesn't for some very strange reason).
      Process_Escape(for_sequence => esc_str & "[D", on_buffer => for_buffer);
   --    -- Now lock only this portion of text from editing
      -- if (not for_buffer.history_review) then
         -- Get_Start_Iter(for_buffer, start_iter);
         -- cursor_mark := Get_Insert(for_buffer);   
         -- Get_Iter_At_Mark(for_buffer, end_iter, cursor_mark);
         -- Backward_Line(end_iter, res);
         -- Apply_Tag_By_Name(for_buffer, "history_text", start_iter, end_iter);
         -- Error_Log.Debug_Data(at_level => 9, with_details => "Process : BS - modified history_text tag start and end.");
      -- end if;
   else  -- An ordinary character
      if for_buffer.markup_text = Null_Ptr
      then  -- not in some kind of mark-up so just add the text
         Insert_At_Cursor(for_buffer, the_text=>the_input);
      else  -- in some kind of mark-up - append it to the mark-up string
         Append_To_Markup(for_buffer, the_text => the_input);
      end if;
      for_buffer.just_wrapped := false;
      null;
   end if;
   -- If we are not in an app and the output is not a consequence of
   -- being at a command prompt and we are navigating through Bash history,
   -- then adjust the editing of the displayed text and adjust the anchor
   -- point.
   -- if (not for_buffer.bracketed_paste_mode) and (not for_buffer.history_review)
   if (not for_buffer.history_review) -- and not (SOMETHING THAT SAYS WE ARE IN AN APPLICATION LIKE LESS OR VI)
   then  -- can lock down uneditable region and set anchor_point
      -- Ensure this displayed text cannot be edited
      Get_Start_Iter(for_buffer, start_iter);
      cursor_mark := Get_Insert(for_buffer);
      Get_Iter_At_Mark(for_buffer, end_iter, cursor_mark);
      if the_input /= BS_str then  -- don't lock if in back space
         Backward_Line(end_iter, res);
         Apply_Tag_By_Name(for_buffer, "history_text", start_iter, end_iter);
         Get_Iter_At_Mark(for_buffer, end_iter, cursor_mark);  -- restore it
      end if;
      -- and move the anchor_point where reading can commence from forward
      Get_Iter_At_Line(for_buffer, start_iter,
                       Glib.Gint(for_buffer.line_number-1));
      for_buffer.anchor_point := 
                  UTF8_Length(Get_Text(for_buffer, start_iter, end_iter));
      Error_Log.Debug_Data(at_level => 9, with_details => "Process : NOT for_buffer.history_review. for_buffer.anchor_point =" & for_buffer.anchor_point'Wide_Image & ".");
   elsif for_buffer.history_review
   then  -- Command line (e.g. Bash) history scrolling taking place
      declare
         unedit_mark : Gtk.Text_Mark.Gtk_Text_Mark;  -- End of uneditable zone
         unedit_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      begin
         cursor_mark := Get_Insert(for_buffer);
         Get_Iter_At_Mark(for_buffer, end_iter, cursor_mark);
         unedit_mark := Get_Mark(for_buffer, "end_unedit");
         Get_Iter_At_Mark(for_buffer, unedit_iter, unedit_mark);
         if Compare(unedit_iter, end_iter) > 0
         then  -- Bash moved back a line, so move the editable region
            Get_Start_Iter(for_buffer, start_iter);
            Apply_Tag_By_Name(for_buffer, "history_text", 
                              start_iter, end_iter);
            Move_Mark(for_buffer, unedit_mark, end_iter);
         end if;
      end;
      -- and move the anchor_point where the cursor currently is
      Get_Iter_At_Line(for_buffer, start_iter,
                       Glib.Gint(for_buffer.line_number-1));
      for_buffer.anchor_point := 
                  UTF8_Length(Get_Text(for_buffer, start_iter, end_iter));
      Error_Log.Debug_Data(at_level => 9, with_details => "Process : NOT for_buffer.history_review. for_buffer.anchor_point =" & for_buffer.anchor_point'Wide_Image & ".");
   else  -- Must be an application operating in the terminal
      Error_Log.Debug_Data(at_level => 9, with_details => "Process : for_buffer.history_review is set. for_buffer.anchor_point =" & for_buffer.anchor_point'Wide_Image & ".");
   end if;
   -- Scroll if required to make it visible
   if not for_buffer.in_esc_sequence then
      cursor_mark := Get_Insert(for_buffer);
      Scroll_Mark_Onscreen(for_buffer.parent, cursor_mark);
   end if;
   -- Check if we didn't get told to exit
   Get_Iter_At_Mark(for_buffer, start_iter,
                    Get_Mark(for_buffer, "end_paste"));
   if (not for_buffer.bracketed_paste_mode) and then
      Get_Text(for_buffer, start_iter, end_iter) = "exit" & LF_str
   then  -- got an exit command
      Gtk_Terminal(Get_Parent(for_buffer.parent)).closed_callback(
                                  Gtk_Terminal(Get_Parent(for_buffer.parent)));
   elsif not for_buffer.bracketed_paste_mode then
      null;  -- Error_Log.Debug_Data(at_level => 9, with_details => "Process : line ='" & Ada.Characters.Conversions.To_Wide_String(Get_Text(for_buffer, start_iter, end_iter)) & "'");
   end if;
   -- Set_Cursor_Visible(for_buffer.parent, true);
   Reset_Cursor_Blink(for_buffer.parent);
   for_buffer.in_response := false;
end Process;