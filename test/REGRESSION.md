# ClockMu 2.0.0: device check (RG35XX, about 15 minutes)

Install, open ClockMu, then (your existing alarms and settings are kept):

1. **List**: the clock card shows the right time and the date; your alarms are
   listed with time, label, repeat, snooze minutes and an on/off dot. **Up/Down**
   move the highlight; **L1/R1** page, **L2/R2** jump. Footer: Edit, Toggle, Add,
   Delete (START), Theme (SELECT), Quit.
2. **Toggle** (X): the dot and the time dim/brighten.
3. **Add** (Y): "New alarm" opens. Change Hour with Left/Right and **L1/R1** (±1 h);
   Minute with Left/Right (±1) and **L1/R1** (±10); open **Label** (A) -> pick one
   -> back on Edit; **Repeat days**: Left/Right moves the cursor, **A** toggles a
   day, **X** clears; **Snooze** cycles 5/10/15; **Enabled** toggles. **START** saves.
   The list shows it. The edit hint bar changes per field.
4. **Preset time** (Y in the editor): list of times every 15 min, starts at the
   closest one; **L1/R1/L2/R2** page and jump; **A** picks, **B** cancels.
5. **Custom label**: Label -> A -> pick "Custom..." (last). The keyboard opens with
   the current text: type with **A**, **X** deletes, **Y** shift, **L1/R1** switch
   to the symbol page (try `! @ # & ( )`), **START** or OK accepts, **B** cancels.
   The label shows on the list (20 characters at most).
6. **Fifth and sixth alarm**: with 5 alarms, **Y** shows "Alarm limit" instead of
   opening the editor.
7. **Delete** (START): asks "Delete alarm?"; **B** keeps, **A** deletes.
8. **Theme** (SELECT): five colours, **Y** dark / light, **A** keeps, **B**
   restores. Quit and reopen: the theme is still there. (An old 1.0 settings file
   with a number picks the matching theme.)
9. **Quit** (B on the list): "Quit ClockMu?"; **B** stays, **A** quits. B on any
   other screen only goes back.
10. **An alarm rings** (set one for the next minute and wait, with the list open):
    the screen turns to the ALARM view (header flashes, big time, label), the
    sound plays. **A** snoozes, **B** dismisses (a one-shot turns itself off). Try
    it once with the Quit? dialog open, and once inside the editor: the alarm
    must still take over.
11. **Snooze comes back** (the fix): snooze an alarm (10 min is the default; use
    5 for the test) and wait. It must ring again when the time is up, with "ZZZ"
    on its row meanwhile. Dismiss the second ring.
12. **Footer glyphs** squish and glow while the button is pressed.
13. Report anything odd with `clockmu.log` from the app folder.

**Hold to repeat (fskit 0.3.1, new)**: hold Up/Down on any list (and on the keyboard, Left/Right): after a short
pause it keeps moving, and it stops at the end of the list instead of wrapping round and round. It stops the moment you let go.
