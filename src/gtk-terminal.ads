-----------------------------------------------------------------------
--                                                                   --
--                      G T K . T E R M I N A L                      --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
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
pragma Warnings (Off, "*is already use-visible*");
with System;
with Interfaces.C, Interfaces.C.Strings;
with Ada.Containers.Vectors;
with Glib;                    use Glib;
with Glib.Spawn;              use Glib.Spawn;
with GLib.Main;
with Glib.Error;
with Gdk.Types;
with Gdk.Event;
with Gtk.Editable;            use Gtk.Editable;
with Gtk.Widget;              use Gtk.Widget;
with Gtk.Viewport;            use Gtk.Viewport;
with Gtk.Scrolled_Window;     use Gtk.Scrolled_Window;
with Gtk.Text_View;           use Gtk.Text_View;
with Gtk.Text_Buffer;         use Gtk.Text_Buffer;
with Gtk.Text_Iter;
with Gtk.Text_Tag_Table;
with Gtk.Text_Mark;
with Gdk.RGBA;                use Gdk.RGBA;
with Pango.Font;              use Pango.Font;
with Gtkada.Types;            use Gtkada.Types;
with Gtk.Terminal_Markup;

package Gtk.Terminal is

   Encoding_Error : exception;
   Terminal_Creation_Error : exception;
   Terminal_IO_Error       : exception;  -- raised for a read or write error
   
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

   type encoding_types is (default, utf8, utf16);
   type Gtk_Terminal_Record is new 
           Gtk.Scrolled_Window.Gtk_Scrolled_Window_Record with private;
   type Gtk_Terminal is access all Gtk_Terminal_Record'Class;

   ------------------
   -- Constructors --
   ------------------
   procedure Gtk_New (the_terminal : out Gtk_Terminal);
   procedure Initialize(the_terminal: access Gtk_Terminal_Record'Class);
   procedure Initialise(the_terminal: access Gtk_Terminal_Record'Class)
   renames Initialize;
      -- Creates a new terminal.
      -- Initialise does nothing if the object was already created with another
      -- call to Initialise* or G_New.

   function Gtk_Terminal_New return Gtk_Terminal;
   --  Creates a new terminal.

   procedure Gtk_New_With_Buffer
      (the_terminal : out Gtk_Terminal; Buffer : UTF8_String);
   procedure Initialise_With_Buffer
      (the_terminal : access Gtk_Terminal_Record'Class; buffer : UTF8_String);
      -- Creates a new terminal with the specified text buffer.
      -- Initialise_With_Buffer does nothing if the object was already created
      -- with another call to Initialise* or Gtk_New.
      -- "buffer": The buffer to load for the new Gtk.Terminal.Gtk_Terminal. It
      -- contains the previous session's data to be preset as the history. 

   function Gtk_Terminal_New_With_Buffer (buffer : UTF8_String)
       return Gtk_Terminal;
       -- Creates a new terminal with the specified text pre-loaded into its
       -- buffer.
       -- "buffer": The buffer to use for the new Gtk.Terminal.Gtk_Terminal.

   function Get_Type return Glib.GType;

   procedure Finalize(the_terminal : access Gtk_Terminal_Record'Class);
   procedure Finalise(the_terminal : access Gtk_Terminal_Record'Class)
      renames Finalize;

   ----------------------
   -- Public Callbacks --
   ----------------------

   type Spawn_Title_Callback is access procedure
        (terminal : Gtk_Terminal; title : UTF8_String);
      -- This call-back procedure is to display the title in the titlebar.
      -- The main application should provide such a procedure that displays
      -- the title.
   type Spawn_Closed_Callback is access procedure (terminal : Gtk_Terminal);
      -- This call-back procedure is to shut down the virtual terminal (or
      -- potentially the application).
   type Switch_Light_Callback is access procedure (for_terminal : Gtk_Terminal;
                                                   at_light_number : natural;
                                                   to_on : boolean := false;
                                                   with_status:UTF8_String:="");
      -- This call-back is to display status switch lights and values.  It is
      -- provided mainly for fault finding purposes.  The statuses are what the
      -- system 'thinks' is the case.
      -- "at_light_number" has the following possible values:
      --    1: whether or not the main screen buffer (and not the auxiliary
      --       buffer) is active.
      --    2: whether the history list is being searched (initiated by
      --       pressing either the up or down arrow at the command line).
      --    3: whether the system has put the virtual terminal into bracketed
      --       paste mode.
      --    4: whether pass-through text is on (or off).  When bracketed paste
      --       mode is on and this is on, programs running in the terminal
      --       (e.g. Vi) should not treat characters as commands.
      --    5: whether the terminal is in 'Insert' (and not 'Overwrite') mode.
      --    6: whether the terminal is at the command line waiting for command
      --       entry.
      --    7: whether or not the terminal is handling an escape code sequence.
      --       Escape code sequences are used to do things to the display, such
      --       as move the cursor about or change the colour of the text or
      --       background or handle the title bar.
      --    8: total number of history lines in the buffer, including those
      --       currently being displayed on screen and those above the top of
      --       the screen.  This number is passed as text in the 'with_status'
      --       field (so is technically not a light).
      --    9: current line number, that is, the line number that the cursor is
      --       on for the currently active buffer. It would be the same as 7 if
      --       the currently active buffer is the main buffer, otherwise it
      --       will most likely be different (i.e. if it is the alternative
      --       buffer).
      --    10: column number where the cursor is.

   type Cb_Gtk_Terminal_Void is access 
                           procedure (Self : access Gtk_Terminal_Record'Class);
   Signal_Show : constant Glib.Signal_Name := "show";
   procedure On_Show (Self  : access Gtk_Terminal_Record;
                      Call  : Cb_Gtk_Terminal_Void;
                      After : Boolean := False);

   type Cb_Gtk_Terminal_Allocation_Void is access 
                           procedure (Self : access Gtk_Terminal_Record'Class);
   Signal_Size_Allocate : constant Glib.Signal_Name := "size-allocate";
   procedure On_Size_Allocate (Self  : access Gtk_Terminal_Record;
                               Call  : Cb_Gtk_Terminal_Allocation_Void;
                               After : Boolean := False);

   type Cb_Gtk_Terminal_Clicked_Void is access 
                           procedure (Self : access Gtk_Terminal_Record'Class);
   Signal_Clicked : constant Glib.Signal_Name := "clicked";
   procedure On_Clicked (Self  : access Gtk_Terminal_Record;
                         Call  : Cb_Gtk_Terminal_Clicked_Void;
                         After : Boolean := False);
       
   -------------
   -- Methods --
   -------------
     
   -- Terminal Setup and Tear-Down Management
   type timeout_period is new integer range -1 .. integer'Last;
   procedure Spawn_Shell (terminal : access Gtk_Terminal_Record'Class; 
                          working_directory : UTF8_String := "";
                          command : UTF8_String := "";
                          environment : UTF8_String := "";
                          use_buffer_for_editing : boolean := true;
                          title_callback : Spawn_Title_Callback;
                          callback       : Spawn_Closed_Callback;
                          switch_light   : Switch_Light_Callback := null);
      -- Principally, spawn a terminal shell.  This procedure does the initial
      -- Terminal Configuration Management (encoding, size, etc).  This
      -- procedure actually launches the terminal, making sure that it is
      -- running with the right shell and set to the right directory with the
      -- right environment variables set.
      --   "terminal": the virtual terminal for which the shell is to be
      --               spawned.
      --   "working_directory": where to land the terminal when it opens.  By
      --                        default, it opens in the current working
      --                        directory.
      --   "command": command to provide the terminal.  For a virtual terminal,
      --              this is usually the shell (e.g. Bash).
      --   "environment": a comma separated list of <ENVIRONMENT>=<VALUE> pairs
      --                  to pass to the virtual terminal.
      --   "use_buffer_for_editing": whether or not to use the built-in editing
      --                             capabilities of the Gtk.Text_Buffer, or
      --                             otherwise use the editing within the
      --                             system's virtual terminal manager.
      --   "title_callback": A procedure (see above) for displaying the title
      --                     as provided by the system's virtual terminal.
      --   "callback": Closed call-back procedure that is called when the
      --               system closes the virtual terminal, for instance, when
      --               the user types the "exit" command.
      --   "switch_light": An optional call-back procedure that displays the
      --                   internal status of various parts of the virtual
      --                   terminal as a series of 'lights' or other values.
   procedure Shut_Down(the_terminal : access Gtk_Terminal_Record'Class);
       -- Finalise everything, shutting down any tasks.
   procedure Set_Encoding (for_terminal : access Gtk_Terminal_Record'Class; 
                           to : in UTF8_string := "UTF8");
      -- Set the terminal's encoding method.  If not UTF-8, then it must be a
      -- valid GIConv target.
   procedure Set_ID(for_terminal : access Gtk_Terminal_Record'Class; 
                    to : natural);
       -- Set the terminal's Identifier (which can be any positive number).
    
   function Get_ID(for_terminal : access Gtk_Terminal_Record'Class) 
   return natural;
       -- Get the terminal's Identifier (which been previously set via Set_ID).
   procedure Set_Size (terminal : access Gtk_Terminal_Record'Class; 
                       columns, rows : natural);
      -- Set the terminal's size to the specified number of columns and rows.  
   type character_width_types is (normal, narrow, wide);
   for character_width_types use (normal => 0, narrow => 1, wide => 2);
      -- 'normal' in the above should never be used.  It is included because
      -- GNAT does not honour the for - use clause above ('narrow' MUST = 1).
   procedure Set_Character_Width 
                      (for_terminal : access Gtk_Terminal_Record'Class; 
                       to : in character_width_types);
      -- Set the terminal's character width to that specified for CJK type
      -- characters.  

   -- Terminal Colour and Font Management
   procedure Set_Colour_Background (terminal: access Gtk_Terminal_Record'Class;
                                    background :  Gdk.RGBA.Gdk_RGBA);
     -- Set the background colour to that specified.
   procedure Set_Colour_Text (terminal: access Gtk_Terminal_Record'Class;
                              text_colour :  Gdk.RGBA.Gdk_RGBA);
     -- Set the text (i.e. the foreground) colour to that specified.
   procedure Set_Colour_Bold (terminal: access Gtk_Terminal_Record'Class;
                              bold_colour :  Gdk.RGBA.Gdk_RGBA);
     -- Set the bold text colour to that specified.
   procedure Set_Colour_Highlight (terminal: access Gtk_Terminal_Record'Class;
                                   highlight_colour :  Gdk.RGBA.Gdk_RGBA);
     -- Set the highlighted text colour to that specified.
     
   procedure Set_Font (for_terminal : access Gtk_Terminal_Record'Class; 
                       to_font_desc : Pango.Font.Pango_Font_Description);
        -- Set the terminal's font to that specified in Pango font format.
   function Get_Font (for_terminal : access Gtk_Terminal_Record'Class) return
                                            Pango.Font.Pango_Font_Description;
        -- Get the terminal's currently set font in Pango font format.
  
   -- Terminal Display Management
   procedure Feed (terminal : access Gtk_Terminal_Record'Class; 
                   data : UTF8_String := "");
     -- Send data to the terminal to display, or to the terminal's forked
     -- command to handle in some way.  If it's 'cat', they should be the same.
   function Get_Text (from_terminal : access Gtk_Terminal_Record'Class) 
     return UTF8_string;
     -- Get all the text in the visibile part of the terminal's display, that
     -- is, don't get any hidden (formatting) text, but do get all other text,
     -- including that outside the displayed region (normally the history).

   procedure Set_Scrollback_Lines(terminal: access Gtk_Terminal_Record'Class;
                                    lines : natural);
        -- Set the number of scroll-back lines to be kept by the terminal.  It
        -- should be noted that this is the number of lines at or above an
        -- internal minimum.
   function Get_Scrollback_Lines(terminal: access Gtk_Terminal_Record'Class)
     return natural;
        -- Get the number of scroll-back lines that have been set.
    
   function Get_Title(for_terminal : access Gtk_Terminal_Record'Class)
    return UTF8_String;
       -- Return the title as the operating system knows it
    
   function Get_Path(for_terminal : access Gtk_Terminal_Record'Class)
    return UTF8_String;
       -- Return the current file as the operating system knows it, essentially
       -- extracting it from the title. It assumes that the path is encoded in
       -- the title and that the title is of the form "<pre-bits>:<path>".  If
       -- there is no ":" in the title, then an empty string will be returned.
       
   function Home_Iterator(for_terminal : access Gtk_Terminal_Record'Class)
    return Gtk.Text_Iter.Gtk_Text_Iter;
       -- Return the home position (that is, the top left hand corner) of the
       -- currently displayed buffer area in the terminal.
       -- This function is provided because neither Get_Iter_At_Location,
       -- Get_Iter_At_Position or Get_Line_At_Y appear to be able to do
       -- anything other than provide the result that you get when calling
       -- Get_End_Iter if within a single screen worth of text, irrespective of
       -- whether the X and Y buffer coordinates are provided from
       -- Get_Visible_Rect or Window_To_Buffer_Coords or whether any other
       -- random value of Y is used.  But otherise, they do work! >:-/
       -- The output of this function is essentially a calculation based on the
       -- terminal's understanding of the number of lines it is displaying
       -- (which, if resized by mouse dragging rather than by command, may be
       -- incorrect).
    
    
   ----------------------------------------------------------------------------
   private
   ----------------------------------------------------------------------------
   use Gdk.Event;
   use Gtk.Terminal_Markup;
   
   Blue_RGBA       : constant Gdk.RGBA.Gdk_RGBA := (0.0, 0.0, 01.0, 1.0);
   nowrap_size     : constant natural := 1000;
   default_columns : constant natural := 120;
   default_rows    : constant natural := 25;
       -- number of column characters that represents a no-wrap screen
   service_initialised : boolean := false;
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

   function UTF8_Length(of_string : in UTF8_String) return natural;
       -- get the absolute string length (i.e. including parts of characters)
   function As_String(the_number : in natural) return UTF8_String;
       -- provide the (non-negative) number as a compact string

   -------------------------
   -- Gtk Terminal Buffer --
   -------------------------
       
   protected type check_for_command_prompt_end is
      -- Monitor input for the end of the command prompt.  This can be either
      -- the "$ " string or the "# " string, depending on whether it is root or
      -- an ordinary user.  It only looks when switched to bracketed paste mode
      -- as this seems to be always the case just prior to the command prompt.
      -- This operation is used to determine where to put the last point of the
      -- history buffer.
      procedure Start_Looking;  -- at bracketed paste mode
      procedure Stop_Looking;   -- not bracketed paste mode or at pass through text
      function Is_Looking return boolean;
      procedure Check(the_character : character);
      function Found_Prompt_End return boolean;
      function Current_String return string;
     private
      looking : boolean := false;
      last_two : string(1..2) := "  ";
   end check_for_command_prompt_end;
   type check_for_command_prompt_end_access is 
        access check_for_command_prompt_end;
   
   buffer_length : constant positive := 255;
   type buf_index is mod buffer_length;
   type buffer_type is array (buf_index) of wide_character;
   max_utf_char_count : constant positive := 4;
   subtype utf_chars is positive range 1..max_utf_char_count;
   protected type input_monitor_type is
      -- A buffer to contain the character stream coming from the virtual
      -- terminal 'client' (id est from the system).
      -- Input from the system is monitored by a task.  This buffers the task's
      -- output and allows the virtual terminal display (the 'server') to
      -- operate in the main task body (which, for Gtk to work, it must do).
      entry Put(the_character : in character);
      entry Get(the_character : out wide_character);
      function Has_Data return boolean;
   private
      buffer  : buffer_type;
      char    : string(utf_chars'range);
      char_pos: utf_chars := 1;
      reqd_chr: utf_chars := 1;
      head,
      tail    : buf_index := 0;
      count   : natural range 0..buffer_length := 0;
      result  : wide_string(1..1);
   end input_monitor_type;
   type input_monitor_type_access is access input_monitor_type;
   
   type keyboard_modifier_options is 
           (ctrl_on_fn, numeric_kp, editing_kp, fn_keys, other_special);
   for keyboard_modifier_options use (0, 1, 2, 4, 8);
   type cursor_key_modifier_options is
           (disabled, first_param, prefix_with_CSI, second_param, is_private);
   for cursor_key_modifier_options use (-1, 0, 1, 2, 3);
   type function_key_modifier_options is
           (shift_ctl, first_param, prefix_with_CSI, second_param, is_private);
   for function_key_modifier_options use (-1, 0, 1, 2, 3);
   type other_key_modifier_options is
           (disabled, all_except_special, all_including_special);
   for other_key_modifier_options use (0, 1, 2);
   type key_modifier_options is record
         modify_keyboard      : keyboard_modifier_options;
         modify_cursor_keys   : cursor_key_modifier_options;
         modify_function_keys : function_key_modifier_options;
         modify_other_keys    : other_key_modifier_options;
      end record;
   default_modifier_setting : constant key_modifier_options :=
         (modify_keyboard      => ctrl_on_fn,
          modify_cursor_keys   => disabled,
          modify_function_keys => first_param,
          modify_other_keys    => disabled);
   
   type mouse_configuration_parameters is record
         x10_mouse : boolean := false;
         btn_event : boolean := false;
         ext_mode  : boolean := false;
         row,
         col       : natural := 0;
      end record;
   
   -- Escape (i.e. command or formatting) strings:
   escape_length : constant natural := 256;
   subtype escape_str_range is natural range 1..escape_length;
   subtype escape_string is string(escape_str_range);
   -- LIne numbers:
   type line_numbers is new integer range -1 .. integer'Last;
   unassigned_line_number : constant line_numbers := -1;
   
   -- GTK Terminal Buffer:
   type Gtk_Terminal_Buffer_Record is new Gtk.Text_Buffer.Gtk_Text_Buffer_Record
      with record
         master_fd           : Interfaces.C.int;
         child_pid           : Glib.Spawn.GPid;
         child_name          : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
         line_number         : line_numbers := unassigned_line_number;
                                     -- current row number in the main buffer
         buf_line_num        : line_numbers := 0;
                 -- current row number in the current buffer (which may be alt)
         anchor_point        : natural := 0;
                 -- placed at the end of the command prompt on line_number line
         history_review      : boolean := false;
                 -- are we reviewing command line (usually Bash) history?
                 -- If so, then that affects editing positions and anchor_point
                 -- movement.
         cmd_prompt_check    : check_for_command_prompt_end_access;
                 -- check for the end of the command prompt so that we know
                 -- where the end point of the history_review is.
         entering_command    : boolean := false;
                 -- is the system waiting for us to enter a command? If not,
                 -- then send each key stroke through to the virtual terminal
                 -- client.  Otherwise respond to keystrokes depending on
                 -- whether we are in use_buffer_editing or not.
         waiting_for_response: boolean := false;  -- from the terminal
         in_response         : boolean := false;  -- from the terminal
         just_wrapped        : boolean := false;  -- is output at next line?
         old_key_at_cursor   : wide_string(1..1); -- captured when in overwrite
         last_key_pressed    : Gdk.Types.Gdk_Key_Type := 16#20#;
            -- each key press is saved away in case it is a momentary action key
         -- Escape sequences alter the display of text, so need to be trapped
         -- and acted upon.
         -- Hold escape sequences over multiple display characters by storing
         -- in a buffer.  if the first character is the Escape character, then
         -- processing it, otherwise processing normal characters.
         escape_sequence          : escape_string := (escape_str_range => ' ');
         escape_position          : escape_str_range := escape_str_range'First;
         in_esc_sequence          : boolean := false; -- toggled off by typing
         cursor_is_visible        : boolean := true;
          -- Escape sequence flags
         bracketed_paste_mode     : boolean := false;
         pass_through_characters  : boolean := false;  -- matchs br. paste mode
         alternative_screen_buffer: boolean := false;
         reporting_focus_enabled  : boolean := false;
         saved_cursor_pos         : Gtk.Text_Mark.Gtk_Text_Mark;
         cursor_keys_in_app_mode  : boolean := false;
         keypad_keys_in_app_mode  : boolean := false;
         -- Escape character handling (including for mark-up)
         markup              : markup_management;
            -- Mark-up management, including array of mark-up (font) modifiers
         background_colour   : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Black_RGBA;
         text_colour         : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.White_RGBA;
         highlight_colour    : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Null_RGBA;
          -- terminal display buffer handling
         input_monitor       : input_monitor_type_access;
         use_buffer_editing  : boolean := true;
            -- indicates to use the buffer's editing capabilities wherever
            -- possible or, alternatively if false, always use the terminal
            -- emulator's editor.
         flush_buffer        : boolean := false;
            -- this is like a one-shot 'use_buffer_editing' and is done when
            -- the tab key is pressed in order to get the terminal emulator's
            -- editor to process the tab key as a auto-completion operation.
         parent              : Gtk.Text_View.Gtk_Text_View;
         -- The alternative buffer (to emulate an xterm)
         alt_buffer          : Gtk.Text_Buffer.Gtk_Text_Buffer;
         -- Modifiers, a component of xterm, that is required for applications
         -- like vi.
         modifiers           : key_modifier_options:= default_modifier_setting;
         -- Mouse configuration defines how the mouse talks to the application
         -- that is hosted by the terminal
         mouse_config        : mouse_configuration_parameters;
         -- A scrolling region top and bottom may be set (this appears to be
         -- determined by the window height).  It appears to be important for
         -- applications such as vi.
         scroll_region_top,
         scroll_region_bottom: natural := 0;
         switch_light_cb     : Switch_Light_Callback;  -- terminal's monitor
      end record;
   type Gtk_Terminal_Buffer is access all Gtk_Terminal_Buffer_Record'Class;
   
   procedure Gtk_New (the_buffer : out Gtk_Terminal_Buffer;
                      table : Gtk.Text_Tag_Table.Gtk_Text_Tag_Table := null);
      --  Create a new terminal text buffer.
   procedure Initialize(the_buffer : access Gtk_Terminal_Buffer_Record'Class;
                        table : Gtk.Text_Tag_Table.Gtk_Text_Tag_Table := null);
   procedure Initialise(the_buffer: access Gtk_Terminal_Buffer_Record'Class;
                        table : Gtk.Text_Tag_Table.Gtk_Text_Tag_Table := null)
   renames Initialize;
      --  Initialise does nothing if the object was already created with another
      --  call to Initialise* or G_New.
      --  "table": a tag table, or null to create a new one
   function Line_Length(for_buffer : in Gtk_Terminal_Buffer;
                        at_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                        for_printable_characters_only : boolean := true)
     return natural;
       -- Get the line length for the line that the at_iter is currently on.
   function Get_Whole_Line(for_buffer : in Gtk_Terminal_Buffer;
                           at_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                           for_printable_characters_only : boolean := true)
     return UTF8_String;
       -- Get the whole line that the at_iter is currently on.
   function Get_Line_From_Start(for_buffer : in Gtk_Terminal_Buffer;
                                up_to_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                                for_printable_characters_only : boolean:= true)
     return UTF8_String;
       -- Get the line that the at_iter is currently on, starting with the
       -- first character and going up to up_to_iter.
   function Get_Line_To_End(for_buffer : in Gtk_Terminal_Buffer;
                            starting_from_iter: in Gtk.Text_Iter.Gtk_Text_Iter;
                            for_printable_characters_only : boolean := true)
     return UTF8_String;
       -- Get the line that the at_iter is currently on, starting with the
       -- first character and going up to up_to_iter.
   
   -- The built-in Gtk.Text_Buffer Insert and Insert_at_Cursor procedures do
   -- not take into account the Overwrite status and Insert whether in Insert
   -- or in Overwrite.  Further, Gtk.Text_Buffer does not have an Overwrite or
   -- an Overwrite_at_Cursor procedure.  So we need to set up our own Insert
   -- procedures and call the relevant inherited function at the appropriate
   -- point, with overwrite handling code around it.
   procedure Insert  (into     : access Gtk_Terminal_Buffer_Record'Class;
                      at_iter  : in out Gtk.Text_Iter.Gtk_Text_Iter;
                      the_text : UTF8_String);
      --  Inserts Len bytes of Text at position Iter. If Len is -1, Text must be
      --  nul-terminated and will be inserted in its entirety. Emits the
      --  "insert-text" signal; insertion actually occurs in the default handler
      --  for the signal. Iter is invalidated when insertion occurs (because the
      --  buffer contents change), but the default signal handler revalidates it
      --  to point to the end of the inserted text.
      --  "iter": a position in the buffer
      --  "text": text in UTF-8 format
   procedure Insert_At_Cursor (into : access Gtk_Terminal_Buffer_Record'Class;
                               the_text : UTF8_String);
      --  Simply calls Gtk.Terminal.Insert, using the current cursor position
      --  as the insertion point.
      --  "text": text in UTF-8 format
   procedure Scrolled_Insert(number_of_lines : in positive; 
                         for_buffer : access Gtk_Terminal_Buffer_Record'Class; 
                         starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter);
      -- Insert the specified number of new lines at the starting_from
      -- location, scrolling down the lines below to ensure that text only
      -- moves between scroll_region_top and scroll_region_bottom, making sure
      -- that lines that scroll above or below the scroll region are discarded
      -- and that the original lines outside of the scroll region are
      -- protected.  If the scroll regions are undefined (i.e. set to 0), then
      -- this procedure does nothing other than insert a regular new line.
   procedure Scrolled_Delete(number_of_lines : in positive; 
                         for_buffer : access Gtk_Terminal_Buffer_Record'Class; 
                         starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter);
      -- Delete the specified number of lines at the starting_from
      -- location, scrolling up the lines below to ensure that text only
      -- moves between scroll_region_top and scroll_region_bottom, making sure
      -- that lines that scroll above or below the scroll region are discarded
      -- and that the original lines outside of the scroll region are
      -- protected.  If the scroll regions are undefined (i.e. set to 0), then
      -- this procedure does nothing other than delete a regular line.
   procedure Scroll_Down(number_of_lines : in positive; 
                         for_buffer : Gtk_Text_Buffer; 
                         starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter);
      -- Scroll down the specified number of lines between scroll_region_top
      -- and scroll_region_bottom, making sure that lines that scroll above or
      -- below the scroll region are discarded and that the original lines
      -- outside of the scroll region are protected.  If the scroll regions are
      -- undefined (i.e. set to 0), then this procedure does nothing.
       
   -------------------------------------------
   -- Gtk_Terminal_Buffer Private Callbacks --
   -------------------------------------------
      
   type Cb_Gtk_Terminal_Buffer_Void is access procedure
                              (Self : access Gtk_Terminal_Buffer_Record'Class);
   Signal_Changed : constant Glib.Signal_Name := "changed";
   procedure On_Changed(Self  : access Gtk_Terminal_Buffer_Record;
                        Call  : Cb_Gtk_Terminal_Buffer_Void;
                        After : Boolean := False);
             
   procedure Key_Pressed(for_buffer : access Gtk_Terminal_Buffer_Record'Class);
      -- Respond to whenever a key is pressed by the user and ensure that it
      -- is appropriately acted upon, usually by passing it on to the terminal
      -- client.  It will also inhibit editing before the current terminal
      -- input point (i.e., before the prompt).  This edition of Key_Pressed is
      -- for the main buffer, but it is called by the Key_Pressed procedure for
      -- the alternative buffer to process its key pressed events.
   procedure Alt_Key_Pressed(for_buffer : access Gtk_Text_Buffer_Record'Class);
      -- Respond to whenever a key is pressed by the user and ensure that it
      -- is appropriately acted upon, usually by passing it on to the terminal
      -- client.  It will also inhibit editing before the current terminal
      -- input point (i.e., before the prompt).  This edition of Key_Pressed is
      -- for the alternative buffer.

    -- Ideally, here we should use the Hyper Quantum dynamic_lists generic
    -- library, but that is quite specific to Hyper Quantum applications (at
    -- the moment) and this is supposed to be a general GTK library component.
    -- So we will use the Ada.Containers.Vectors library instead, even though
    -- we only need to create a simple list.
    -- This list contains a pointer to each of the buffers so that, when there
    -- is some spare idle time, the Check_For_Display_Data routine can use this
    -- list to call on each buffer's display buffer to check that there is
    -- something to display, in which case it displays it.  The display
    -- operation must be done in the main application thread and cannot be done
    -- in a task.
   package Buffer_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => Gtk_Terminal_Buffer);
   subtype buffer_array is Buffer_Arrays.vector;
   display_output_handling_buffer : buffer_array;
   
   function Check_For_Display_Data return boolean;
      -- Check that there is any data to display.  If so, then process it.
      -- This function is called as a part of the idle cycles, essentially in
      -- lieu of the ability to use a task, to take data from the system's
      -- virtual terminal (i.e. the terminal client) and process it for
      -- display.
      -- For it to work, every terminal must register it's buffer into the
      -- display_output_handling_buffer (done as a part of Spawn_Shell).

   procedure Switch_The_Light (for_buffer : access Gtk_Terminal_Buffer_Record'Class;
                               at_light_number : natural;
                               to_on : boolean := false;
                               with_status : UTF8_String := "");
      -- Check that the switch_light_cb call back procedure is assigned.  If
      -- so, execute it, otherwise, just ignore and continue processing.

   ------------------
   -- Gtk Terminal --
   ------------------
   
   task type Terminal_Input_Handling is
      -- Terminal Input Handling responds to data coming from the terminal
      -- client, that is, the system's virtual terminal.  This data gets
      -- displayed on the screen and could involve manipulation of the screen
      -- (for instance, to go into bold mode, change the font colour or other
      -- screen commands).
      entry Start(with_fd : Interfaces.C.int;
                  with_terminal_buffer : Gtk_Terminal_Buffer);
      entry Stop;
   end Terminal_Input_Handling;
   type Terminal_Handling_Access is access Terminal_Input_Handling;
  
   type Gtk_Terminal_Record is new Gtk.Scrolled_Window.Gtk_Scrolled_Window_Record
      with record
         terminal         : Gtk.Text_View.Gtk_Text_View;
         buffer           : Gtk_Terminal_Buffer;
         master_fd        : Interfaces.C.int;
         id               : natural := 0;
         title            : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
         saved_title      : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
            -- used in window manipulation (XTWINOPS) number 22 and 23
         scrollback_size  : natural := 0;
         current_font     : Pango.Font.Pango_Font_Description := Pango.Font.
                             To_Font_Description("Monospace Regular",size=>10);
         encoding         : encoding_types := utf8;
         title_callback   : Spawn_Title_Callback;
         closed_callback  : Spawn_Closed_Callback;
         term_input       : Terminal_Handling_Access;
         cols             : natural := default_columns;  -- number of columns
         rows             : natural := default_rows;  -- number of rows
      end record;
       
   function Get_Line_Number(for_terminal : Gtk.Text_View.Gtk_Text_View; 
                            at_iter : in Gtk.Text_Iter.Gtk_Text_Iter) 
   return natural;
      -- Return the current line number from the top of the screen to the
      -- specified at_iter.
     
   -------------------------------------------
   -- Gtk_Terminal_Record Private Callbacks --
   -------------------------------------------

   function Scroll_Key_Press_Check(for_terminal : access Gtk_Widget_Record'Class;
                                   for_event : Gdk.Event.Gdk_Event_Key)
   return boolean;
      -- Respond to any key press events to check if an up arrow, down arrow
      -- or, in the case of terminal emulator controlled editing, left and
      -- right arrow key has been been pressed.  If so, it gets passed to the
      -- terminal emulator and not to the buffer for processing.
      
   function Motion_Notify_CB(for_terminal_view: access Gtk_Widget_Record'Class;
                             event : Gdk_Event_Motion) return boolean;
      -- Called whenever the mouse moves inside the terminal's Gtk.Text_View,
      -- but never if it leaves the window.  It also seems to only work when
      -- the button is pressed.
--       
   -- procedure Show (the_terminal : access Gtk_Widget_Record'Class);
--       -- Respond to being shown by ensuring the cursor is visible.
      
   -- Supporting IO functions
   -- Read and Write are provided to read from and write to a Linux file handle
   -- (as the OS understands a file handle).  These procedures are needed
   -- because reading and writing to files is a little tricky, very much
   -- written for a C program rather than an Ada program.
   procedure Write(fd    : in out Interfaces.C.int; Buffer : in string);
   procedure Read (fd    : in out Interfaces.C.int; 
                   buffer: in out string; Last: out natural);
      
end Gtk.Terminal;
