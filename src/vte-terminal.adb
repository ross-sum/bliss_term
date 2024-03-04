pragma Style_Checks (Off);
pragma Warnings (Off, "*is already use-visible*");
-- with System;
-- with Glib;                    use Glib;
-- with Glib.Spawn;              use Glib.Spawn;
-- with Glib.Cancellable;        use Glib.Cancellable;
-- with Gtk.Editable;            use Gtk.Editable;
-- with Gtk.Widget;              use Gtk.Widget;
-- with Gdk.RGBA;                use Gdk.RGBA;
-- with Pango.Font;              use Pango.Font;
-- with VTE.Enums;
with Interfaces.C;
with Ada.Unchecked_Conversion;
with Glib.Type_Conversion_Hooks; use Glib.Type_Conversion_Hooks;
with Glib.Object;                use Glib.Object;
pragma Warnings(Off);  --  might be unused
with Gtkada.Types;               use Gtkada.Types;
pragma Warnings(On);

package body Vte.Terminal is

   -- type Vte_Terminal_Record is new Gtk_Widget_Record with null record;
   -- type Vte_Terminal is access all Vte_Terminal_Record'Class;
   -- type character_width_types is (narrow, wide);
   
   package Type_Conversion_Vte_Terminal is new 
           Glib.Type_Conversion_Hooks.Hook_Registrator
                         (Get_Type'Access, Vte_Terminal_Record);
   pragma Unreferenced (Type_Conversion_Vte_Terminal);

   ------------------
   -- Constructors --
   ------------------
   
   function Vte_Terminal_New return Vte_Terminal is
      The_Terminal : constant Vte_Terminal := new Vte_Terminal_Record;
   begin
      Vte.Terminal.Initialise (The_Terminal);
      return The_Terminal;
   end Vte_Terminal_New;

   function Vte_Terminal_New_With_Buffer (Buffer : UTF8_String) return Vte_Terminal is
   --  Creates a new terminal with the specified text buffer as the preset.
   --  history
   --  "buffer": The buffer to use for the new Vte.Terminal.Vte_Terminal.  It
   --  contains the previous session's data to be preset as the history.
      The_Terminal : constant Vte_Terminal := new Vte_Terminal_Record;
   begin
      Vte.Terminal.Initialise_With_Buffer (The_Terminal, Buffer);
      return The_Terminal;
   end Vte_Terminal_New_With_Buffer;

   procedure Vte_New (The_Terminal : out Vte_Terminal) is
   --  Creates a new terminal.
   begin
      The_Terminal := new Vte_Terminal_Record;
      Vte.Terminal.Initialise (The_Terminal);
   end Vte_New;

   procedure Vte_New_With_Buffer (The_Terminal : out Vte_Terminal;
                                  Buffer    : UTF8_String) is
   begin
      The_Terminal := new Vte_Terminal_Record;
      Vte.Terminal.Initialise_With_Buffer (The_Terminal, Buffer);
   end Vte_New_With_Buffer;
   
   procedure Initialize (The_Terminal : access Vte_Terminal_Record'Class) is
   --  Creates a new terminal.
   --  Initialise does nothing if the object was already created with another
   --  call to Initialise* or G_New.
      function Internal return System.Address;
        pragma Import (C, Internal, "vte_terminal_new");
   begin
      if not The_Terminal.Is_Created then
         Set_Object (The_Terminal, Internal);
      end if;
   end Initialize;
   -- procedure Initialise (The_Terminal : not null access Vte_Terminal_Record'Class)
   -- renames Initialize;
   
   procedure Initialise_With_Buffer
      (The_Terminal : access Vte_Terminal_Record'Class;
       Buffer    : UTF8_String) is
   --  Creates a new terminal with the specified text buffer as the preset
   --  history.
   --  Initialise_With_Buffer does nothing if the object was already created
   --  with another call to Initialise* or G_New.
   --  "buffer": The buffer to load for the new Vte.Terminal.Vte_Terminal.  It
   --  contains the previous session's data to be preset as the history. 
   begin
      Initialise(The_Terminal);
      -- Set the terminal up with the specified buffer as its history.
      Feed(The_Terminal, data => Buffer);
   end Initialise_With_Buffer;
 
   ---------------
   -- Callbacks --
   ---------------

   -- To make call-backs work, the GtkAda call-back is called by the C GTK
   -- function, then that GTKADA call-back calls the C GTK call-back.
   
   function To_Spawn_Async_Callback is new Ada.Unchecked_Conversion
     (System.Address, Spawn_Async_Callback);

   function To_Address is new Ada.Unchecked_Conversion
     (Spawn_Async_Callback, System.Address);

   procedure Internal_Spawn_Async_Callback (terminal : System.Address;
                                            pid : Glib.Spawn.GPid;
                                            error : System.Address;
                                            user_data : System.Address);
   pragma Convention (C, Internal_Spawn_Async_Callback);  -- ./vteterminal.h:155
   --  arg 1 (terminal) : Vte_Terminal access
   --  arg 2 (pid) : Glib.Spawn.GPid  (process ID)
   --  arg 3 (error) : GError
   --  arg 4 (user_data) : gPointer to User Data

   procedure Internal_Spawn_Async_Callback (terminal : System.Address;
                                            pid : Glib.Spawn.GPid;
                                            error : System.Address;
                                            user_data : System.Address) is
      proc: constant Spawn_Async_Callback:= To_Spawn_Async_Callback(user_data);
      stub_Vte_Terminal : Vte_Terminal_Record;
      temp_proxy : Glib.C_Proxy := Glib.To_Proxy(error);
      temp_error : Glib.Error.GError := Glib.Error.Gerror(temp_proxy);
   begin
      Proc(Vte.Terminal.Vte_Terminal(Get_User_Data(terminal,stub_Vte_Terminal)),
           pid, temp_error);
   end Internal_Spawn_Async_Callback;

   function To_Child_Setup_Func is new Ada.Unchecked_Conversion
     (System.Address, Child_Setup_Func);

   function To_Address is new Ada.Unchecked_Conversion
     (Child_Setup_Func, System.Address);
   
   procedure Internal_Child_Setup_Func (arg1 : System.Address) is
      proc : Child_Setup_Func := To_Child_Setup_Func(arg1);
   begin
      proc(arg1);
   end Internal_Child_Setup_Func;

   function To_G_Destroy_Notify is new Ada.Unchecked_Conversion
     (System.Address, GLib.G_Destroy_Notify);

   function To_Address is new Ada.Unchecked_Conversion
     (GLib.G_Destroy_Notify, System.Address);
  
   -------------
   -- Methods --
   -------------
   
   procedure Spawn_Async (terminal : access Vte_Terminal_Record'Class; 
                          pty_flags : VTE.Enums.VtePtyFlags;
                          working_directory : UTF8_String := "";
                          argv : UTF8_String := "";
                          envv : UTF8_String := "";
                          spawn_flags : Glib.Spawn.GSpawn_Flags;
                          child_setup : Child_Setup_Func;
                          child_setup_data : System.Address;
                          child_setup_data_destroy : GLib.G_Destroy_Notify;
                          timeout : timeout_period;
                          cancellable : Glib.Cancellable.Gcancellable;
                          callback : Spawn_Async_Callback;
                          user_data : System.Address) is
      procedure Internal (terminal : System.Address;
                          pty_flags : VTE.Enums.VtePtyFlags;
                          working_directory : Gtkada.Types.Chars_Ptr;
                          argv : access Gtkada.Types.Chars_Ptr;
                          envv : access Gtkada.Types.Chars_Ptr;
                          spawn_flags : Glib.Spawn.GSpawn_Flags;
                          child_setup : System.Address;
                          child_setup_data : System.Address;
                          child_setup_data_destroy : System.Address; --GLib.G_Destroy_Notify;
                          timeout : int;
                          cancellable : System.Address;  -- access Glib.Cancellable.Gcancellable;
                          callback : System.Address;  -- Internal_Spawn_Async_Callback;
                          user_data : System.Address);  -- ./vteterminal.h:161
         pragma Import (C, Internal, "vte_terminal_spawn_async");
      temp_wd     : Gtkada.Types.Chars_Ptr;
      temp_argv   : aliased Gtkada.Types.Chars_Ptr;
      temp_envv   : aliased Gtkada.Types.Chars_Ptr;
      temp_chldset: System.Address;
      temp_csdestr: System.Address;
      temp_cancel : System.Address;
   begin
      -- First, set up the strings to be in C format
      if working_directory = ""
      then
         temp_wd := Gtkada.Types.Null_Ptr;
      else
         temp_wd := New_String (working_directory);
      end if;
      if argv = ""
      then
         temp_argv := Gtkada.Types.Null_Ptr;
      else
         temp_argv := New_String (argv);
      end if;
      if envv = ""
      then
         temp_envv := Gtkada.Types.Null_Ptr;
      else
         temp_envv := New_String (envv);
      end if;
      -- Then set up the call-back pointers
      if child_setup = null
      then
         temp_chldset := System.Null_Address;
      else
         temp_chldset := To_Address (child_setup);
      end if;
      if child_setup_data_destroy = null
      then
         temp_csdestr := System.Null_Address;
      else
         temp_csdestr := To_Address(child_setup_data_destroy);
      end if;
      if cancellable = null
      then
         temp_cancel := System.Null_Address;
      else
         temp_cancel := Get_Object(cancellable);
      end if;
      -- Depending on whether the callback has been specified or not,
      -- call internal with one or with a null value.
      if callback = null
      then
         Internal(terminal =>Get_Object(terminal),
                  pty_flags => pty_flags,
                  working_directory => temp_wd,
                  argv => temp_argv'access,
                  envv => temp_envv'access,
                  spawn_flags => spawn_flags,
                  child_setup => temp_chldset,
                  child_setup_data => child_setup_data,
                  child_setup_data_destroy => temp_csdestr,
                  timeout => Int(timeout),
                  cancellable => temp_cancel,
                  callback => System.Null_Address,  -- To_Address (callback),
                  user_data => user_data);
      else
         Internal(terminal =>Get_Object(terminal),
                  pty_flags => pty_flags,
                  working_directory => temp_wd,
                  argv => temp_argv'access,
                  envv => temp_envv'access,
                  spawn_flags => spawn_flags,
                  child_setup => temp_chldset,
                  child_setup_data => child_setup_data,
                  child_setup_data_destroy => temp_csdestr,
                  timeout => Int(timeout),
                  cancellable => temp_cancel,
                  callback => Internal_Spawn_Async_Callback'Address, -- To_Address (callback),  -- System.Null_Address,
                  user_data => user_data);
      end if;
   end Spawn_Async;

    -- Terminal Configuration Management (encoding, size, etc)
   procedure Set_Encoding (for_terminal : access Vte_Terminal_Record'Class; 
                       to : in UTF8_string := "UTF8") is
      -- Set the terminal's encoding method.  If not UTF-8, then it must be a
      -- valid GIConv target.
      type GError_Pointer is access Glib.Error.GError;
      function Internal (terminal : System.Address; 
                         codeset  : in Gtkada.Types.Chars_Ptr;  
                         error    : System.Address) return Glib.GBoolean;
        pragma Import (C, Internal, "vte_terminal_set_encoding");
      function To_Address is new
                    Ada.Unchecked_Conversion(Glib.Error.GError,System.Address);
      temp_codeset : Gtkada.Types.Chars_Ptr;
      the_error    : aliased Glib.Error.GError;
      temp_error   : Glib.Error.GError_Access := the_error'access;
      result : Glib.GBoolean;
      GFALSE : constant Glib.GBoolean := Glib.GBoolean(Glib.Gint(0));
   begin
      if to = "UTF8" or to = ""
      then
         temp_codeset := Gtkada.Types.Null_Ptr;
      else
         temp_codeset := New_String (to);
      end if;
      result := Internal(Get_Object(for_terminal), temp_codeset, To_Address(the_error));
      if result = GFALSE then  -- error situation
         raise Encoding_Error;
      end if;
   end Set_Encoding;
      
   procedure Set_Character_Width 
                      (for_terminal : access Vte_Terminal_Record'Class; 
                       to : in character_width_types) is
      -- Set the terminal's character width to that specified for CJK type
      -- characters.
      procedure Internal (terminal : System.Address; width : int);
        pragma Import (C, Internal, "vte_terminal_set_cjk_ambiguous_width");
      temp_width : Interfaces.C.int := int(character_width_types'Pos(to));
   begin
      Internal(Get_Object(for_terminal), temp_width);
   end Set_Character_Width;
   
   procedure Set_Size (terminal : access Vte_Terminal_Record'Class; 
                       columns, rows : natural) is
      -- Set the terminal's size to the specified number of columns and rows.  
      procedure Internal (terminal : System.Address; 
                          columns : Glib.Glong; rows : Glib.Glong);
      pragma Import (C, Internal, "vte_terminal_set_size");
   begin
      Internal (Get_Object (terminal), 
                Glib.Glong(columns), Glib.Glong(rows));
   end Set_Size;

   procedure Feed (terminal : access Vte_Terminal_Record'Class; 
                   data : UTF8_String := "") is
     -- Send data to the terminal to display, or to the terminal's forked
     -- command to handle in some way.  If it's 'cat', they should be the same.
      procedure Internal (terminal : System.Address; 
                          data : Gtkada.Types.Chars_Ptr;
                          length : Glib.Gssize);
      pragma Import (C, Internal, "vte_terminal_feed");
      temp_data   : Gtkada.Types.Chars_Ptr;
      data_length : Glib.Gssize := Glib.Gssize(data'Length);
   begin
      if data = ""
      then
         temp_data := Gtkada.Types.Null_Ptr;
      else
         temp_data := New_String (data);
      end if;
      Internal (Get_Object (terminal), temp_data, data_length);
   end Feed;

   function Get_Text (from_terminal : access Vte_Terminal_Record'Class) 
   return UTF8_string is
     -- Get all the text in the visibilbe part of the terminal's display.
      type VteSelectionFunc is access function
             (terminal : System.Address;
              column, row : Glib.Glong;
              data : System.Address) return Glib.GBoolean;
        pragma Convention (C, VteSelectionFunc);
      function Internal (terminal : System.Address; 
                          is_selected : VteSelectionFunc;
                          user_data : System.Address;
                          attributes : System.Address)
      return Gtkada.Types.Chars_Ptr;
         pragma Import (C, Internal, "vte_terminal_get_text");
      result      : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
      temp_data   : Gtkada.Types.Chars_Ptr := Gtkada.Types.Null_Ptr;
      temp_attribs: aliased Glib.Gchar_Array(0..500) := 
                                                 (others => Glib.Gchar'Val(0));
   begin
      result := Internal(Get_Object (from_terminal), null, 
                         temp_data'Address, temp_attribs'Address);
      if result = Gtkada.Types.Null_Ptr
      then  -- return empty string (Gtkada.Types.Value can't handle a Null_Ptr)
         return "";
      else  -- some data in the string, so convert it.
         return Gtkada.Types.Value(result);
      end if;
   end Get_Text;

   procedure Set_Colour_Background (terminal: access Vte_Terminal_Record'Class;
                                    background :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the background colour to that specified.
      procedure Internal (terminal : System.Address; 
                          cursor_background : System.Address);
      pragma Import (C, Internal, "vte_terminal_set_color_background");
   begin
      Internal (Get_Object (terminal), 
                Gdk.RGBA.Gdk_RGBA_Or_Null (background'Address));
   end Set_Colour_Background;
   
   procedure Set_Colour_Text (terminal: access Vte_Terminal_Record'Class;
                              text_colour :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the text (i.e. the foreground) colour to that specified.
      procedure Internal (terminal : System.Address; 
                          cursor_foreground : System.Address);
      pragma Import (C, Internal, "vte_terminal_set_color_foreground");
   begin
      Internal (Get_Object (terminal), 
                Gdk.RGBA.Gdk_RGBA_Or_Null (text_colour'Address));
   end Set_Colour_Text;
   
   procedure Set_Colour_Bold (terminal: access Vte_Terminal_Record'Class;
                              bold_colour :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the bold text colour to that specified.
      procedure Internal (terminal : System.Address; 
                          cursor_foreground : System.Address);
      pragma Import (C, Internal, "vte_terminal_set_color_bold");
   begin
      Internal (Get_Object (terminal), 
                Gdk.RGBA.Gdk_RGBA_Or_Null (bold_colour'Address));
   end Set_Colour_Bold;
   
   procedure Set_Colour_Highlight (terminal: access Vte_Terminal_Record'Class;
                                   highlight_colour :  Gdk.RGBA.Gdk_RGBA) is
     -- Set the bold text colour to that specified.
      procedure Internal (terminal : System.Address; 
                          cursor_foreground : System.Address);
      pragma Import (C, Internal, "vte_terminal_set_color_highlight");
   begin
      Internal (Get_Object (terminal), 
                Gdk.RGBA.Gdk_RGBA_Or_Null (highlight_colour'Address));
   end Set_Colour_Highlight;
   
   procedure Set_Font (terminal: access Vte_Terminal_Record'Class;
                       to_font_desc : Pango.Font.Pango_Font_Description) is
     -- Set the terminal's font to that specified in Pango font format.
      procedure Internal (terminal : System.Address; 
                          font_desc : System.Address);
      pragma Import (C, Internal, "vte_terminal_set_font");
   begin
      Internal (Get_Object (terminal), 
                Pango.Font.To_Address (to_font_desc));
   end Set_Font;
   
   function Get_Font (terminal: access Vte_Terminal_Record'Class) return 
                                           Pango.Font.Pango_Font_Description is
     -- Set the terminal's font to that specified in Pango font format.
      function Internal (terminal : System.Address) return System.Address;
      pragma Import (C, Internal, "vte_terminal_get_font");
      function To_Font_Description is new Ada.Unchecked_Conversion
                  (System.Address, Pango.Font.Pango_Font_Description);
      the_font : aliased Pango.Font.Pango_Font_Description;
   begin
      the_font := To_Font_Description(Internal (Get_Object (terminal)));
      return the_font;
   end Get_Font;

   procedure Set_Scrollback_Lines(terminal: access Vte_Terminal_Record'Class;
                                    lines : natural) is
        -- Set the number of scroll-back lines to be kept by the terminal.  It
        -- should be noted that this is the number of lines at or above an
        -- internal minimum.
      procedure Internal (terminal : System.Address; lines : Glib.Glong);
      pragma Import (C, Internal, "vte_terminal_set_scrollback_lines");
   begin
      Internal (Get_Object (terminal), Glib.Glong(lines));
   end Set_Scrollback_Lines;
     
   function Get_Scrollback_Lines(terminal: access Vte_Terminal_Record'Class)
     return natural is
        -- Get the number of scroll-back lines that have been set.
      function Internal (terminal : System.Address) return Glib.Glong;
      pragma Import (C, Internal, "vte_terminal_get_scrollback_lines");
   begin
      return Natural(Internal (Get_Object (terminal)));
   end Get_Scrollback_Lines;

end Vte.Terminal;
