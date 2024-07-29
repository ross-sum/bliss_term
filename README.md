# Bliss Terminal
$Date: Sun Jul 28 21:46:14 2024 +1000$

## Description

Bliss_Term  is a terminal built to handle  combining  character
Unicode  fonts.  It was written because there is little  to  no
support  for  combining characters in terminals,  even  amongst
those that support UTF-8 Unicode.  The primary purpose of  this
particular terminal is to support Blissymbolics, including  for
date and time display and for file name display.

## Building

Bliss_Term uses the following packages:
1. GTKAda - this is for the user interface.  In fact, it uses Glade.
2. AdaSockets - this is used by some of the library packages, so is
   not directly required, but is needed for compilation.
3. Dynamic-Strings - this is a super-set of the unbounded wide strings
   package (and pre-dates it in its origin).  it is expected to be at
   the same directory level as the top level of Bliss Term, but in
   its own ../dynamic-strings/ directory.
4. Hyper Quantum's Ada Tools library - various tools are used from 
   this library and they are expected to also be at the same directory
   level as the top level of Bliss Term, namely in its own
   ../tools/ directory.

## Installation

* It may be wise to install the Blissymbolics package first.
* Ensure Gnat is installed:

    `apt-get install gnat`

* Ada sockets is required by the Hyper Quantum Ada tools; install viz:

    `apt-get install libadasockets12-dev libadasockets10`

* Ensure prerequisites outlined in Building (above) are installed, in particular
  dynamic-strings and ada tools.  Make sure the directories for those are called
  `dynamic-strings` and `tools` and have appropriate read and write permissions.
* In each of the `dynamic-strings` and `tools` directories, execute the following:

    `mkdir obj_amd64  obj_arm  obj_pi  obj_pi64  obj_x86`

* Compile and load the Ada software, viz from the top level Bliss Term directory:

    `mkdir obj_amd64  obj_arm  obj_pi  obj_pi64  obj_x86`

    `make ; sudo make install`

## Usage

The full instructions for using Bliss Term are contained in the on-line manual,
which is available from within the application under Help (click on the Help|
About button, (?) to bring up the About dialogue box, then select the Manual tab).

The main issue to consider during execution of Bliss Term is the location of
the log file.  If the system administrator has not made /var/log/bliss_term.log
world writable (or, at least, writable by users who will be using Bliss Term),
then you must specify your own log file.  Otherwise, you can just use the default
and not specify it on the command line.  The other factor to consider is the level
of logging required.  When the application is stable, this can be left blank (i.e.,
only log errors), but otherwise you may choose something more vigorous.  A log
level is a number between 1 (almost no logging) and 9 (log everything).
When logging, the --format option determines whether to use UTF-8 formatting or
not.  If just using Bliss Term for a language like English (or, perhaps, most
European languages), then this need not be specified.  If using it for a language
like Blissymbolics, then it should be specified, but in that case, you must view
the log file with an editor that can view in the language specified.  The built-in
less doesn't cut it unless it is used within Bliss_Term.

Execute via something like:
bliss_term --log /tmp/bliss_term.log --format WCEM=8,ctrl --debug 5

## Support

For help, email me at ross<at>hyperquantum<dot>com<dot>au.  Otherwise, 
issue tracking is through GitHub.

If you wish to contribute, see Contributing and Roadmap sections below.

## Contributing

Contributions are welcome.  The following needs to be done.

We need to get the Blissymbolics language recognised by the Unicode Consortium. 
This may require a few of us writing a few books and probably requires a lot of 
lobbying.  Prior to that, we all need to agree on the character set.  That may 
take a bit of work.  Please see the Blissymbolics repository for more 
information.

The roadmap section below outlines work that needs to be done.  Help would be 
welcomed there as I am also updating Cell_Writer.

To help, contact me, Ross Summerfield, ross <at> hyperquantum <dot> com <dot> au.
Collaboration is envisaged to be through Github.

## Authors and acknowledgment

Clearly, a lot of thanks goes to the developers of VTE.  Although there is none
of their code in this, it has inspired the development.  Also thanks to Vincent
Bernat who has a web page that shows how to make a simple terminal using VTE.
Source the page at https://vincent.bernat.ch/en/blog/2017-write-own-terminal
The source really came from the developer of EduTerm, whose web page is at
https://www.uninformativ.de/blog/postings/2018-02-24/0/POSTING-en.html
That code gave the true insight in how to actually implement the code to
actually run up a terminal.

I would also like to thank the late Dr Charles K. Bliss.  It was an article about 
him and Blissymbolics in a Readers Digest magazine that I read when I was really 
young that got me interested in the symbol set.  That inspired me to look for a 
practical way to input Blissymbolics symbols into a computer.

## Licence

Bliss_Term is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public Licence as published by the Free Software 
Foundation; either version 2, or (at your option) any later version.  Bliss_Term 
is distributed in hope that it will be useful, but WITHOUT ANY WARRANTY; without 
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public Licence for more details.  You should have received 
a copy of the GNU General Public Licence distributed with  Bliss_Term. If not, 
write to the Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston, 
MA 02110-1301, USA.

## Project status

As detailed in the Manual, the current project status is in its early days.  It 
needs a bit of work right now.

Outstanding features required of the application and other work required are as 
follows:
* The cursor is not displayed or active when the application first opens. The
  cause has yet to be found but appears to be some issue with Gtk.Text_View.
  The work-around is to press the Down Arrow when you first open the first
  terminal.  It will be visible for all terminals, new or already created, from
  there on in.
* Error repair including for window resize when changing lines or column.
* Allow editing and update of the CSS in the Setup dialogue box and make the 
  changes take effect straight away.  See Gtk.Text_Buffer for the hooks for 
  editing (e.g. cut, copy, paste, selection and iterators).
* Modify Bliss Term so that all components of the system, including hints, 
  about text and help, use the selected language in the selected font.
* Get window docking to work.
* Display the Manual using a mark-up to highlight headings and the like.  At the 
  moment it does not do that, rather it just displays plain text (with the 
  mark-up/mark-down displayed as plain text).
* Code linting and automated testing is required.
* Cut, copy and paste needs some more work.  Selection is not done well as it
  is the native selection supplied by the Gtk.Text_Buffer/Gtk.Text_View, which
  is not always obvious.  Paste does not yet work properly when in command
  history mode (mostly a display issue).
* The codes for Page Up and Page Down are clearly not correct.  There is a
  work-around in place, but it is probably not optimal.
* The delete operation in the Process_Keys sub-procedure throws an error
  warning into the terminal that this terminal is called from.  The error
  warning is harmless, but is ugly.  There is another similar error that occurs
  when in the alternative buffer (which is the case when using something like
  less or vi) that also needs identifying and somehow removing. 
* The cursor shapes cannot be changed.  This is an issue with the Gtk.Text_View
  and would require Gtk.Text_View/Gtk.Text_Buffer to be modified or rewritten.
  If someone with C++ skills would like to do that, ... :-)
* Not all Escape commands have been implemented.  Finishing those off would be
  potentially useful for those applications that have yet be tested with
  Bliss_Term.
* Word wrap is yet to be implemented.  At the moment, the terminal assumes an
  'endless' (1000 character) line length.  It should enforce word wrap when
  the user requests it.
* vi does not work with a file that is in Blissymbolics.  This is because vi
  wants to position the cursor after every non-ASCII character and Gtk.Text_
  buffer will not put the cursor at points immediately after the last entered
  Blissymbolic charaacter (rembembering Blissymbolics characters are outside
  of the ASCII character range).

There are probably numerous other errors that I have yet to discover.  I am
actively using this terminal emulator whenever it is safe for me to do so, so I
hope to discover most of them myself.  My current challenge is to get it to
edit a document using vi without any issues.  I have already tested less and it
is satisfactory.  I have seen some strange behaviour from time to time when
scrolling through the history buffer, but have yet to identify exact causes of
issues.

