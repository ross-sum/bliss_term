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
   function Get_Key_Map(for_display : in Gdk_Display) return Gdk_Keymap;
   
   function Num_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
   function Caps_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
   function Scroll_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
   function There_Are_BIDI_Layouts(for_keymap : access Gdk_Keymap_Record) 
   return boolean;
   
end GDK.Key_Map;