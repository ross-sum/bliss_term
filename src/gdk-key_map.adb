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
-- pragma Warnings (Off, "*is already use-visible*");
-- with Glib.Object;  use Glib.Object;
-- with Gdk.Display;  use Gdk.Display;
with Interfaces.C;
with Ada.Unchecked_Conversion;
with Glib;                       use Glib;
with Glib.Type_Conversion_Hooks; use Glib.Type_Conversion_Hooks;
package body GDK.Key_Map is

--    type Gdk_Keymap_Record is new GObject_Record with null record;
--    type Gdk_Keymap is access all Gdk_Keymap_Record'Class;

   function Convert (R : Gdk_Keymap) return System.Address is
   begin
      return Get_Object (R);
   end Convert;
   function Convert (R : System.Address) return Gdk.Key_Map.Gdk_Keymap is
      Stub : Gdk.Key_Map.Gdk_Keymap_Record;
   begin
      return Gdk.Key_Map.Gdk_Keymap (Glib.Object.Get_User_Data (R, Stub));
   end Convert;
         
   function Get_Default_Key_Map return Gdk_Keymap is
      function Internal return System.Address;
      pragma Import (C, Internal, "gdk_keymap_get_default");
   begin
      return Convert(Internal);
   end Get_Default_Key_Map;
   
   function Get_Key_Map(for_display : in Gdk_Display) 
   return Gdk_Keymap is
      function Internal(display : System.Address) return System.Address;
      pragma Import (C, Internal, "gdk_keymap_get_for_display");
   begin
      return Convert(Internal(Get_Object (for_display)));
   end Get_Key_Map;
   
   function Num_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean is
      function Internal(K : System.Address) return gBoolean;
      pragma Import (C, Internal, "gdk_keymap_get_num_lock_state");
   begin
      return Internal(Get_Object(for_keymap)) /= 0;
   end Num_Lock_Is_On;
   
   function Caps_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean is
      function Internal(K : System.Address) return gBoolean;
      pragma Import (C, Internal, "gdk_keymap_get_caps_lock_state");
   begin
      return Internal(Get_Object(for_keymap)) /= 0;
   end Caps_Lock_Is_On;
   
   function Scroll_Lock_Is_On(for_keymap : access Gdk_Keymap_Record) 
   return boolean is
      function Internal(K : System.Address) return gBoolean;
      pragma Import (C, Internal, "gdk_keymap_get_scroll_lock_state");
   begin
      return Internal(Get_Object(for_keymap)) /= 0;
   end Scroll_Lock_Is_On;
   
   function There_Are_BIDI_Layouts(for_keymap : access Gdk_Keymap_Record) 
   return boolean is
      function Internal(K : System.Address) return gBoolean;
      pragma Import (C, Internal, "gdk_keymap_have_bidi_layouts");
   begin
      return Internal(Get_Object(for_keymap)) /= 0;
   end There_Are_BIDI_Layouts;
   
end GDK.Key_Map;