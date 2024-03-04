   -----------------------------------------------------------------------
   --                                                                   --
   --                 B L I S S _ T E R M _ V E R S I O N               --
   --                                                                   --
   --                             P r o j e c t                         --
   --                                                                   --
   --                           $Revision: 1.0 $                        --
   --                                                                   --
   --  Copyright (C) 2024 Hyper Quantum Pty Ltd,                        --
   --  Written by Ross Summerfield.                                     --
   --                                                                   --
   --  Bliss  Term is a terminal built to handle  combining  character  --
   --  Unicode  fonts.  It was written because there is little  to  no  --
   --  support  for  combining characters in terminals,  even  amongst  --
   --  those that support UTF-8 Unicode.  The primary purpose of  this  --
   --  particular terminal is to support Blissymbolics, includin g for  --
   --  date and time display and for file name display.                 --
   --  This module provides the versioning for Bliss Term.              --
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
with Generic_Versions;
package Bliss_Term_Version is

   package Bliss_Term_Versions is new Generic_Versions
   ("1.0.0", "Bliss_Term");

   function Version return wide_string 
   renames Bliss_Term_Versions.Version;
   function Application_Title return wide_string
   renames Bliss_Term_Versions.Application_Title;
   function Application_Name return wide_string
   renames Bliss_Term_Versions.Application_Name;
   function Computer_Name return wide_string
   renames Bliss_Term_Versions.Computer_Name;
   procedure Register(revision, for_module : in wide_string)
   renames Bliss_Term_Versions.Register;
   function Revision_List return wide_string
   renames Bliss_Term_Versions.Revision_List;

end Bliss_Term_Version;
