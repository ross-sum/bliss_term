-----------------------------------------------------------------------
--                                                                   --
--                          G T K . T E R M                          --
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
--  General Public Licence distributed with  Cell Writer.            --
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
   type Spawn_Closed_Callback is access procedure (terminal : Gtk_Terminal);

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

   -------------
   -- Methods --
   -------------
     
   type timeout_period is new integer range -1 .. integer'Last;
   procedure Spawn_Shell (terminal : access Gtk_Terminal_Record'Class; 
                          working_directory : UTF8_String := "";
                          command : UTF8_String := "";
                          environment : UTF8_String := "";
                          use_buffer_for_editing : boolean := true;
                          title_callback : Spawn_Title_Callback;
                          callback       : Spawn_Closed_Callback);
      -- Principally, spawn a terminal shell.  This procedure does the initial
      -- Terminal Configuration Management (encoding, size, etc).  This
      -- procedure actually launches the terminal, making sure that it is
      -- running with the right shell and set to the right directory with the
      -- right environment variables set.
   procedure Set_Encoding (for_terminal : access Gtk_Terminal_Record'Class; 
                           to : in UTF8_string := "UTF8");
      -- Set the terminal's encoding method.  If not UTF-8, then it must be a
      -- valid GIConv target.
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
     -- Get all the text in the visibilbe part of the terminal's display.

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
    
   procedure Set_ID(for_terminal : access Gtk_Terminal_Record'Class; 
                    to : natural);
       -- Set the terminal's Identifier (which can be any positive number).
    
   function Get_ID(for_terminal : access Gtk_Terminal_Record'Class) 
   return natural;
       -- Get the terminal's Identifier (which been previously set via Set_ID).
       
   procedure Shut_Down(the_terminal : access Gtk_Terminal_Record'Class);
       -- Finalise everything, shutting down any tasks.
    
   ----------------------------------------------------------------------------
   private
   ----------------------------------------------------------------------------
   
   service_initialised : boolean := false;
   the_error_handler : error_handler := null;
   procedure Handle_The_Error(the_error : in integer;
                              error_intro, error_message : in wide_string);
       -- For the error display, if the_error_handler is assigned, then call
       -- that function with the three parameters, otherwise formulate an
       -- output and write it out to Standard Error using the Write procedure.

   function UTF8_Length(of_string : in UTF8_String) return natural;
       -- get the absolute string length (i.e. including parts of characters)

   -------------------------
   -- Gtk Terminal Buffer --
   -------------------------
   
   buffer_length : constant positive := 255;
   type buf_index is mod buffer_length;
   type buffer_type is array (buf_index) of wide_character;
   max_utf_char_count : constant positive := 4;
   subtype utf_chars is positive range 1..max_utf_char_count;
   protected type input_monitor_type is
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
   
   escape_length : constant natural := 100;
   subtype escape_str_range is natural range 1..escape_length;
   subtype escape_string is string(escape_str_range);
   type line_numbers is new integer range -1 .. integer'Last;
   unassigned_line_number : constant line_numbers := -1;
   type font_modifiers is (normal, bold, italic, underline, strikethrough, 
                           span); --, reversevideo, doubleunderline, coloured);
   type font_modifier_array is array (font_modifiers) of natural;
   type Gtk_Terminal_Buffer_Record is new Gtk.Text_Buffer.Gtk_Text_Buffer_Record
      with record
         master_fd           : Interfaces.C.int;
         child_pid           : Glib.Spawn.GPid;
         child_name          : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
         line_number         : line_numbers := unassigned_line_number;
                                     -- current row number in the buffer
         anchor_point        : natural := 0;
                 -- placed at the end of the command prompt on line_number line
         waiting_for_response: boolean := false;  -- from the terminal
         in_response         : boolean := false; -- from the terminal
         just_wrapped        : boolean := false; -- is output at next line?
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
         alternative_screen_buffer: boolean := false;
         reporting_focus_enabled  : boolean := false;
         saved_cursor_pos         : Gtk.Text_Mark.Gtk_Text_Mark;
         -- Escape character handling
         markup_text         : Gtkada.Types.Chars_Ptr := Null_Ptr;
         modifier_array      : font_modifier_array := (others => 0);
         background_colour   : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Black_RGBA;
         text_colour         : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.White_RGBA;
         highlight_colour    : Gdk.RGBA.Gdk_RGBA := Gdk.RGBA.Null_RGBA;
          -- terminal display buffer handling
         input_monitor       : input_monitor_type_access;
         use_buffer_editing  : boolean := true;
            -- indicates to use the buffer's editing capabilities wherever
            -- possible or, alternatively, always use the terminal emulator's
            -- editor.
         parent              : Gtk.Text_View.Gtk_Text_View;
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
      -- input point (i.e., before the prompt).

    -- Ideally, here we should use the Hyper Quantum dynamic_lists generic
    -- library, but that is quite specific to Hyper Quantum applications (at
    -- the moment) and this is supposed to be a general GTK library component.
    -- So we will use the Ada.Containers.Vectors library instead, even though
    -- we only need to create a simple list.
    -- This list contains a pointer to each of the buffers so that, when there
    -- is some spare idle time, the Check_For_Display_Data routine can use this
    -- list to call on each buffer's display buffer to check that there is
    -- something to display, in which case it displays it.  The display
    -- operation must be done is the main application thread and cannot be done
    -- in a task.
   package Buffer_Arrays is new Ada.Containers.Vectors
         (index_type   => natural,
          element_type => Gtk_Terminal_Buffer);
   subtype buffer_array is Buffer_Arrays.vector;
   display_output_handling_buffer : buffer_array;
   
   function Check_For_Display_Data return boolean;

   ------------------
   -- Gtk Terminal --
   ------------------
   
   task type Terminal_Input_Handling is
      -- Terminal Input Handling responds to data coming from the terminal
      -- client.  This data gets displayed on the screen and could involve
      -- manipulation of the screen (for instance, to go into bold mode,
      -- change the font colour or other screen commands).
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
         scrollback_size  : natural := 0;
         current_font     : Pango.Font.Pango_Font_Description := Pango.Font.
                             To_Font_Description("Monospace Regular",size=>10);
         encoding         : encoding_types := utf8;
         title_callback   : Spawn_Title_Callback;
         closed_callback  : Spawn_Closed_Callback;
         term_input       : Terminal_Handling_Access;
         cols             : natural := 80;  -- default number of columns
         rows             : natural := 25;  -- default number of rows
      end record;
       
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
      
   -- Supporting IO functions
   procedure Write(fd    : in out Interfaces.C.int; Buffer : in string);
   procedure Read (fd    : in out Interfaces.C.int; 
                   buffer: in out string; Last: out natural);
      
end Gtk.Terminal;
