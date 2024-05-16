-----------------------------------------------------------------------
--                                                                   --
--                G T K . T E R M . I N T E R F A C E                --
--                                                                   --
--                     S p e c i f i c a t i o n                     --
--                                                                   --
--                           $Revision: 1.0 $                        --
--                                                                   --
--  Copyright (C) 2024  Hyper Quantum Pty Ltd.                       --
--  Written by Ross Summerfield.                                     --
--                                                                   --
--  This package provides the C interfaces to the system  functions  --
--  used  to build a virtual terminal.  There are  more  interfaces  --
--  defined than are used.  Many of these relate to the journey  in  --
--  getting  the  terminal to work and have been left in  place  in  --
--  case they are required in the future.                            --
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
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with Ada.Characters.Conversions;
with GLib, Glib.Spawn;
with Gtkada.Types;
package Gtk.Terminal.CInterface is

   type flags is array (0 .. Interfaces.C.int'size - 1) of boolean;
   pragma pack (flags);
   -- File status flags for opening files
   O_RDONLY : constant flags := (others => false);           -- Open read-only
   O_WRONLY : constant flags := (0 => true, others=>false);  -- Open write-only
   O_RDWR   : constant flags := (1 => true, others=>false);  -- Open read/write
   O_NOCTTY : constant flags := (15=> true, others=>false);
                                 -- Don't assign a controlling terminal
   -- I/O control flags and commands
   TIOCSWINSZ:constant Interfaces.C.unsigned_long  := 16#5414#;
   TIOCSCTTY : constant Interfaces.C.unsigned_long := 16#540E#;
   -- Input mode flag bits (/usr/include/asm-generic/termbits.h)
   IUCLC     : constant Interfaces.C.unsigned      := 16#0200#;
   IXON      : constant Interfaces.C.unsigned      := 16#0400#;
   IXOFF     : constant Interfaces.C.unsigned      := 16#1000#;
   IMAXBEL   : constant Interfaces.C.unsigned      := 16#2000#;
   IUTF8     : constant Interfaces.C.unsigned      := 16#4000#;
   -- local mode flag bits (/usr/include/asm-generic/termbits.h)
   ISIG      : constant Interfaces.C.unsigned      := 16#00001#;
   ICANON    : constant Interfaces.C.unsigned      := 16#00002#;
   XCASE     : constant Interfaces.C.unsigned      := 16#00004#;
   ECHO      : constant Interfaces.C.unsigned      := 16#00008#;
   ECHOE     : constant Interfaces.C.unsigned      := 16#00010#;
   ECHOK     : constant Interfaces.C.unsigned      := 16#00020#;
   ECHONL    : constant Interfaces.C.unsigned      := 16#00040#;
   NOFLSH    : constant Interfaces.C.unsigned      := 16#00080#;
   TOSTOP    : constant Interfaces.C.unsigned      := 16#00100#;
   ECHOCTL   : constant Interfaces.C.unsigned      := 16#00200#;
   ECHOPRT   : constant Interfaces.C.unsigned      := 16#00400#;
   ECHOKE    : constant Interfaces.C.unsigned      := 16#00800#;
   FLUSHO    : constant Interfaces.C.unsigned      := 16#01000#;
   PENDIN    : constant Interfaces.C.unsigned      := 16#04000#;
   IEXTEN    : constant Interfaces.C.unsigned      := 16#08000#;
   EXTPROC   : constant Interfaces.C.unsigned      := 16#10000#;
   -- Optional actions flags (/usr/include/asm-generic/termbits.h)
   TCSANOW   : constant Interfaces.C.int := 0;
   TCSADRAIN : constant Interfaces.C.int := 1;
   TCSAFLUSH : constant Interfaces.C.int := 2;

   NCCS : constant natural := 19;
   type NCCS_array is array (0..NCCS) of character;
   type term_attribs is record --C termio (/usr/include/asm-generic/termbits.h)
         input_mode_flags   : Interfaces.C.unsigned;
         output_mode_flags  : Interfaces.C.unsigned;
         control_mode_flags : Interfaces.C.unsigned;
         local_mode_flags   : Interfaces.C.unsigned;
         line_discipline    : character;
         control_characters : NCCS_array;
      end record;
   type win_size is record -- C winsize (in /usr/include/asm-generic/termios.h)
         rows     : Interfaces.C.unsigned_short;
         cols     : Interfaces.C.unsigned_short;
         x_pixels : Interfaces.C.unsigned_short;
         y_pixels : Interfaces.C.unsigned_short;
      end record;
     -- fd_access is declared in Gtk.Terminal as 'access all Interfaces.C.int'.
   function Fork_Pseudo_Terminal(with_fd : System.Address; 
                                with_name: in out Gtkada.Types.Chars_Ptr;
                                with_attribs : access term_attribs;
                                with_win_size : access win_size)
   return Glib.Spawn.GPid;
      pragma Import (C, Fork_Pseudo_Terminal, "forkpty");
      -- This fork a pseudo-terminal command combines openpty(), fork(2) and
      -- login_tty() to sporn a terminal, setting up a master device and
      -- returning a file descriptor that can be used to refer to master that
      -- device.  The returned PID is the PID of the child if greater than 0,
      -- otherwise if 0 then this is the child process of the fork, otherwise
      -- if -1 then the fork failed.  If with_name is not null, then the file
      -- name of the client terminal is returned in that buffer.  The
      -- with_attribs determines the terminal attributes and with_win_size
      -- specifies the window size if not null.  'man 3 termios' for more
      -- information.  It is a part of libutil.

   function Open_Pseudo_Terminal(with_mfd, with_sfd : System.Address; 
                                with_name: in out Gtkada.Types.Chars_Ptr;
                                with_attribs : access term_attribs;
                                with_win_size : access win_size)
   return int;
      pragma Import (C, Open_Pseudo_Terminal, "openpty");
      -- This open a pseudo terminal function finds an available pseudoterminal
      -- and returns file descriptors for the master and slave in with_mfd and
      -- with_sfd.  The other parameters work the same as for the Fork_Pseudo_-
      -- Terminal.  The return value is -1 for a failure to open, and 0 for
      -- success.  It is a part of libutil.

   function Fork_Process return Glib.Spawn.GPid;
      pragma Import (C, Fork_Process, "fork");
      -- This is the standard fork(2) process and is used in conjunction with
      -- Open_Pseudo_Terminal.  If the return function is -1, then the fork
      -- failed, otherwise if it is 0, then it is the child process, otherwise
      -- if it is greater than 0, then it is the process ID of the child and
      -- therefore you are in the parent process.  It is a part of libc.

   procedure Terminate_Process(with_status : Interfaces.C.int);
      pragma Import (C, Terminate_Process, "_exit");
      -- Immediately terminate the calling process.  Any open file descriptors
      -- belonging to the process are closed.  The parent of the process is
      -- sent a SIGCHLD signal.  It is a part of libc.
      
   function TTY_Name(for_fd : in int) return Gtkada.Types.Chars_Ptr;
      pragma Import (C, TTY_Name, "ttyname");
      -- For the specified 'for_fd' pseudo terminal file descriptor, return
      -- that terminal's name.  It is a part of libc.
   function Get_Terminal_Attributes(for_fd : in int;
                                      into : access term_attribs) return Int;
      pragma Import (C, Get_Terminal_Attributes, "tcgetattr");
      -- For the specified 'for_fd' pseudo terminal file descriptor, return in
      -- 'into' the attributes as currently set within that terminal.
   function Set_Terminal_Attributes(for_fd : in int; optional_actons : int;
                                    to_attribs: access term_attribs)return Int;
      pragma Import (C, Set_Terminal_Attributes, "tcsetattr");
      -- For the specified 'for_fd' pseudo terminal file descriptor, given the
      -- actions (e.g. 'act now'), set the specified 'to_attribs' values.
      
   function Posix_Open_Pseudo_Terminal(with_flags:Interfaces.C.int) return Int;
      pragma Import (C, Posix_Open_Pseudo_Terminal, "posix_openpt");
      -- Open a pseudo-terminal master device, returning a file descriptor that
      -- can be used to refer to that device.  It is a part of libc.

   function Grant_Pseudo_terminal_Access(for_fd : int) return Int;
      pragma Import (C, Grant_Pseudo_terminal_Access, "grantpt");
      -- Grant access to the slave pseudo terminal.  It is a part of libc.
     
   function Unlock_Pseudo_Terminal(for_fd : int) return Int;
      pragma Import (C, Unlock_Pseudo_Terminal, "unlockpt");
      -- Unlock a pseudo-terminal master/slave pair.  It is a part of libc.
     
   function Slave_Pseudo_Terminal_Name(for_fd : int)
      return Gtkada.Types.Chars_Ptr;
      pragma Import (C, Slave_Pseudo_Terminal_Name, "ptsname");
      -- Get the name of the slave pseudo-terminal device that corresponds to
      -- the master that is referred to by the specified file descriptor.
      -- It is a part of libc.
      
   terminal_name : constant wide_string := "xterm-256color";
   term_name : constant Gtkada.Types.Chars_Ptr := 
                  Gtkada.Types.New_String(Ada.Characters.Conversions.
                                                     To_String(terminal_name));
      -- Return the current terminal's name as set up by setupterm.
      -- It is the default value for the terminal.
      
   function Set_Environment(variable : Gtkada.Types.Chars_Ptr;
                               to: Gtkada.Types.Chars_Ptr; overwrite : int)
      return int;
      pragma Import (C, Set_Environment, "setenv");
      -- Add the specified environment variable to the environment with the
      -- specified value ('to') or, if it already exists and overwrite is not
      -- zero, overwrite the specified environment variable with 'to'.
      -- Set_Environment returns a success status.  It does not eat or destroy
      -- the string pointers (so you need to free them after use). Success = 0,
      -- Error = -1.
      -- It is a part of libc.
   function Unset_Environment(variable : Gtkada.Types.Chars_Ptr) 
      return int;
      pragma Import (C, Unset_Environment, "unsetenv");
      -- Delete the specified environment variable from the environment.  In
      -- the event that the variable does not exist, then the function still
      -- returns success and the environment remains unchanged.  Success = 0,
      -- Error = -1.
      -- It is a part of libc.

   function Open_Device(for_name : Gtkada.Types.Chars_Ptr; 
                        with_flags : Interfaces.C.int) return int;
      pragma Import (C, Open_Device, "open");
      -- Open the specified device in accordance with the flags set.  In all
      -- likelihood, standard Ada file management could be used here, but this
      -- particular interface keeps the file descriptors consistent.
      -- It is a part of libc.

   function Close_Device(for_fd : int) return int;
      pragma Import (C, Close_Device, "close");
      -- Close the specified device.  In all likelihood, standard Ada file
      -- management could be used here, but as per Open_Device, this particular
      -- interface keeps the file descriptors consistent.
      -- It is a part of libc.
    
   function Duplicate_File(from_fd, to_fd : int) return int;
      pragma Import (C, Duplicate_File, "dup2");
      -- Duplicate the file descriptor from from_fd to to_fd.  This would be
      -- used, for example, to make the standard error file the same as the
      -- from file descriptor (same goes for standard in and standard out).
      -- It is a part of libc.
 
   function IO_Control(for_file : int; 
                       request : unsigned_long; 
                       params : access System.Address) return int;
      pragma Import (C, IO_Control, "ioctl");
      -- Manipulate the underlying parameters for the specified device.  This
      -- function is quite important for managing the operating characteristics
      -- of a terminal device (and other special character devices).
      -- It is a part of libc.

   function Set_Session_ID return Glib.Spawn.GPid;
      pragma Import (C, Set_Session_ID, "setsid");
      -- Create a new Session, providing the calling process is not a process
      -- group leader.
      -- It is a part of libc.
   
   POLLIN   : constant Interfaces.C.short := 2#0000_0000_0000_0001#;
   POLLOUT  : constant Interfaces.C.short := 2#0000_0000_0000_0100#;
   POLLPRI  : constant Interfaces.C.short := 2#0000_0000_0000_0010#;
   POLLERR  : constant Interfaces.C.short := 2#0000_0000_0000_1000#;
   POLLHUP  : constant Interfaces.C.short := 2#0000_0000_0001_0000#;
   POLLNVAL : constant Interfaces.C.short := 2#0000_0000_0010_0000#;
   type poll_fd is record
         fd      : Interfaces.C.int;
         events  : Interfaces.C.short;
         revents : Interfaces.C.short;
      end record;
   type poll_fd_access is access all poll_fd;
   subtype nfds_t is Interfaces.C.unsigned;
   function Poll(fds : poll_fd_access; nfds : nfds_t; timeout : int) return int;
      pragma Import (C, Poll, "poll");
      -- Poll the file descriptor defined in fds for the events defined in
      -- events and return the result in revents.  Events is a bit-mask of
      -- flags to monitor.  It will return after timeout milliseconds.
      -- nfds specifies number of poll_fd entries there are (since it is
      -- supposed to be an array).  Poll returns the number  of elements in the
      -- pollfds whose revents fields have been set to a nonzero value
      -- (indicating an event or an error).  A return value of zero indicates
      -- that the system call timed out before any file descriptors became
      -- ready.  A value of -1 indicates that there was an error.
      -- It is a part of libc.


   function C_Write
     (fd : int;
      data : Interfaces.C.Strings.chars_ptr;
      len : int) return int;  -- ./serial_comms.h:31
   pragma Import (C, C_Write, "WriteFD");
      -- Write the buffer, data, out to the file pointed to by fd. len is the
      -- number of valid characters in the buffer to write.
      -- WriteFD is a C routine in gtk_terminal_io.h.  

   function C_Read (fd : int; data : Interfaces.C.Strings.chars_ptr; 
                    length : int) return int;  -- ./serial_comms.h:36
   pragma Import (C, C_Read, "ReadFD");
      -- Read into the buffer (a character array) to the file pointed to by fd.
      -- data is something like: unsigned char data[80];
      -- returns the number of bytes read.  If there is no data yet, then
      -- 0 is returned.
      -- ReadFD is a C routine in gtk_terminal_io.h.

   function Execvp (filename : Gtkada.Types.Chars_Ptr;
                    argv     : Gtkada.Types.Chars_Ptr_Array) return C.int;
      -- filename is the executable (or script) with or without a path.
      -- If the path is not specified, then the $PATH environment variable is
      -- used to search for filename.
      -- argv is an array of parameter strings.
      -- argv must be terminated by a null pointer.
      -- If the function is successful, it does not return, otherwise it
      -- returns -1 and sets the error code in errno.
      pragma Import (C, Execvp, "execvp");

   function Execle (filename : Gtkada.Types.Chars_Ptr;
                    argv     : Gtkada.Types.Chars_Ptr_Array; 
                    envp     : Gtkada.Types.Chars_Ptr_Array) return C.int;
      -- filename is the executable (or script) with a path.
      -- argv is an array of parameter strings.
      -- envp is an array of environment variables of the form key=value
      -- Both argv and envp must be terminated by a null pointer.
      -- If the function is successful, it does not return, otherwise it
      -- returns -1 and sets the error code in errno.
      pragma Import (C, Execle, "execle");
      
   function Execve(filename : Gtkada.Types.Chars_Ptr;
                   argv     : Gtkada.Types.Chars_Ptr_Array; 
                   envp     : Gtkada.Types.Chars_Ptr_Array) return C.int;
      -- filename is the full path to the executable (or script)
      -- argv is an array of parameter strings
      -- envp is an array of environment variables of the form key=value
      -- Both argv and envp must be terminated by a null pointer.
      -- If the function is successful, it does not return, otherwise it
      -- returns -1 and sets the error code in errno.
      pragma Import (C, Execve, "execve");

end Gtk.Terminal.CInterface;