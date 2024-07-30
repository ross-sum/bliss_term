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
   use Ada.Strings.UTF_Encoding.Wide_Strings;
   esc_start     : constant string(1..3) := Ada.Characters.Latin_1.Esc & "[ ";
   app_esc_st    : constant string(1..3) := Ada.Characters.Latin_1.Esc & "O ";
   the_term      : Gtk_Text_View := Gtk_Text_View(for_terminal);
   the_terminal  : Gtk_Terminal := Gtk_Terminal(Get_Parent(the_term));
   the_key       : string(1..3) := esc_start;
   the_character : wide_string(1..1);
begin
   Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: key = " & for_event.keyval'Wide_Image & ", last_key_pressed=" & the_terminal.buffer.last_key_pressed'Wide_Image & ".");
   if the_terminal.buffer.cursor_keys_in_app_mode
   then  -- substitute the '[' for a 'O'
      the_key := app_esc_st;
   end if;
   case for_event.keyval is
      when GDK_Up => 
         the_key(3) := 'A';
      when GDK_Down =>
         the_key(3) := 'B';
      when GDK_Home =>
         if (not the_terminal.buffer.use_buffer_editing) or
            the_terminal.buffer.cursor_keys_in_app_mode
         then
            the_key(3) := 'G';
         end if;
      when GDK_End =>
         if (not the_terminal.buffer.use_buffer_editing) or
            the_terminal.buffer.cursor_keys_in_app_mode
         then
            the_key(3) := '4';
         end if;
      when GDK_Page_Up =>
         if (not the_terminal.buffer.use_buffer_editing) or
            the_terminal.buffer.cursor_keys_in_app_mode
         then
            the_key(3) := '5';
         end if;
      when GDK_Page_Down =>
         if (not the_terminal.buffer.use_buffer_editing) or
            the_terminal.buffer.cursor_keys_in_app_mode
         then
            the_key(3) := '6';
         end if;
      when GDK_Left =>
         if the_terminal.buffer.history_review or
            (not the_terminal.buffer.use_buffer_editing) or
            the_terminal.buffer.cursor_keys_in_app_mode
         then
            the_key(3) := 'D';
         end if;
      when GDK_Right =>
         if the_terminal.buffer.history_review or
            (not the_terminal.buffer.use_buffer_editing) or
            the_terminal.buffer.cursor_keys_in_app_mode
         then
            the_key(3) := 'C';
         end if;
      when GDK_BackSpace =>  --16#FF08# / 10#65288#
         if the_terminal.buffer.history_review or
            not the_terminal.buffer.use_buffer_editing
         then
            the_key(1) := Ada.Characters.Latin_1.BS;
            the_key(2) := ' ';
         end if;
      when GDK_Tab =>  --16#FF09# / 10#65289#
         Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: tab key = pressed.");
         -- if in command line, but not history_review, put it in that state
         if (the_terminal.buffer.use_buffer_editing and
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
            the_key(2) := ' ';
         end if;
      when GDK_Escape =>  --16#FF1B#
         the_key(1) := Ada.Characters.Latin_1.Esc;
         the_key(2) := ' ';
      when GDK_Return =>
         if the_terminal.buffer.keypad_keys_in_app_mode and then
            the_terminal.buffer.alternative_screen_buffer
         then  -- send the control sequence for this key
            the_key(1) := Ada.Characters.Latin_1.CR;
            the_key(2) := ' ';
         end if;
      when GDK_KP_0 | GDK_KP_Insert =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := '2';
         end if;
      when GDK_KP_1 | GDK_KP_End =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := '4';
         end if;
      when GDK_KP_2 | GDK_KP_Down =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := 'B';
         end if;
      when GDK_KP_3 | GDK_KP_Page_Down =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := '6';
         end if;
      when GDK_KP_4 | GDK_KP_Left =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := 'D';
         end if;
      when GDK_KP_5 =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            null;
         end if;
      when GDK_KP_6 | GDK_KP_Right =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := 'C';
         end if;
      when GDK_KP_7 | GDK_KP_Home =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := 'G';
         end if;
      when GDK_KP_8 | GDK_KP_Up =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := 'A';
         end if;
      when GDK_KP_9 | GDK_KP_Page_Up =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := '5';
         end if;
      when GDK_KP_Decimal | GDK_KP_Delete =>
         if the_terminal.buffer.keypad_keys_in_app_mode
         then  -- send the control sequence for this key
            the_key(3) := 'P';
         end if;
      when GDK_LC_a .. GDK_LC_z =>
         if the_terminal.buffer.last_key_pressed = GDK_Control_L or
           the_terminal.buffer.last_key_pressed = GDK_Control_R
         then  -- Control-A - Control-Z
            the_key(1) := Character'Val(for_event.keyval-Character'Pos('a')+1);
            the_key(2) := ' ';
         end if;
      when others =>
         null;  -- Don't do anything
   end case;
   -- For Control, Alt, Super and similar keys, we need to save away  the
   -- previous key to know, since that could be the Alt, Super, etc. key.
   the_terminal.buffer.last_key_pressed := for_event.keyval;
   -- In the event of there being a history_review key press or in and
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
   -- Check if modifier keys are in effect and, if so, act upon them
   null;
   -- Operate on any key interpretations where required
   if the_terminal.buffer.bracketed_paste_mode and then
      (((not the_terminal.buffer.cursor_keys_in_app_mode) and 
        the_key /= esc_start) or 
       (the_terminal.buffer.cursor_keys_in_app_mode and 
        the_key /= app_esc_st))
   then  -- at command prompt: we have set it to pass to the write routine
      Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: at cmd prompt and sending '" & Ada.Characters.Conversions.To_Wide_String(the_key) & "'.  Set the_terminal.buffer.history_review to true and Set_Overwrite(the_terminal.terminal) to true.");
      if for_event.keyval = GDK_BackSpace or for_event.keyval = Gdk_Escape or
         for_event.keyval = GDK_Return
      then  -- Actually a single back-space, Escape or Return character
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
      elsif for_event.keyval = GDK_Tab
      then  -- Actually a single tab character
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
      elsif the_key(2) = ' ' and  the_key(3) = ' ' and 
            the_key(1) /= Ada.Characters.Latin_1.Esc
      then  -- A single control character
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
      else  -- standard sequence
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key);
      end if;
      if for_event.keyval = GDK_Up or for_event.keyval = GDK_Down
      then  -- these keys are about starting/continuing history review
         the_terminal.buffer.history_review := true;
         Switch_The_Light(the_terminal.buffer, 2, true);
         Set_Overwrite(the_terminal.terminal, true);
         Switch_The_Light(the_terminal.buffer, 5, false);
      end if;
      return true;
   elsif (not the_terminal.buffer.bracketed_paste_mode) and then
         (((not the_terminal.buffer.cursor_keys_in_app_mode) and 
           the_key /= esc_start) or 
          (the_terminal.buffer.cursor_keys_in_app_mode and 
           the_key /= app_esc_st))
   then  -- in an app: we have set it to pass to the write routine
      Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: in app and sending '" & Ada.Characters.Conversions.To_Wide_String(the_key) & "'.");
      -- According to https://invisible-island.net/xterm/ctlseqs/
      --                         ctlseqs.html#h2-The-Alternate-Screen-Buffer
      -- the following codes in the form of "CSI n ~" should work.  That is
      -- corroborated by the DEC VT240 Programmer Reference Manual.  But, for
      -- Page Up and Page Down at least, they do not.  Hence the work-arounds
      -- below.
      if the_key(3) = '2' or the_key(3) = '4' 
         -- or the_key(3) = '5' or the_key(3) = '6'
      then  -- Actually a 4 character non-standard sequence
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key & '~');
      elsif the_key(3) = '5' or the_key(3) = '6'  -- Page Up, Page Down
      then
         if the_key(3) = '5' then the_key(3) := 'A'; end if;
         if the_key(3) = '6' then the_key(3) := 'B'; end if;
         for cntr in 1 .. (the_terminal.rows / 2) + 1 loop  -- half screen
            Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key);
         end loop;
      elsif for_event.keyval = GDK_BackSpace or for_event.keyval = Gdk_Escape or
            for_event.keyval = GDK_Return
      then  -- Actually a single back-space, Escape or Return character
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
      elsif the_key(2) = ' ' and  the_key(3) = ' ' and 
            the_key(1) /= Ada.Characters.Latin_1.Esc
      then  -- A single control character
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
      else  -- standard sequence
         Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key);
      end if;
      return true;
   elsif the_terminal.buffer.alternative_screen_buffer and then
         (for_event.keyval>=GDK_space and for_event.keyval<GDK_3270_Duplicate)
   then  -- when in alaternative buffer and not a cursor movement key, pass on
      the_character(1) := wide_character'Val(for_event.keyval);
      Write(fd=> the_terminal.buffer.master_fd, Buffer=>Encode(the_character));
      return true;
   else  -- at command prompt and not a terminal history action key press
      return false;
   end if;
end Scroll_Key_Press_Check;
