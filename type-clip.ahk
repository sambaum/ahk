#NoEnv                      ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance FORCE       ; Skip invocation dialog box and silently replace previously executing instance of this script.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#InstallKeybdHook
#Persistent

; ---- tunables for the robust method ----------------------------------------
global TC_StartDelay := 100   ; ms before typing starts (window/focus settle)
global TC_CharDelay  := 15    ; ms between characters (15)
global TC_PressDur   := 15    ; ms a key is held down (15)
global TC_ClearMods  := true  ; release Ctrl/Alt/Shift/Win before typing


; ============================================================================
;  fast paste - SendInput {Text}. Works almost everywhere; the default.
; ============================================================================

; LCtrl + LAlt + LWin + v
<^<!<#v::
; F13
F13::
  Sleep, 100 ; Maybe helps with the first character sometimes not being sent
  Send, {Text}%Clipboard%
return


; ============================================================================
;  robust paste - raw scancode injection (SendInput with KEYEVENTF_SCANCODE).
;  Slower, but works on Citrix hosts where {Text} above sends the wrong
;  characters.
; ============================================================================

; LCtrl + LAlt + LWin + b
<^<!<#b::
; F14
F14::
  ; Wait for the trigger keys to actually be released. Without this, holding
  ; the combo lets the keyboard's own auto-repeat re-assert Ctrl/Alt/Win as
  ; down mid-loop, corrupting whatever character is being typed at the time.
  KeyWait, LCtrl
  KeyWait, LAlt
  KeyWait, LWin
  KeyWait, b
  KeyWait, F14
  Sleep, %TC_StartDelay%
  ClearMods()
  hkl := ActiveHKL()
  for i, ch in TC_Chars()
  {
    if (ch = "`n")
    {
      TapSC(0x1C), Sleep, %TC_CharDelay%
      continue
    }
    if (ch = "`t")
    {
      TapSC(0x0F), Sleep, %TC_CharDelay%
      continue
    }
    vks := DllCall("VkKeyScanExW", "UShort", Asc(ch), "Ptr", hkl, "Short")
    if (vks = -1)                       ; not typeable on this layout
    {
      SendUnicodeChar(Asc(ch)), Sleep, %TC_CharDelay%
      continue
    }
    vk := vks & 0xFF, sh := (vks >> 8) & 0xFF
    sc := DllCall("MapVirtualKeyExW", "UInt", vk, "UInt", 0, "Ptr", hkl, "UInt")
    if (sh & 1)
      KeySC(0x2A, false)                ; LShift down
    if (sh & 2)
      KeySC(0x1D, false)                ; LCtrl down
    if (sh & 4)
      KeySC(0x38, false, true)          ; RAlt / AltGr down
    TapSC(sc)
    if (sh & 4)
      KeySC(0x38, true, true)
    if (sh & 2)
      KeySC(0x1D, true)
    if (sh & 1)
      KeySC(0x2A, true)
    Sleep, %TC_CharDelay%
  }
return


; ============================================================================
;  helpers (robust paste)
; ============================================================================

; Clipboard as text, with CRLF collapsed to LF so per-character typing does
; not press Enter twice per line.
TC_Text()
{
  txt := Clipboard
  StringReplace, txt, txt, `r`n, `n, All
  StringReplace, txt, txt, `r, `n, All
  return txt
}

; The clipboard as an array of single characters.
TC_Chars()
{
  chars := []
  Loop, Parse, % TC_Text()
    chars.Push(A_LoopField)
  return chars
}

; Keyboard layout of the window that will receive the text - the script and
; the focused window can be on different layouts.
ActiveHKL()
{
  hwnd := WinExist("A")
  tid  := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0, "UInt")
  return DllCall("GetKeyboardLayout", "UInt", tid, "Ptr")
}

; Make sure no modifier is stuck down before typing starts - a stuck Ctrl or
; AltGr on the far end is itself a classic "wrong characters" cause.
ClearMods()
{
  if (!TC_ClearMods)
    return
  for i, k in ["LCtrl","RCtrl","LAlt","RAlt","LShift","RShift","LWin","RWin"]
    if GetKeyState(k)
      SendInput, % "{" k " up}"
}

; --- low level SendInput ----------------------------------------------------
; flags: 0x1 EXTENDEDKEY, 0x2 KEYUP, 0x4 UNICODE, 0x8 SCANCODE
SendInputRaw(vk, sc, flags)
{
  static size := (A_PtrSize = 8) ? 40 : 28
  static off  := (A_PtrSize = 8) ? 8  : 4
  VarSetCapacity(ip, size, 0)
  NumPut(1,     ip, 0,       "UInt")    ; INPUT_KEYBOARD
  NumPut(vk,    ip, off,     "UShort")
  NumPut(sc,    ip, off + 2, "UShort")
  NumPut(flags, ip, off + 4, "UInt")
  NumPut(0,     ip, off + 8, "UInt")    ; time = 0 -> system supplies it
  return DllCall("SendInput", "UInt", 1, "Ptr", &ip, "Int", size)
}

; One scancode-only key event (no VK) - what real hardware generates.
KeySC(sc, up, extended := false)
{
  flags := 0x8
  if (up)
    flags |= 0x2
  if (extended)
    flags |= 0x1
  SendInputRaw(0, sc, flags)
}

TapSC(sc, extended := false)
{
  KeySC(sc, false, extended)
  Sleep, %TC_PressDur%
  KeySC(sc, true, extended)
}

; One UTF-16 code unit as a unicode packet, down + up - fallback for
; characters that have no key on the active layout.
SendUnicodeChar(code)
{
  SendInputRaw(0, code, 0x4)
  Sleep, %TC_PressDur%
  SendInputRaw(0, code, 0x4 | 0x2)
}

; EOF
