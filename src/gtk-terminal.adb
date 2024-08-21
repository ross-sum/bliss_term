-----------------------------------------------------------------------
--                                                                   --
--                      G T K . T E R M I N A L                      --
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
--  General Public Licence distributed with  Bliss Term.             --
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
-- with Gdk.Types;
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
-- with Gtk.Clipboard;
-- with Gdk.RGBA;                use Gdk.RGBA;
-- with Pango.Font;              use Pango.Font;
-- with Gtkada.Types;            use Gtkada.Types;
-- with Gtk.Terminal_Markup;
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
with Glib.Convert;
with Gdk.Color;
with Gdk.Types.Keysyms;
with Gdk.Rectangle;
with Gdk.Display;
with GDK.Key_Map;
with Gtk.Enums;
with Gtk.Window;
with Gtk.Text_Tag;
with Gtk.Arguments;              use Gtk.Arguments;
with Gtk.CSS_Provider, Gtk.Style_Context, Gtk.Style_Provider;
with Gtk.Terminal.CInterface;
with Gtk.Terminal.Colour;
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
   --       history_review      : boolean := false;
   --               -- are we reviewing command line (usually Bash) history?
   --               -- If so, then that affects editing positions and anchor_point
   --               -- movement.
   --       cmd_prompt_check    : check_for_command_prompt_end;
   --               -- check for the end of the command prompt so that we know
   --               -- where the end point of the history_review is.
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
   --       pass_through_characters  : boolean := false;  -- matchs br. paste mode
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
   --       use_buffer_editing  : boolean := true;
   --          -- indicates to use the buffer's editing capabilities wherever
   --          -- possible or, alternatively, always use the terminal emulator's
   --          -- editor.
   --       parent              : Gtk.Text_View.Gtk_Text_View;
   --       -- The alternative buffer (to emulate an xterm)
   --       alt_buffer          : Gtk_Text_Buffer;
   --       switch_light_cb     : Switch_Light_Callback;  -- or monitoring
   --    end record;
   -- type Gtk_Terminal_Buffer is access all Gtk_Terminal_Buffer_Record'Class;
   -- Encoding_Error : exception;
   -- type Gtk_Terminal_Record is new Gtk_Scrolled_Window_Record with 
   --    record
   --       terminal         : Gtk.Text_View.Gtk_Text_View;
   --       buffer           : Gtk_Terminal_Buffer;
   --       master_fd        : Interfaces.C.int;
   --       id               : natural := 0;
   --       title            : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
   --       scrollback_size  : natural := 0;
   --       current_font     : Pango.Font.Pango_Font_Description := Pango.Font.
   --                          To_Font_Description("Monospace Regular",size=>10);
   --       encoding         : encoding_types := utf8;
   --       title_callback   : Spawn_Title_Callback
   --       closed_callback  : Spawn_Closed_Callback;
   --       term_input       : Terminal_Handling_Access;
   --       cols             : natural := default_columns;  -- number of columns
   --       rows             : natural := default_rows;  -- number of rows
   -- end record;
   -- type Gtk_Terminal is access all Gtk_Terminal_Record'Class;
      
   Insert_Return : constant character := Ada.Characters.Latin_1.EOT;
      -- We are commandeering this character to represent a LF character when
      -- we don't want to do a LF overwrite when in overwrite mode (i.e. we
      -- actually want to do a line feed).
   
   key_map : GDK.Key_Map.Gdk_Keymap;
      -- The key map module in GTK has the detection routines to advise whether
      -- the Num Lock, Scroll Lock  or Caps Lock keys are in the depressed
      -- (i.e. 'on') state.  This variable is universal to  the application,
      -- irrespective of the number of terminals it has, and so is set once at
      -- initialisation of the first terminal.
   
   -----------------------------
   -- Error and Debug Logging --
   -----------------------------

   procedure Set_The_Error_Handler(to : error_handler) is
   begin
      the_error_handler := to;
      Gtk.Terminal_Markup.Set_The_Error_Handler
                                 (to => Gtk.Terminal_Markup.error_handler(to));
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

   procedure Set_The_Log_Handler(to : log_handler) is
   begin
      the_log_handler := to;
      Gtk.Terminal_Markup.Set_The_Log_Handler(to=>Gtk.Terminal_Markup.log_handler(to));
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
         -- Additionally, we set the key_map to match the current application's
         -- main window, thus allowing the application to detect when the
         -- NumLock is 'on'.
         key_map :=
               Gdk.Key_Map.Get_Key_Map(for_display => Gdk.Display.Get_Default);
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
         --Set up the key and mouse events
         On_Key_Press_Event(self=>the_terminal.terminal, 
                            call=>Scroll_Key_Press_Check'access, after=>false);
         On_Motion_Notify_Event(self=>the_terminal.terminal, 
                                call=>Motion_Notify_CB'access, after=>false);
         On_Button_Press_Event(self=>the_terminal.terminal, 
                               call=>Button_Press_CB'access, after=>false);
         On_Button_Release_Event(self=>the_terminal.terminal, 
                                 call=>Button_Release_CB'access, after=>false);
         On_Scroll_Event(self=>the_terminal.terminal, 
                         call=>Mouse_Scroll_CB'access, after=>false);
         -- Give an initial default dimension of nowrap_size (1000) characters
         -- wide x default_rows (25) lines (i.e. no wrap)
         Set_Size (terminal => the_terminal, 
                   columns => nowrap_size, rows => default_rows);
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
      -- Create the buffer itself
      the_buffer := new Gtk_Terminal_Buffer_Record;
      -- Now create the alternative buffer (as per xterm)
      Gtk_New(the_buffer.alt_buffer);
      -- Initialise both the_buffer and the alternative buffer, making sure
      -- that they share the same tag table.
      Gtk.Terminal.Initialise(the_buffer, table);
      Gtk.Text_Buffer.Initialize(the_buffer.alt_buffer, 
                   Gtk.Text_Buffer.Get_Tag_Table(Gtk_Text_Buffer(the_buffer)));
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
         Gtk.Text_Buffer.Initialize(Gtk_Text_Buffer(the_buffer), table);
         -- Set up the character handlers
         On_Changed(self=> the_buffer, 
                    call=> Key_Pressed'access, after => false);
         Gtk.Text_Buffer.On_Changed(self=> the_buffer.alt_buffer, 
                    call=> Alt_Key_Pressed'access, after => false);
         -- And set up the command prompt end finding protected entity
         the_buffer.cmd_prompt_check := new check_for_command_prompt_end;
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
      Finalise(the_markup => the_terminal.buffer.markup);
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

   function Cb_To_Address is new Ada.Unchecked_Conversion
     (Cb_Gtk_Terminal_Clicked_Void, System.Address);
   function Address_To_Cb is new Ada.Unchecked_Conversion
     (System.Address, Cb_Gtk_Terminal_Clicked_Void);

   procedure Connect(Object  : access Gtk_Terminal_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Clicked_Void;
                     After   : Boolean);

   procedure On_Clicked (Self  : access Gtk_Terminal_Record;
                         Call  : Cb_Gtk_Terminal_Clicked_Void;
                         After : Boolean := False)
   is
   begin
      Connect (Self, "clicked" & ASCII.NUL, Call, After);
   end On_Clicked;

   procedure Marsh_Gtk_Terminal_Clicked_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address);
   pragma Convention (C, Marsh_Gtk_Terminal_Clicked_Void);
   
   procedure Connect(Object  : access Gtk_Terminal_Record'Class;
                     C_Name  : Glib.Signal_Name;
                     Handler : Cb_Gtk_Terminal_Clicked_Void;
                     After   : Boolean)
   is
   begin
      Unchecked_Do_Signal_Connect
         (Object      => Object,
         C_Name      => C_Name,
         Marshaller  => Marsh_Gtk_Terminal_Clicked_Void'Access,
         Handler     => Cb_To_Address (Handler),--  Set in the closure
         After       => After);
   end Connect;
   
   procedure Marsh_Gtk_Terminal_Clicked_Void
      (Closure         : GClosure;
       Return_Value    : Glib.Values.GValue;
       N_Params        : Glib.Guint;
       Params          : Glib.Values.C_GValues;
       Invocation_Hint : System.Address;
       User_Data       : System.Address)
   is
      pragma Unreferenced (Return_Value, N_Params, Invocation_Hint, User_Data);
      H   : constant Cb_Gtk_Terminal_Clicked_Void := 
                         Address_To_Cb (Get_Callback (Closure));
      Obj : constant Gtk_Terminal := 
                         Gtk_Terminal (Unchecked_To_Object (Params, 0));
   begin
      H (Obj);
      exception 
         when E : others => Process_Exception (E);
   end Marsh_Gtk_Terminal_Clicked_Void;
   
   -- type CSS_Load_Callback is access procedure
   --                          (the_view : in out Gtk.Text_View.gtk_text_view);
   procedure Set_CSS_View(for_terminal : access Gtk_Terminal_Record'Class;
                          to : in CSS_Load_Callback) is
       -- Load a handle for the text view aspect of the terminal.  This
       -- procedure is required for setting up CSS for the terminal.  The
       -- CSS_Load_Callback is the procedure that loads the CSS for the
       -- terminal's text view aspect.
   begin
      to(for_terminal.terminal);
   end Set_CSS_View;

   function Scroll_Key_Press_Check(for_terminal : access Gtk_Widget_Record'Class;
                                   for_event : Gdk.Event.Gdk_Event_Key)
   return boolean is separate;
      -- Respond to any key press events to check if an up arrow, down arrow
      -- or, in the case of terminal emulator controlled editing, left and
      -- right arrow and backspace key has been been pressed.  If so, it gets
      -- passed to the terminal emulator and not to the buffer for processing.

   procedure Switch_The_Light (for_buffer : access Gtk_Terminal_Buffer_Record'Class;
                               at_light_number : natural;
                               to_on : boolean := false;
                               with_status : UTF8_String := "";
                               and_status_b: Glib.UTF8_String := "") is
      -- Check that the switch_light_cb call back procedure is assigned.  If
      -- so, execute it, otherwise, just ignore and continue processing.
      the_term  : Gtk_Text_View := for_buffer.parent;
      the_terminal : Gtk_Terminal := Gtk_Terminal(Get_Parent(the_term));
   begin
      if for_buffer.switch_light_cb /= null
      then  -- it is assigned, so process it
         for_buffer.switch_light_cb (the_terminal, 
                                     at_light_number, to_on, 
                                     with_status, and_status_b);
      end if;
   end Switch_The_Light;
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
     
   -----------------------------
   -- Mouse Movement Routines --
   -----------------------------
   
   procedure Report_Mouse_Position(at_terminal : Gtk_Terminal;
                                   for_button : in positive;
                                   at_button_press : in boolean := true;
                                   at_button_release: in boolean := false) is
      -- Provide the service to motion notify and button press events to report
      -- the current button state and mouse position to the virtual terminal
      -- emulator client.
      use Gdk.Types;
      Esc_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.Esc);
      function To_Characters(the_number : in natural;
                             apply_offset: in boolean:= false) return string is
         result : string := " ";
         offset : natural := 16#20#;
      begin
         if apply_offset
         then  -- crank up the offset to add in the motion indicator
            offset := offset + 16#20#;
         end if;
         result(1) := Character'Val(the_number + offset);
         return result;
      end To_Characters;
      function Button_ID(for_button : in positive;
                         with_offset : in natural := 16#20#;
                         apply_offset : in boolean := false) return string is
         use GDK.Key_Map;
         function "and"(Left, Right: Gdk_Modifier_Type) 
         return Gdk_Modifier_Type is
            type Mod_Natural is mod 2**Gdk_Modifier_Type'Size;
         begin
            return Gdk_Modifier_Type(Mod_Natural(Left) and Mod_Natural(Right));
         end "and";
         total_id : natural := for_button - 1;
         offset : natural := with_offset;
         key_state: natural := The_Modifier_State(for_keymap => key_map);
         result   : string := " ";
      begin
         if apply_offset
         then  -- crank up the offset to add in the motion indicator
            offset := offset + 16#20#;
         end if;
         Translate_Modifiers(for_keymap => key_map, for_state => key_state);
         if (Gdk_Modifier_Type(key_state) and Shift_Mask) > 0
         then  -- set the shift bit
            total_id := total_id + 2#100#;
         end if;
         if ((Gdk_Modifier_Type(key_state) and Mod1_Mask) > 0) or
            ((Gdk_Modifier_Type(key_state) and Meta_Mask) > 0)
         then  -- set the Meta bit
            total_id := total_id + 2#1000#;
         end if;
         if (Gdk_Modifier_Type(key_state) and Control_Mask) > 0
         then  -- set the control bit
            total_id := total_id + 2#10000#;
         end if;
         result(1) := Character'Val(total_id + offset);
         return result;
      end Button_ID;
      mouse_details: mouse_configuration_parameters renames  
                                              at_terminal.buffer.mouse_config;
      the_button   : positive := for_button;
      depress_type : Character;
   begin
      if mouse_details.x10_mouse
      then  -- Report mouse details viz CSI M CbCxCy
         Write(at_terminal.master_fd, 
               buffer => Esc_str & "[M" & 
                         To_Characters(for_button-1, 
                                       apply_offset=>(not at_button_press)) &
                         To_Characters(mouse_details.col) &
                         To_Characters(mouse_details.row));
      elsif mouse_details.x11_mouse and not mouse_details.ext_mode
      then  -- Report mouse details viz CSI M CbCxCy
         if at_button_release then
            the_button := 2#100#;  -- 1 more than what it becomes (2#11#)
         end if;
         Write(at_terminal.master_fd, 
               buffer => Esc_str & "[M" & 
                         Button_ID(the_button, 
                                   apply_offset => (not at_button_press)) &
                         To_Characters(mouse_details.col) &
                         To_Characters(mouse_details.row));
      elsif mouse_details.x11_mouse and mouse_details.ext_mode
      then  -- Report mouse details viz CSI < Cb ; Cx ; Cy M/m
         if at_button_release
         then
            depress_type := 'm';
         else  -- button must be pressed in
            depress_type := 'M';
         end if;
         Write(at_terminal.master_fd, 
               buffer=> Esc_str & "[<" & As_String(Character'Pos(
                           Button_ID(for_button, 
                                     with_offset => 0,
                                     apply_offset=>(not at_button_press))(1)))&
                        ";" & As_String(mouse_details.col) & ";" &
                        As_String(mouse_details.row) &
                        depress_type);
      end if;
   end Report_Mouse_Position;
   
   function Motion_Notify_CB (for_terminal_view: access Gtk_Widget_Record'Class;
                              event : Gdk_Event_Motion) return boolean is
      -- If mouse moves, then this records the character (as a row and column)
      -- that the mouse is over.  That information is stored in the mouse_
      -- configuration_parameters for this terminal's buffer.
      use Gdk.Rectangle, Gdk.Types;
      function "and"(Left, Right: Gdk_Modifier_Type) 
         return Gdk_Modifier_Type is
         type Mod_Natural is mod 2**Gdk_Modifier_Type'Size;
      begin
         return Gdk_Modifier_Type(Mod_Natural(Left) and Mod_Natural(Right));
      end "and";
      the_terminal : Gtk_Terminal:=Gtk_Terminal(Get_Parent(for_terminal_view));
      the_rect     : Gdk.Rectangle.Gdk_Rectangle;
      screen_length: natural renames the_terminal.rows;
      screen_width : natural renames the_terminal.cols;
      mouse_details: mouse_configuration_parameters renames 
                                              the_terminal.buffer.mouse_config;
      mouse_button : natural;
      x_scale_factor: float;
      y_scale_factor: float;
      -- The following adjustment and offset constants were determined through
      -- trial and error (and a spreadsheet) using the Blissymbolics fixed
      -- (i.e. mono-spaced) courier font.
      xadj : constant float := 0.995;
      yadj : constant float := 0.97;
      xofs : constant float := -0.001;
      yofs : constant float := -0.004;
      -- The following preseve the x- and y- coordinates of the cursor for
      -- checking whether there has been a change in character position
      old_row : constant natural := mouse_details.row;
      old_col : constant natural := mouse_details.col;
   begin
      -- Get our boundary for scaling purposes
      Get_Visible_Rect(Gtk_Text_View(for_terminal_view), the_rect);
      -- calculate the scale factor for each of row and column (y and x)
      if screen_width >= nowrap_size
      then
         x_scale_factor := xadj* float(default_columns)/float(the_rect.Width);
      else
         x_scale_factor := xadj * float(screen_width) / float(the_rect.Width);
      end if;
      if the_terminal.buffer.scroll_region_bottom > 0
      then  -- Defined screen range
         y_scale_factor := yadj * 
                           float(the_terminal.buffer.scroll_region_bottom - 
                           the_terminal.buffer.scroll_region_top + 1) / 
                           float(the_rect.Height);
      else
         y_scale_factor := yadj * float(screen_length)/ float(the_rect.Height);
      end if;
      -- calculate the row and column number, given location and scale factor
      -- Note that the row and column for mouse are 1 based, so add 1 to them
      mouse_details.row := natural((float(event.Y)+yofs) * y_scale_factor) + 1;
      mouse_details.col := natural((float(event.X)+xofs) * x_scale_factor) + 1;
      Switch_The_Light(the_terminal.buffer, 11, false,mouse_details.col'Image,
                                                      mouse_details.row'Image);
      -- Report the mouse position if there has been a change in position and
      -- if there is a button press of any kind provding SET_BTN_EVENT_MOUSE is
      -- set
      if mouse_details.btn_event and then
         (mouse_details.row /= old_row or mouse_details.col /= old_col) and then
         ((event.state and Button1_Mask) > 0 or 
          (event.state and Button2_Mask) > 0 or
          (event.state and Button3_Mask) > 0)
      then  -- SET_BTN_EVENT_MOUSE set and a mouse button is down 
         if (event.state and Button1_Mask) > 0
         then  -- Left mouse button
            mouse_button := 1;
         elsif (event.state and Button2_Mask) > 0
         then  -- middle mouse button
            mouse_button := 2;
         elsif (event.state and Button3_Mask) > 0
         then  -- right mouse button
            mouse_button := 3;
         end if;
         Report_Mouse_Position(at_terminal => the_terminal, 
                               for_button => mouse_button,
                               at_button_press => false);
      end if;
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Motion_Notify_CB: the_rect:(H=" & the_rect.Height'Wide_Image & ",W=" & the_rect.Width'Wide_Image & ", X=" & the_rect.X'Wide_Image & ",Y=" & the_rect.X'Wide_Image & "), scale_factor (x=" & x_scale_factor'Wide_Image & ",y=" & y_scale_factor'Wide_Image & "), event: (X=" & event.X'Wide_Image & ",Y=" & event.Y'Wide_Image & ") and mouse_details: (col=" & mouse_details.col'Wide_Image & ", row=" & mouse_details.row'Wide_Image & ").");
      return false;  -- Allow for further processing of this event
   end Motion_Notify_CB;
      
   function Button_Press_CB(for_terminal_view : access Gtk_Widget_Record'Class;
                            event : Gdk.Event.Gdk_Event_Button) return boolean
   is
      -- Called whenever the mouse is clicked inside the terminal's
      -- Gtk.Text_View, but not if it leaves the window.  Event contains the
      -- details on the mouse button that was pressed.
      -- If this function returns True, then other signal handers will not be
      -- called, otherwise the button press signal will be propagted further.
      use Gdk.Event, Gtk.Clipboard, Gtk.Text_Iter;
      the_terminal : Gtk_Terminal:=Gtk_Terminal(Get_Parent(for_terminal_view));
      mouse_details: mouse_configuration_parameters renames 
                                              the_terminal.buffer.mouse_config;
      buffer       : Gtk.Text_Buffer.Gtk_Text_Buffer;
      start_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter     : Gtk.Text_Iter.Gtk_Text_Iter;
      the_clipboard: Gtk.Clipboard.Gtk_Clipboard := 
                   Gtk.Clipboard.Get_Default(Display=>Gdk.Display.Get_Default);
      result       : boolean;
   begin
      if the_terminal.buffer.alternative_screen_buffer
      then  -- using the alternative buffer for display
         buffer := the_terminal.buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(the_terminal.buffer);
      end if;
      -- Work out which button was pressed
      if event.Button = 1  -- left mouse button
      then  -- Left mouse button: start the selection highlight process
         -- First, save away the cursor position before selecting
         -- (Note: 1-based row and column)
         Get_Iter_At_Mark(buffer, end_iter, Get_Insert(buffer));
         mouse_details.pre_sel_row := natural(Get_Line(end_iter)) + 1;
         mouse_details.pre_sel_col := natural(Get_Line_Offset(end_iter)) + 1;
         Error_Log.Debug_Data(at_level => 9, with_details => "Button_Press_CB: -Left button Cursor was at (row" & mouse_details.pre_sel_row'Wide_Image & ", col" & mouse_details.pre_sel_col'Wide_Image & "), bracketed_paste_mode =" & the_terminal.buffer.bracketed_paste_mode'Wide_Image & ", the_terminal.buffer.entering_command=" & the_terminal.buffer.entering_command'Wide_Image & ", the_terminal.buffer.use_buffer_editing=" & the_terminal.buffer.use_buffer_editing'Wide_Image & ".");
         -- Then signal that we are selecting text
         mouse_details.in_select := true;
         -- Do mouse management for this button
         Report_Mouse_Position(at_terminal => the_terminal, 
                               for_button => natural(event.button));
      elsif event.Button = 2  -- middle mouse button
      then  -- Middle mouse button: start the paste process
         -- Note that a paste operation has commenced
         mouse_details.in_paste := true;
         -- Ensure cursor is correctly located
         Error_Log.Debug_Data(at_level => 9, with_details => "Button_Press_CB: - Middle button event.the_Type= '" & event.the_Type'Wide_Image & "' (" & Gdk_Event_Type'Pos(event.the_Type)'Wide_Image & "), event.Send_Event =" & event.Send_Event'Wide_Image & ", event.Button =" & event.Button'Wide_Image & ", mouse_details.row =" & mouse_details.row'Wide_Image & ", mouse_details.col =" & mouse_details.col'Wide_Image & ", entering_command = " & the_terminal.buffer.entering_command'Wide_Image & ", Get_Overwrite = " & Get_Overwrite(the_terminal.terminal)'Wide_Image & ".");
            -- restore the cursor to the correct location, but only if
            -- the copy took place within the current virtual terminal (tab)
         if mouse_details.pre_sel_row > 0 or mouse_details.pre_sel_col > 0
         then  -- a valid location has been recorded
            end_iter := Home_Iterator(for_terminal => the_terminal);
         else  -- set end_iter to the current cursor location, which is valid
            Get_Iter_At_Mark(buffer, end_iter, Get_Insert(buffer));
         end if;
         if mouse_details.pre_sel_row > 1 then
            Forward_Lines(end_iter, 
                             Gint(mouse_details.pre_sel_row - 1), result);
         end if;
         if mouse_details.pre_sel_col > 1 then
            for col in 2 .. mouse_details.pre_sel_col loop
               if not Ends_Line(end_iter) then
                  Forward_Char(end_iter, result);
               end if;
            end loop;
         end if;
         Place_Cursor(buffer, where => end_iter);
         Error_Log.Debug_Data(at_level => 9, with_details => "Button_Press_CB: - middle button Cursor is at (row" & Get_Line(end_iter)'Wide_Image & ", col" & Get_Line_Offset(end_iter)'Wide_Image & "), bracketed_paste_mode =" & the_terminal.buffer.bracketed_paste_mode'Wide_Image & ", the_terminal.buffer.entering_command=" & the_terminal.buffer.entering_command'Wide_Image & ", the_terminal.buffer.use_buffer_editing=" & the_terminal.buffer.use_buffer_editing'Wide_Image & ".");
         -- If (and only if) in insert mode, paste into the buffer
         if the_terminal.buffer.use_buffer_editing and
            the_terminal.buffer.entering_command and
            not Get_Overwrite(the_terminal.terminal)
         then  -- Paste its contents to the buffer for further processing
            Paste_Clipboard(buffer, the_clipboard);
         else  -- Send contents directly to system's terminal emulator client
            -- Set up the file descriptor for the call (and hope there is no
            -- intervening click in another terminal emulator)
            clipboard_id := the_terminal.buffer;
            -- And set up the call-back request
            Gtk.Clipboard.Request_Text(clipboard => the_clipboard, 
                                       callback => Write_From'Access);
         end if;
         Report_Mouse_Position(at_terminal => the_terminal, 
                               for_button => natural(event.button));
         -- Invalidate the pre-copy cursor location as the paste is now done
         mouse_details.pre_sel_row := 0;
         mouse_details.pre_sel_col := 0;
         -- return true;
      elsif event.Button = 3  -- right mouse button
      then
         null;  -- other than mouse click reporting, nothing to do here
         Report_Mouse_Position(at_terminal => the_terminal, 
                               for_button => natural(event.button));
      else  -- which button??
         Error_Log.Debug_Data(at_level => 9, with_details => "Button_Press_CB: button =" & event.Button'Wide_Image & ".");
      end if;
      -- For button 2, don't allow further processing, for button 1 and 3,
      -- potentially allow for further processing of this event, but
      -- only if NOT doing a 'Cell Motion Mouse Tracking' type of mouse
      -- reporting (when not, 'true'=don't allow, otherwise 'false'=allow).
      Error_Log.Debug_Data(at_level => 9, with_details => "Button_Press_CB: finishing up - ((x10_mouse=" & mouse_details.x10_mouse'Wide_Image & " OR x11_mouse=" & mouse_details.x11_mouse'Wide_Image & ") AND NOT Cell Motion Mouse Tracking (btn_event) =" & mouse_details.btn_event'Wide_Image & ") and event.Button=" & event.Button'Wide_Image & ".");
      return (((mouse_details.x10_mouse or mouse_details.x11_mouse) and
               not mouse_details.btn_event) and 
              (event.Button = 3)) or (event.Button =2);
              -- (event.Button = 1 or event.Button = 3)) or (event.Button =2);
   end Button_Press_CB;
      
   function Button_Release_CB(for_terminal_view:access Gtk_Widget_Record'Class;
                              event:Gdk.Event.Gdk_Event_Button) return boolean
   is
      -- Called whenever the mouse is clicked inside the terminal's
      -- Gtk.Text_View, but not if it leaves the window.  Event contains the
      -- details on the mouse button that was pressed.
      -- If this function returns True, then other signal handers will not be
      -- called, otherwise the button press signal will be propagted further.
      use Gdk.Event, Gtk.Clipboard, Gtk.Text_Iter;
      the_terminal : Gtk_Terminal:=Gtk_Terminal(Get_Parent(for_terminal_view));
      mouse_details: mouse_configuration_parameters renames 
                                              the_terminal.buffer.mouse_config;
      the_clipboard: Gtk.Clipboard.Gtk_Clipboard := 
                   Gtk.Clipboard.Get_Default(Display=>Gdk.Display.Get_Default);
      buffer       : Gtk.Text_Buffer.Gtk_Text_Buffer;
      start_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter     : Gtk.Text_Iter.Gtk_Text_Iter;
      result       : boolean;
   begin
      if event.Button = 1 and mouse_details.in_select
      then  -- Button 1 release: finish the selection highlight process
         Error_Log.Debug_Data(at_level => 9, with_details => "Button_Release_CB: event.the_Type= '" & event.the_Type'Wide_Image & "' (" & Gdk_Event_Type'Pos(event.the_Type)'Wide_Image & "), event.Send_Event =" & event.Send_Event'Wide_Image & ", event.Button =" & event.Button'Wide_Image & ", mouse_details.row=" & mouse_details.row'Wide_Image & ", mouse_details.col=" & mouse_details.col'Wide_Image & ", mouse_details.in_select=" & mouse_details.in_select'Wide_Image & ".");
         if the_terminal.buffer.alternative_screen_buffer
         then  -- using the alternative buffer for display
            buffer := the_terminal.buffer.alt_buffer;
         else  -- using the main buffer for display
            buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(the_terminal.buffer);
         end if;
         -- Get the selection and load into the clipboard
         Get_Selection_Bounds(buffer, start_iter, end_iter, result);
         if result then  -- some text was selected to paste
            Error_Log.Debug_Data(at_level => 9, with_details => "Button_Release_CB: Loading clipboard with '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(buffer, start_iter, end_iter)) & "'.");
            Set_Text(the_clipboard, Get_Text(buffer, start_iter, end_iter));
         end if;
         -- Reset the note that text is being selected
         mouse_details.in_select := false;
      end if;
      -- Work out if mouse position reporting is required on button release,
      -- then report if so
      if (mouse_details.x11_mouse and mouse_details.ext_mode) and then
         (event.Button  >= 1 and event.Button <= 3)
      then  -- SET_VT200_MOUSE + SET_SGR_EXT_MODE_MOUSE set + a button going up
         Report_Mouse_Position(at_terminal => the_terminal, 
                               for_button => positive(event.Button),
                               at_button_press => true,  -- i.e. no offset
                               at_button_release => true);
      end if;
      -- For button 2, don't allow further processing, for button 1 and 3,
      -- potentially allow for further processing of this event, pending it
      -- being an X10 or VT200 X11 type of mouse reporting (when not, 'true'=
      -- don't allow further processing, otherwise 'false'=allow it).
      Error_Log.Debug_Data(at_level => 9, with_details => "Button_Release_CB: finishing up - (x10_mouse=" & mouse_details.x10_mouse'Wide_Image & " OR x11_mouse=" & mouse_details.x11_mouse'Wide_Image & ") [Cell Motion Mouse Tracking (btn_event) =" & mouse_details.btn_event'Wide_Image & "] AND event.Button=" & event.Button'Wide_Image & ".");
      return ((mouse_details.x10_mouse or mouse_details.x11_mouse) and
              (event.Button = 1 or event.Button = 3)) or (event.Button =2);
   end Button_Release_CB;
      
   function Mouse_Scroll_CB(for_terminal_view:access Gtk_Widget_Record'Class;
                            event:Gdk.Event.Gdk_Event_Scroll) return boolean is
      -- Called whenever the mouse is scrolled inside the terminal's
      -- Gtk.Text_View, but not if it leaves the window.  Event contains the
      -- details on the scroll wheel motion.
      -- If this function returns True, then no other signal handers will be
      -- called, otherwise the scroll wheel signal will be propagted further.
      use Gdk.Event, Gtk.Text_Iter;
      Esc_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.Esc);
      the_terminal : Gtk_Terminal:=Gtk_Terminal(Get_Parent(for_terminal_view));
      mouse_details: mouse_configuration_parameters renames 
                                              the_terminal.buffer.mouse_config;
      direction : Gdk.Event.Gdk_Scroll_Direction;
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Mouse_Scroll_CB: (mouse_details.alt_scroll=" & mouse_details.alt_scroll'Wide_Image & " AND alternative_screen_buffer=" & the_terminal.buffer.alternative_screen_buffer'Wide_Image & ") AND THEN event.Direction = " & event.Direction'Wide_Image & ". event.The_Type = " & event.The_Type'Wide_Image & ", event.State = " & event.State'Wide_Image & ", event.Delta_X =" & event.Delta_X'Wide_Image & ", event.Delta_Y =" & event.Delta_Y'Wide_Image & ", event.X =" & event.X'Wide_Image & ", event.Y =" & event.Y'Wide_Image & ".");
      if (mouse_details.alt_scroll and 
          the_terminal.buffer.alternative_screen_buffer) and then
         (event.Direction = scroll_up or event.Direction = scroll_down or
         event.Direction = scroll_smooth)
      then  -- Pass on the scroll operation of the wheel as up or down motion
         if event.Direction = scroll_smooth
         then  -- extract the direction
            -- Gdk.Event.Get_Scroll_Direction(event, direction);
            if event.Delta_Y > 0.0
            then direction := scroll_up;
            else direction := scroll_down;
            end if;
         end if;
         -- Work out direction of wheel (up or down)
         if event.Direction = scroll_up or else direction = scroll_up
         then  -- do the up direction (which means go down)
            if the_terminal.buffer.cursor_keys_in_app_mode
            then
               Write(the_terminal.master_fd, buffer => Esc_Str & "OB");
            else
               Write(the_terminal.master_fd, buffer => Esc_Str & "[B");
            end if;
         elsif event.Direction = scroll_down or else direction = scroll_down
         then  -- do the down direction (which means go up)
            if the_terminal.buffer.cursor_keys_in_app_mode
            then
               Write(the_terminal.master_fd, buffer => Esc_Str & "OA");
            else
               Write(the_terminal.master_fd, buffer => Esc_Str & "[A");
            end if;
         end if;
         return true;
      else  -- Allow normal scroll operations to proceed
         return false;
      end if;
   end Mouse_Scroll_CB;

   procedure Write_From(the_clipboard : not null 
                               access Gtk.Clipboard.Gtk_Clipboard_Record'Class;
                        the_text : UTF8_string := "") is
      Esc_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.Esc);
   begin
      if the_text'Length > 0 then
         if clipboard_id.bracketed_paste_mode
         then
            Write(clipboard_id.master_fd,
                  buffer => Esc_Str & "[200~" & the_text & Esc_Str & "[201~");
         else
            Write(clipboard_id.master_fd, buffer => the_text);
         end if;
      end if;
   end Write_From;
     
   -------------------------------
   -- Terminal Support Routines --
   -------------------------------

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
      return UTF8_Length(Get_Whole_Line(for_buffer, at_iter, 
                                         for_printable_characters_only));
   end Line_Length;

   function Get_Whole_Line(for_buffer : in Gtk_Terminal_Buffer;
                           at_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                           for_printable_characters_only : boolean := true)
     return UTF8_String is
       -- Get the whole line that the at_iter is currently on.
      use Gtk.Text_Iter;
      buffer     : Gtk.Text_Buffer.Gtk_Text_Buffer;
      line_start : Gtk.Text_Iter.Gtk_Text_Iter;
      line_end   : Gtk.Text_Iter.Gtk_Text_Iter;
      result     : boolean;
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      -- Get pointers to the start and end of the current line
      line_start := at_iter;
      if not Starts_Line(line_start)
      then  -- not at the start of the line
         Set_Line_Offset(line_start, 0);
      end if;
      line_end := line_start;
      if not Ends_Line(line_end)
      then -- not at the end of the line
         Forward_To_Line_End(line_end, result);
      end if;
      -- Calculate and return the line between iterators
      return Get_Slice(buffer, line_start, line_end, 
                       not for_printable_characters_only);
   end Get_Whole_Line;
       
   function Get_Line_From_Start(for_buffer : in Gtk_Terminal_Buffer;
                                up_to_iter : in Gtk.Text_Iter.Gtk_Text_Iter;
                                for_printable_characters_only : boolean:= true)
     return UTF8_String is
       -- Get the line that the at_iter is currently on, starting with the
       -- first character and going up to up_to_iter.
      use Gtk.Text_Iter;
      buffer     : Gtk.Text_Buffer.Gtk_Text_Buffer;
      line_start : Gtk.Text_Iter.Gtk_Text_Iter;
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      -- Get pointers to the start and end of the current line
      line_start := up_to_iter;
      if not Starts_Line(line_start)
      then  -- not at the start of the line
         Set_Line_Offset(line_start, 0);
      end if;
      -- Calculate and return the line between iterators
      return Get_Slice(buffer, line_start, up_to_iter, 
                       not for_printable_characters_only);
   end Get_Line_From_Start;
       
   function Get_Line_To_End(for_buffer : in Gtk_Terminal_Buffer;
                            starting_from_iter: in Gtk.Text_Iter.Gtk_Text_Iter;
                            for_printable_characters_only : boolean := true)
     return UTF8_String is
       -- Get the line that the at_iter is currently on, starting with the
       -- first character and going up to up_to_iter.
      use Gtk.Text_Iter;
      buffer     : Gtk.Text_Buffer.Gtk_Text_Buffer;
      line_end   : Gtk.Text_Iter.Gtk_Text_Iter;
      result     : boolean;
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      -- Get pointers to the start and end of the current line
      line_end := starting_from_iter;
      if not Ends_Line(line_end)
      then -- not at the end of the line
         Forward_To_Line_End(line_end, result);
      end if;
      -- Calculate and return the length of the line between iterators
      return Get_Slice(buffer, starting_from_iter, line_end, 
                       not for_printable_characters_only);
   end Get_Line_To_End;
   
   function Get_Line_Number(for_terminal : Gtk.Text_View.Gtk_Text_View; 
                            at_iter : in Gtk.Text_Iter.Gtk_Text_Iter) 
   return natural is
      -- Return the current line number from the top of the screen to the
      -- specified at_iter.
      use Gtk.Text_Iter;
      result      : boolean;
      line_number : natural;
      first_line  : Gtk.Text_Iter.Gtk_Text_Iter;
      current_line: Gtk.Text_Iter.Gtk_Text_Iter := at_iter;
      the_terminal : Gtk_Terminal := Gtk_Terminal(Get_Parent(for_terminal));
   begin
      -- Get the top left hand corner point in the buffer
      first_line := Home_Iterator(for_terminal => the_terminal);
       -- Get the start of the current line
      if Get_Line_Offset(current_line) > 0
      then  -- not at the start of the line
         Set_Line_Offset(current_line, 0);
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
    
   standard_prompt : constant string := "$ ";
   root_prompt     : constant string := "# ";
   protected body check_for_command_prompt_end is
      -- Monitor input for the end of the command prompt.  This can be either
      -- the "$ " string or the "# " string, depending on whether it is root or
      -- an ordinary user.  It only looks when switched to bracketed paste mode
      -- as this seems to be always the case just prior to the command prompt.
      -- This operation is used to determine where to put the last point of the
      -- history buffer.
      procedure Start_Looking is
         -- at bracketed paste mode
      begin
         looking := true;
      end Start_Looking;
      procedure Stop_Looking is
         -- not bracketed paste mode or at pass through text
      begin
         looking := false;
         last_two := "  ";
      end Stop_Looking;
      function Is_Looking return boolean is
      begin
         return looking;
      end Is_Looking;
      procedure Check(the_character : character) is
      begin
         if looking then  -- only check if looking
            last_two(1) := last_two(2);
            last_two(2) := the_character;
         end if;
      end Check;
      function Found_Prompt_End return boolean is
      begin
         return last_two = standard_prompt or last_two = root_prompt;
      end Found_Prompt_End;
      function Current_String return string is
      begin
         return last_two;
      end Current_String;
   --   private
      -- looking : boolean := false;
      -- last_two : string(1..2) := "  ";
   end check_for_command_prompt_end;

   -------------------------
   -- Terminal Management --
   -------------------------
   
   -- The built-in Gtk.Text_Buffer Insert and Insert_at_Cursor procedures do
   -- not take into account the Overwrite status and Insert whether in Insert
   -- or in Overwrite.  Further, Gtk.Text_Buffer does not have an Overwrite or
   -- an Overwrite_at_Cursor procedure.  So we need to set up our own Insert
   -- procedures and call the relevant inherited function at the appropriate
   -- point, with overwrite handling code around it.
   procedure Insert  (into     : access Gtk_Terminal_Buffer_Record'Class;
                      at_iter  : in out Gtk.Text_Iter.Gtk_Text_Iter;
                      the_text : UTF8_String) is
      -- Inserts the_text at position at_iter. The_text will be inserted in its
      -- entirety. Emits the "insert-text" signal; insertion actually occurs in
      -- the default handler for the signal. Iter is invalidated when insertion
      -- occurs (because the buffer contents change), but the default signal
      -- handler revalidates it to point to the end of the inserted text.
      -- If in overwrite, will overwrite existing text from the cursor point
      -- onwards, rather than insert it.
      -- "at_iter": a position in the buffer
      -- "the_text": text in UTF-8 format
      use Gtk.Text_Iter, Ada.Strings.Fixed;
      function Wide_String_For(the_text : UTF8_String) return Wide_String
         renames Ada.Strings.UTF_Encoding.Wide_Strings.Decode;
      LF_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.LF);
      InsRet : constant UTF8_String(1..1) := (1 => Insert_Return);
        -- this is an inserting CR/line feed (including when in overwrite)
      iter_line : constant natural := natural(Get_Line(at_iter)) + 1;
      buffer    : Gtk.Text_Buffer.Gtk_Text_Buffer;
      end_iter  : Gtk.Text_Iter.Gtk_Text_Iter;
      delete_ch : Gtk.Text_Iter.Gtk_Text_Iter;
      result    : boolean;
      num_lf    : positive;
   begin
      if into.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := into.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(into);
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Insert: In Overwrite? : " & boolean'Wide_Image(Get_Overwrite(into.parent) or into.alternative_screen_buffer) & " and Count(source=>the_text, pattern=>InsRet) =" & Count(source=>the_text, pattern=>InsRet)'Wide_Image & " and Count(source=>the_text, pattern=>Lf_str) =" & Count(source=>the_text, pattern=>Lf_str)'Wide_Image & " with iter_line =" & iter_line'Wide_Image & " and at_iter index =" & Get_Line_Index(at_iter)'Wide_Image & " (column" & Get_Line_Offset(at_iter)'Wide_Image & ").");
      if (Get_Overwrite(into.parent) or into.alternative_screen_buffer)
         and then  -- i.e. if in 'overwrite' mode
            ((Count(source=>the_text, pattern=>InsRet) = 0) and
             (Count(source=>the_text, pattern=>LF_str) = 0))
      then  -- delete the characters at the iter before inserting the new one
         -- The assumption for overwrite is that it is only to the end of the
         -- line.  If in overwrite, you are at the end of the line and you keep
         -- typing, then it does not go to the next line, but inserts beyond the
         -- end of the line.
         Error_Log.Debug_Data(at_level => 9, with_details => "Insert: In Overwrite - checking and deleting if necessary any characters that this will overwrite (if not already at end of line)...");
         end_iter := at_iter;
         if not Ends_Line(end_iter)
         then  -- Not at end, so set up the end_iter to be the end of the line
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert: In Overwrite and not a Insert_Return character operation, Executing Forward_To_Line_End(end_iter, result)...");
            Forward_To_Line_End(end_iter, result);
         end if;
         delete_ch := at_iter;  -- starting point to work forward from
         Forward_Chars(delete_ch, the_text'Length, result);
         if result and Compare(delete_ch, end_iter) < 0
         then  -- more than enough characters to delete
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert: In Overwrite - setting end_iter := delete_ch...");
            end_iter := delete_ch;
         end if;  -- (otherwise delete as many as possible)
         if not Equal(at_iter, end_iter)
         then  -- there is something to be deleted (i.e. not at end of line)
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : In Overwrite - at_iter line number in buffer =" & Get_Line(at_iter)'Wide_Image & ", Deleting '" & Wide_String_For(the_text=>Get_Text(buffer, at_iter, end_iter)) & "' with at_iter line =" & natural'Wide_Image(natural(Get_Line(at_iter))+1) & " and at_iter index =" & Get_Line_Index(at_iter)'Wide_Image & " (column" & Get_Line_Offset(at_iter)'Wide_Image & ").");
            Delete(buffer, at_iter, end_iter);
         end if;
      end if;
      -- Now call the inherited Insert operation as appropriate
      -- this is ordinary, un-marked-up text, so just display it as is
      Get_End_Iter(buffer, end_iter);  -- get end (for comparison)
      Error_Log.Debug_Data(at_level => 9, with_details => "Insert: Working out if we need to deal with a line feed - into.scroll_region_top =" &into.scroll_region_top'Wide_Image & ", into.scroll_region_bottom =" & into.scroll_region_bottom'Wide_Image  & " and Count(source=>the_text, pattern=>InsRet) =" & Count(source=>the_text, pattern=>InsRet)'Wide_Image & " and Count(source=>the_text, pattern=>Lf_str) =" & Count(source=>the_text, pattern=>Lf_str)'Wide_Image & ".");
      if (into.scroll_region_top > 0 and into.scroll_region_bottom > 0) and
         then (Count(source=>the_text, pattern=>InsRet) > 0)
      then  -- An Inserting LF exists, need to ensure scrolling within region
         num_lf := Count(source=>the_text, pattern=>InsRet);
         if Index(the_text, InsRet) > 1
         then  -- Inserting CR/LF is part way through the_text
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(InsRet) & "') > 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", Inserting part 1 '" & Ada.Characters.Conversions.To_Wide_String(the_text(the_text'First..Index(the_text, InsRet)-the_text'First)) & "'.");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                                   the_text(the_text'First..
                                            Index(the_text, InsRet)-
                                                              the_text'First));
            Scrolled_Insert(number_of_lines => num_lf, for_buffer=> into, 
                            starting_from => at_iter);
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(InsRet) & "') > 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", now inserting part 2 '" & Ada.Characters.Conversions.To_Wide_String(the_text(Index(the_text, InsRet)-the_text'First+num_lf..the_text'Last)) & "'.");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                                   the_text(Index(the_text, InsRet)-
                                        the_text'First+num_lf..the_text'Last));
         else  -- Inserting CR/LF must be at the start
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(InsRet) & "') <= 1, Inserting" & num_lf'Wide_Image & " line feeds at buffer line number =" & Get_Line(at_iter)'Wide_Image & ".");
            Scrolled_Insert(number_of_lines => num_lf, for_buffer=> into, 
                            starting_from => at_iter);
            if the_text'Length > 1 then
               Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(InsRet) & "') <= 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", Inserting part 1 '" & Ada.Characters.Conversions.To_Wide_String(the_text(the_text'First+num_lf..the_text'Last)) & "'.");
               Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                               the_text(the_text'First+num_lf..the_text'Last));
            end if;
         end if;
      elsif (Get_Overwrite(into.parent) or into.alternative_screen_buffer)
            and then (Count(source=>the_text, pattern=>Lf_str) > 0) and then
            (Compare(at_iter, end_iter) < 0) and then
            (into.scroll_region_top > 0 and into.scroll_region_bottom > 0)
            and then (iter_line >= into.scroll_region_top and 
                      iter_line < into.scroll_region_bottom)
      then  -- LF character is actually just a move cursor down 1 line
         num_lf := Count(source=>the_text, pattern=>LF_str);
         if Index(the_text, LF_str) > 1
         then  -- CR/LF is part way through the_text
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index(the_text, LF_str) > 1 and Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(LF_str) & "') > 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", Inserting part 1 '" & Ada.Characters.Conversions.To_Wide_String(the_text(the_text'First..Index(the_text, LF_str)-the_text'First)) & "'.");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                                   the_text(the_text'First..
                                            Index(the_text, LF_str)-
                                                              the_text'First));
            Forward_Lines(at_iter, Glib.Gint(num_lf), result);
            if result
            then  -- Successfully gone one line forward
               Place_Cursor(buffer, where => at_iter);
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index(the_text, LF_str) > 1 and Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(LF_str) & "') > 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", now inserting part 2 '" & Ada.Characters.Conversions.To_Wide_String(the_text(Index(the_text, LF_str)-the_text'First+num_lf..the_text'Last)) & "'.");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                                   the_text(Index(the_text, LF_str)-
                                        the_text'First+num_lf..the_text'Last));
         else  -- CR/LF must be at the start
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index(the_text, LF_str) > 1 and Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(LF_str) & "') <= 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & " - going forward " & num_lf'Wide_Image & " line.");
            Forward_Lines(at_iter, Glib.Gint(num_lf), result);
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : attempted to move forward" & num_lf'Wide_Image & " line with result of " & result'Wide_Image & ", now at buffer line number =" & Get_Line(at_iter)'Wide_Image & ".");
            if result
            then  -- Successfully gone one line forward
               Place_Cursor(buffer, where => at_iter);
            end if;
            if the_text'Length > 1 then
               Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index(the_text, LF_str) > 1 and Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(LF_str) & "') <= 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", Inserting the text '" & Ada.Characters.Conversions.To_Wide_String(the_text(the_text'First+num_lf..the_text'Last)) & "'.");
               Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                               the_text(the_text'First+num_lf..the_text'Last));
            end if;
         end if;
      elsif (Get_Overwrite(into.parent) or into.alternative_screen_buffer)
            and then (Count(source=> the_text, pattern=> Lf_str) > 0) and then
            (into.scroll_region_top > 0 and into.scroll_region_bottom > 0)--  and
            -- then Compare(at_iter, end_iter) >= 0
      then  -- LF exists, need to ensure scrolling within region
         num_lf := Count(source=>the_text, pattern=>LF_str);
         if Index(the_text, Lf_str) > 1
         then  -- LF is part way through the_text
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(Lf_str) & "') > 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", Inserting part 1 '" & Ada.Characters.Conversions.To_Wide_String(the_text(the_text'First..Index(the_text, Lf_str)-the_text'First)) & "'.");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                                   the_text(the_text'First..
                                            Index(the_text, Lf_str)-
                                                              the_text'First));
            Scrolled_Insert(number_of_lines => num_lf, for_buffer=> into, 
                            starting_from => at_iter);
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(Lf_str) & "') > 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", now inserting part 2 '" & Ada.Characters.Conversions.To_Wide_String(the_text(Index(the_text, Lf_str)-the_text'First+num_lf..the_text'Last)) & "'.");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                                   the_text(Index(the_text, Lf_str)-
                                        the_text'First+num_lf..the_text'Last));
         else  -- LF must be at the start
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(Lf_str) & "') <= 1, scrolling for " & num_lf'Wide_Image & " Lf_str lines at buffer line number =" & Get_Line(at_iter)'Wide_Image & ".");
            Scrolled_Insert(number_of_lines => num_lf, for_buffer=> into, 
                            starting_from => at_iter);
            if the_text'Length > 1 then
               Error_Log.Debug_Data(at_level => 9, with_details => "Insert : Index('" & Ada.Characters.Conversions.To_Wide_String(the_text) & "', '" & Ada.Characters.Conversions.To_Wide_String(Lf_str) & "') <= 1, at buffer line number =" & Get_Line(at_iter)'Wide_Image & ", Inserting after Lf_str '" & Ada.Characters.Conversions.To_Wide_String(the_text(the_text'First+num_lf..the_text'Last)) & "'.");
               Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, 
                               the_text(the_text'First+num_lf..the_text'Last));
            end if;
         end if;
      else  -- Not a scroll region or no CR/LF but within a scrolled region
         if Count(source=>the_text, pattern=>InsRet) > 0
         then  -- in case there is more than one, do Count worth of them
            for item in 1 .. Count(source=>the_text, pattern=>LF_str) loop
               Error_Log.Debug_Data(at_level => 9, with_details => "Insert: inserting a LF_str at iter's line number " & Get_Line(at_iter)'Wide_Image & "...");
               Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer),at_iter, LF_str);
            end loop;
         else
            Error_Log.Debug_Data(at_level => 9, with_details => "Insert : doing regular insert of '" & Ada.Strings.UTF_Encoding.Wide_Strings.Decode(the_text) & "' at_iter line ID in buffer =" & Get_Line(at_iter)'Wide_Image  & " and at_iter index =" & Get_Line_Index(at_iter)'Wide_Image & " (column" & Get_Line_Offset(at_iter)'Wide_Image & ").");
            Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer), at_iter, the_text);
         end if;
      end if;
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
   
   procedure Scrolled_Insert(number_of_lines : in positive; 
                         for_buffer : access Gtk_Terminal_Buffer_Record'Class; 
                         starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter) is
      -- Insert the specified number of new lines at the starting_from
      -- location, scrolling down the lines below to ensure that text only
      -- moves between scroll_region_top and scroll_region_bottom, making sure
      -- that lines that scroll above or below the scroll region are discarded
      -- and that the original lines outside of the scroll region are
      -- protected.  If the scroll regions are undefined (i.e. set to 0), then
      -- this procedure does nothing other than insert a regular new line.
      -- This procedure assumes that starting_from is between scroll_region_top
      -- and scroll_region_bottom (but it checks just in case).
      use Gtk.Text_Iter;
      LF_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.LF);
      starting_line : constant natural := natural(Get_Line(starting_from)) + 1;
      buffer   : Gtk.Text_Buffer.Gtk_Text_Buffer;
      home_iter: Gtk_Text_Iter;
      last_iter: Gtk_Text_Iter;
      end_iter : Gtk_Text_Iter;
      insert_mk: Gtk.Text_Mark.Gtk_Text_Mark;
      result   : boolean;
      the_terminal: Gtk_Terminal:= Gtk_Terminal(Get_Parent(for_buffer.parent));
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      for line in 1 .. number_of_lines loop
         if (for_buffer.scroll_region_top > 0 and 
             for_buffer.scroll_region_bottom > 0) and then
            (starting_line >= for_buffer.scroll_region_top and
             starting_line <= for_buffer.scroll_region_bottom)
         then  -- scroll down below current cursor as new lines are inserted
            home_iter := Home_Iterator(for_terminal => the_terminal);
            -- Set last_iter to the last character on the last line
            last_iter := home_iter;
            Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert: for_buffer.scroll_region_top > 0 and for_buffer.scroll_region_bottom > 0, setting last_iter (=home_iter, at line " & Get_Line(last_iter)'Wide_Image & ") forward by " & Glib.Gint(for_buffer. scroll_region_bottom-1)'Wide_Image & " lines...");
            Forward_Lines(last_iter, 
                          Glib.Gint(for_buffer.scroll_region_bottom-1),
                          result);
            if not Ends_Line(last_iter)
            then  -- Not at end, set up the last_iter to be the end of the line
               Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert: Executing Forward_To_Line_End(last_iter (= line " & Get_Line(last_iter)'Wide_Image & "), result)...");
               Forward_To_Line_End(last_iter, result);
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert: last_iter now = line" & Get_Line(last_iter)'Wide_Image & ".");
            Get_End_Iter(buffer, end_iter);
            if Natural(Get_Line(last_iter))>= for_buffer.scroll_region_bottom-1
               and then Compare(last_iter, end_iter) <= 0
            then  -- lines go up to the bottom of the scrolled region
               -- Now, if the starting_from is at the bottom of the scrolled
               -- region, then we scroll with the top line disappearing.
               --  Otherwise, we push the last line out.
               if natural(Get_Line(starting_from)) + 1 >= 
                                                for_buffer.scroll_region_bottom
               then  -- scroll by removing the top line
                  -- We need to delete from the top line, set home_iter to that
                  if for_buffer.scroll_region_top > 1
                  then  -- the window starts some way down from the top line
                     Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert: Executing Forward_Lines(home_iter, " & integer'Wide_Image((for_buffer.scroll_region_top-1)) & ", result)...");
                     Forward_Lines(home_iter, 
                                   Glib.Gint(for_buffer.scroll_region_top-1),
                                   result);
                  end if;
                  -- set end iter to the end of the line at home_iter
                  end_iter := home_iter;
                  if not Ends_Line(end_iter)
                  then  -- Not at end, so set to the end of the line
                     Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert: Executing Forward_To_Line_End(end_iter (= line " & Get_Line(end_iter)'Wide_Image & "), result)...");
                     Forward_To_Line_End(end_iter, result);
                  end if;
                  -- and tip it over the end (so we delete the whole line)
                  Forward_Char(end_iter, result);
                  -- compensate by moving starting_from iter down one
                  Forward_Line(starting_from, result);
                  -- Protect the starting_from iter
                  insert_mk := Create_Mark(buffer, "InsertPt", starting_from);
               else  -- scroll by removing the bottom line
                  end_iter  := last_iter;
                  home_iter := last_iter;
                  Set_Line_Index(home_iter, 0);
                  -- and tip it over the start (so we delete the whole line)
                  Backward_Char(home_iter, result);
                  -- Protect the starting_from iter
                  insert_mk := Create_Mark(buffer, "InsertPt", starting_from);
               end if;
               -- Delete the line at the top of the scrolled region
               Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert : home_iter line number in buffer =" & Get_Line(home_iter)'Wide_Image & ", Deleting '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(buffer, home_iter, end_iter)) & "'.");
               Delete(buffer, home_iter, end_iter);
               -- Now can do the insert at the specified location:
               -- Restore the starting_from iter
               Get_Iter_At_Mark(buffer, starting_from, insert_mk);
               -- And clean up the mark
               Delete_Mark(buffer, insert_mk);
            end if;
         end if;
         -- Now insert the CR/LF at starting_from
         Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Insert: inserting a LF_str at iter's line number " & Get_Line(starting_from)'Wide_Image & "...");
         Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer),starting_from, LF_str);
      end loop;
   end Scrolled_Insert;
    
   procedure Scrolled_Delete(number_of_lines : in positive; 
                         for_buffer : access Gtk_Terminal_Buffer_Record'Class; 
                         starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter) is
      -- Delete the specified number of new lines at the starting_from
      -- location, scrolling up the lines below to ensure that text only
      -- moves between scroll_region_top and scroll_region_bottom, making sure
      -- that lines that scroll above or below the scroll region are discarded
      -- and that the original lines outside of the scroll region are
      -- protected.  If the scroll regions are undefined (i.e. set to 0), then
      -- this procedure does nothing other than delete a regular line.
      -- This procedure assumes that starting_from is between scroll_region_top
      -- and scroll_region_bottom (but it checks just in case).
      use Gtk.Text_Iter;
      LF_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.LF);
      starting_line : constant natural := natural(Get_Line(starting_from)) + 1;
      buffer   : Gtk.Text_Buffer.Gtk_Text_Buffer;
      home_iter: Gtk_Text_Iter;
      last_iter: Gtk_Text_Iter;
      end_iter : Gtk_Text_Iter;
      delete_mk: Gtk.Text_Mark.Gtk_Text_Mark;
      result   : boolean;
      the_terminal: Gtk_Terminal:= Gtk_Terminal(Get_Parent(for_buffer.parent));
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      for line in 1 .. number_of_lines loop
         if (for_buffer.scroll_region_top > 0 and 
             for_buffer.scroll_region_bottom > 0) and then
            (starting_line >= for_buffer.scroll_region_top and
             starting_line <= for_buffer.scroll_region_bottom)
         then  -- scroll up from below current cursor as lines are deleted
            home_iter := Home_Iterator(for_terminal => the_terminal);
            -- Set last_iter to the last character on the last line in the
            -- scrolled region.  A blank line gets inserted after this to
            -- replace the line that gets deleted at starting_from.
            last_iter := home_iter;
            Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: for_buffer.scroll_region_top > 0 and for_buffer.scroll_region_bottom > 0, setting last_iter (=home_iter, at line " & Get_Line(last_iter)'Wide_Image & ") forward by " & Glib.Gint(for_buffer. scroll_region_bottom-1)'Wide_Image & " lines...");
            Forward_Lines(last_iter, 
                          Glib.Gint(for_buffer.scroll_region_bottom-1),
                          result);
            if not Ends_Line(last_iter)
            then  -- Not at end, set up the last_iter to be the end of the line
               Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: Executing Forward_To_Line_End(last_iter (= line " & Get_Line(last_iter)'Wide_Image & "), result)...");
               Forward_To_Line_End(last_iter, result);
            end if;
            Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: last_iter now = line" & Get_Line(last_iter)'Wide_Image & ".");
            Get_End_Iter(buffer, end_iter);
            if Natural(Get_Line(last_iter))>= for_buffer.scroll_region_bottom-1
               and then Compare(last_iter, end_iter) <= 0
            then  -- lines go up from the bottom of the scrolled region
               -- Protect the starting_from iter
               delete_mk := Create_Mark(buffer, "DeletePt", starting_from);
               -- Now, if the starting_from is at the bottom of the scrolled
               -- region, then we just delete that line.  Otherwise, we insert
               -- a line after last_iter and delete the line at starting_from.
               if natural(Get_Line(starting_from)) + 1 >= 
                                                for_buffer.scroll_region_bottom
               then  -- delete by removing that bottom line
                  end_iter  := last_iter;
                  home_iter := last_iter;
                  Set_Line_Index(home_iter, 0);
                  -- and tip it over the start (so we delete the whole line)
                  Backward_Char(home_iter, result);
               else  -- delete by removing the line at starting_from
                  -- First up, insert the line at the bottom first up by
                  -- inserting a LF there
                  Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: inserting a LF_str at last_iter's line number " & Get_Line(last_iter)'Wide_Image & "...");
                  Gtk.Text_Buffer.Insert(Gtk_Text_Buffer(buffer),
                                         last_iter, LF_str);
                  -- Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: inserted LF_str at last_iter's line, which now has number " & Get_Line(last_iter)'Wide_Image & " (should be 1 more than previously).");
                  -- We need to delete from the starting_from line, set
                  -- home_iter to that
                  Get_Iter_At_Mark(buffer, home_iter, delete_mk);
                  -- Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: Set home_iter := starting_from.");
                  Set_Line_Index(home_iter, 0);
                  -- Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: Set home_iter to the start of the starting_from line.");
                  -- set end iter to the end of the line at home_iter
                  end_iter := home_iter;
                  -- Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: Set end_iter := home_iter.");
                  if not Ends_Line(end_iter)
                  then  -- Not at end, so set to the end of the line
                     -- Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete: Executing Forward_To_Line_End(end_iter (= line " & Get_Line(end_iter)'Wide_Image & "), result)...");
                     Forward_To_Line_End(end_iter, result);
                  end if;
                  -- and tip it over the end (so we delete the whole line)
                  Forward_Char(end_iter, result);
               end if;
               -- Delete the line at the top of the scrolled region
               Error_Log.Debug_Data(at_level => 9, with_details => "Scrolled_Delete : home_iter line number in buffer =" & Get_Line(home_iter)'Wide_Image & ", Deleting '" & Ada.Characters.Conversions.To_Wide_String(Get_Text(buffer, home_iter, end_iter)) & "'.");
               Delete(buffer, home_iter, end_iter);
               -- Restore the starting_from iter
               Get_Iter_At_Mark(buffer, starting_from, delete_mk);
               -- And clean up the mark
               Delete_Mark(buffer, delete_mk);
            end if;
         end if;
      end loop;
   end Scrolled_Delete;
   
   procedure Scroll_Down(number_of_lines : in positive; 
                         for_buffer :  access Gtk_Terminal_Buffer_Record'Class; 
                         starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter) is
      -- Scroll down the specified number of lines between scroll_region_top
      -- and scroll_region_bottom, making sure that lines that scroll above the
      -- scroll region are discarded and that the original lines outside of the
      -- scroll region are protected. If the scroll regions are undefined (i.e.
      -- set to 0), then this procedure does nothing other than go down a line
      -- if possible.  If not possible, then it will not add any new line.
      use Gtk.Text_Iter;
      LF_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.LF);
      starting_line : constant natural := natural(Get_Line(starting_from)) + 1;
      buffer   : Gtk.Text_Buffer.Gtk_Text_Buffer;
      home_iter: Gtk_Text_Iter;
      last_iter: Gtk_Text_Iter;
      cursor_mk: Gtk.Text_Mark.Gtk_Text_Mark;
      start_mk : Gtk.Text_Mark.Gtk_Text_Mark;
      column   : natural := natural(Get_Line_Index(starting_from));
      result   : boolean;
      the_terminal: Gtk_Terminal:= Gtk_Terminal(Get_Parent(for_buffer.parent));
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      for line in 1 .. number_of_lines loop
         if (for_buffer.scroll_region_top > 0 and 
             for_buffer.scroll_region_bottom > 0) and then
            (starting_line >= for_buffer.scroll_region_top and
             starting_line <= for_buffer.scroll_region_bottom)
         then  -- scroll down from below current cursor
            -- Set the home_iter to the top of the screen.  A line gets
            -- deleted at the top of the screen.
            home_iter := Home_Iterator(for_terminal => the_terminal);
            -- Set last_iter to the last character on the last line in the
            -- scrolled region.  A blank line gets inserted after this to
            -- replace the line that gets deleted at home_iter.
            last_iter := home_iter;
            Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Down: for_buffer.scroll_region_top > 0 and for_buffer.scroll_region_bottom > 0, setting last_iter (=home_iter, at line " & Get_Line(last_iter)'Wide_Image & ") forward by " & Glib.Gint(for_buffer. scroll_region_bottom-1)'Wide_Image & " lines...");
            Forward_Lines(last_iter, 
                          Glib.Gint(for_buffer.scroll_region_bottom-1),
                          result);
            if not Ends_Line(last_iter)
            then  -- Not at end, set up the last_iter to be the end of the line
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Down: Executing Forward_To_Line_End(last_iter (= line " & Get_Line(last_iter)'Wide_Image & "), result)...");
               Forward_To_Line_End(last_iter, result);
            end if;
            -- Now set home_iter to be at the scroll_region_top
            if for_buffer.scroll_region_top > 1
            then  -- Not at the top of the scroll region - go there
               Forward_Lines(home_iter, 
                             Glib.Gint(for_buffer.scroll_region_top-1),
                             result);
            end if;
            -- and preserve that location
            start_mk := Create_Mark(buffer, "StartPt", home_iter);
            -- If starting_from is before last_iter, then just move down a line
            if Get_Line(starting_from) >= 
                                   Glib.Gint(for_buffer.scroll_region_bottom-1)
            then  -- already at the top, need to scroll the screen
               -- Preserve starting_from into a mark
               cursor_mk := Create_Mark(buffer, "CursorPt", starting_from);
               -- Insert a line at the bottom
               Insert(buffer, iter=>last_iter, text=>LF_str);
               -- Restore the home_iter (as it has been destroyed by 'Insert')
               Get_Iter_At_Mark(buffer, home_iter, start_mk);
               -- Check that the last_iter is actually at the end of the screen
               -- as, if not, don't delete the line at the top
               if natural(Get_Line(last_iter))+1 >= 
                                                for_buffer.scroll_region_bottom
               then  -- Okay - there is a line at the top to delete
                  -- Set last_iter to be the end of the first line
                  last_iter := home_iter;
                  if not Ends_Line(last_iter)
                  then  -- Not at end, so set to the end of the line
                     -- Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Down: Executing Forward_To_Line_End(last_iter (= line " & Get_Line(last_iter)'Wide_Image & "), result)...");
                     Forward_To_Line_End(last_iter, result);
                  end if;
                  -- and tip it over the end (so that we delete the whole line)
                  Forward_Char(last_iter, result);
                  -- and delete it
                  Delete(buffer, home_iter, last_iter);
               end if;
               -- Restore the starting_from iter
               Get_Iter_At_Mark(buffer, starting_from, cursor_mk);
               -- And clean up the marks
               Delete_Mark(buffer, cursor_mk);
               Delete_Mark(buffer, start_mk);
            end if;
            -- Now move down a line
            Forward_Line(starting_from, result);
            if line = number_of_lines
            then  -- make sure that we are in the correct column
               while (not Ends_Line(starting_from)) and then
                     (natural(Get_Line_Offset(starting_from)) < column) loop
                  Forward_Char(starting_from, result);
               end loop;
               -- Pad out with spaces if necessary to get to correct column
               while (natural(Get_Line_Offset(starting_from)) < column) loop
                  Insert(buffer, iter=>starting_from, text=>" ");
               end loop;
            end if;
         else  -- Not a scroll region
            if Get_Line(starting_from) > 0
            then  -- lines to go
               Forward_Line(starting_from, result);
            end if;
            if line = number_of_lines
            then  -- make sure that we are in the correct column
               while (not Ends_Line(starting_from)) and then
                     (natural(Get_Line_Offset(starting_from)) < column) loop
                  Forward_Char(starting_from, result);
               end loop;
               -- Pad out with spaces if necessary to get to correct column
               while (natural(Get_Line_Offset(starting_from)) < column) loop
                  Insert(buffer, iter=>starting_from, text=>" ");
               end loop;
            end if;
         end if;
      end loop;
   end Scroll_Down;
   
   procedure Scroll_Up (number_of_lines : in positive; 
                        for_buffer :  access Gtk_Terminal_Buffer_Record'Class; 
                        starting_from :in out Gtk.Text_Iter.Gtk_Text_Iter) is
      -- Scroll up the specified number of lines between scroll_region_top
      -- and scroll_region_bottom, making sure that lines that scroll below the
      -- scroll region are discarded and that the original lines outside of the
      -- scroll region are protected. If the scroll regions are undefined (i.e.
      -- set to 0), then this procedure does nothing other than go up a line if
      -- possible.  If not possible, it does not insert any new line at the
      -- start.
      use Gtk.Text_Iter;
      LF_str : constant UTF8_String(1..1) := (1 => Ada.Characters.Latin_1.LF);
      starting_line : constant natural := natural(Get_Line(starting_from)) + 1;
      buffer   : Gtk.Text_Buffer.Gtk_Text_Buffer;
      home_iter: Gtk_Text_Iter;
      last_iter: Gtk_Text_Iter;
      cursor_mk: Gtk.Text_Mark.Gtk_Text_Mark;
      end_mark : Gtk.Text_Mark.Gtk_Text_Mark;
      column   : natural := natural(Get_Line_Index(starting_from));
      result   : boolean;
      the_terminal: Gtk_Terminal:= Gtk_Terminal(Get_Parent(for_buffer.parent));
   begin
      if for_buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         buffer := for_buffer.alt_buffer;
      else  -- using the main buffer for display
         buffer := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: In Overwrite? : " & boolean'Wide_Image(Get_Overwrite(for_buffer.parent) or for_buffer.alternative_screen_buffer) & " and starting_from index =" & Get_Line_Index(starting_from)'Wide_Image & " (column" & Get_Line_Offset(starting_from)'Wide_Image & ").");
      for line in 1 .. number_of_lines loop
         if (for_buffer.scroll_region_top > 0 and 
             for_buffer.scroll_region_bottom > 0) and then
            (starting_line >= for_buffer.scroll_region_top and
             starting_line <= for_buffer.scroll_region_bottom)
         then  -- scroll up from below current cursor as lines are deleted
            -- Set the home_iter to the top of the screen.  A line gets
            -- inserted at the top of the screen.
            home_iter := Home_Iterator(for_terminal => the_terminal);
            -- Set last_iter to the last character on the last line in the
            -- scrolled region.  This line gets deleted, being replaced by the
            -- line that gets inserted at home_iter.
            last_iter := home_iter;
            Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: for_buffer.scroll_region_top > 0 and for_buffer.scroll_region_bottom > 0, setting last_iter (=home_iter, at line " & Get_Line(last_iter)'Wide_Image & ") forward by " & Glib.Gint(for_buffer. scroll_region_bottom-1)'Wide_Image & " lines...");
            Forward_Lines(last_iter, 
                          Glib.Gint(for_buffer.scroll_region_bottom-1),
                          result);
            Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: last_iter =(" & Get_Line(last_iter)'Wide_Image & ", column" & Get_Line_Offset(last_iter)'Wide_Image & "),  checking for Ends_Line(last_iter) (=" & Ends_Line(last_iter)'Wide_Image & ").");
            if not Ends_Line(last_iter)
            then  -- Not at end, set up the last_iter to be the end of the line
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: Executing Forward_To_Line_End(last_iter (= line " & Get_Line(last_iter)'Wide_Image & "), result)...");
               Forward_To_Line_End(last_iter, result);
            end if;
            -- and preserve that location
            end_mark := Create_Mark(buffer, "EndPt", last_iter);
            -- Now set home_iter to be at the scroll_region_top
            if for_buffer.scroll_region_top > 1
            then  -- Not at the top of the scroll region - go there
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: for_buffer.scroll_region_top > 1, setting home_iter (at line " & Get_Line(home_iter)'Wide_Image & ") forward by " & Glib.Gint(for_buffer. scroll_region_top-1)'Wide_Image & " lines...");
               Forward_Lines(home_iter, 
                             Glib.Gint(for_buffer.scroll_region_top-1),
                             result);
            end if;
            -- If starting_from is after home_iter, then just move it up a line
            if Get_Line(starting_from) <= 
                                      Glib.Gint(for_buffer.scroll_region_top-1)
            then  -- already at the top, need to scroll the screen
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: Get_Line(starting_from) (=" & Get_Line(starting_from)'Wide_Image & ") <= Glib.Gint(for_buffer.scroll_region_top-1) (=" & Glib.Gint(for_buffer.scroll_region_top-1)'Wide_Image & ").");
               -- Preserve starting_from into a mark
               cursor_mk := Create_Mark(buffer, "CursorPt", starting_from);
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: Preserved starting_from into a mark.");
               -- Insert a line at the top
               Insert(buffer, iter=>home_iter, text=>LF_str);
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: Inserted new line at home_iter.");
               -- Restore the last_iter (as it has been destroyed by 'Insert')
               Get_Iter_At_Mark(buffer, last_iter, end_mark);
               -- Check that the last_iter is actually at the end of the screen
               -- as, if not, don't delete the line at the bottom
               if natural(Get_Line(last_iter))+1 >= 
                                                for_buffer.scroll_region_bottom
               then  -- Okay - there is a line at the bottom to delete
                  -- Set home_iter to be the start of the last line
                  home_iter := last_iter;
                  Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: set home_iter := last_iter.");
                  if Get_Line_Offset(home_iter) > 0
                  then  -- not at the start of the line
                     Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: Get_Line_Offset(home_iter) > 0, setting home_iter (at line " & Get_Line(home_iter)'Wide_Image & ") to column 0...");
                     Set_Line_Offset(home_iter, 0);
                  end if;      
                  -- and tip home_iter over the previous end (so that we delete
                  -- the whole line)
                  Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: home_iter is now at line" & Get_Line(home_iter)'Wide_Image & ", column" & Get_Line_Offset(home_iter)'Wide_Image & ", tipping home_iter over the previous end...");
                  Backward_Char(home_iter, result);
                  -- and delete it
                  Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: doing Delete(buffer, home_iter, last_iter)...");
                  Delete(buffer, home_iter, last_iter);
               end if;
               -- Restore the starting_from iter
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: Restoring the starting_from iter...");
               Get_Iter_At_Mark(buffer, starting_from, cursor_mk);
               -- And clean up the marks
               Error_Log.Debug_Data(at_level => 9, with_details => "Scroll_Up: And cleaning up the marks...");
               Delete_Mark(buffer, cursor_mk);
               Delete_Mark(buffer, end_mark);
            end if;
            -- Now move up a line
            Backward_Line(starting_from, result);
            if line = number_of_lines
            then  -- make sure that we are in the correct column
               while (not Ends_Line(starting_from)) and then
                     (natural(Get_Line_Offset(starting_from)) < column) loop
                  Forward_Char(starting_from, result);
               end loop;
               -- Pad out with spaces if necessary to get to correct column
               while (natural(Get_Line_Offset(starting_from)) < column) loop
                  Insert(buffer, iter=>starting_from, text=>" ");
               end loop;
            end if;
         else  -- Not a scroll region
            if Get_Line(starting_from) > 0
            then  -- lines to go
               Backward_Line(starting_from, result);
            end if;
            if line = number_of_lines
            then  -- make sure that we are in the correct column
               while (not Ends_Line(starting_from)) and then
                     (natural(Get_Line_Offset(starting_from)) < column) loop
                  Forward_Char(starting_from, result);
               end loop;
               -- Pad out with spaces if necessary to get to correct column
               while (natural(Get_Line_Offset(starting_from)) < column) loop
                  Insert(buffer, iter=>starting_from, text=>" ");
               end loop;
            end if;
         end if;
      end loop;
   end Scroll_Up;
   
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
         Handle_The_Error(the_error  => 11, 
                          error_intro=> "Read(fd): File error",
                          error_message => "File not opened.");
         buffer := (buffer'First..Buffer'Last => ' ');
         Last := 0;
         Free (in_buffer);
         raise Terminal_IO_Error;
      end if;
      res := C_Read(fd => fd, data => in_buffer, length => int(len));
      if res <= -1 or res > int(len) then
         Handle_The_Error(the_error  => 12, 
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
         Handle_The_Error(the_error  => 13, 
                          error_intro=> "Write(fd): File error",
                          error_message => "File not opened.");
         Free (out_buffer);
         raise Terminal_IO_Error;
      end if;
   
      Error_Log.Debug_Data(at_level => 9, with_details => "Write: sending to system's VT '" & Ada.Characters.Conversions.To_Wide_String(Buffer) & "'.");
      res := C_Write(fd => fd, data => out_buffer, len => Interfaces.C.int(len));
      Free (out_buffer);
   
      if res <= -1 then
         Handle_The_Error(the_error  => 14, 
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
      input2    : string(1..2) := "  ";  -- to start with
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
            elsif res > 0 and then the_fds.revents = POLLHUP
            then  -- Been commanded to exit the terminal
               read_len := natural'Last;  -- simulate 2 characters
               Error_Log.Debug_Data(at_level => 9, with_details => "Terminal_Input_Handling: input Got POLLHUP.");
               input2 := Ada.Characters.Latin_1.Esc & '<';
            else
               read_len := 0;  -- simulate no character yet
            end if;
            case read_len is
               when  0 =>  -- No character yet
                  delay 0.05;
               when  natural'Last =>  -- 2 character output
                  the_buffer.input_monitor.Put(the_character => input2(1));
                  the_buffer.input_monitor.Put(the_character => input2(2));
                  the_buffer.waiting_for_response := false;
                  delay 0.15;
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
      -- input point (i.e., before the prompt).  This edition of Key_Pressed is
      -- for the main buffer, but it is called by the Key_Pressed procedure for
      -- the alternative buffer to process its key pressed events.
      use Gtk.Text_Iter;
      procedure Process_Keys(for_buffer : access Gtk_Terminal_Buffer_Record'Class;
                             for_string : in UTF8_String;
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
         the_buf : Gtk.Text_Buffer.Gtk_Text_Buffer;
      begin
         if for_buffer.alternative_screen_buffer
         then  -- using the alternative buffer for display
            Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys SWITCHED TO ALTERNATIVE SCREEN BUFFER!!!**************************************.");
            the_buf := for_buffer.alt_buffer;
         else  -- using the main buffer for display
            the_buf := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
         end if;
         -- Check for end of line (i.e. the Return/Enter key is pressed) or
         -- alternatively User has buffer_editing (i.e. use the virtual
         -- terminal's editing) not set, and then set flags and potentially
         -- enable update of the line count.
         if ( for_string'Length > 0 and 
              not for_buffer.alternative_screen_buffer )
            and then 
            ( (for_string(for_string'Last) = Ada.Characters.Latin_1.LF and
               (not(for_string'Length > 1 and then             -- not carry-
                    for_string(for_string'Last-1) = '\') and   -- over line in
                    for_buffer.entering_command)) or           -- command line
              ((not for_buffer.use_buffer_editing) or -- process each char for
               (not for_buffer.entering_command)) or  -- system edits or apps
              for_buffer.flush_buffer )  -- tab key must have been pressed
         then  -- Return/Enter key has been pressed + not cmd line continuation
               -- or otherwise not using the buffer's editing or is in an app
            -- Reset the history processing indicator value
            Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys processing '" & Ada.Characters.Conversions.To_Wide_String(for_string) & "' after a line terminator.");
            if for_string(for_string'Last) = Ada.Characters.Latin_1.LF then
               for_buffer.history_review := false;
               Switch_The_Light(for_buffer, 2, false);
               if not for_buffer.alternative_screen_buffer then
                  if for_buffer.mouse_config.in_paste
                  then  -- reset the in_paste flag + don't switch off overwrite
                     for_buffer.mouse_config.in_paste := false;
                  else  -- not in paste - behave as per normal
                     Set_Overwrite(for_buffer.parent, false);
                     Switch_The_Light(for_buffer, 5, true);
                  end if;
               end if;
               for_buffer.entering_command := false;  -- command now entered
               Switch_The_Light(for_buffer, 6, false);
               Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed - Process_Keys (on '" & Ada.Characters.Conversions.To_Wide_String(for_string) & "') : Set for_buffer.history_review to false and Set_Overwrite(for_buffer.parent) to false and sending to client (i.e. system VT).");
            end if;
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
            -- Put ourselves into a 'waiting for response' mode
            -- This stops responses to the buffer changes in the following
            if for_buffer.bracketed_paste_mode then
               for_buffer.waiting_for_response := true;
            end if;
            if history_text and for_buffer.use_buffer_editing
            then  -- terminal client is just expecting an Enter key here
               -- we need to assume the terminal client (i.e. the system's
               -- virtual terminal) has the correct line including edits to it
               -- First, undo the 'Enter' key press
               declare
                  cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
                  res : boolean;
               begin
                  Get_Iter_At_Mark(the_buf, cursor_iter, Get_Insert(the_buf));
                  res := Backspace(the_buf, cursor_iter, false, true);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys done backspace.");
               end;
               -- Now output that enter key
               Write(fd => for_buffer.master_fd, Buffer => enter_text);
            else -- not history, normal keyboard command entry
               -- Delete the text from the buffer so that the terminal may write
               -- it back and then write that deleted text out to the termnal
               Delete(the_buf, over_range_start, and_end);  -------------******************FIX: causes a subsequent Gtk-WARNING **: 21:48:00.652: Invalid text buffer iterator: either the iterator is uninitialized... 
               Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys done Delete.");
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
            -- Update the line count
            for_buffer.line_number := line_numbers(Get_Line_Count(for_buffer));
            for_buffer.buf_line_num := line_numbers(Get_Line_Count(the_buf));
            Switch_The_Light(for_buffer,8, false, for_buffer.line_number'Image);
            Switch_The_Light(for_buffer, 9, false, for_buffer.buf_line_num'Image);
         elsif for_string'Length > 0 and then 
            ( (history_text and for_buffer.use_buffer_editing) or
              for_buffer.alternative_screen_buffer )
         then  -- some other key pressed to modify a history line
            Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys processing '" & Ada.Characters.Conversions.To_Wide_String(for_string) & "' after some other key pressed.");
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
            -- Put ourselves into a 'waiting for response' mode
            -- This stops responses to the buffer changes in the following
            if for_buffer.bracketed_paste_mode then
               for_buffer.waiting_for_response := true;
            end if;
            -- Then, undo the key press in the buffer
            declare
               cursor_iter : Gtk.Text_Iter.Gtk_Text_Iter;
               res : boolean;
            begin
               Get_Iter_At_Mark(the_buf, cursor_iter, Get_Insert(the_buf));
               -- get rid of the character just typed from the terminal
               res := Backspace(the_buf, cursor_iter, false, true);
               Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys done backspace.");
               if Get_Overwrite(for_buffer.parent)
               then  -- replace character under cursor with original
                  Gtk.Text_Buffer.
                     Insert(the_buf, cursor_iter,
                            Ada.Strings.UTF_Encoding.Wide_Strings.Encode(
                                                for_buffer.old_key_at_cursor));
                  Gtk.Text_Iter.Backward_Chars(cursor_iter, 1, res);
                  Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed  - Process_Keys inserted original character and backed up one character's distance with a result of " & res'Wide_Image & ".");
                  Place_Cursor(the_buf, where => cursor_iter);
               end if;
            end;
            -- Now output that key that was pressed
            Write(fd => for_buffer.master_fd, Buffer => for_string);
         end if;
      end Process_Keys;
      start_iter : Gtk.Text_Iter.Gtk_Text_Iter;
      end_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
      the_buf : Gtk.Text_Buffer.Gtk_Text_Buffer;
   begin     -- Key_Pressed
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Key_Pressed: Start.");
      if (for_buffer.line_number > unassigned_line_number) and
         (not for_buffer.waiting_for_response) and
         (not for_buffer.in_response)
      then  -- Spawn_Shell has been run for this terminal buffer
         if for_buffer.alternative_screen_buffer
         then  -- using the alternative buffer for display
            the_buf := for_buffer.alt_buffer;
         else  -- using the main buffer for display
            the_buf := Gtk.Text_Buffer.Gtk_Text_Buffer(for_buffer);
         end if;
         for_buffer.in_esc_sequence := false;
         Switch_The_Light(for_buffer, 7, false);
         -- Get the key(s) pressed
         if for_buffer.history_review or for_buffer.alternative_screen_buffer
         then  -- use the cursor position to copy up to
            Get_Iter_At_Mark(the_buf, end_iter, Get_Insert(the_buf));
         else  -- getting entire line (so the end point
            Get_End_Iter(the_buf, end_iter);
         end if;
         -- Get the start of the current text entered
         if for_buffer.alternative_screen_buffer
         then  -- just entered a (Unicode) character
            start_iter := end_iter;
            if Get_Line_Offset(start_iter)/= Glib.Gint(for_buffer.anchor_point)
            then  -- not at the required location
               Set_Line_Offset(start_iter, 
                               Glib.Gint(for_buffer.anchor_point));
            end if;
         elsif for_buffer.anchor_point = 0
         then  -- start_iter is at the start of the line
            Get_Iter_At_Line(the_buf, start_iter,
                             Glib.Gint(for_buffer.buf_line_num-1));
         else  -- start_iter is at anchor_point in the current line(s)
            Get_Iter_At_Line_Index(the_buf, start_iter, 
                                   Glib.Gint(for_buffer.buf_line_num-1),
                                   Glib.Gint(for_buffer.anchor_point));
         end if;
         if (not Equal(end_iter, start_iter))
         then  -- There is actually some input - get the string and act upon it
            Process_Keys(for_buffer, 
                         for_string => Get_Text(the_buf, start_iter, end_iter),
                         over_range_start => start_iter, and_end => end_iter);
         else  -- Nothing to do here
            null;  -- do nothing
         end if;
      else  -- Spawn_Shell has not yet been run for this terminal buffer
         null;  -- do nothing
      end if;
   end Key_Pressed;

   procedure Alt_Key_Pressed(for_buffer : access Gtk_Text_Buffer_Record'Class) is
      -- Respond to whenever a key is pressed by the user and ensure that it
      -- is appropriately acted upon, usually by passing it on to the terminal
      -- client.  It will also inhibit editing before the current terminal
      -- input point (i.e., before the prompt).  This edition of Key_Pressed is
      -- for the alternative buffer.
      use Buffer_Arrays;
      use Ada.Strings.UTF_Encoding.Wide_Strings;
      the_buffer   : Gtk_Terminal_Buffer;
      alt_buffer   : Gtk_Text_Buffer := Gtk_Text_Buffer(for_buffer);
   begin
      -- Error_Log.Debug_Data(at_level => 9, with_details => "Alt_Key_Pressed: Start.");
      if not Is_Empty(display_output_handling_buffer) then
         for cntr in display_output_handling_buffer.First_Index .. 
                     display_output_handling_buffer.Last_Index loop
            the_buffer := display_output_handling_buffer(cntr);
            if the_buffer.alt_buffer = alt_buffer
            then  -- found it
               Key_Pressed(for_buffer => the_buffer);
               exit;
            end if;
         end loop;
      end if;
   end Alt_Key_Pressed;
  
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
                          switch_light    : Switch_Light_Callback := null) is
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
      hypertext   : Gtk.Text_Tag.Gtk_Text_Tag;
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
         Handle_The_Error(the_error  => 15, 
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
      terminal.buffer.buf_line_num := terminal.buffer.line_number;
      Switch_The_Light(terminal.buffer, 8, false, 
                       terminal.buffer.line_number'Image);
      Switch_The_Light(terminal.buffer, 9, false, 
                       terminal.buffer.buf_line_num'Image);
      history_tag := terminal.buffer.Create_Tag("history_text");
      Set_Property(history_tag, Editable_Property, false);
      Apply_Tag(terminal.buffer, history_tag,
                start_iter, end_iter);
      hypertext := terminal.buffer.Create_Tag("hypertext");
      Set_Property(hypertext, Gtk.Text_Tag.Underline_Set_Property, true);
      Set_Property(hypertext, Gtk.Text_Tag.Underline_Rgba_Property, Blue_RGBA);
      unedit_mark := Create_Mark(terminal.buffer, "end_unedit", end_iter, 
                                 left_gravity=>true);
      Get_Iter_At_Line(terminal.buffer, start_iter,
                       Glib.Gint(terminal.buffer.line_number));
      terminal.buffer.anchor_point := 
                  UTF8_Length(Get_Text(terminal.buffer, start_iter, end_iter));
      Switch_The_Light(terminal.buffer, 10, false, 
                       terminal.buffer.anchor_point'Image);
      Place_Cursor(terminal.buffer, end_iter);
      end_mark := Create_Mark(terminal.buffer, "end_paste", end_iter, 
                              left_gravity=>true);
      end_mark := Create_Mark(terminal.buffer.alt_buffer, "end_paste",
                              end_iter, left_gravity=>true);
      Set_Colour_Highlight(terminal, 
                           highlight_colour=>terminal.buffer.highlight_colour);
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
                                with_terminal_buffer => terminal.buffer);
      -- Ensure the terminal's mark-up management is set up
      Set_The_Buffer(to => Gtk.Text_Buffer.Gtk_Text_Buffer(terminal.buffer),
                     for_markup => terminal.buffer.markup);
      Set_The_View(for_markup => terminal.buffer.markup, 
                   to => terminal.terminal);
      -- Final sanity check on the creation of the input handler task
      if terminal.term_input = null then  -- it failed out
         Handle_The_Error(the_error  => 16, 
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
      default_vert_size: constant natural := 32;
      horizontal_scale : constant natural := 10;
      vertical_scale   : constant float := 
                            1.342*float(Get_Size(terminal.current_font))/1000.0;
      col_size : Glib.Gint := Glib.Gint(columns * horizontal_scale);
      row_size : Glib.Gint := Glib.Gint(float(rows) * vertical_scale);
      term_size: aliased win_size := (0, 0, 0, 0);
   begin
      Error_Log.Debug_Data(at_level => 9, with_details => "Set_Size :  Font size =" &  Get_Size(terminal.current_font)'Wide_Image & ", Font Stretch =" & Get_Stretch(terminal.current_font)'Wide_Image & ", vertical_scale =" & vertical_scale'Wide_Image & " and row size =" & row_size'Wide_Image & ".");
      if natural(row_size) < rows
      then  -- it could be that the font has yet to be set
         row_size := Glib.Gint(rows * default_vert_size);
      end if;
      if columns >= nowrap_size
      then  -- Assume no wrapping, set displayed size to default_columns chars
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
            Handle_The_Error(the_error => 17, 
                          error_intro  => "Set_Size: Terminal resize error",
                          error_message=> "Couldn't get current window size.");
         else  -- Second, set the new number of rows and columns
            term_size.rows := Interfaces.C.unsigned_short(rows);
            term_size.cols := Interfaces.C.unsigned_short(columns);
            if IO_Control(for_file => terminal.master_fd, request=> TIOCSWINSZ,
                          params => term_size'Address) < 0
            then -- Error in rezizing :-(
               Handle_The_Error(the_error => 18, 
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
     -- Get all the text in the visibile part of the terminal's display, that
     -- is, don't get any hidden (formatting) text, but do get all other text,
     -- including that outside the displayed region (normally the history).
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
     -- This highlight colour gets applied to the background of selected text.
      use Gtk.Text_Tag_Table, Gtk.Text_Tag, Glib.Properties;
      use Gtk.CSS_Provider, Gtk.Style_Context, Gtk.Style_Provider;
      -- selection : Gtk.Text_Tag.Gtk_Text_Tag;
   begin
      terminal.buffer.highlight_colour := highlight_colour;
      -- Now load this into the CSS with the text colour being the current
      -- background colour and the background colour being this highlight
      -- colour.
      declare
         highlight : constant string := Gdk.RGBA.To_String(highlight_colour);
         background: constant string := 
                         Gdk.RGBA.To_String(terminal.buffer.background_colour);
         the_error : aliased Glib.Error.GError;
         provider  : Gtk.CSS_Provider.Gtk_CSS_Provider;
         context   : Gtk.Style_Context.Gtk_Style_Context;
      begin
         Error_Log.Debug_Data(at_level => 9, with_details => "Set_Colour_Highlight : highlight - sending '" & "textview* { .view text selection { background-color: "& Ada.Characters.Conversions.To_Wide_String(highlight) & ";  color: " & Ada.Characters.Conversions.To_Wide_String(background) & ";} text selection { background-color: " & Ada.Characters.Conversions.To_Wide_String(highlight) & ";  color: " & Ada.Characters.Conversions.To_Wide_String(background) & ";} }" & "'.");
         Gtk_New(provider);
         if Load_From_Data(provider, 
                           "textview* {" &
                                  " .view text selection { background-color: "&
                                  highlight & ";  color: " & background & ";} "&
                                  "text selection { background-color: " &
                                  highlight & ";  color: " & background & ";} "&
                                      "}",
                              the_error'access)
         then  -- successful load
            Error_Log.Debug_Data(at_level => 9, with_details => "Set_Colour_Highlight : Load_From_Data(provider) successful.");
            context := Get_Style_Context(terminal);
            Gtk.Style_Context.Add_Provider(context, +provider,
                                           Priority_Application);
         end if;
      end;
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
   
   function Get_Icon_Name(for_terminal : access Gtk_Terminal_Record'Class)
    return UTF8_String is
       -- Return the title as the operating system knows it
   begin
      if for_terminal.icon_name = Gtkada.Types.Null_Ptr
      then
         return "bliss_term";
      else
         return Gtkada.Types.Value(for_terminal.icon_name);
      end if;
   end Get_Icon_Name;
    
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

   function Home_Iterator(for_terminal : access Gtk_Terminal_Record'Class)
    return Gtk.Text_Iter.Gtk_Text_Iter is
       -- Return the home position (that is, the top left hand corner) of the
       -- currently displayed buffer area in the terminal.
       -- This function is provided because neither Get_Iter_At_Location,
       -- Get_Iter_At_Position or Get_Line_At_Y appear to be able to do
       -- anything other than provide the result that you get when calling
       -- Get_End_Iter, irrespective of whether the X and Y buffer coordinates
       -- are provided from Get_Visible_Rect or Window_To_Buffer_Coords or
       -- whether any other random value of Y is used.
       -- The output of this function is essentially a calculation based on the
       -- terminal's understanding of the number of lines it is displaying
       -- (which, if resized by mouse dragging rather than by command, may be
       -- incorrect).
      use Gtk.Text_Iter, Gtk.Text_Mark;
      the_buf      : Gtk.Text_Buffer.Gtk_Text_Buffer;
      homed_iter   : Gtk.Text_Iter.Gtk_Text_Iter;
      cursor_iter  : Gtk.Text_Iter.Gtk_Text_Iter;
      last_line    : Gtk.Text_Iter.Gtk_Text_Iter;
      cursor_line  : natural;
      total_lines  : natural;
      res          : boolean := true;
      screen_length: natural renames for_terminal.rows;
   begin
      -- The assumption here is that the current cursor position is in the
      -- visible region of the terminal.  So, finding the home position will
      -- find the position based on the cursor being visible and will assume
      -- that the cursor is at the bottom of the screen if there is more than
      -- one screen-full of text and if it is at the end of the text.  This
      -- assumption is made because Gtk.Text_Buffer will not allow blank space
      -- beneath it.  When not within the first screen ful of text, then the
      -- Get_Line_At_Y is used as it does work outside of the first page.
      -- First up, work out which buffer, the main or the alternative buffer
      -- that the top left hand corner of the screen is to be found for
      if for_terminal.buffer.alternative_screen_buffer
       then  -- using the alternative buffer for display
         the_buf := for_terminal.buffer.alt_buffer;
      else  -- using the main buffer for display
         the_buf := Gtk.Text_Buffer.Gtk_Text_Buffer(for_terminal.buffer);
      end if;
      -- Then, get the cursor and it's line number
      Get_Iter_At_Mark(the_buf,cursor_iter,Get_Insert(the_buf));
      -- Work out the line number for the cursor and the total number of lines
      cursor_line := Natural(Get_Line(cursor_iter)) + 1; -- Get_Ln is 0 based
      total_lines := Natural(Get_Line_Count(the_buf));
      -- Work out if the cursor is on the last line
      Get_End_Iter(the_buf, last_line);
      if not Starts_Line(cursor_iter) then
         Set_Line_Offset(cursor_iter, 0);
      end if;
      if not Starts_Line(last_line) then
         Set_Line_Offset(last_line, 0);
      end if;
      if Equal(cursor_iter, last_line)
      then  -- cursor is on the last line
         -- cursor must be at the bottom of the screen or there aren't that
         -- many lines in the screen page
         if cursor_line <= screen_length
         then  -- not a full screen of text to deal with
            Get_Start_Iter(the_buf, homed_iter);
         else  -- greater, so work out page boundary and go there
            -- boundary will be screen_length (SL) lines back, so we back up
            -- one less than that
            homed_iter := cursor_iter;
            Backward_Lines(homed_iter, Glib.Gint(screen_length)-1, res);
         end if;
      else  -- cursor is not on the last line
         -- work out how far up the screen page it is and go there
         if total_lines <= screen_length
         then  -- basically dist to top = SL-(TL-CL) so we go back one less
            homed_iter := cursor_iter;  -- than that
            Backward_Lines(homed_iter, 
                           Glib.Gint(screen_length-(total_lines-cursor_line))-1,
                           res);
         else  -- more than a page full and not on last line
            declare
               use Gdk.Rectangle;
               the_view : Gtk_Text_View renames for_terminal.terminal;
               buf_x, buf_y : GLib.GInt;
               line_top     : Glib.GInt;
            begin
               -- Get_Visible_Rect(the_view, buf_rect);
               Window_To_Buffer_Coords(the_view, Gtk.Enums.Text_Window_Text, 
                                       0, 0, buf_x, buf_y);
               Get_Line_At_Y(the_view, homed_iter,  buf_y, line_top);
            end;
         end if;
      end if;
      Error_Log.Debug_Data(at_level => 9, with_details => "Home_Iterator: cursor_line =" & cursor_line'Wide_Image & ", homed_iter line =" & Get_Line(homed_iter)'Wide_Image & ", total_lines =" & total_lines'Wide_Image & ", screen_length =" & screen_length'Wide_Image & " and res = " & res'Wide_Image & ".");
      return homed_iter;
   end Home_Iterator;
    
   procedure Set_ID(for_terminal : access Gtk_Terminal_Record'Class; 
                    to : natural) is
       -- Set the terminal's Identifier (which can be any positive number).
      the_buffer : Gtk_Terminal_Buffer renames for_terminal.buffer;
      alt_buffer : Gtk.Text_Buffer.Gtk_Text_Buffer renames the_buffer.alt_buffer;
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

