-----------------------------------------------------------------------
--                                                                   --
--                       G D K . K E Y _ M A P                       --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2024  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package provides a simple and incomplete Ada interface  to  --
--  the GDK Keymap C library within the GTK system.                  --
--  A  GdkKeymap  defines  the  translation  from  keyboard   state  --
--  (including a hardware key, a modifier mask, and active keyboard  --
--  group) to a keyval. This translation has two phases. The  first  --
--  phase  is to determine the effective keyboard group  and  level  --
--  for  the  keyboard state; the second phase is to  look  up  the  --
--  keycode/group/level  triplet in the keymap and see what  keyval  --
--  it corresponds to.                                               --
--  You  should also refer to Gdk.Types and  Gdk.Types.Keysyms  for  --
--  key  translations as that package defines the numerical  values  --
--  that are passed into the application.                            --
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
with Glib.Object;  use Glib.Object;
with Gdk.Display;  use Gdk.Display;
package GDK.Key_Map is

   type Gdk_Keymap_Record is new GObject_Record with null record;
   type Gdk_Keymap is access all Gdk_Keymap_Record'Class;
   
   function Get_Default_Key_Map return Gdk_Keymap;
   pragma Obsolescent (Get_Default_Key_Map);
      -- Returns the GdkKeymap attached to the default display.
      -- This call is apparently depreciated since 3.22.
      -- Use Get_Key_Map() instead.
   function Get_Key_Map(for_display : in Gdk_Display) return Gdk_Keymap;
      -- Returns the GdkKeymap attached to display.
   
   function Num_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
      -- Returns whether the Num Lock modifer is locked.
      -- Returns TRUE if Num Lock is on.
   function Caps_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
      -- Returns whether the Caps Lock modifer is locked.
      -- Returns TRUE if Caps Lock is on.
   function Scroll_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
      -- Returns whether the Scroll Lock modifer is locked.
      -- Returns TRUE if Scroll Lock is on.
   function There_Are_BIDI_Layouts(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
      -- Determines if keyboard layouts for both right-to-left and
      -- left-to-right languages are in use.
      -- Returns TRUE if there are layouts in both directions, FALSE otherwise.
   function The_Modifier_State(for_keymap : access Gdk_Keymap_Record) 
   return natural;
      -- Returns the current modifier state.
      -- Known modifier states are:
      --    shift
      --    meta
      --    control
   
end GDK.Key_Map;