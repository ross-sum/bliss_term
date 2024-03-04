pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;

package VTE.Enums is

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

  --*
  -- * VteCursorBlinkMode:
  -- * @VTE_CURSOR_BLINK_SYSTEM: Follow GTK+ settings for cursor blinking.
  -- * @VTE_CURSOR_BLINK_ON: Cursor blinks.
  -- * @VTE_CURSOR_BLINK_OFF: Cursor does not blink.
  -- *
  -- * An enumerated type which can be used to indicate the cursor blink mode
  -- * for the terminal.
  --  

   type VteCursorBlinkMode is 
     (VTE_CURSOR_BLINK_SYSTEM,
      VTE_CURSOR_BLINK_ON,
      VTE_CURSOR_BLINK_OFF);
   Pragma Convention (C, VteCursorBlinkMode);  -- ./vteenums.h:41

  --*
  -- * VteCursorShape:
  -- * @VTE_CURSOR_SHAPE_BLOCK: Draw a block cursor.  This is the default.
  -- * @VTE_CURSOR_SHAPE_IBEAM: Draw a vertical bar on the left side of character.
  -- * This is similar to the default cursor for other GTK+ widgets.
  -- * @VTE_CURSOR_SHAPE_UNDERLINE: Draw a horizontal bar below the character.
  -- *
  -- * An enumerated type which can be used to indicate what should the terminal
  -- * draw at the cursor position.
  --  

   type VteCursorShape is 
     (VTE_CURSOR_SHAPE_BLOCK,
      VTE_CURSOR_SHAPE_IBEAM,
      VTE_CURSOR_SHAPE_UNDERLINE);
   Pragma Convention (C, VteCursorShape);  -- ./vteenums.h:57

  --*
  -- * VteTextBlinkMode:
  -- * @VTE_TEXT_BLINK_NEVER: Do not blink the text.
  -- * @VTE_TEXT_BLINK_FOCUSED: Allow blinking text only if the terminal is focused.
  -- * @VTE_TEXT_BLINK_UNFOCUSED: Allow blinking text only if the terminal is unfocused.
  -- * @VTE_TEXT_BLINK_ALWAYS: Allow blinking text. This is the default.
  -- *
  -- * An enumerated type which can be used to indicate whether the terminal allows
  -- * the text contents to be blinked.
  -- *
  -- * Since: 0.52
  --  

   type VteTextBlinkMode is 
     (VTE_TEXT_BLINK_NEVER,
      VTE_TEXT_BLINK_FOCUSED,
      VTE_TEXT_BLINK_UNFOCUSED,
      VTE_TEXT_BLINK_ALWAYS);
   Pragma Convention (C, VteTextBlinkMode);  -- ./vteenums.h:76

  --*
  -- * VteEraseBinding:
  -- * @VTE_ERASE_AUTO: For backspace, attempt to determine the right value
  --   from the terminal's IO settings.  For delete, use the control sequence.
  -- * @VTE_ERASE_ASCII_BACKSPACE: Send an ASCII backspace character (0x08).
  -- * @VTE_ERASE_ASCII_DELETE: Send an ASCII delete character (0x7F).
  -- * @VTE_ERASE_DELETE_SEQUENCE: Send the "@@7" control sequence.
  -- * @VTE_ERASE_TTY: Send terminal's "erase" setting.
  -- *
  -- * An enumerated type which can be used to indicate which string the terminal
  -- * should send to an application when the user presses the Delete or Backspace
  -- * keys.
  --  

   type VteEraseBinding is 
     (VTE_ERASE_AUTO,
      VTE_ERASE_ASCII_BACKSPACE,
      VTE_ERASE_ASCII_DELETE,
      VTE_ERASE_DELETE_SEQUENCE,
      VTE_ERASE_TTY);
   Pragma Convention (C, VteEraseBinding);  -- ./vteenums.h:96

  --*
  -- * VtePtyError:
  -- * @VTE_PTY_ERROR_PTY_HELPER_FAILED: Obsolete. Deprecated: 0.42
  -- * @VTE_PTY_ERROR_PTY98_FAILED: failure when using PTY98 to allocate the PTY
  --  

   type VtePtyError is 
     (VTE_PTY_ERROR_PTY_HELPER_FAILED,
      VTE_PTY_ERROR_PTY98_FAILED);
   Pragma Convention (C, VtePtyError);  -- ./vteenums.h:106

  --*
  -- * VtePtyFlags:
  -- * @VTE_PTY_NO_LASTLOG: Unused. Deprecated: 0.38
  -- * @VTE_PTY_NO_UTMP: Unused. Deprecated: 0.38
  -- * @VTE_PTY_NO_WTMP: Unused. Deprecated: 0.38
  -- * @VTE_PTY_NO_HELPER: Unused. Deprecated: 0.38
  -- * @VTE_PTY_NO_FALLBACK: Unused. Deprecated: 0.38
  -- * @VTE_PTY_NO_SESSION: Do not start a new session for the child in
  -- *   vte_pty_child_setup(). See man:setsid(2) for more information. Since: 0.58
  -- * @VTE_PTY_NO_CTTY: Do not set the PTY as the controlling TTY for the child
  -- *   in vte_pty_child_setup(). See man:tty_ioctl(4) for more information. Since: 0.58
  -- * @VTE_PTY_DEFAULT: the default flags
  --  

   subtype VtePtyFlags is unsigned;
   VtePtyFlags_VTE_PTY_NO_LASTLOG : constant VtePtyFlags := 1;
   VtePtyFlags_VTE_PTY_NO_UTMP : constant VtePtyFlags := 2;
   VtePtyFlags_VTE_PTY_NO_WTMP : constant VtePtyFlags := 4;
   VtePtyFlags_VTE_PTY_NO_HELPER : constant VtePtyFlags := 8;
   VtePtyFlags_VTE_PTY_NO_FALLBACK : constant VtePtyFlags := 16;
   VtePtyFlags_VTE_PTY_NO_SESSION : constant VtePtyFlags := 32;
   VtePtyFlags_VTE_PTY_NO_CTTY : constant VtePtyFlags := 64;
   VtePtyFlags_VTE_PTY_DEFAULT : constant VtePtyFlags := 0;  -- ./vteenums.h:130

  --*
  -- * VteWriteFlags:
  -- * @VTE_WRITE_DEFAULT: Write contents as UTF-8 text.  This is the default.
  -- *
  -- * A flag type to determine how terminal contents should be written
  -- * to an output stream.
  --  

   type VteWriteFlags is 
     (VTE_WRITE_DEFAULT);
   Pragma Convention (C, VteWriteFlags);  -- ./vteenums.h:141

  --*
  -- * VteRegexError:
  -- * @VTE_REGEX_ERROR_INCOMPATIBLE: The PCRE2 library was built without
  -- *   Unicode support which is required for VTE
  -- * @VTE_REGEX_ERROR_NOT_SUPPORTED: Regexes are not supported because VTE was
  -- *   built without PCRE2 support
  -- *
  -- * An enum type for regex errors. In addition to the values listed above,
  -- * any PCRE2 error values may occur.
  -- *
  -- * Since: 0.46
  --  

  -- Negative values are PCRE2 errors  
  -- VTE specific values  
   subtype VteRegexError is unsigned;
   VteRegexError_VTE_REGEX_ERROR_INCOMPATIBLE : constant VteRegexError := 2147483646;
   VteRegexError_VTE_REGEX_ERROR_NOT_SUPPORTED : constant VteRegexError := 2147483647;  -- ./vteenums.h:161

  --*
  -- * VteFormat:
  -- * @VTE_FORMAT_TEXT: Export as plain text
  -- * @VTE_FORMAT_HTML: Export as HTML formatted text
  -- *
  -- * An enumeration type that can be used to specify the format the selection
  -- * should be copied to the clipboard in.
  -- *
  -- * Since: 0.50
  --  

   subtype VteFormat is unsigned;
   VteFormat_VTE_FORMAT_TEXT : constant VteFormat := 1;
   VteFormat_VTE_FORMAT_HTML : constant VteFormat := 2;  -- ./vteenums.h:176

  --*
  -- * VteFeatureFlags:
  -- * @VTE_FEATURE_FLAG_BIDI: whether VTE was built with bidirectional text support
  -- * @VTE_FEATURE_FLAG_ICU: whether VTE was built with ICU support
  -- * @VTE_FEATURE_FLAG_SYSTEMD: whether VTE was built with systemd support
  -- * @VTE_FEATURE_FLAG_SIXEL: whether VTE was built with SIXEL support
  -- * @VTE_FEATURE_FLAGS_MASK: mask of all feature flags
  -- *
  -- * An enumeration type for features.
  -- *
  -- * Since: 0.62
  --  

  --< skip > 
  -- force enum to 64 bit  
   subtype VteFeatureFlags is unsigned_long;
   VteFeatureFlags_VTE_FEATURE_FLAG_BIDI : constant VteFeatureFlags := 1;
   VteFeatureFlags_VTE_FEATURE_FLAG_ICU : constant VteFeatureFlags := 2;
   VteFeatureFlags_VTE_FEATURE_FLAG_SYSTEMD : constant VteFeatureFlags := 4;
   VteFeatureFlags_VTE_FEATURE_FLAG_SIXEL : constant VteFeatureFlags := 8;
   VteFeatureFlags_VTE_FEATURE_FLAGS_MASK : constant VteFeatureFlags := 18446744073709551615;  -- ./vteenums.h:197 -- force enum to 64 bit

  --*
  -- * VteAlign:
  -- * @VTE_ALIGN_START: align to left/top
  -- * @VTE_ALIGN_CENTER: align to centre
  -- * @VTE_ALIGN_END: align to right/bottom
  -- *
  -- * An enumeration type that can be used to specify how the terminal
  -- * uses extra allocated space.
  -- *
  -- * Since: 0.76
  --  

  -- VTE_ALIGN_BASELINE    = 2U,  
   subtype VteAlign is unsigned;
   VteAlign_VTE_ALIGN_START : constant VteAlign := 0;
   VteAlign_VTE_ALIGN_CENTER : constant VteAlign := 1;
   VteAlign_VTE_ALIGN_END : constant VteAlign := 3;  -- ./vteenums.h:216

end VTE.Enums;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
