-----------------------------------------------------------------------
--                                                                   --
--                      G T K . T E R M I N A L                      --
--                      Scroll_Key_Press_Check                       --
--                          S E P A R A T E                          --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2024  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package  provides a simple  virtual  terminal  interface,  --
--  which contains the necessary components to construct and run  a  --
--  virtual  terminal.  It was built because the VTE terminal  does  --
--  not   properly   handle  the  combining  characters   used   in  --
--  Blissymbolics.                                                   --
--  It  allows  control of virtual terminal interface  details  for  --
--  dimensions,  window  control,  status  icon  and  colours,  the  --
--  language (i.e. Unicode group) being used for input and display,  --
--  options around the language, and input and output management.    --
--  It  was  built  as a part of the Bliss  Terminal  (Bliss  Term)  --
--  software  construction.   But it really could be  considered  a  --
--  part of the Gtk Ada software suite as, other than allowing  for  --
--  the capability of using languages like Blissymbolics, there  is  --
--  nothing in it that specifically alligns it to Blissymbolics.     --
--                                                                   --
--  This particular Separate file is for the Scroll_Key_Press_Check  --
--  That checks the keys pressed (prior to the Key_Pressed handler)  --
--  for need to modify the key code or even to send it directly  to  --
--  the system's terminal emulator client.                           --
--  A number of the sequences were determined from the command:      --
--     od -c                                                         --
--  and then typing the key stroke to see the result.                --
--                                                                   --
--  For modifiers, used to work out whether Shift, Control, Alt are  --
--  pressed  and  in what combination, the following  table,  taken  --
--  from   https://invisible-island.net/xterm/ctlseqs/ctlseqs.html,  --
--  is useful:                                                       --
--       Code     Modifiers                                          --
--       ---------+---------------------------                       --
--          2     | Shift                                            --
--          3     | Alt                                              --
--          4     | Shift + Alt                                      --
--          5     | Control                                          --
--          6     | Shift + Control                                  --
--          7     | Alt + Control                                    --
--          8     | Shift + Alt + Control                            --
--          9     | Meta                                             --
--          10    | Meta + Shift                                     --
--          11    | Meta + Alt                                       --
--          12    | Meta + Alt + Shift                               --
--          13    | Meta + Ctrl                                      --
--          14    | Meta + Ctrl + Shift                              --
--          15    | Meta + Ctrl + Alt                                --
--          16    | Meta + Ctrl + Alt + Shift                        --
--       ---------+---------------------------                       --
--                                                                   --
-- According to https://invisible-island.net/xterm/ctlseqs/          --
--                      ctlseqs.html#h2-The-Alternate-Screen-Buffer  --
-- the codes in the form of "CSI n ~" should work for Page Up, Page  --
-- Down,  Insert  and End.  That is corroborated by the  DEC  VT240  --
-- Programmer Reference Manual.                                      --
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
separate (Gtk.Terminal)
function Scroll_Key_Press_Check(for_terminal : access Gtk_Widget_Record'Class;
                                for_event : Gdk.Event.Gdk_Event_Key)
return boolean is
   -- Respond to any key press events to check if an up arrow, down arrow
   -- or, in the case of terminal emulator controlled editing, left and
   -- right arrow and backspace key has been been pressed.  If so, it gets
   -- passed to the terminal emulator and not to the buffer for processing.
   use Gdk.Event, Gdk.Types, Gdk.Types.Keysyms;
   use Gdk.Key_Map;
   use Ada.Strings.UTF_Encoding.Wide_Strings;
   esc_str_length : constant natural := 10;
   subtype esc_string is string(1..esc_str_length);
   key_state      : natural := The_Modifier_State(for_keymap => key_map);
   procedure Apply_Modifier(to : in out esc_string; of_length : in out natural;
                            for_keytype: in natural; with_key: in character) is
      -- Based on the modifiers in action, build the key to be sent to the 
      -- virtual terminal's operating system terminal client.
      the_keytype : constant string := As_String(for_keytype);
   begin
      if (Gdk_Modifier_Type(key_state) and Shift_Mask) > 0 and
         (Gdk_Modifier_Type(key_state) and Control_Mask) > 0 and
         ((Gdk_Modifier_Type(key_state) and Meta_Mask) > 0 or
            (Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0)
      then  -- Ctrl-Shift- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";8" & with_key;
      elsif (Gdk_Modifier_Type(key_state) and Shift_Mask) > 0 and
         (Gdk_Modifier_Type(key_state) and Control_Mask) > 0
      then  -- Ctrl-Shift- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";6" & with_key;
      elsif (Gdk_Modifier_Type(key_state) and Shift_Mask) > 0 and
         ((Gdk_Modifier_Type(key_state) and Meta_Mask) > 0 or
            (Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0)
      then  -- Shift-Alt- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";4" & with_key;
      elsif (Gdk_Modifier_Type(key_state) and Control_Mask) > 0 and
         ((Gdk_Modifier_Type(key_state) and Meta_Mask) > 0 or
            (Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0)
      then  -- Ctrl-Alt- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";7" & with_key;
      elsif (Gdk_Modifier_Type(key_state) and Shift_Mask) > 0
      then  -- Shift- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";2" & with_key;
      elsif (Gdk_Modifier_Type(key_state) and Control_Mask) > 0
      then  -- Ctrl- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";5" & with_key;
      elsif (Gdk_Modifier_Type(key_state) and Meta_Mask) > 0 or
            (Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0
      then  -- Alt- modifier
         of_length := 5 + the_keytype'Length;
         to(3..of_length) := the_keytype & ";3" & with_key;
      else  -- no modifier
         if for_keytype = 1
         then
            of_length := 3;
            to(of_length) := with_key;
         else
            of_length := 3 + the_keytype'Length;
            to(3..of_length) := the_keytype & with_key;
         end if;
      end if;
   end Apply_Modifier;
   esc_start : constant esc_string := 
                    (1 => Ada.Characters.Latin_1.Esc, 2 => '[', others => ' ');
   app_esc_st: constant esc_string := 
                    (1 => Ada.Characters.Latin_1.Esc, 2 => 'O', others => ' ');
   the_term      : Gtk_Text_View := Gtk_Text_View(for_terminal);
   the_terminal  : Gtk_Terminal := Gtk_Terminal(Get_Parent(the_term));
   interpret_key : constant boolean :=
                            the_terminal.buffer.history_review or
                            (not the_terminal.buffer.use_buffer_editing) or
                            Get_Overwrite(the_terminal.terminal) or
                             the_terminal.buffer.alternative_screen_buffer;
   the_key       : esc_string := esc_start;
   key_length    : natural range 0..esc_str_length := 0;  -- 0 = no key
   the_character : wide_string(1..1);
begin
   Translate_Modifiers(for_keymap => key_map, for_state => key_state);
   if the_terminal.buffer.cursor_keys_in_app_mode
   then  -- substitute the '[' for a 'O'
      the_key := app_esc_st;
   end if;
   case for_event.keyval is
      when GDK_Up => 
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'A');
      when GDK_Down =>
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'B');
      when GDK_Home =>
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'H');
      when GDK_End =>
         if interpret_key
         then
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'F');
         end if;
      when GDK_Page_Up =>
         if interpret_key
         then
            the_key(2) := '[';  -- always CSI
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 5, with_key => '~');
         end if;
      when GDK_Page_Down =>
         if interpret_key
         then
            the_key(2) := '[';  -- always CSI
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 6, with_key => '~');
         end if;
      when GDK_Left =>
         if interpret_key
         then
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'D');
         end if;
      when GDK_Right =>
         if interpret_key
         then
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'C');
         end if;
      when GDK_Insert =>
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 2, with_key => '~');
      when GDK_Delete =>
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 3, with_key => '~');
      when GDK_BackSpace =>  --16#FF08# / 10#65288#
         if interpret_key
         then
            the_key(1) := Ada.Characters.Latin_1.BS;
            key_length := 1;
         end if;
      when GDK_Tab =>  --16#FF09# / 10#65289#
         if (Gdk_Modifier_Type(key_state) and Shift_Mask) > 0
         then  -- Shift-Tab
            case the_terminal.buffer.modifiers.modify_other_keys is
               when disabled =>  -- <esc> [ Z
                  the_key(2..3) := "[Z";
                  key_length := 3;
               when all_except_special | all_including_special =>
                  -- Define as alt, + character as number
                  the_key(3..7) := "27;2;";  -- 2=Shift (3=Alt,5=Ctl,6=Shft-Ctl)
                  the_key(8) := 
                        As_String(Character'Pos(Ada.Characters.Latin_1.HT))(1);
                  key_length := 8;
            end case;
         elsif (Gdk_Modifier_Type(key_state) and Control_Mask) > 0
         then  -- Control-Tab
            case the_terminal.buffer.modifiers.modify_other_keys is
               when disabled =>  -- <esc> then shift by 128
                  the_key(2) := 
                     Character'Val(Character'Pos(Ada.Characters.Latin_1.HT)+128);
                  key_length := 2;
               when all_except_special | all_including_special =>
                  -- Define as alt, + character as number
                  the_key(3..7) := "27;5;";  -- 5=Ctl (3=Alt,2=Shift,6=Shft-Ctl)
                  the_key(8) := 
                        As_String(Character'Pos(Ada.Characters.Latin_1.HT))(1);
                  key_length := 8;
            end case;
         elsif (Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0 or
               (Gdk_Modifier_Type(key_state) and Meta_Mask) > 0
         then  -- Alt-Tab
            case the_terminal.buffer.modifiers.modify_other_keys is
               when disabled =>  -- <esc> but no shift
                  the_key(2) := Ada.Characters.Latin_1.HT;
                  key_length := 2;
               when all_except_special | all_including_special =>
                  -- Define as alt, + Tab as number
                  the_key(3..7) := "27;3;";  -- 3=Alt (2=Shift,...)
                  the_key(8) := 
                        As_String(Character'Pos(Ada.Characters.Latin_1.HT))(1);
                  key_length := 8;
            end case;
         -- if in command line, but not history_review, put it in that state
         elsif (not the_terminal.buffer.alternative_screen_buffer) and then
               (the_terminal.buffer.use_buffer_editing and
                not the_terminal.buffer.history_review) and then 
               the_terminal.buffer.entering_command
         then  -- should be in command line entry
            -- First, set a flag to flush the buffer
            the_terminal.buffer.flush_buffer := true;
            -- now output any already entered text
            Key_Pressed(for_buffer => the_terminal.buffer);
            -- reset the flush command
            the_terminal.buffer.flush_buffer := false;
            -- simulate going into handling stroke by stroke by switching on
            -- history_review
            the_terminal.buffer.history_review := true;
            -- then just let the Tab key pass on through...
            the_key(1) := Ada.Characters.Latin_1.HT;
            key_length := 1;
         end if;
      when GDK_Escape =>  --16#FF1B#
         the_key(1) := Ada.Characters.Latin_1.Esc;
         key_length := 1;
      when GDK_Return =>
         if interpret_key and then
            the_terminal.buffer.alternative_screen_buffer
         then  -- send the control sequence for this key
            the_key(1) := Ada.Characters.Latin_1.CR;
            key_length := 1;
         end if;
      when GDK_KP_0 | GDK_KP_Insert =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            the_key(2) := '[';  -- always CSI
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 2, with_key => '~');
         else  -- send the numeric key
            the_key(1) := '0';
            key_length := 1;
         end if;
      when GDK_KP_1 | GDK_KP_End =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'F');
         else  -- send the numeric key
            the_key(1) := '1';
            key_length := 1;
         end if;
      when GDK_KP_2 | GDK_KP_Down =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'B');
         else  -- send the numeric key
            the_key(1) := '2';
            key_length := 1;
         end if;
      when GDK_KP_3 | GDK_KP_Page_Down =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            the_key(2) := '[';  -- always CSI
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 6, with_key => '~');
         else  -- send the numeric key
            the_key(1) := '3';
            key_length := 1;
         end if;
      when GDK_KP_4 | GDK_KP_Left =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'D');
         else  -- send the numeric key
            the_key(1) := '4';
            key_length := 1;
         end if;
      when GDK_KP_5 =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            null;
         else  -- send the numeric key
            the_key(1) := '5';
            key_length := 1;
         end if;
      when GDK_KP_6 | GDK_KP_Right =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'C');
         else  -- send the numeric key
            the_key(1) := '6';
            key_length := 1;
         end if;
      when GDK_KP_7 | GDK_KP_Home =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'H');
         else  -- send the numeric key
            the_key(1) := '7';
            key_length := 1;
         end if;
      when GDK_KP_8 | GDK_KP_Up =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 1, with_key => 'A');
         else  -- send the numeric key
            the_key(1) := '8';
            key_length := 1;
         end if;
      when GDK_KP_9 | GDK_KP_Page_Up =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            the_key(2) := '[';  -- always CSI
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 5, with_key => '~');
         else  -- send the numeric key
            the_key(1) := '9';
            key_length := 1;
         end if;
      when GDK_KP_Decimal | GDK_KP_Delete =>
         if the_terminal.buffer.keypad_keys_in_app_mode and
            not Num_Lock_Is_On(for_keymap => key_map)
         then  -- send the control sequence for this key
            the_key(2) := '[';  -- always CSI
            Apply_Modifier(to => the_key, of_length => key_length,
                           for_keytype => 3, with_key => '~');
         else  -- send the 'numeric' key
            the_key(1) := '.';
            key_length := 1;
         end if;
      when GDK_F1 | GDK_KP_F1 => 
         the_key(2) := 'O';  -- always SS3
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'P');
      when GDK_F2 | GDK_KP_F2 => 
         the_key(2) := 'O';  -- always SS3
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'Q');
      when GDK_F3 | GDK_KP_F3 => 
         the_key(2) := 'O';  -- always SS3
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'R');
      when GDK_F4 | GDK_KP_F4 => 
         the_key(2) := 'O';  -- always SS3
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 1, with_key => 'S');
      when GDK_F5 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 15, with_key => '~');
      when GDK_F6 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 17, with_key => '~');
      when GDK_F7 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 18, with_key => '~');
      when GDK_F8 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 19, with_key => '~');
      when GDK_F9 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 20, with_key => '~');
      when GDK_F10 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 21, with_key => '~');
      when GDK_F11 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 23, with_key => '~');
      when GDK_F12 => 
         the_key(2) := '[';  -- always CSI
         Apply_Modifier(to => the_key, of_length => key_length,
                        for_keytype => 24, with_key => '~');
      when GDK_parenleft | GDK_parenright | GDK_slash | 
           GDK_colon..GDK_greater | GDK_bracketleft .. GDK_bracketright |
           GDK_LC_a .. GDK_LC_z | GDK_braceleft .. GDK_braceright =>
         if (Gdk_Modifier_Type(key_state) and Control_Mask) > 0 and then
            (for_event.keyval >= GDK_LC_a and for_event.keyval <= GDK_LC_z)
         then  -- Control-A - Control-Z
            the_key(1) := Character'Val(for_event.keyval-Character'Pos('a')+1);
            key_length := 1;
         elsif (Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0 or
               (Gdk_Modifier_Type(key_state) and Meta_Mask) > 0
         then  -- Alt-A - Alt-Z, Alt-
            case the_terminal.buffer.modifiers.modify_other_keys is
               when disabled =>  -- <esc> then (lower case) character
                  the_key(2) := Character'Val(for_event.keyval);
                  key_length := 2;
               when all_except_special | all_including_special =>
                  -- Define as alt, + character as number
                  the_key(3..7) := "27;3;";  -- 3=Alt (2=Shift)
                  if for_event.keyval < 10
                  then
                     the_key(8) := Gdk_Key_Type'Image(for_event.keyval)(1);
                     key_length := 8;
                  elsif for_event.keyval < 100
                  then
                     the_key(8..9):=Gdk_Key_Type'Image(for_event.keyval)(1..2);
                     key_length := 9;
                  else
                     the_key(8..10):=Gdk_Key_Type'Image(for_event.keyval)(1..3);
                     key_length := 10;
                  end if;
            end case;
         end if;
      when others =>
         null;  -- Don't do anything
   end case;
   -- For being in highlight mode when typing on the keyboard, this terminal
   -- needs to know what the key was that was pressed in order to knot that it
   -- has been typed rather than passed on.
   the_terminal.buffer.last_key_pressed := for_event.keyval;
   -- In the event of there being a history_review key press or in an
   -- application in the alternative buffer, need to make sure that an actual
   -- insert takes place
   if Get_Overwrite(the_terminal.terminal)
   then  -- capture the character under cursor for potential future use
      declare
         cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
         cursor_end  : Gtk.Text_Iter.Gtk_Text_Iter;
         the_buf : Gtk.Text_Buffer.Gtk_Text_Buffer;
         res : boolean;
      begin
         if the_terminal.buffer.alternative_screen_buffer
         then  -- using the alternative buffer for display
            the_buf := the_terminal.buffer.alt_buffer;
         else  -- using the main buffer for display
            the_buf := Gtk.Text_Buffer.Gtk_Text_Buffer(the_terminal.buffer);
         end if;
         Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
         cursor_end := cursor_iter;
         Gtk.Text_Iter.Forward_Chars(cursor_end, 1, res);
         if res
         then
            the_terminal.buffer.old_key_at_cursor :=
                  Ada.Strings.UTF_Encoding.Wide_Strings.Decode(
                                Get_Text(the_buf, cursor_iter, cursor_end));
         else
            the_terminal.buffer.old_key_at_cursor := " ";
         end if;
      end;
   end if;
   -- Operate on any key interpretations where required
   if the_terminal.buffer.bracketed_paste_mode and then key_length > 0
   then  -- at command prompt: we have set it to pass to the write routine
      Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..key_length));
      if for_event.keyval = GDK_Up or for_event.keyval = GDK_Down
      then  -- these keys are about starting/continuing history review
         the_terminal.buffer.history_review := true;
         Switch_The_Light(the_terminal.buffer, 2, true);
         Set_Overwrite(the_terminal.terminal, true);
         Switch_The_Light(the_terminal.buffer, 5, false);
      end if;
      return true;
   elsif (not the_terminal.buffer.bracketed_paste_mode) and then key_length > 0
   then  -- in an app: we have set it to pass to the write routine
      Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..key_length));
      return true;
   elsif the_terminal.buffer.alternative_screen_buffer and then
         (for_event.keyval>=GDK_space and for_event.keyval<GDK_3270_Duplicate)
   then  -- when in alaternative buffer and not a cursor movement key, pass on
      the_character(1) := wide_character'Val(for_event.keyval);
      Write(fd=> the_terminal.buffer.master_fd, Buffer=>Encode(the_character));
      return true;
   elsif the_terminal.buffer.alternative_screen_buffer and then
         (for_event.keyval = GDK_Tab)
   then  -- when in alaternative buffer and a tab key, send it on (for Emacs)
      the_character(1) := 
                  Wide_Character'Val(Character'Pos(Ada.Characters.Latin_1.HT));
      Write(fd=> the_terminal.buffer.master_fd, Buffer=>Encode(the_character));
      return true;
   else  -- at command prompt and not a terminal history action key press
      return false;
   end if;
end Scroll_Key_Press_Check;
