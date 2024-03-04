pragma Warnings (Off, "*is already use-visible*");
with System;
with Glib;                    use Glib;
with Glib.Spawn;              use Glib.Spawn;
with Glib.Cancellable;        use Glib.Cancellable;
with Glib.Error;
with Gtk.Editable;            use Gtk.Editable;
with Gtk.Widget;              use Gtk.Widget;
with Gdk.RGBA;                use Gdk.RGBA;
with Pango.Font;              use Pango.Font;
with VTE.Enums;

package Vte.Terminal is

   Encoding_Error : exception;

   type Vte_Terminal_Record is new Gtk_Widget_Record with null record;
   type Vte_Terminal is access all Vte_Terminal_Record'Class;

   ------------------
   -- Constructors --
   ------------------
   procedure Vte_New (The_Terminal : out Vte_Terminal);
   procedure Initialize(The_Terminal: access Vte_Terminal_Record'Class);
   procedure Initialise(The_Terminal: access Vte_Terminal_Record'Class)
   renames Initialize;
   --  Creates a new terminal.
   --  Initialise does nothing if the object was already created with another
   --  call to Initialise* or G_New.

   function Vte_Terminal_New return Vte_Terminal;
   --  Creates a new terminal.

   procedure Vte_New_With_Buffer
      (The_Terminal : out Vte_Terminal; Buffer : UTF8_String);
   procedure Initialise_With_Buffer
      (The_Terminal : access Vte_Terminal_Record'Class;
       Buffer    : UTF8_String);
   --  Creates a new terminal with the specified text buffer.
   --  Since: gtk+ 2.18
   --  Initialise_With_Buffer does nothing if the object was already created
   --  with another call to Initialise* or G_New.
   --  "buffer": The buffer to load for the new Vte.Terminal.Vte_Terminal.  It
   --  contains the previous session's data to be preset as the history. 

   function Vte_Terminal_New_With_Buffer (Buffer : UTF8_String)
       return Vte_Terminal;
   --  Creates a new entry with the specified text buffer.
   --  Since: gtk+ 2.18
   --  "buffer": The buffer to use for the new Gtk.GEntry.Gtk_Entry.

   function Get_Type return Glib.GType;
   pragma Import (C, Get_Type, "vte_terminal_get_type");

   ---------------
   -- Callbacks --
   ---------------

   type Spawn_Async_Callback is access procedure
        (terminal : Vte_Terminal;
         pid : Glib.Spawn.GPid;
         error : Glib.Error.GError);
         -- user_data : GLib.GIO.Gpointer);

   type Child_Setup_Func is access procedure (arg1 : System.Address);
   pragma Convention (C, Child_Setup_Func);

   -------------
   -- Methods --
   -------------
     
   type timeout_period is new integer range -1 .. integer'Last;
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
                          user_data : System.Address);
   -- Terminal Configuration Management (encoding, size, etc)
   procedure Set_Encoding (for_terminal : access Vte_Terminal_Record'Class; 
                           to : in UTF8_string := "UTF8");
      -- Set the terminal's encoding method.  If not UTF-8, then it must be a
      -- valid GIConv target.
   procedure Set_Size (terminal : access Vte_Terminal_Record'Class; 
                       columns, rows : natural);
      -- Set the terminal's size to the specified number of columns and rows.  
   type character_width_types is (normal, narrow, wide);
   for character_width_types use (normal => 0, narrow => 1, wide => 2);
      -- 'normal' in the above should never be used.  It is included because
      -- GNAT does not honour the for - use clause above ('narrow' MUST = 1).
   procedure Set_Character_Width 
                      (for_terminal : access Vte_Terminal_Record'Class; 
                       to : in character_width_types);
      -- Set the terminal's character width to that specified for CJK type
      -- characters.  

   -- Terminal Colour and Font Management
   procedure Set_Colour_Background (terminal: access Vte_Terminal_Record'Class;
                                    background :  Gdk.RGBA.Gdk_RGBA);
     -- Set the background colour to that specified.
   procedure Set_Colour_Text (terminal: access Vte_Terminal_Record'Class;
                              text_colour :  Gdk.RGBA.Gdk_RGBA);
     -- Set the text (i.e. the foreground) colour to that specified.
   procedure Set_Colour_Bold (terminal: access Vte_Terminal_Record'Class;
                              bold_colour :  Gdk.RGBA.Gdk_RGBA);
     -- Set the bold text colour to that specified.
   procedure Set_Colour_Highlight (terminal: access Vte_Terminal_Record'Class;
                                   highlight_colour :  Gdk.RGBA.Gdk_RGBA);
     -- Set the highlighted text colour to that specified.
     
   procedure Set_Font (terminal : access Vte_Terminal_Record'Class; 
                       to_font_desc : Pango.Font.Pango_Font_Description);
        -- Set the terminal's font to that specified in Pango font format.
   function Get_Font (terminal : access Vte_Terminal_Record'Class) return 
                                           Pango.Font.Pango_Font_Description;
        -- Get the terminal's currently set font in Pango font format.
  
   -- Terminal Display Management
   procedure Feed (terminal : access Vte_Terminal_Record'Class; 
                   data : UTF8_String := "");
     -- Send data to the terminal to display, or to the terminal's forked
     -- command to handle in some way.  If it's 'cat', they should be the same.
   function Get_Text (from_terminal : access Vte_Terminal_Record'Class) 
     return UTF8_string;
     -- Get all the text in the visibilbe part of the terminal's display.

   procedure Set_Scrollback_Lines(terminal: access Vte_Terminal_Record'Class;
                                    lines : natural);
        -- Set the number of scroll-back lines to be kept by the terminal.  It
        -- should be noted that this is the number of lines at or above an
        -- internal minimum.
   function Get_Scrollback_Lines(terminal: access Vte_Terminal_Record'Class)
     return natural;
        -- Get the number of scroll-back lines that have been set.
     
end Vte.Terminal;
