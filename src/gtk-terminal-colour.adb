-----------------------------------------------------------------------
--                                                                   --
--               G T K . T E R M I N A L . C O L O U R               --
--                                                                   --
--                              B o d y                              --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2024  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This  package provides the 8-bit colour palette support  for  a  --
--  simple virtual terminal interface, which contains the necessary  --
--  components to construct and run a virtual  terminal.             --
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

-- with Gdk.RGBA;                use Gdk.RGBA;
package body Gtk.Terminal.Colour is

   -- type colour_palette_number is new integer range 0..255;

   function RGB(for_colour : in colour_palette_number) return Gdk.RGBA.Gdk_RGBA
   is
   begin
      return (GDouble(colour_pallette(for_colour).red)/255.0,
              GDouble(colour_pallette(for_colour).green)/255.0,
              GDouble(colour_pallette(for_colour).blue)/255.0,
              1.0);
   end RGB;

end Gtk.Terminal.Colour;
