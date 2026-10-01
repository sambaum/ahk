#NoEnv                      ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance FORCE       ; Skip invocation dialog box and silently replace previously executing instance of this script.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#InstallKeybdHook
#Persistent

; ============================================================================
;  type-clip-enhanced - alternative clipboard typing methods.
;
;  For hosts (new Citrix versions) where the plain SendInput {Text} of
;  type-clip.ahk types the *wrong* characters. Every F-key below uses a
;  different input mechanism; try them one after another in the broken app
;  and keep the one that comes out correct.
;
;  F13 is the unchanged original method - the reliable fallback while testing
;  the others. It is identical to type-clip.ahk, so run only ONE of the two
;  scripts at a time (both claim F13 and LCtrl+LAlt+LWin+v).
;
;  A tooltip names the method that was used, so a result can be matched to
;  the method afterwards. Test with a string that contains the characters
;  that break, plus digits, uppercase and an umlaut.
;
;  ---- round 1 results ----
;  F14: too many errors, reproducible          -> commented out
;  F15: too many errors, reproducible          -> commented out
;  F16: best; rare non-reproducible mistake    -> KEPT, round 2 built on it
;  F17: sometimes good, sometimes really bad   -> KEPT for reference
;  F18: unusable                               -> commented out, slot reused below
;  F19: unusable                               -> commented out, slot reused below
;  F20: unusable                               -> commented out, slot reused below
;  F21: works quite well, but slow             -> KEPT, round 2 built on it
;  F22: nothing happens                        -> commented out, slot reused below
;  F23: nothing happens                        -> commented out
;  F24: unusable                               -> commented out
;
;  ---- round 2: improvements built on F16/F21 ----
;  F25+ doesn't exist (Windows F-key VK codes stop at F24), so these reuse
;  the F18/F19/F20/F22 hotkeys that round 1 freed up. Each slot below still
;  carries its original round-1 code as a comment for reference, followed by
;  the new active hotkey.
;
;  F18: F16 + a short settle delay around modifier changes (guards against a
;       shift/AltGr race being the source of F16's rare miss)
;  F19: F16, but the extra settle/delay only applies to shifted or AltGr
;       characters (digits, uppercase, umlaut) - plain chars stay F16 speed
;  F20: F16's scancode method with F21's long press duration - isolates
;       whether hold time alone explains why F21 is reliable
;  F22: F21 with a shorter hold - is the full 40/60ms needed, or can it be
;       faster while staying reliable
; ============================================================================

; ---- tunables --------------------------------------------------------------
global TC_StartDelay      := 100   ; ms before typing starts (window/focus settle)
global TC_CharDelay       := 15    ; ms between characters (slow methods)
global TC_PressDur        := 15    ; ms a key is held down (slow methods)
global TC_ChunkSize       := 20    ; characters per burst for the chunked method
global TC_ChunkDelay      := 60    ; ms between chunks
global TC_ClearMods       := true  ; release Ctrl/Alt/Shift/Win before typing
global TC_ModSettle       := 8     ; ms pause around a modifier down/up transition
global TC_ShiftExtraDelay := 20    ; ms extra delay after a shifted/AltGr character


; ============================================================================
;  F13 - the original, unchanged. Reliable fallback while testing the rest.
; ============================================================================

; LCtrl + LAlt + LWin + v
<^<!<#v::
; F13
F13::
  Sleep, 100 ; Maybe helps with the first character sometimes not being sent
  Send, {Text}%Clipboard%
return   ; needed here because other hotkeys follow below


; ============================================================================
;  F14 - SendEvent {Text}  [too many errors, reproducible - not a candidate]
;  Same unicode packets as the original, but one at a time through the event
;  queue with a delay. Separates "Citrix cannot do unicode" from "Citrix
;  cannot do unicode at SendInput speed".
; ============================================================================
/*
F14::
  Note("F14: SendEvent {Text} slow")
  Sleep, %TC_StartDelay%
  SendMode Event
  SetKeyDelay, %TC_CharDelay%, %TC_PressDur%
  ClearMods()
  SendEvent, {Text}%Clipboard%
return
*/


; ============================================================================
;  F15 - SendEvent {Raw}  [too many errors, reproducible - not a candidate]
;  No unicode at all: AHK translates every character into a real VK + shift
;  state using the keyboard layout. The closest thing to "someone is typing"
;  that AHK offers out of the box. Needs the Citrix session layout to match
;  the local one.
; ============================================================================
/*
F15::
  Note("F15: SendEvent {Raw}")
  Sleep, %TC_StartDelay%
  SendMode Event
  SetKeyDelay, %TC_CharDelay%, %TC_PressDur%
  ClearMods()
  txt := TC_Text()
  SendEvent, {Raw}%txt%
return
*/


; ============================================================================
;  F16 - raw scancode injection (SendInput with KEYEVENTF_SCANCODE)
;  Bypasses AHK's Send: builds INPUT records carrying only a scancode, no VK,
;  which is exactly what a physical keyboard produces and what the newer
;  Citrix "Scancode" keyboard input mode expects. Best candidate if {Text}
;  produces wrong characters.
;
;  RESULT: best so far. Characters are generally fine; sometimes a mistake
;  that isn't reproducible - possibly a modifier-timing race. See the round 2
;  variants on F18/F19/F20 below.
; ============================================================================
F16::
  Note("F16: raw scancode injection")
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
;  F17 - explicit {vkXXscYYY} per character
;  Like F15, but VK *and* hardware scancode are named explicitly and the
;  shift/AltGr modifiers are pressed by hand. Use when {Raw} gets the letter
;  right but the shift state or the AltGr characters wrong.
;
;  RESULT: inconsistent - sometimes pretty good, other times really bad.
;  Kept for reference; F16 is the more reliable base to improve on.
; ============================================================================
F17::
  Note("F17: explicit vk+sc")
  Sleep, %TC_StartDelay%
  SendMode Event
  SetKeyDelay, %TC_CharDelay%, %TC_PressDur%
  ClearMods()
  hkl := ActiveHKL()
  for i, ch in TC_Chars()
  {
    if (SendSpecial(ch))
      continue
    vks := DllCall("VkKeyScanExW", "UShort", Asc(ch), "Ptr", hkl, "Short")
    if (vks = -1)
    {
      SendEvent, {Text}%ch%
      continue
    }
    vk := vks & 0xFF, sh := (vks >> 8) & 0xFF
    sc := DllCall("MapVirtualKeyExW", "UInt", vk, "UInt", 0, "Ptr", hkl, "UInt")
    down := "", up := ""
    if (sh & 1)
      down .= "{Shift down}", up := "{Shift up}" up
    if (sh & 2)
      down .= "{Ctrl down}",  up := "{Ctrl up}"  up
    if (sh & 4)
      down .= "{Alt down}",   up := "{Alt up}"   up
    key := Format("{{}vk{:02X}sc{:03X}{}}", vk, sc)
    SendEvent, %down%%key%%up%
  }
return


; ============================================================================
;  F18 [round 1] - unicode injection, one character per SendInput call
;  Same packet type as the original, but with a proper key-up and a pause
;  after every single character. RESULT: unusable.
; ============================================================================
/*
F18::
  Note("F18: unicode, one char at a time")
  Sleep, %TC_StartDelay%
  ClearMods()
  for i, ch in TC_Chars()
  {
    if (ch = "`n")
      TapSC(0x1C)
    else if (ch = "`t")
      TapSC(0x0F)
    else
      SendUnicodeChar(Asc(ch))
    Sleep, %TC_CharDelay%
  }
return
*/

; ============================================================================
;  F18 [round 2] - F16 + a short settle delay around every modifier transition
;  F16's rare, non-reproducible mistake looks like a timing race rather than
;  a translation error. This adds a small pause right after a modifier goes
;  down (let Citrix register Shift/AltGr before the key itself arrives) and
;  right before it comes back up (let the key register before the modifier
;  is released).
; ============================================================================
F18::
  Note("F18: scancode + modifier settle")
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
    if (vks = -1)
    {
      SendUnicodeChar(Asc(ch)), Sleep, %TC_CharDelay%
      continue
    }
    vk := vks & 0xFF, sh := (vks >> 8) & 0xFF
    sc := DllCall("MapVirtualKeyExW", "UInt", vk, "UInt", 0, "Ptr", hkl, "UInt")
    if (sh & 1)
    {
      KeySC(0x2A, false)                ; LShift down
      Sleep, %TC_ModSettle%
    }
    if (sh & 2)
    {
      KeySC(0x1D, false)                ; LCtrl down
      Sleep, %TC_ModSettle%
    }
    if (sh & 4)
    {
      KeySC(0x38, false, true)          ; RAlt / AltGr down
      Sleep, %TC_ModSettle%
    }
    TapSC(sc)
    Sleep, %TC_ModSettle%
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
;  F19 [round 1] - Alt + numpad (Alt+0nnn)
;  The legacy DOS-era input path. Ignores the keyboard layout completely and
;  still works in many thin-client / terminal windows where nothing else
;  does. RESULT: unusable.
; ============================================================================
/*
F19::
  Note("F19: Alt+numpad")
  Sleep, %TC_StartDelay%
  ClearMods()
  numsc := {0:0x52, 1:0x4F, 2:0x50, 3:0x51, 4:0x4B, 5:0x4C, 6:0x4D, 7:0x47, 8:0x48, 9:0x49}
  for i, ch in TC_Chars()
  {
    if (ch = "`n")
    {
      TapSC(0x1C), Sleep, %TC_CharDelay%
      continue
    }
    code := Asc(ch)
    if (code > 255)
    {
      SendUnicodeChar(code), Sleep, %TC_CharDelay%
      continue
    }
    KeySC(0x38, false)                  ; LAlt down
    digits := Format("{:04d}", code)    ; leading zero = ANSI codepage
    Loop, Parse, digits
    {
      TapSC(numsc[A_LoopField + 0])
      Sleep, 5
    }
    KeySC(0x38, true)                   ; LAlt up
    Sleep, %TC_CharDelay%
  }
return
*/

; ============================================================================
;  F19 [round 2] - F16, extra delay only on shifted/AltGr characters
;  Same as F18's settle delay, but scoped to shifted or AltGr characters
;  (digits, uppercase, umlaut) only. Plain lowercase characters stay at F16
;  speed. Narrower bet than F18: if the sporadic mistake only ever lands on
;  a shifted/AltGr character, this fixes it without slowing everything.
; ============================================================================
F19::
  Note("F19: scancode, extra delay only on shifted/AltGr chars")
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
    if (vks = -1)
    {
      SendUnicodeChar(Asc(ch)), Sleep, %TC_CharDelay%
      continue
    }
    vk := vks & 0xFF, sh := (vks >> 8) & 0xFF
    sc := DllCall("MapVirtualKeyExW", "UInt", vk, "UInt", 0, "Ptr", hkl, "UInt")
    shifted := (sh & 7) ? true : false
    if (sh & 1)
    {
      KeySC(0x2A, false)
      if (shifted)
        Sleep, %TC_ModSettle%
    }
    if (sh & 2)
    {
      KeySC(0x1D, false)
      if (shifted)
        Sleep, %TC_ModSettle%
    }
    if (sh & 4)
    {
      KeySC(0x38, false, true)
      if (shifted)
        Sleep, %TC_ModSettle%
    }
    TapSC(sc)
    if (shifted)
      Sleep, %TC_ModSettle%
    if (sh & 4)
      KeySC(0x38, true, true)
    if (sh & 2)
      KeySC(0x1D, true)
    if (sh & 1)
      KeySC(0x2A, true)
    Sleep, % shifted ? (TC_CharDelay + TC_ShiftExtraDelay) : TC_CharDelay
  }
return


; ============================================================================
;  F20 [round 1] - chunked {Text}
;  The original method, but in small bursts with a pause between them. Fixes
;  the "long pastes scramble, short pastes are fine" symptom, which is an
;  input buffer overrun rather than a translation problem. RESULT: unusable.
; ============================================================================
/*
F20::
  Note("F20: chunked {Text}")
  Sleep, %TC_StartDelay%
  ClearMods()
  txt := TC_Text()
  len := StrLen(txt)
  pos := 1
  while (pos <= len)
  {
    chunk := SubStr(txt, pos, TC_ChunkSize)
    SendInput, {Text}%chunk%
    pos += TC_ChunkSize
    Sleep, %TC_ChunkDelay%
  }
return
*/

; ============================================================================
;  F20 [round 2] - F16's scancode method, timed like F21 (long hold)
;  F21 (layout-based {Raw}, 40/60ms) is reliable but slow; F16 (scancode,
;  15/15ms) is fast but occasionally wrong. This isolates hold time as the
;  variable: same scancode injection as F16, but held as long as F21 holds
;  its keys. If this comes out clean, the fix is hold duration, not method.
; ============================================================================
F20::
  Note("F20: scancode injection, F21-length hold")
  Sleep, %TC_StartDelay%
  ClearMods()
  savedDelay := TC_CharDelay, savedPress := TC_PressDur
  TC_CharDelay := 40, TC_PressDur := 60
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
    if (vks = -1)
    {
      SendUnicodeChar(Asc(ch)), Sleep, %TC_CharDelay%
      continue
    }
    vk := vks & 0xFF, sh := (vks >> 8) & 0xFF
    sc := DllCall("MapVirtualKeyExW", "UInt", vk, "UInt", 0, "Ptr", hkl, "UInt")
    if (sh & 1)
      KeySC(0x2A, false)
    if (sh & 2)
      KeySC(0x1D, false)
    if (sh & 4)
      KeySC(0x38, false, true)
    TapSC(sc)
    if (sh & 4)
      KeySC(0x38, true, true)
    if (sh & 2)
      KeySC(0x1D, true)
    if (sh & 1)
      KeySC(0x2A, true)
    Sleep, %TC_CharDelay%
  }
  TC_CharDelay := savedDelay, TC_PressDur := savedPress
return


; ============================================================================
;  F21 - {Raw} with a long key hold
;  Layout based typing where every key is held down for ~60 ms. Citrix
;  compresses very short down/up pairs; if characters go missing or get
;  swapped only under load, a longer hold is what fixes it.
;
;  RESULT: works quite well, but slow. See F22 below for a faster hold.
; ============================================================================
F21::
  Note("F21: {Raw}, long key hold")
  Sleep, %TC_StartDelay%
  SendMode Event
  SetKeyDelay, 40, 60
  ClearMods()
  txt := TC_Text()
  SendEvent, {Raw}%txt%
return


; ============================================================================
;  F22 [round 1] - SendPlay {Raw}
;  SendPlay uses a completely different injection path than SendInput and
;  SendEvent. Some remoting clients see it, some see nothing at all - one
;  test rules it in or out. RESULT: nothing happens, not seen by this host.
; ============================================================================
/*
F22::
  Note("F22: SendPlay {Raw}")
  Sleep, %TC_StartDelay%
  SendMode Play
  SetKeyDelay, %TC_CharDelay%, %TC_PressDur%, Play
  ClearMods()
  txt := TC_Text()
  SendPlay, {Raw}%txt%
return
*/

; ============================================================================
;  F22 [round 2] - F21 with a shorter hold
;  F21's 40ms delay / 60ms press works but is slow to sit through. This tries
;  a middle ground to see how far the hold can be cut before F21's reliability
;  breaks down again.
; ============================================================================
F22::
  Note("F22: {Raw}, medium key hold (faster F21)")
  Sleep, %TC_StartDelay%
  SendMode Event
  SetKeyDelay, 25, 30
  ClearMods()
  txt := TC_Text()
  SendEvent, {Raw}%txt%
return


; ============================================================================
;  F23 - real Ctrl+V with the clipboard normalised to plain text
;  [nothing happens - not a candidate]
;  Not typing at all, but if the paste itself works and only the rich text /
;  HTML clipboard formats confuse Citrix, stripping the clipboard down to
;  CF_UNICODETEXT is the whole fix. The original clipboard is restored.
; ============================================================================
/*
F23::
  Note("F23: Ctrl+V, plain text clipboard")
  saved := ClipboardAll
  Clipboard := ""
  Clipboard := TC_Text()
  ClipWait, 2
  Sleep, %TC_StartDelay%
  ClearMods()
  SendInput, ^v
  Sleep, 400
  Clipboard := saved
  saved := ""
return
*/


; ============================================================================
;  F24 - ControlSend {Raw} to the focused control  [unusable]
;  Posts the keystrokes straight into the window's message queue instead of
;  the system input queue. Citrix usually ignores this (it reads raw input),
;  but it costs nothing to rule out.
; ============================================================================
/*
F24::
  Note("F24: ControlSend {Raw}")
  Sleep, %TC_StartDelay%
  txt := TC_Text()
  ControlGetFocus, ctl, A
  if (ctl = "")
    ControlSend, , {Raw}%txt%, A
  else
    ControlSend, %ctl%, {Raw}%txt%, A
return
*/


; ============================================================================
;  helpers
; ============================================================================

; Clipboard as text, with CRLF collapsed to LF so the per-character methods
; do not press Enter twice per line.
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

; Newline / tab handling shared by the AHK-Send based methods.
SendSpecial(ch)
{
  if (ch = "`n")
  {
    SendEvent, {Enter}
    return true
  }
  if (ch = "`t")
  {
    SendEvent, {Tab}
    return true
  }
  return false
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
; AltGr on the Citrix side is itself a classic "wrong characters" cause.
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

; One UTF-16 code unit as a unicode packet, down + up.
SendUnicodeChar(code)
{
  SendInputRaw(0, code, 0x4)
  Sleep, %TC_PressDur%
  SendInputRaw(0, code, 0x4 | 0x2)
}

; --- feedback ---------------------------------------------------------------
Note(txt)
{
  ToolTip, % "type-clip -> " txt
  SetTimer, TC_ClearTip, -1500
}

TC_ClearTip:
  ToolTip
return

; EOF
