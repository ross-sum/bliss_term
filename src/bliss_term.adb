   -----------------------------------------------------------------------
   --                                                                   --
   --                          B L I S S _ T E R M                      --
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
with Ada.Directories;
with DStrings;            use DStrings;
with dStrings.IO;         use dStrings.IO;
with Error_Log;
with Host_Functions;
with Generic_Command_Parameters;
with Bliss_Term_Version;
with Setup;
with Terminal;
with Gtk.Terminal;
procedure Bliss_Term is

   Already_Running : exception;
   
   pre                    : constant wide_string := "/usr/local";
   default_config_name    : constant wide_string := "bliss_term.conf";
   default_css_name       : constant wide_string := "bliss_term.css";
   default_log_file_name  : constant wide_string := "/var/log/bliss_term.log";
   default_log_file_format: constant wide_string := "";
   default_path_to_temp   : constant wide_string := "/tmp/";
   default_path_to_config : constant wide_string := 
                                            "~/.config/" & default_config_name;
   default_path_to_glade  : constant wide_string := pre&"/etc/bliss_term.glade";
   default_path_to_css    : constant wide_string := 
                                            "~/.config/" & default_css_name;

   package Parameters is new Generic_Command_Parameters
      (Bliss_Term_Version.Version,
       "c,config,string," & default_path_to_config &
                 ",path to the configuration file for Bliss Term;" &
       "z,temp,string," & default_path_to_temp &
                 ",path to the system writable temporary directory;" &
       "i,instructive,boolean,FALSE, show verbose heading and details;" &
       "l,log,string," & default_log_file_name & 
                 ",log file name with optional path;" &
       "f,format,string," & default_log_file_format &
                 ",log file format (e.g. '' or 'WCEM=8' for UTF-8 or " & 
                 "'WECM=8‚ctrl' to do UTF-8 and turn control characters into" &
                 "a readable format);" &
       "g,glade,string," & default_path_to_glade & 
                 ",path to the Glade (display layout) file for Bliss Term;" &
       "s,css,string," & default_path_to_css & 
                 ",path to the CSS (display format) file for Bliss Term;" &
       "d,debug,integer,0,debug level (0=none + 9=max);",
       0, false);
   use Parameters;
   
   procedure Check_Configuration_Exists(at_config_path : text;
               for_default_config_name : wide_string := default_config_name) is
   -- Make sure the configuration file exists.  Create it if it does not.
      use dStrings.IO;
      use Ada.Directories;
      config_file : dStrings.IO.File_Type;
      config_name : text := To_Text(for_default_config_name);
   begin
      if not Exists (Value(at_config_path))
      then
               -- file doesn't exist yet, so check if template in /etc
               -- and copy it in (by using it) if it does.   
         Put_Line("Creating local configuration file...");
         if not Exists ("/etc/" & Value(config_name))
         then
            if Exists ("/usr/local/etc/" & Value(config_name))
            then  -- got a source to clone
               Copy_File(Source_Name => "/usr/local/etc/" & Value(config_name),
                         Target_Name => Value(at_config_path),
                         Form  => "WCEM=8");
            else  -- no source - bail at this point
               -- cause Name_Error to be raised.
               Open(config_file, mode=> In_File, name=> Value(at_config_path),
                   form => "WCEM=8");
            end if;
         else  -- exists in /etc/
            Copy_File (Source_Name => "/etc/" & Value(config_name),
                       Target_Name => Value(at_config_path),
                       Form  => "WCEM=8");
         end if;
      end if;
   end Check_Configuration_Exists;
   
   still_running : boolean := true;
   temp_path : text := Parameter(with_flag => flag_type'('z'));
   conf_path : text := Setup.Adjust_Configuration_Path(from => 
                                      Parameter(with_flag => flag_type'('c')));
   glade_path: text := Parameter(with_flag => flag_type'('g'));
   css_path  : text := Setup.Adjust_Configuration_Path(from => 
                                      Parameter(with_flag => flag_type'('s')));
begin  -- Bliss_Term
   Bliss_Term_Version.Register(revision   => "$Revision: v1.0.1 $",
                                for_module => "Bliss_Term");
   if Parameter(with_flag => flag_type'('i')) then
      Put_Line("Bliss_Term");
      Put_Line("Combining character aware Unicode terminal");
      Put_Line("Copyright (C) 2024 Hyper Quantum Pty Ltd");
      Put_Line("Written by Ross Summerfield");
      New_Line;
      -- Host_Functions.Check_Reservation;
   end if;
   if  Parameters.is_invalid_parameter or
       Parameters.is_help_parameter or
       Parameters.is_version_parameter then
      -- abort Bliss_Terminal
      return;
   end if;
   
   -- Initialise log files if necessary
   if Parameter(with_flag => flag_type'('i')) then
      Put_Line("Setting Log file to '" & 
               Value(Parameter(with_name=>Value("log"))) & "'.");
   end if;
   Error_Log.Set_Log_File_Name(
      Value(Parameter(with_name=>Value("log"))), 
      Value(Parameter(with_name=>Value("format"))));
   Error_Log.Set_Debug_Level
         (to => Parameter(with_flag => flag_type'('d')) );
   Gtk.Terminal.Set_The_Error_Handler(to => Error_Log.Put'access);
   Gtk.Terminal.Set_The_Log_Handler(to => Error_Log.Debug_Data'access);
   Error_Log.Debug_Data(at_level => 1, 
                        with_details => "----------------------------");
   Error_Log.Debug_Data(at_level => 1, 
                        with_details => "Bliss_Term: Start processing");
   still_running := false;
   
   -- Load in the configuration data
   Check_Configuration_Exists(at_config_path => conf_path);
   Check_Configuration_Exists(at_config_path => css_path,
                              for_default_config_name => default_css_name);
   -- Bring up the main menu
   Terminal.Initialise_Terminal(Parameters.The_Usage, 
                                path_to_temp => temp_path,
                                glade_filename => glade_path, 
                                css_filename => css_path,
                                at_config_path => conf_path);
   
   -- wait for termination and wait for messages
   while still_running loop
      delay 1.0;  -- wait a second
      still_running:= not Host_Functions.Told_To_Die;
   end loop;
   
   Error_Log.Debug_Data(at_level=>1, with_details=>"Bliss_Term: Finish");
                        
   exception  -- invalid parameter
      when Name_Error | Use_Error =>
         Usage("Error in configuration file name("& To_String(conf_path)&").");
      when Host_Functions.Terminate_Application =>
         null; --  requested to terminate: exit gracefully
      when Gtk.Terminal.Terminal_IO_Error =>
         --  An IO problem, log, display and then exit gracefully
         Error_Log.Put(the_error  => 1, 
                       error_intro=> "Gtk.Terminal: I/O error",
                       error_message => "Read or Write failed; exiting.");
         Put_Line("Gtk.Terminal: I/O error - Read or Write failed; exiting.");
      when Constraint_Error =>  -- probably already dealt with
         Usage("Error in glade file name("& To_String(glade_path)&").");
         raise;  -- for now (may be deleted later)
end Bliss_Term;
