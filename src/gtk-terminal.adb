-----------------------------------------------------------------------
--                                                                   --
--                          G T K . T E R M                          --
--                                                                   --
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
--  General Public Licence distributed with  Cell Writer.            --
--  If  not,  write to the Free Software  Foundation,  51  Franklin  --
--  Street, Fifth Floor, Boston, MA 02110-1301, USA.                 --
--                                                                   --
-----------------------------------------------------------------------
pragma Style_Checks (Off);
pragma Warnings (Off, "*is already use-visible*");
-- with System;
-- with Interfaces.C, Interfaces.C.Strings;
-- with Ada.Containers.Vectors;
-- with Glib;                    use Glib;
-- with Glib.Spawn;              use Glib.Spawn;
-- with Glib.Cancellable;        use Glib.Cancellable;
-- with Glib.Error;
-- with Gdk.Event;
-- with Gtk.Editable;            use Gtk.Editable;
-- with Gtk.Widget;              use Gtk.Widget;
-- with Gtk.Viewport;            use Gtk.Viewport;
-- with Gtk.Scrolled_Window;     use Gtk.Scrolled_Window;
-- with Gtk.Text_View;           use Gtk.Text_View;
-- with Gtk.Text_Buffer;         use Gtk.Text_Buffer;
-- with Gtk.Text_Iter;
-- with Gtk.Text_Tag_Table;
-- with Gtk.Text_Mark;
-- with Gdk.RGBA;                use Gdk.RGBA;
-- with Pango.Font;              use Pango.Font;
-- with Gtkada.Types;            use Gtkada.Types;
with Ada.Wide_Text_IO;
with Ada.Characters.Conversions;
with Ada.Strings.UTF_Encoding.Wide_Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Characters.Latin_1;
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with GNAT.Strings;
with Glib.Values;
with Glib.Properties;
with Gdk.Color;
with Gdk.Types, Gdk.Types.Keysyms;
with Gdk.Rectangle;
with Gtk.Enums;
with Gtk.Window;
with Gtk.Text_Tag;
with Gtk.Arguments;              use Gtk.Arguments;
with Gtk.CSS_Provider, Gtk.Style_Context, Gtk.Style_Provider;
with Gtk.Terminal.CInterface;
with GtkAda.Bindings;            use GtkAda.Bindings;
with Error_Log;  ----------------------------*********DELETE ME*********----------------------------

package body Gtk.Terminal is

   -- type Gtk_Terminal_Buffer_Record is new Gtk_Text_Buffer_Record with
   --    record
   --       master_fd           : Interfaces.C.int;
   --       child_pid           : Glib.Spawn.GPid;
   --       child_name          : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
   --       line_number         : line_numbers := unassigned_line_number;
   --                                   -- current row number in the buffer
   --       anchor_point        : natural := 0;
   --               -- placed at the end of the command prompt on line_number line
   --       waiting_for_response: boolean := false;  -- from the terminal
   --       in_response         : boolean := false; -- from the terminal
   --       just_wrapped        : boolean := false; -- is output at next line?
   --       -- Escape sequences alter the display of text, so need to be trapped
   --       -- and acted upon.
   --       -- Hold escape sequences over multiple display characters by storing
   --       -- in a buffer.  if the first character is the Escape character, then
   --       -- processing it, otherwise processing normal characters.
   --       escape_sequence       : escape_string := (escape_str_range => ' ');
   --       escape_position       : escape_str_range := escape_str_range'First;
   --       in_esc_sequence          : boolean := false
   --       cursor_is_visible        : boolean := true;
   --        -- Escape sequence flags
   --       bracketed_paste_mode     : boolean := false;
   --       alternative_screen_buffer: boolean := false;
   --       reporting_focus_enabled  : boolean := false;
   --       saved_cursor_pos         : Gtk.Text_Mark.Gtk_Text_Mark;
   --       -- Escape character handling
   --       markup_text         : Gtkada.Types.Chars_Ptr := Null_Ptr;
   --       modifier_array      : font_modifier_array := (others => 0);
   --       background_colour   : Gdk.RGBA.Gdk_RGBA;
   --       text_colour         : Gdk.RGBA.Gdk_RGBA;
   --       highlight_colour    : Gdk.RGBA.Gdk_RGBA;
   --        -- terminal display buffer handling
   --       input_monitor       : input_monitor_type_access;
   --       parent              : Gtk.Text_View.Gtk_Text_View;
   --       alt_buffer          : Gtk_Text_Buffer;
   --    end record;
   -- type Gtk_Terminal_Buffer is access all Gtk_Terminal_Buffer_Record'Class;
   -- Encoding_Error : exception;
   -- type Gtk_Terminal_Record is new Gtk_Scrolled_Window_Record with 
   --    record
   --       terminal         : Gtk.Text_View.Gtk_Text_View;
   --       buffer           : Gtk_Terminal_Buffer;
   --       master_fd        : Interfaces.C.int;
   --       scrollback_size  : natural := 0;
   --       current_font     : Pango.Font.Pango_Font_Description := Pango.Font.
   --                          To_Font_Description("Monospace Regular",size=>10);
   --       encoding         : encoding_types := utf8;
   --       title_callback   : Spawn_Title_Callback
   --       closed_callback  : Spawn_Closed_Callback;
   --       cancellable      : Glib.Cancellable.Gcancellable;
   --       term_input       : Terminal_Handling_Access;
   --       cols             : natural := 80;  -- default number of columns
   --       rows             : natural := 25;  -- default number of rows
   -- end record;
   -- type Gtk_Terminal is access all Gtk_Terminal_Record'Class;

   procedure Set_The_Error_Handler(to : error_handler) is
   begin
      the_error_handler := to;
   end Set_The_Error_Handler;

   procedure Handle_The_Error(the_error : in integer;
                              error_intro, error_message : in wide_string) is
       -- For the error display, if the_error_handler is assigned, then call
       -- that function with the three parameters, otherwise formulate an
       -- output and write it out to Standard Error using the Write procedure.
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
      
   ------------------
   -- Constructors --
   ------------------
   
   function Gtk_Terminal_New return Gtk_Terminal is
      the_terminal : Gtk_Terminal;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Gtk_Terminal_New: Start.");
      Gtk.Terminal.Gtk_New(the_terminal);
      return the_terminal;
   end Gtk_Terminal_New;

   function Gtk_Terminal_New_With_Buffer (buffer : UTF8_String) 
   return gtk_terminal is
      --  Creates a new terminal with the specified text buffer as the preset
      --  history.
      --  "buffer": The buffer to use for the new Gtk.Terminal.Gtk_Terminal. It
      --  contains the previous session's data to be preset as the history.
      the_terminal : Gtk_Terminal;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Gtk_Terminal_New_With_Buffer: Start.");
      Gtk.Terminal.Gtk_New_With_Buffer (the_terminal, buffer);
      return the_terminal;
   end Gtk_Terminal_New_With_Buffer;

   procedure Gtk_New (the_terminal : out Gtk_Terminal) is
      --  Create a new terminal.
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Gtk_New: Start.");
      Gtk_New_With_Buffer(the_terminal, "");
   end Gtk_New;

   procedure Gtk_New_With_Buffer (the_terminal : out Gtk_Terminal;
                                  buffer    : UTF8_String) is
      ip_source : GLib.Main.G_Source_ID;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Gtk_New_With_Buffer: Start.");
      the_terminal := new Gtk_Terminal_Record;
      Gtk.Terminal.Initialise_With_Buffer (the_terminal, buffer);
      if not service_initialised
      then  -- Set up the I/O monitoring service
         -- The following should be done only once, to key the Gtk.Terminal into
         -- the service cycle
         Buffer_Arrays.Clear(display_output_handling_buffer);
         ip_source := GLib.Main.Timeout_Add(250, Check_For_Display_Data'access);
         GLib.Main.Set_Priority(GLib.Main.Find_Source_By_ID(ip_source), 
                                GLib.Main.Priority_Low);
         service_initialised := true;
      end if;
   end Gtk_New_With_Buffer;
   
   procedure Initialize (the_terminal : access Gtk_Terminal_Record'Class) is
      --  Create a new terminal.
      --  Initialise does nothing if the object was already created with another
      --  call to Initialise* or G_New.
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialize: Start.");
      if not the_terminal.Is_Created
      then  -- create the terminal, its buffer and initialise
         -- First up, call the inherited initialise operation
         Gtk.Scrolled_Window.Initialize(Gtk_Scrolled_Window(the_terminal));
         -- Set_Min_Content_Height(the_terminal, 1);
         Set_Policy(the_terminal, 
                    Gtk.Enums.Policy_Automatic, Gtk.Enums.Policy_Always);
         Gtk.Text_View.Gtk_New(view => the_terminal.terminal);
         Gtk_New(the_terminal.buffer);
         Gtk.Text_View.Set_Buffer(view => the_terminal.terminal,
                                  buffer => the_terminal.buffer);
         the_terminal.buffer.parent := the_terminal.terminal;
         -- Define the border size (in pixels)
         Set_Left_Margin  (the_terminal.terminal, 3);
         Set_Right_Margin (the_terminal.terminal, 2);
         Set_Top_Margin   (the_terminal.terminal, 3);
         Set_Bottom_Margin(the_terminal.terminal, 3);
         -- Insert the terminal into the scrolled window (creating a
         -- view port on the way through only if necessary)
         Add(the_terminal, the_terminal.terminal);
         On_Key_Press_Event(self=>the_terminal.terminal, 
                            call=>Scroll_Key_Press_Check'access, after=>false);
         -- Give an initial default dimension of nowrap_size (1000) characters
         -- wide x 25 lines (i.e. no wrap)
         Set_Size (terminal => the_terminal, columns => nowrap_size, rows => 25);
         -- Create the alternative buffer (as per xterm)
         Gtk_New(the_terminal.buffer.alt_buffer);
         -- Ensure the terminal's cursor is visible when it is shown
      --    On_Show(self=>the_terminal.terminal, call=>Show'access, after=>false);
      end if;
   end Initialize;
   -- procedure Initialise (The_Terminal : access Gtk_Terminal_Record'Class)
   -- renames Initialize;
   
   procedure Initialise_With_Buffer
      (the_terminal : access Gtk_Terminal_Record'Class; buffer: UTF8_String) is
   --  Create a new terminal with the specified text buffer as the preset
   --  history.
   --  Initialise_With_Buffer does nothing if the object was already created
   --  with another call to Initialise* or G_New.
   --  "buffer": The buffer to load for the new Gtk.Terminal.Gtk_Terminal.  It
   --  contains the previous session's data to be preset as the history. 
      cr_char : constant character := Ada.Characters.Latin_1.CR;
      lf_char : constant character := Ada.Characters.Latin_1.LF;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialise_With_Buffer: Start.");
      Initialise(the_terminal);
      -- Set the terminal up with the specified buffer as its history.
      if buffer'Length > 1 or else 
         (buffer'Length = 1 and then buffer(buffer'First) /= character'Val(0))
      then  --  It is not a null buffer or an empty buffer
         Feed(the_terminal, data => buffer & cr_char & lf_char);
      --    -- Now ensure the cursor is visible at the end of the buffer  -- THIS DIDN'T WORK
      --    declare
      --       use Gtk.Text_Iter;
      --       end_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      --       res      : boolean;
      --    begin
      --       Get_End_Iter(the_terminal.buffer, end_iter);
      --       Backward_Visible_Cursor_Position(end_iter, res);
      --       Forward_Visible_Cursor_Position(end_iter, res);
      --       Place_Cursor(the_terminal.buffer, end_iter);
      --    end;
      end if;
   end Initialise_With_Buffer;

   function Get_Type return Glib.GType is
      the_type : Glib.GType;
   begin
      the_type := Glib.GType(Gtk.Scrolled_Window.Get_Type);
      return the_type;
   end Get_Type;
   
   procedure Gtk_New (the_buffer : out Gtk_Terminal_Buffer;
                      table : Gtk.Text_Tag_Table.Gtk_Text_Tag_Table := null) is
      --  Create a new terminal text buffer.
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Gtk_New (the_buffer): Start.");
      the_buffer := new Gtk_Terminal_Buffer_Record;
      Gtk.Terminal.Initialise(the_buffer, table);
   end Gtk_New;

   procedure Initialize(the_buffer : access Gtk_Terminal_Buffer_Record'Class;
                        Table : Gtk.Text_Tag_Table.Gtk_Text_Tag_Table := null)
   is
      --  Create a new terminal text buffer.
      --  Initialise does nothing if the object was already created with another
      --  call to Initialise* or G_New.
      --  "table": a tag table, or null to create a new one
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Initialize (the_buffer): Start.");
      if not the_buffer.Is_Created
      then  -- create the terminal text buffer and initialise
         -- First up, call the inherited initialise operation
         Gtk.Text_Buffer.Initialize(Gtk_Text_Buffer(the_buffer));
         -- Set up the character handler
         On_Changed(self=> the_buffer, 
                    call=> Key_Pressed'access, after => false);
      end if;
   end Initialize;
   -- procedure Initialise(the_buffer: access Gtk_Terminal_Buffer_Record'Class;
   --                      table  Gtk.Text_Tag_Table.Gtk_Text_Tag_Table:= null)
   -- renames Initialize;

   procedure Finalize(the_terminal : access Gtk_Terminal_Record'Class) is
   begin
      -- Clean up the terminal first
      Error_Log.Debug_Data(at_level => 9, with_details => "Finalize: Start.");
      Free(the_terminal.buffer.child_name);
      Free(the_terminal.buffer.markup_text);
      Free(the_terminal.title);
      null;
      -- Finally, call up the inherited finalise operation (if any)
      null;  -- there's none
   end Finalize;
   -- procedure Finalise(the_terminal : access Gtk_Terminal_Record'Class)
   --    renames Finalize;
 
   ---------------
   -- Callbacks --
   ---------------

   -- To make call-backs work, the GtkAda call-back is called by the C GTK
   -- function, then that GTKADA call-back calls the C GTK call-back.

   function Cb_To_Address is new Ada.Unchecked_Conversion
     (Cb_Gtk_Terminal_Buffer_Void, System.Address);
   function Address_To_Cb is new Ada.Unchecked_Conversion
     (System.Address, Cb_Gtk_Terminal_Buffer_Void);

   procedure Connect(Object  : access Gtk_Terminal_Buffer_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Buffer_Void;
                     After   : Boolean);

   procedure On_Changed(Self  : access Gtk_Terminal_Buffer_Record;
                        Call  : Cb_Gtk_Terminal_Buffer_Void;
                             After : Boolean := False)
   is
   begin
      Connect (Self, "changed" & ASCII.NUL, Call, After);
   end On_Changed;

   procedure Marsh_Gtk_Terminal_Buffer_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address);
   pragma Convention (C, Marsh_Gtk_Terminal_Buffer_Void);
   
   procedure Connect(Object  : access Gtk_Terminal_Buffer_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Buffer_Void;
                     After   : Boolean)
   is
   begin
      Unchecked_Do_Signal_Connect
         (Object      => Object,
         C_Name      => C_Name,
         Marshaller  => Marsh_Gtk_Terminal_Buffer_Void'Access,
         Handler     => Cb_To_Address (Handler),--  Set in the closure
         After       => After);
   end Connect;
   
   procedure Marsh_Gtk_Terminal_Buffer_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address)
   is
      pragma Unreferenced (Return_Value, N_Params, Invocation_Hint, User_Data);
      H   : constant Cb_Gtk_Terminal_Buffer_Void := 
                         Address_To_Cb (Get_Callback (Closure));
      Obj : constant Gtk_Terminal_Buffer := 
                         Gtk_Terminal_Buffer (Unchecked_To_Object (Params, 0));
   begin
      H (Obj);
      exception 
         when E : others => Process_Exception (E);
   end Marsh_Gtk_Terminal_Buffer_Void;

   function Cb_To_Address is new Ada.Unchecked_Conversion
     (Cb_Gtk_Terminal_Void, System.Address);
   function Address_To_Cb is new Ada.Unchecked_Conversion
     (System.Address, Cb_Gtk_Terminal_Void);

   procedure Connect(Object  : access Gtk_Terminal_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Void;
                     After   : Boolean);

   procedure On_Show(Self  : access Gtk_Terminal_Record;
                     Call  : Cb_Gtk_Terminal_Void;
                     After : Boolean := False)
   is
   begin
      Connect (Self, "show" & ASCII.NUL, Call, After);
   end On_Show;

   procedure Marsh_Gtk_Terminal_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address);
   pragma Convention (C, Marsh_Gtk_Terminal_Void);
   
   procedure Connect(Object  : access Gtk_Terminal_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Void;
                     After   : Boolean)
   is
   begin
      Unchecked_Do_Signal_Connect
         (Object      => Object,
         C_Name      => C_Name,
         Marshaller  => Marsh_Gtk_Terminal_Void'Access,
         Handler     => Cb_To_Address (Handler),--  Set in the closure
         After       => After);
   end Connect;
   
   procedure Marsh_Gtk_Terminal_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address)
   is
      pragma Unreferenced (Return_Value, N_Params, Invocation_Hint, User_Data);
      H   : constant Cb_Gtk_Terminal_Void := 
                         Address_To_Cb (Get_Callback (Closure));
      Obj : constant Gtk_Terminal := 
                         Gtk_Terminal (Unchecked_To_Object (Params, 0));
   begin
      H (Obj);
      exception 
         when E : others => Process_Exception (E);
   end Marsh_Gtk_Terminal_Void;

   function Cb_To_Address is new Ada.Unchecked_Conversion
     (Cb_Gtk_Terminal_Allocation_Void, System.Address);
   function Address_To_Cb is new Ada.Unchecked_Conversion
     (System.Address, Cb_Gtk_Terminal_Allocation_Void);

   procedure Connect(Object  : access Gtk_Terminal_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Allocation_Void;
                     After   : Boolean);

   procedure On_Size_Allocate(Self  : access Gtk_Terminal_Record;
                              Call  : Cb_Gtk_Terminal_Allocation_Void;
                              After : Boolean := False)
   is
   begin
      Connect (Self, "size-allocate" & ASCII.NUL, Call, After);
   end On_Size_Allocate;

   procedure Marsh_Gtk_Terminal_Allocation_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address);
   pragma Convention (C, Marsh_Gtk_Terminal_Allocation_Void);
   
   procedure Connect(Object  : access Gtk_Terminal_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Allocation_Void;
                     After   : Boolean)
   is
   begin
      Unchecked_Do_Signal_Connect
         (Object      => Object,
         C_Name      => C_Name,
         Marshaller  => Marsh_Gtk_Terminal_Allocation_Void'Access,
         Handler     => Cb_To_Address (Handler),--  Set in the closure
         After       => After);
   end Connect;
   
   procedure Marsh_Gtk_Terminal_Allocation_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address)
   is
      pragma Unreferenced (Return_Value, N_Params, Invocation_Hint, User_Data);
      H   : constant Cb_Gtk_Terminal_Allocation_Void := 
                         Address_To_Cb (Get_Callback (Closure));
      Obj : constant Gtk_Terminal := 
                         Gtk_Terminal (Unchecked_To_Object (Params, 0));
   begin
      H (Obj);
      exception 
         when E : others => Process_Exception (E);
   end Marsh_Gtk_Terminal_Allocation_Void;

   function Scroll_Key_Press_Check(for_terminal : access Gtk_Widget_Record'Class;
                                   for_event : Gdk.Event.Gdk_Event_Key)
   return boolean is
      -- Respond to any key press events to check if an up arrow, down arrow
      -- or, in the case of terminal emulator controlled editing, left and
      -- right arrow and backspace key has been been pressed.  If so, it gets
      -- passed to the terminal emulator and not to the buffer for processing.
      use Gdk.Event, Gdk.Types, Gdk.Types.Keysyms;
      esc_start : constant string(1..3) := Ada.Characters.Latin_1.Esc & "[ "; 
      the_term  : Gtk_Text_View := Gtk_Text_View(for_terminal);
      the_terminal : Gtk_Terminal := Gtk_Terminal(Get_Parent(the_term));
      the_key   : string(1..3) := esc_start;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: key = " & for_event.keyval'Wide_Image & ".");
      case for_event.keyval is
         when GDK_Up => 
            the_key(3) := 'A';
         when GDK_Down =>
            the_key(3) := 'B';
         when GDK_Home =>
            if not the_terminal.buffer.use_buffer_editing
            then
               the_key(3) := 'G';
            end if;
         when GDK_End =>
            if not the_terminal.buffer.use_buffer_editing
            then
               the_key(3) := '4';
            end if;
         when GDK_Left =>
            if the_terminal.buffer.history_review or
               not the_terminal.buffer.use_buffer_editing
            then
               the_key(3) := 'D';
            end if;
         when GDK_Right =>
            if the_terminal.buffer.history_review or
               not the_terminal.buffer.use_buffer_editing
            then
               the_key(3) := 'C';
            end if;
         when GDK_BackSpace =>  --16#FF08# / 10#65288#
            the_key(1) := Ada.Characters.Latin_1.BS;
            the_key(2) := ' ';
         when others =>
            null;
      end case;
      if the_terminal.buffer.bracketed_paste_mode and the_key /= esc_start
      then  -- at command prompt: we have set it to pass to the write routine
         Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: at cmd prompt and sending '" & Ada.Characters.Conversions.To_Wide_String(the_key) & "'.  Set the_terminal.buffer.history_review to true and Set_Overwrite(the_terminal.terminal) to true.");
         if for_event.keyval = GDK_BackSpace
         then  -- Actually a single back-space character
            Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
         else  -- standard sequence
            Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key);
         end if;
         if for_event.keyval = GDK_Up or for_event.keyval = GDK_Down
         then  -- these keys are about starting/continuing history review
            the_terminal.buffer.history_review := true;
            the_terminal.buffer.switch_light_cb(3, true);
            Set_Overwrite(the_terminal.terminal, true);
         end if;
         return true;
      elsif (not the_terminal.buffer.bracketed_paste_mode) and the_key /= esc_start
      then  -- in an app: we have set it to pass to the write routine
         Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Key_Press_Check: in app and sending '" & Ada.Characters.Conversions.To_Wide_String(the_key) & "'.");
         if for_event.keyval = GDK_End
         then  -- Actually a 4 character non-standard sequence
            Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key & '~');
         elsif for_event.keyval = GDK_BackSpace
         then  -- Actually a single back-space character
            Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key(1..1));
         else  -- standard sequence
            Write(fd => the_terminal.buffer.master_fd, Buffer=> the_key);
         end if;
         return true;
      else  -- at command prompt and not a terminal history action key press
         return false;
      end if;
   end Scroll_Key_Press_Check;
-- 
   -- procedure Show (the_terminal : access Gtk_Widget_Record'Class) is  -- DOESN'T WORK
--       -- Respond to being shown by ensuring the cursor is visible.
      -- the_term      : Gtk_Text_View := Gtk_Text_View(the_terminal);
      -- this_terminal : Gtk_Terminal := Gtk_Terminal(Get_Parent(the_term));
   --    res           : boolean;
--    begin
--       Set_Cursor_Visible(this_terminal.terminal, true);
--       res := Place_Cursor_Onscreen(this_terminal.terminal);
--    end Show;

   -------------------------
   -- Terminal Management --
   -------------------------

   function UTF8_Length(of_string : in UTF8_String) return natural is
       -- get the absolute string length (i.e. including parts of characters)
   begin
      return Natural(String(of_string)'Length);
   end UTF8_Length;
   
   function As_String(the_number : in natural) return UTF8_String is
       -- provide the (non-negative) number as a compact string
      number: UTF8_String := the_number'Image;
   begin
      return number(number'First+1..number'Last);
   end As_String;
   
   function Line_Length(for_buffer : in Gtk_Terminal_Buffer;
                        at_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                        for_printable_characters_only : boolean := true)
     return natural is
       -- Get the line length for the line that the at_iter is currently on.
   begin
      return UTF8_Length(Get_Line_Length(for_buffer, at_iter, 
                                         for_printable_characters_only));
   end Line_Length;

   function Get_Line_Length(for_buffer : in Gtk_Terminal_Buffer;
                            at_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                            for_printable_characters_only : boolean := true)
     return UTF8_String is
       -- Get the whole line that the at_iter is currently on.
      use Gtk.Text_Iter;
      line_start : Gtk.Text_Iter.Gtk_Text_Iter;
      line_end   : Gtk.Text_Iter.Gtk_Text_Iter;
      result     : boolean;
      line_number: natural;
   begin
      -- Get pointers to the start and end of the current line
      line_start := at_iter;
      line_number := natural(Get_Line(line_start));
      Backward_Line(line_start, result);
      if line_number > 0 and result
      then  -- was not on the first line
         Forward_Line(line_start, result);
      end if;
      line_end := at_iter;
      Forward_To_Line_End(line_end, result);
      -- Calculate and return the line between iterators
      return Get_Slice(for_buffer, line_start, line_end, 
                       not for_printable_characters_only);
   end Get_Line_Length;
       
   function Get_Line_From_Start(for_buffer : in Gtk_Terminal_Buffer;
                                up_to_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                                for_printable_characters_only : boolean:= true)
     return UTF8_String is
       -- Get the line that the at_iter is currently on, starting with the
       -- first character and going up to up_to_iter.
      use Gtk.Text_Iter;
      line_start : Gtk.Text_Iter.Gtk_Text_Iter;
      result     : boolean;
      line_number: natural;
   begin
      -- Get pointers to the start and end of the current line
      line_start := up_to_iter;
      line_number := natural(Get_Line(line_start));
      Backward_Line(line_start, result);
      if line_number > 0 and result
      then  -- was not on the first line
         Forward_Line(line_start, result);
      end if;
      -- Calculate and return the line between iterators
      return Get_Slice(for_buffer, line_start, up_to_iter, 
                       not for_printable_characters_only);
   end Get_Line_From_Start;
       
   function Get_Line_To_End(for_buffer : in Gtk_Terminal_Buffer;
                            starting_from_iter: in Gtk.Text_Iter.Gtk_Text_Iter;
                            for_printable_characters_only : boolean := true)
     return UTF8_String is
       -- Get the line that the at_iter is currently on, starting with the
       -- first character and going up to up_to_iter.
      use Gtk.Text_Iter;
      line_end   : Gtk.Text_Iter.Gtk_Text_Iter;
      result     : boolean;
   begin
      -- Get pointers to the start and end of the current line
      line_end := starting_from_iter;
      Forward_To_Line_End(line_end, result);
      -- Calculate and return the length of the line between iterators
      return Get_Slice(for_buffer, starting_from_iter, line_end, 
                       not for_printable_characters_only);
   end Get_Line_To_End;
   
   function Get_Line_Number(for_terminal : Gtk.Text_View.Gtk_Text_View; 
                            at_iter : in Gtk.Text_Iter.Gtk_Text_Iter) 
   return natural is
      -- Return the current line number from the top of the screen to the
      -- specified at_iter.
      use Gtk.Text_Iter;
      result      : boolean;
      buf_x       : Glib.Gint := 0;
      buf_y       : Glib.Gint := 0;
      line_number : natural;
      first_line  : aliased Gtk.Text_Iter.Gtk_Text_Iter;
      current_line: Gtk.Text_Iter.Gtk_Text_Iter := at_iter;
   begin
      -- Get the top left hand corner point in the buffer
      Window_To_Buffer_Coords(for_terminal, Gtk.Enums.Text_Window_Text, 0, 0, 
                              buf_x, buf_y);
      result:= Get_Iter_At_Position(for_terminal, first_line'access, null, 
                                 buf_x, buf_y);
       -- Get the start of the current line
      line_number := natural(Get_Line(current_line));
      Backward_Line(current_line, result);
      if line_number > 0 and result
      then  -- was not on the first line, so move back to the line
         Forward_Line(current_line, result);  -- now at first character
      end if;
      -- Move the first_line pointer until it matches the current line
      line_number := 1;
      while Compare(first_line, current_line) < 0 loop
         Forward_Line(first_line, result);
         if result then  -- not at the very end
            line_number := line_number + 1;
         end if;
      end loop;
      return line_number;
   end Get_Line_Number;
   
   -- The built-in Gtk.Text_Buffer Insert and Insert_at_Cursor procedures do
   -- not take into account the Overwrite status and Insert whether in Insert
   -- or in Overwrite.  Further, Gtk.Text_Buffer does not have an Overwrite or
   -- an Overwrite_at_Cursor procedure.  So we need to set up our own Insert
   -- procedures and call the relevant inherited function at the appropriate
   -- point, with overwrite handling code around it.
   procedure Insert  (into     : access Gtk_Terminal_Buffer_Record'Class;
                      at_iter  : in out Gtk.Text_Iter.Gtk_Text_Iter;
                      the_text : UTF8_String) is
      --  Inserts Len bytes of Text at position Iter. If Len is -1, Text must be
      --  nul-terminated and will be inserted in its entirety. Emits the
      --  "insert-text" signal; insertion actually occurs in the default handler
      --  for the signal. Iter is invalidated when insertion occurs (because the
      --  buffer contents change), but the default signal handler revalidates it
      --  to point to the end of the inserted text.
      --  "iter": a position in the buffer
      --  "text": text in UTF-8 format
      use Gtk.Text_Iter;
      buffer   : Gtk.Text_Buffer.Gtk_Text_Buffer;
      end_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      result   : boolean;
   begin
      if into.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := into.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(into);
      end if;
      Get_End_Iter(buffer, end_iter);
      if Get_Overwrite(into.parent) and then  -- if in 'overwrite' mode
         Compare(at_iter, end_iter) < 0
      then  -- delete the character at the iter before inserting the new one
         end_iter := at_iter;
         Forward_Char(end_iter, result);
         Delete(buffer, at_iter, end_iter);
      end if;
      -- Now call the inherited Insert operation
      Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, the_text);
   end Insert;
      
   procedure Insert_At_Cursor (into : access Gtk_Terminal_Buffer_Record'Class;
                               the_text : UTF8_String) is
      --  Simply calls Gtk.Terminal.Insert, using the current cursor position
      --  as the insertion point.
      --  "text": text in UTF-8 format
      use Gtk.Text_Iter;
      cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
   begin
      if into.alternative_screen_buffer
       then  -- using the alternative buffer for display
         Get_Iter_At_Mark(into.alt_buffer, cursor_iter, 
                          Get_Insert(into.alt_buffer));
      else  -- using the main buffer for display
         Get_Iter_At_Mark(into, cursor_iter, Get_Insert(into));
      end if;
      Gtk.Terminal.Insert(into, at_iter => cursor_iter, the_text => the_text);
   end Insert_At_Cursor;
   
   -- buffer_length : constant positive := 255;
   -- type buf_index is mod buffer_length;
   -- type buffer_type is array (buf_index) of wide_character;
   -- max_utf_char_count : constant positive := 4;
   -- subtype utf_chars is positive range 1..max_utf_char_count;
   protected body input_monitor_type is
      entry Put(the_character : in character) when count < buffer_length is
         use Ada.Strings.UTF_Encoding.Wide_Strings, Ada.Characters.Conversions;
      begin
         if char_pos < max_utf_char_count and then
            character'Pos(the_character) >= 2#1111_0000#
         then  -- it's the start of of a UTF8 string
            reqd_chr := 4;
            char(char_pos) := the_character;
            char_pos := char_pos + 1;
         elsif char_pos < max_utf_char_count and then
            character'Pos(the_character) >= 2#1110_0000#
         then  -- it's the start of a UTF8 string
            reqd_chr := 3;
            char(char_pos) := the_character;
            char_pos := char_pos + 1;
         elsif char_pos < max_utf_char_count and then
            character'Pos(the_character) >= 2#1100_0000#
         then  -- it's the start of a UTF8 string
            reqd_chr := 2;
            char(char_pos) := the_character;
            char_pos := char_pos + 1;
         elsif (char_pos > 1 and char_pos < reqd_chr) and then
            character'Pos(the_character) >= 2#1000_0000#
         then  -- it is in the middle of a UTF8 string
            char(char_pos) := the_character;
            char_pos := char_pos + 1;
         elsif (char_pos > 1 and char_pos >= reqd_chr) and then
            character'Pos(the_character) >= 2#1000_0000#
         then  -- it is at the end of a UTF8 string
            char(char_pos) := the_character;
            result := Decode(char(1..char_pos));
            buffer(tail) := result(1);
            tail := tail + 1;
            count := count + 1;
            -- reset UTF8 string counters
            char_pos := 1;
            reqd_chr := 1;
         else  -- it is an ASCII character
            buffer(tail) := To_Wide_Character(the_character);
            tail := tail + 1;
            count := count + 1;
         end if;
      end Put;
      entry Get(the_character : out wide_character) when count > 0 is
         use Ada.Strings.UTF_Encoding.Wide_Strings;
      begin
         the_character := buffer(head);
         head := head + 1;
         count := count - 1;
      end Get;
      function Has_Data return boolean is
      begin
         return count > 0;
      end Has_Data;
      -- private
      --    buffer  : buffer_type;
      -- char    : string(utf_chars'range);
      -- char_pos: utf_chars := 1;
      -- reqd_chr: utf_chars := 1;
      -- head,
      -- tail    : buf_index := 0;
      -- count   : natural range 0..buffer_length := 0;
      -- result  : wide_string(1..1);
   end input_monitor_type;
   -- type input_monitor_type_access is access input_monitor_type;

   procedure Process(the_input : in UTF8_String; for_buffer : Gtk_Terminal_Buffer)
    is separate;
    
   function Check_For_Display_Data return boolean is
      -- Check that there is any data to display.  If so, then process it.
      -- This function is called as a part of the idle cycles, essentially in
      -- lieu of the ability to use a task, to take data from the system's
      -- virtual terminal (i.e. the terminal client) and process it for
      -- display.
      -- For it to work, every terminal must register it's buffer into the
      -- display_output_handling_buffer (done as a part of Spawn_Shell).
      use Buffer_Arrays;
      use Ada.Strings.UTF_Encoding.Wide_Strings;
      the_buffer    : Gtk_Terminal_Buffer;
      the_character : wide_string(1..1);
   begin
      if not Is_Empty(display_output_handling_buffer) then
         for cntr in display_output_handling_buffer.First_Index .. 
                     display_output_handling_buffer.Last_Index loop
            the_buffer := display_output_handling_buffer(cntr);
            while the_buffer.input_monitor.Has_Data loop
               -- Clear the data waiting for display
               the_buffer.input_monitor.Get(the_character(1));
               Process(the_input => Encode(the_character), 
                       for_buffer => the_buffer);
            end loop;
         end loop;
      end if;
      return true;  -- always, as otherwise it is removed from the event queue.
   end Check_For_Display_Data;

   procedure Read (fd: in out Interfaces.C.int; 
                   buffer: in out string; Last: out natural) is
      use Interfaces.C, Interfaces.C.Strings, Gtk.Terminal.CInterface;
      in_buffer : Interfaces.C.Strings.chars_ptr := New_String (Buffer);
      len       : constant natural := Buffer'Length;
      res       : Interfaces.C.int;
   begin
      if fd = -1 then
         Handle_The_Error(the_error  => 7, 
                          error_intro=> "Read(fd): File error",
                          error_message => "File not opened.");
         buffer := (buffer'First..Buffer'Last => ' ');
         Last := 0;
         Free (in_buffer);
         raise Terminal_IO_Error;
      end if;
      res := C_Read(fd => fd, data => in_buffer, length => int(len));
      if res <= -1 or res > int(len) then
         Handle_The_Error(the_error  => 8, 
                          error_intro=> "Read(fd): File error",
                          error_message => "Read failed.");
         buffer := (buffer'First..Buffer'Last => ' ');
         raise Terminal_IO_Error;
      elsif res = 0 then
         Last := 0;
      else
         declare
            result : string := Interfaces.C.Strings.Value(in_buffer);
            str_len: natural:= Natural(res);
         begin
            if result'Last < result'First + str_len - 1 then
               str_len := result'Last - result'First;
            end if;
            Buffer(Buffer'First .. Buffer'First+str_len-1) := 
                                result(result'First .. result'First+str_len-1);
         end;
         Last := buffer'First  + Natural(res);
      end if;
      Free (in_buffer);
   end Read;

   procedure Write(fd   : in out Interfaces.C.int; Buffer : in string) is
      use Interfaces.C, Interfaces.C.Strings, Gtk.Terminal.CInterface;
      out_buffer: Interfaces.C.Strings.chars_ptr:=New_String(Buffer&ASCII.NUL);
      len       : constant natural := Buffer'Length;
      res       : Interfaces.C.int;
   
   begin
      if fd <= 0 then
         Handle_The_Error(the_error  => 9, 
                          error_intro=> "Write(fd): File error",
                          error_message => "File not opened.");
         Free (out_buffer);
         raise Terminal_IO_Error;
      end if;
   
      Error_Log.Debug_Data(at_level => 9, with_details => "Write: sending to system's VT '" & Ada.Characters.Conversions.To_Wide_String(Buffer) & "'.");
      res := C_Write(fd => fd, data => out_buffer, len => Interfaces.C.int(len));
      Free (out_buffer);
   
      if res <= -1 then
         Handle_The_Error(the_error  => 10, 
                          error_intro=> "Write(fd): Write error",
                          error_message => "Write Failed  with length " &
                                        Interfaces.C.int'Wide_Image(-res)&".");
         raise Terminal_IO_Error;
      end if;
   end Write;

   task body Terminal_Input_Handling is
      use Gtk.Terminal.CInterface, Interfaces.C, GLib;
      -- Terminal Input Handling responds to data coming from the terminal
      -- client, that is, the system's virtual terminal.  This data gets
      -- displayed on the screen and could involve manipulation of the screen
      -- (for instance, to go into bold mode, change the font colour or other
      -- screen commands).
      char_wait_time : constant Interfaces.C.Int := 250; -- msec
      master_fd : Interfaces.C.int;
      quit_loop : boolean := false;
      the_buffer: Gtk_Terminal_Buffer;
      input     : string(1..1) := " ";  -- to start with
      read_len  : natural;
      the_fds   : Gtk.Terminal.CInterface.poll_fd_access;
      nfds      : constant Gtk.Terminal.CInterface.nfds_t := 1;
      res       : Interfaces.C.int;
   begin
      accept Start(with_fd : Interfaces.C.int;
                   with_terminal_buffer : Gtk_Terminal_Buffer) do
         master_fd := with_fd;
         Error_Log.Debug_Data(at_level => 9, with_details => "Terminal_Input_Handling: Start - master_fd = " & master_fd'wide_image & ".");
         the_buffer := with_terminal_buffer;
      end Start;
      -- Set up the monitor value
      the_fds := new Gtk.Terminal.CInterface.poll_fd;
      the_fds.fd      := master_fd;
      the_fds.events  := POLLIN;
      -- Monitor the input from the terminal and handle that input.
      while not quit_loop loop
         select
            accept Stop do
               quit_loop := true;
            end;
         else
            the_fds.revents := 0;
            res := Gtk.Terminal.CInterface.Poll(the_fds, nfds, char_wait_time);
            if res > 0 and then the_fds.revents = POLLIN
            then  -- There is key presses waiting to be read
               Read(master_fd, input, read_len);
               Error_Log.Debug_Data(at_level => 9, with_details => "Terminal_Input_Handling: input (from terminal client (system's virtual terminal)) = '" & Ada.Characters.Conversions.To_Wide_String(input) & "'.");
            else
               read_len := 0;  -- simulate no character yet
            end if;
            case read_len is
               when  0 =>  -- No character yet
                  delay 0.05;
               when others =>  -- Got input
                  the_buffer.input_monitor.Put(the_character => input(1));
                  the_buffer.waiting_for_response := false;
            end case;
         end select;
      end loop;
      exception
         when Terminal_IO_Error =>
            raise;
         when others =>
            raise;
   end Terminal_Input_Handling;

   procedure Key_Pressed(for_buffer : access Gtk_Terminal_Buffer_Record'Class) is
      -- Respond to whenever a key is pressed by the user and ensure that it
      -- is appropriately acted upon, usually by passing it on to the terminal
      -- client.  It will also inhibit editing before the current terminal
      -- input point (i.e., before the prompt).
      use Gtk.Text_Iter;
      procedure Process_Keys(for_string : in UTF8_String;
                             over_range_start, 
                             and_end : in out Gtk.Text_Iter.Gtk_Text_Iter) is
         use Gtk.Terminal.CInterface, Interfaces.C;
         char_wait_time : constant Interfaces.C.Int := 250; -- msec
         nfds           : constant Gtk.Terminal.CInterface.nfds_t := 1;
         the_fds        : Gtk.Terminal.CInterface.poll_fd_access;
         res            : Interfaces.C.int;
         history_text   : constant boolean := for_buffer.history_review;
         clear_line_text: constant UTF8_String := 
                                   Ada.Characters.Latin_1.Esc & "[2K";
         enter_text     : constant UTF8_String(1..1) := 
                                   (1 => Ada.Characters.Latin_1.LF);
         the_terminal   : Gtk_Terminal := Gtk_Terminal(Get_Parent(for_buffer.parent));
      begin
         -- Check for end of line (i.e. the Return/Enter key is pressed) or
         -- alternatively User has buffer_editing (i.e. use the virtual
         -- terminal's editing) not set, and then set flags and potentially
         -- enable update of the line count.
         if for_string'Length > 0 and then 
            ((for_string(for_string'Last) = Ada.Characters.Latin_1.LF and
              (not(for_string'Length > 1 and then
                   for_string(for_string'Last-1) = '\'))) or
             ((not for_buffer.use_buffer_editing) ))--or 
              --(not for_buffer.bracketed_paste_mode)))
         then  -- Return/Enter key has been pressed + not line continuation
            -- Reset the history processing indicator value
            if for_string(for_string'Last) = Ada.Characters.Latin_1.LF then
               for_buffer.history_review := false;
               for_buffer.switch_light_cb(3, false);
               Set_Overwrite(for_buffer.parent, false);
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed - Process_Keys (on '" & Ada.Characters.Conversions.To_Wide_String(for_string) & "') : Set for_buffer.history_review to false and Set_Overwrite(for_buffer.parent) to false and sending to client (i.e. system VT).");
            -- Process the keys through to the terminal
            the_fds := new Gtk.Terminal.CInterface.poll_fd;
            the_fds.fd      := for_buffer.master_fd;
            the_fds.events  := POLLOUT;
            loop
               the_fds.revents := 0;
               res := Gtk.Terminal.CInterface.Poll(the_fds, nfds, char_wait_time);
               exit when res > 0 and then the_fds.revents = POLLOUT;
               delay 0.05;  -- seconds
            end loop;
            if history_text and for_buffer.use_buffer_editing
            then  -- terminal client is just expecting an Enter key here
               -- we need to assume the terminal client (i.e. the system's
               -- virtual terminal) has the correct line including edits to it
               -- First, undo the 'Enter' key press
               declare
                  cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
                  res : boolean;
               begin
                  Get_Iter_At_Mark(for_buffer, cursor_iter, Get_Insert(for_buffer));
                  res := Backspace(for_buffer, cursor_iter, false, true);
               end;
               -- Now output that enter key
               Write(fd => for_buffer.master_fd, Buffer => enter_text);
            else -- not history, normal keyboard command entry
               -- Delete the text from the buffer so that the terminal may write
               -- it back and then write that deleted text out to the termnal
               Delete(for_buffer, over_range_start, and_end);  -------------******************FIX: causes a subsequent Gtk-WARNING **: 21:48:00.652: Invalid text buffer iterator: either the iterator is uninitialized... 
               Write(fd => for_buffer.master_fd, Buffer => for_string);
            end if;
            -- Check that the buffer length is not exceeded (remove line if so)
            if natural(Get_Line_Count(for_buffer))>the_terminal.scrollback_size
            then  -- Clip the buffer back to being within size
               declare
                  start_iter  : Gtk.Text_Iter.gtk_text_iter;
                  line_2_iter : Gtk.Text_Iter.gtk_text_iter;
               begin
                  Get_Start_Iter(for_buffer, start_iter);
                  Get_Iter_At_Line(for_buffer, line_2_iter, 1);
                  Delete(for_buffer, start_iter, line_2_iter);
               end;
            end if;
            -- Put ourselves into a 'waiting for response' mode
            if for_buffer.bracketed_paste_mode then
               for_buffer.waiting_for_response := true;
            end if;
            -- Update the line count
            for_buffer.line_number := line_numbers(Get_Line_Count(for_buffer));
         elsif for_string'Length > 0 and then 
            (history_text and for_buffer.use_buffer_editing)
         then  -- some other key pressed to modify a history line
            -- Process the key(s) through to the terminal
            the_fds := new Gtk.Terminal.CInterface.poll_fd;
            the_fds.fd      := for_buffer.master_fd;
            the_fds.events  := POLLOUT;
            loop
               the_fds.revents := 0;
               res := Gtk.Terminal.CInterface.Poll(the_fds, nfds, char_wait_time);
               exit when res > 0 and then the_fds.revents = POLLOUT;
               delay 0.05;  -- seconds
            end loop;
            -- First, undo the key press in the buffer
            declare
               cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
               res : boolean;
            begin
               Get_Iter_At_Mark(for_buffer, cursor_iter, Get_Insert(for_buffer));
               res := Backspace(for_buffer, cursor_iter, false, true);
            end;
            -- Now output that key that was pressed
            Write(fd => for_buffer.master_fd, Buffer => for_string);
            -- Put ourselves into a 'waiting for response' mode
            if for_buffer.bracketed_paste_mode then
               for_buffer.waiting_for_response := true;
            end if;
         end if;
      end Process_Keys;
      start_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
   begin     -- Key_Pressed
      Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed: Start.");
      if (for_buffer.line_number > unassigned_line_number) and
         (not for_buffer.waiting_for_response) and
         (not for_buffer.in_response)
      then  -- Spawn_Shell has been run for this terminal buffer
         for_buffer.in_esc_sequence := false;
         -- Get the key(s) pressed
         if for_buffer.history_review
         then  -- use the cursor position to copy up to
            Get_Iter_At_Mark(for_buffer, end_iter, Get_Insert(for_buffer));
         else  -- getting entire line (so the end point
            Get_End_Iter(for_buffer, end_iter);
         end if;
         if for_buffer.anchor_point = 0
         then  -- start_iter is at the start of the line
            Get_Iter_At_Line(for_buffer, start_iter,
                             Glib.Gint(for_buffer.line_number-1));
         else  -- start_iter is at anchor_point in the current line(s)
            Get_Iter_At_Line_Index(for_buffer, start_iter, 
                                   Glib.Gint(for_buffer.line_number-1),
                                   Glib.Gint(for_buffer.anchor_point));
         end if;
         if (not Equal(end_iter, start_iter))
         then  -- There is actually some input
            -- Get the string and act upon it
            Process_Keys(for_string => Get_Text(for_buffer,start_iter,end_iter),
                         over_range_start => start_iter, and_end => end_iter);
         else  -- Nothing to do here
            null;  -- do nothing
         end if;
      else  -- Spawn_Shell has not yet been run for this terminal buffer
         null;  -- do nothing
      end if;
   end Key_Pressed;
  
   -------------
   -- Methods --
   -------------
   
   procedure Spawn_Shell (terminal : access Gtk_Terminal_Record'Class; 
                          working_directory : UTF8_String := "";
                          command : UTF8_String := "";
                          environment : UTF8_String := "";
                          use_buffer_for_editing : boolean := true;
                          title_callback : Spawn_Title_Callback;
                          callback : Spawn_Closed_Callback;
                          switch_light    : Switch_Light_Callback) is
      -- Principally, spawn a terminal shell.  This procedure does the initial
      -- Terminal Configuration Management (encoding, size, etc).  This
      -- procedure actually launches the terminal, making sure that it is
      -- running with the right shell and set to the right directory with the
      -- right environment variables set.
      use Gtk.Terminal.CInterface, Interfaces.C, Glib.Properties;
      separator : constant wide_character := ',';
      Failure   : constant C.int := -1;
      type String_Access is access UTF8_string;
      type argument_array is array(positive range<>) of String_Access;
      null_arg_array : constant argument_array(2..1) := (others => null);
      procedure Free is new Ada.Unchecked_Deallocation (String, String_Access);
      procedure Free is
                new Ada.Unchecked_Deallocation (char_array, char_array_access);
      procedure Free_String_List(env_list : in out GNAT.Strings.String_List) is
         -- GNAT.Strings.String_List needs to be manually freed at the end of
         -- its life :-(
         -- This is done by freeing each string in the list (each string is
         -- actually a pointer to a string).  The list itself is not a pointer,
         -- so Ada automatically frees it (therefore it is not done here).
      begin
         for item in env_list'Range loop
            GNAT.Strings.Free(env_list(item));
         end loop;
      end Free_String_List;
      procedure Execute(args : UTF8_string; envs : UTF8_string := "") is
         function Convert_To_Array(the_string : in UTF8_string)
         return argument_array is
            use Ada.Strings.UTF_Encoding.Wide_Strings;
            str_as_wide : wide_string := Decode(the_string);
            str_len     : natural := str_as_wide'Length;
            str_count   : natural := 1;
         begin
            if str_len > 0 then
               for item in 1..str_len loop
                  if str_as_wide(item) = separator then
                     str_count := str_count + 1;
                  end if;
               end loop;
            end if;
            declare
               elements  : argument_array (1..str_count);
               str_num   : positive := 1;
               str_start : positive := 1;
            begin
               if str_count = 1 then
                  elements(1) := new UTF8_string'(the_string);
               else
                  for item in 1 .. str_len+1 loop
                     if item = str_len+1 or else
                        str_as_wide(item) = separator
                     then
                        elements(str_num):= new UTF8_string'(Encode(
                                              str_as_wide(str_start..item-1)));
                        str_start := item + 1;
                        str_num := str_num + 1;
                     end if;
                  end loop;
               end if;
               return elements;
            end;
         end Convert_To_Array;
         function Launch_Process(args: argument_array;
                                 envs: argument_array) return boolean is
            use Ada.Strings.Fixed;
            cmd     : Gtkada.Types.Chars_Ptr;
            envc    : Gtkada.Types.Chars_Ptr;
            envp    : Gtkada.Types.Chars_Ptr;
            argv    : Gtkada.Types.Chars_Ptr_Array(0..size_t(args'Length));
            argvLst : natural := args(args'First).all'Last;
            argv0St : integer := argvLst;
            res     : int;
         begin
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Start.");
            -- load up the full command path and the argv(0) with the command
            cmd := New_String(args(args'First).all);
            while argv0St >= args(args'First).all'First and then
                  args(args'First).all(argv0St) /= '/' loop
               argv0St := argv0St - 1;
            end loop;
            if args(args'First).all(argv0St) = '/' then
               argv0St := argv0St + 1;
            end if;
            argv(0) := New_String(args(args'First).all(argv0St..argvLst));
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: argv(0) = '" & Ada.Characters.Conversions.To_Wide_String(Gtkada.Types.Value(argv(0))) & "'.");
            -- load up the arrays and add a null pointer to the end
            if args'Length > 1
            then
               for item in args'First+1..args'Last loop  -- arguments
                  argv(size_t(item-args'First)) := New_String(args(item).all);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: argv(" & item'Wide_Image & ") = '" & Ada.Characters.Conversions.To_Wide_String(Gtkada.Types.Value(argv(size_t(item-args'First)))) & "'.");
               end loop;
            end if;
            argv(size_t(args'Length)) := Null_Ptr;
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Got argv items as pointer strings.");
            if envs'Length > 0 then
               for item in envs'Range loop  -- environment variables
                  envc:=New_String(envs(item).all(envs(item).all'First..
                                                 Index(envs(item).all,"=")-1));
                  envp:=New_String(envs(item).all(Index(envs(item).all,"=")+1..
                                                         envs(item).all'Last));
                  res := Set_Environment(variable=>envc,to=>envp,overwrite=>1);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Set '" & Ada.Characters.Conversions.To_Wide_String(Gtkada.Types.Value(envc))  & "'='" & Ada.Characters.Conversions.To_Wide_String(Gtkada.Types.Value(envp))  & "'.");
               end loop;
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Got envp items and set them.");
            -- do it
            res := Execvp(cmd, argv);
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Execvp(cmd, argv).");
            -- Clean up what we can
            for item in args'First..args'Last+1 loop
               Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Freed argv item number" & item'Wide_Image & "...");
               Free(argv(size_t(item)));
            end loop;
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process Launch_Process: Freed argv items.");
            return (res /= Failure);
         end Launch_Process;
         success : boolean;
         res     : Interfaces.C.int;
         the_environment: GNAT.Strings.String_List := Glib.Spawn.Get_Environ;
      begin  -- Execute
         Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell : Execute: Start.");
         -- Set up the standard environment
         res := Unset_Environment(New_String("COLUMNS"));
         res := Unset_Environment(New_String("LINES"));
         res := Unset_Environment(New_String("TERMCAP"));
         Free_String_List(the_environment);
         -- Launch the process
         if envs'Length > 0 then
            success := Launch_Process(Convert_To_Array(args),
                                      Convert_To_Array(envs));
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell : Execute: Launched process with environment variables.");
         else
            success := Launch_Process(Convert_To_Array(args), null_arg_array);
         end if;
         if not success then
            Error_Log.Debug_Data(at_level => 1, with_details => "Spawn_Shell : Execute: Launch failed.");
         end if;
      end Execute;
      procedure Set_Cursor_Shape
                         (for_terminal : in out Gtk.Text_View.Gtk_Text_View) is
         use Gtk.CSS_Provider, Gtk.Style_Context, Gtk.Style_Provider;
         the_error : aliased Glib.Error.GError;
         provider  : Gtk.CSS_Provider.Gtk_CSS_Provider;
         context   : Gtk.Style_Context.Gtk_Style_Context;
      begin
         Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell : Set_Cursor_Shape: Start.");
         Gtk_New(provider);
         if Load_From_Data(provider, 
                           "textview* {" &
                                     "  caret-color: white; " &
                                     -- The following is not yet implemented
                                     -- (even in nearly any CSS app):
                                     -- "  caret-shape: block; " &
                           --           "} " &
                           -- "textview.entry { " &
                           --           "  caret-shape: block; " &
                                     "}",
                              the_error'access)
         then  -- successful load
            Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell : Load_From_Data(provider) successful.");
            context := Get_Style_Context(for_terminal);
            Gtk.Style_Context.Add_Provider(context, +provider,
                                           Priority_Application);
         end if;
      end Set_Cursor_Shape;
      child_pid   : Glib.Spawn.GPid;
      term_params : aliased Gtk.Terminal.CInterface.term_attribs;
      res         : Interfaces.C.int;
      start_iter  : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter    : Gtk.Text_Iter.Gtk_Text_Iter;
      history_tag : Gtk.Text_Tag.Gtk_Text_Tag;
      end_mark    : Gtk.Text_Mark.Gtk_Text_Mark;
      unedit_mark : Gtk.Text_Mark.Gtk_Text_Mark;
      window_size : aliased win_size := 
                                (Interfaces.C.unsigned_short(terminal.rows),
                                 Interfaces.C.unsigned_short(terminal.cols), 
                                 Interfaces.C.unsigned_short(0), 
                                 Interfaces.C.unsigned_short(0));
   begin  -- Spawn_Shell
      Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell: Start.");
      -- First, set up the call-back pointers
      terminal.closed_callback := callback;
      terminal.title_callback  := title_callback;
      terminal.buffer.use_buffer_editing := use_buffer_for_editing;
      terminal.buffer.switch_light_cb := switch_light;
      Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell: Set up callbacks done.  terminal.master_fd initialised at" & terminal.master_fd'Wide_Image & ".");
      -- Get the file descriptors and spawn the child
      child_pid := Fork_Pseudo_Terminal(with_fd  => terminal.master_fd'Address,
                                        with_name=> terminal.buffer.child_name,
                                        with_attribs  => null,
                                        with_win_size => window_size'access);
      Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell: Did fork.");
      if child_pid = -1
      then -- failed to fork
         Handle_The_Error(the_error  => 11, 
                          error_intro=> "Spawn_Shell: Fork error",
                          error_message => "Fork_Process failed.");
         raise Terminal_Creation_Error;
      elsif child_pid = 0
      then  -- we are the child - Load shell and then go to the top
         Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Child process: doing Execute for command.");
         -- As we are the child, close the master file descriptor here
         res := Close_Device(for_fd => terminal.master_fd);
         -- Load the requested shell (or other command)
         if working_directory'Length > 0 and environment'Length > 0
         then
            Execute(args   => command, 
                    envs   => "CWD=" & working_directory & ',' & environment);
         elsif working_directory'Length > 0 and environment'Length = 0
         then
            Execute(args => command, envs => "CWD=" & working_directory);
         else  -- working_directory'Length = 0, environment may or may not be 0
            Execute(args => command, envs => environment);
         end if;
         -- Go to the top
         Terminate_Process(with_status => 0);  -- Kill ourself if we get here
      else  -- we are the parent - Continue on
         Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Parent process: Setting up PIDs and the like. Master_fd=" & terminal.master_fd'Wide_Image & ".");
         terminal.buffer.child_pid  := child_pid;
         Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell Parent process: Got Child PID (" & child_pid'Wide_Image & ").");
         terminal.buffer.child_name := TTY_Name(for_fd => terminal.master_fd);
         Error_Log.Debug_Data(at_level => 9, with_details => "Spawn_Shell :  Terminal child name is '" &  Ada.Characters.Conversions.To_Wide_String(Gtkada.Types.Value(terminal.buffer.child_name)) & "'.");
         terminal.buffer.master_fd := terminal.master_fd;
      end if;
      -- Only the parent should be executing the below.
      -- Set up the terminal controls
      res := Get_Terminal_Attributes(for_fd => terminal.master_fd,
                                     into => term_params'Access);
      term_params.input_mode_flags := term_params.input_mode_flags + IUTF8;
      res := Set_Terminal_Attributes(for_fd => terminal.master_fd,
                                     optional_actons => TCSANOW,
                                     to_attribs => term_params'Access);
      Set_Input_Purpose(terminal.terminal, Gtk.Enums.Input_Purpose_Terminal);
      -- Initialise the buffer state
      Begin_User_Action(terminal.buffer);
      Get_Start_Iter(terminal.buffer, start_iter);
      Get_End_Iter(terminal.buffer, end_iter);
      terminal.buffer.line_number := 
                      line_numbers(Get_Line_Count(terminal.buffer));
      history_tag := terminal.buffer.Create_Tag("history_text");
      Set_Property(history_tag, Editable_Property, false);
      Apply_Tag(terminal.buffer, history_tag,
                start_iter, end_iter);
      unedit_mark := Create_Mark(terminal.buffer, "end_unedit", end_iter, 
                                 left_gravity=>true);
      Get_Iter_At_Line(terminal.buffer, start_iter,
                       Glib.Gint(terminal.buffer.line_number));
      terminal.buffer.anchor_point := 
                  UTF8_Length(Get_Text(terminal.buffer, start_iter, end_iter));
      Place_Cursor(terminal.buffer, end_iter);
      end_mark := Create_Mark(terminal.buffer, "end_paste", end_iter, 
                              left_gravity=>true);
      -- Make sure cursor movement controls are not inserted into buffer text
      Set_Accepts_Tab(terminal.terminal, true);
      Set_Cursor_Shape(for_terminal => terminal.terminal);
      Set_Cursor_Visible(terminal.terminal, true);
      Reset_Cursor_Blink(terminal.terminal);
      -- Create and initiate the input task's output processing loop monitor
      terminal.buffer.input_monitor := new input_monitor_type;
      Buffer_Arrays.Append(display_output_handling_buffer, terminal.buffer);
      -- Launch handling of input from the child terminal
      terminal.term_input := new Terminal_Input_Handling;
      terminal.term_input.Start(with_fd => terminal.master_fd, 
                                -- with_command => command, 
                                -- with_environment => environment, 
                                with_terminal_buffer => terminal.buffer);
      -- Final sanity check on the creation of the input handler task
      if terminal.term_input = null then  -- it failed out
         Handle_The_Error(the_error  => 12, 
                        error_intro=> "Spawn_Shell: Terminal input task error",
                        error_message => "terminal.term_input is unassigned.");
         raise Terminal_Creation_Error;
      end if;
      if working_directory'Length > 0  -- i.e. it is specified
      then  -- put ourselves in the right directory
         delay 0.25;
         Write(fd => terminal.buffer.master_fd, 
               Buffer=> "cd " & working_directory & Ada.Characters.Latin_1.LF);
      end if;
      --    -- Now ensure the cursor is visible at the end of the buffer  -- THIS DIDN'T WORK
      --    declare
      --       use Gtk.Text_Iter;
      --       end_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      --       res      : boolean;
      --    begin
      --       Get_End_Iter(terminal.buffer, end_iter);
      --       Backward_Cursor_Position(end_iter, res);
      --       Forward_Cursor_Position(end_iter, res);
      --       Place_Cursor(terminal.buffer, end_iter);
      --       res := Place_Cursor_Onscreen(terminal.terminal);
      --    end;
   end Spawn_Shell;

    -- Terminal Configuration Management (encoding, size, etc)
   procedure Set_Encoding (for_terminal : access Gtk_Terminal_Record'Class; 
                       to : in UTF8_string := "UTF8") is
      -- Set the terminal's encoding method.  If not UTF-8, then it must be a
      -- valid GIConv target.
   begin
      if    to = "UTF8"    then for_terminal.encoding := utf8;
      elsif to = "UTF16"   then for_terminal.encoding := utf16;
      elsif to = "DEFAULT" then for_terminal.encoding := default;
      else raise Encoding_Error;
      end if;
   end Set_Encoding;
      
   procedure Set_Character_Width 
                      (for_terminal : access Gtk_Terminal_Record'Class; 
                       to : in character_width_types) is
      -- Set the terminal's character width to that specified for CJK type
      -- characters.
   begin
      case to is  -- Control the font type
         when normal => Set_Monospace(for_terminal.terminal, true);
         when narrow => Set_Monospace(for_terminal.terminal, false);
         when wide   => Set_Monospace(for_terminal.terminal, false);
      end case;
   end Set_Character_Width;
   
   procedure Set_Size (terminal : access Gtk_Terminal_Record'Class; 
                       columns, rows : natural) is
      -- Set the terminal's size to the specified number of columns and rows.
      use Gtk.Terminal.CInterface, Interfaces.C;
      default_columns  : constant natural := 80;
      default_vert_size: constant natural := 32;
      horizontal_scale : constant natural := 15;
      vertical_scale   : constant natural := 
                   natural(1.3*float(Get_Size(terminal.current_font))/1000.0);
      col_size : Glib.Gint := Glib.Gint(columns * horizontal_scale);
      row_size : Glib.Gint := Glib.Gint(rows * vertical_scale);
      term_size: aliased win_size := (0, 0, 0, 0);
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Set_Size :  Font size =" &  Get_Size(terminal.current_font)'Wide_Image & ", vertical_scale =" & vertical_scale'Wide_Image & ".");
      if natural(row_size) < rows
      then  -- it could be that the font has yet to be set
         row_size := Glib.Gint(rows * default_vert_size);
      end if;
      if columns >= nowrap_size
      then  -- Assume no wrapping, so set the displayed size to 80 characters
         col_size := Glib.Gint(default_columns * horizontal_scale);
         -- and set wrapping to off for the screen
         Set_Wrap_Mode(terminal.terminal, Gtk.Enums.Wrap_None);
      else  -- Set wrapping to on for the screen
         Set_Wrap_Mode(terminal.terminal, Gtk.Enums.Wrap_Char);
      end if;
      Set_Size_Request(terminal, Width=>col_size, Height=>row_size);
      -- Do a sanity check
      if terminal.scrollback_size < rows
      then -- it makes no sense for the scroll-back size to be < display height
         terminal.scrollback_size := rows;  -- so set it to that.
      end if;
      -- Tell the virtual terminal to resize
      if terminal.id /= 0 then  -- i.e. terminal is already set up
         -- First, get the current size
         if IO_Control(for_file => terminal.master_fd, request => TIOCGWINSZ, 
                       params => term_size'Address) < 0
         then  -- failed to get the current size :-(
            Handle_The_Error(the_error => 13, 
                          error_intro  => "Set_Size: Terminal resize error",
                          error_message=> "Couldn't get current window size.");
         else  -- Second, set the new number of rows and columns
            term_size.rows := Interfaces.C.unsigned_short(rows);
            term_size.cols := Interfaces.C.unsigned_short(columns);
            if IO_Control(for_file => terminal.master_fd, request=> TIOCSWINSZ,
                          params => term_size'Address) < 0
            then -- Error in rezizing :-(
               Handle_The_Error(the_error => 14, 
                             error_intro  => "Set_Size: Terminal resize error",
                             error_message=> "Couldn't set window size to " & 
                                             "rows =" & rows'Wide_Image & 
                                             ", cols =" & columns'Wide_Image &
                                             ".");
            end if;
         end if;
      end if;
      -- And save the size itself
      terminal.cols := columns;
      terminal.rows := rows;
   end Set_Size;

   procedure Feed (terminal : access Gtk_Terminal_Record'Class; 
                   data : UTF8_String := "") is
     -- Send data to the terminal to display, or to the terminal's forked
     -- command to handle in some way.  If it's 'cat', they should be the same.
     -- Basically, this just initialises the terminal display with content.
   begin
      Set_Text (terminal.buffer, data);
   end Feed;

   function Get_Text (from_terminal : access Gtk_Terminal_Record'Class) 
   return UTF8_string is
     -- Get all the text in the visibilbe part of the terminal's display.
      buf_start  : Gtk.Text_Iter.Gtk_Text_Iter;
      buf_end    : Gtk.Text_Iter.Gtk_Text_Iter;
   begin
      Get_Start_Iter(from_terminal.buffer, buf_start);
      Get_End_Iter(from_terminal.buffer, buf_end);
      return Get_Slice(from_terminal.buffer, buf_start, buf_end);
   end Get_Text;

   procedure Set_Colour_Background (terminal: access Gtk_Terminal_Record'Class;
                                    background :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the background colour to that specified.
      use Gtk.Enums, Gdk.Color, Gdk.RGBA;
      the_colour : Gdk.Color.Gdk_Color;
   begin
      Override_Background_Color(terminal.terminal, 0, background);
      Set_RGB(the_colour, Guint16(background.Red), Guint16(background.Green), 
              Guint16(background.Blue));
      Modify_Base(widget=> terminal.terminal, state=> State_Normal, 
                  color=> the_colour);
      terminal.buffer.background_colour := background;
   end Set_Colour_Background;
   
   procedure Set_Colour_Text (terminal: access Gtk_Terminal_Record'Class;
                              text_colour :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the text (i.e. the foreground) colour to that specified.
      use Gtk.Enums, Gdk.Color, Gdk.RGBA;
      the_colour : Gdk.Color.Gdk_Color;
   begin
      Override_Color(widget => terminal.terminal, 
                     state => Gtk_State_Flag_Normal, color => text_colour);
      
      Override_Cursor(widget => terminal.terminal, 
                     cursor => text_colour, secondary_cursor => text_colour);
      Set_RGB(the_colour, Guint16(text_colour.Red), Guint16(text_colour.Green),
              Guint16(text_colour.Blue));
      Modify_Cursor(widget => terminal.terminal, 
                    primary => the_colour, secondary => the_colour);
      terminal.buffer.text_colour := text_colour;
      if not Get_Cursor_Visible(terminal.terminal) then
         Set_Cursor_Visible(terminal.terminal, true);
      end if;
   end Set_Colour_Text;
   
   procedure Set_Colour_Bold (terminal: access Gtk_Terminal_Record'Class;
                              bold_colour :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the bold text colour to that specified.
      use Gtk.Enums, Gdk.Color, Gdk.RGBA;
      the_colour : Gdk.Color.Gdk_Color;
   begin
      Set_RGB(the_colour, Guint16(bold_colour.Red), Guint16(bold_colour.Green),
              Guint16(bold_colour.Blue));
      Modify_Text(widget =>terminal.terminal, state => State_Prelight, 
                  color => the_colour);
   end Set_Colour_Bold;
   
   procedure Set_Colour_Highlight (terminal: access Gtk_Terminal_Record'Class;
                                   highlight_colour :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the highlight text colour to that specified.
      -- use Gtk.Enums, Gdk.Color, Gdk.RGBA;
      -- the_colour : Gdk.Color.Gdk_Color;
   begin
      terminal.buffer.highlight_colour := highlight_colour;
   --    Set_RGB(the_colour, Guint16(highlight_colour.Red), 
         --      Guint16(highlight_colour.Green), Guint16(highlight_colour.Blue));
      -- Modify_Text(widget => terminal.terminal, state => State_Focused,  -------------******************FIX: raises Gtk-CRITICAL **: 16:59:29.617: gtk_widget_modify_text: assertion 'state >= GTK_STATE_NORMAL && state <= GTK_STATE_INSENSITIVE' failed
         --          color => the_colour);
   end Set_Colour_Highlight;
   
   procedure Set_Font (for_terminal: access Gtk_Terminal_Record'Class;
                       to_font_desc : Pango.Font.Pango_Font_Description) is
     -- Set the terminal's font to that specified in Pango font format.
   begin
      Modify_Font (for_terminal.terminal, to_font_desc);
      for_terminal.current_font := to_font_desc;
   end Set_Font;
   
   function Get_Font (for_terminal: access Gtk_Terminal_Record'Class) return 
                                           Pango.Font.Pango_Font_Description is
     -- Get the terminal's font to that specified in Pango font format.
   begin
      return for_terminal.current_font;
   end Get_Font;

   procedure Set_Scrollback_Lines(terminal: access Gtk_Terminal_Record'Class;
                                    lines : natural) is
        -- Set the number of scroll-back lines to be kept by the terminal.  It
        -- should be noted that this is the number of lines at or above an
        -- internal minimum.
   begin
      terminal.scrollback_size := lines;
   end Set_Scrollback_Lines;
     
   function Get_Scrollback_Lines(terminal: access Gtk_Terminal_Record'Class)
     return natural is
        -- Get the number of scroll-back lines that have been set.
   begin
      return terminal.scrollback_size;
   end Get_Scrollback_Lines;
   
   function Get_Title(for_terminal : access Gtk_Terminal_Record'Class)
    return UTF8_String is
       -- Return the title as the operating system knows it
   begin
      if for_terminal.title = Gtkada.Types.Null_Ptr
      then
         return "Bliss Term";
      else
         return Gtkada.Types.Value(for_terminal.title);
      end if;
   end Get_Title;
    
   function Get_Path(for_terminal : access Gtk_Terminal_Record'Class)
    return UTF8_String is
       -- Return the current file as the operating system knows it, essentially
       -- extracting it from the title. It assumes that the path is encoded in
       -- the title and that the title is of the form "<pre-bits>:<path>".  If
       -- there is no ":" in the title, then an empty string will be returned.
      use Ada.Strings.Fixed;
   begin
      if Count(source=>Get_Title(for_terminal), pattern=>":") > 0
      then
         return Get_Title(for_terminal)
                         (Index(Get_Title(for_terminal),":")+2 ..
                                                 Get_Title(for_terminal)'Last);
      else
         return "";
      end if;
   end Get_Path;
    
   procedure Set_ID(for_terminal : access Gtk_Terminal_Record'Class; 
                    to : natural) is
       -- Set the terminal's Identifier (which can be any positive number).
   begin
      for_terminal.id := to;
   end Set_ID;
    
   function Get_ID(for_terminal : access Gtk_Terminal_Record'Class) 
   return natural is
       -- Get the terminal's Identifier (which been previously set via Set_ID).
   begin
      return for_terminal.id;
   end Get_ID;
    
   procedure Shut_Down(the_terminal : access Gtk_Terminal_Record'Class) is
       -- Finalise everything, shutting down any tasks.
   begin
      if the_terminal.term_input /= null
       then  -- it has been set off, so stop it
         the_terminal.term_input.Stop;
      end if;
      null;
   end Shut_Down;

end Gtk.Terminal;
