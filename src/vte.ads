pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;

package VTE is

  -- Generated using gcc -c -fdump-ada-spec -I /usr/include/glib-2.0/ \
  --                      -I /usr/lib/x86_64-linux-gnu/glib-2.0/include/ \
  --                      -I /usr/include/gtk-3.0/ -I /usr/include/pango-1.0/ \
  --                      -I /usr/include/harfbuzz -I /usr/include/cairo/ \
  --                      -I /usr/include/gdk-pixbuf-2.0/ -I /usr/include/atk-1.0/
  --                      -I /usr/include/vte-2.91/vte/ -C ./vte.
  -- * Copyright (C) 2001,2002,2003,2009,2010 Red Hat, Inc.
  -- *
  -- * This library is free software: you can redistribute it and/or modify
  -- * it under the terms of the GNU Lesser General Public License as published
  -- * by the Free Software Foundation, either version 3 of the License, or
  -- * (at your option) any later version.
  -- *
  -- * This library is distributed in the hope that it will be useful,
  -- * but WITHOUT ANY WARRANTY; without even the implied warranty of
  -- * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  -- * GNU Lesser General Public License for more details.
  -- *
  -- * You should have received a copy of the GNU Lesser General Public License
  -- * along with this library.  If not, see <https://www.gnu.org/licenses/>.
  --  

  -- This must always be included first  
  -- #include "vtemacros.h"
end VTE;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
