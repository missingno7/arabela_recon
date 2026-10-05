# Behavior audit: DOS oracle versus SDL3

Audited on 2026-10-05 against the untouched `historical-exact-oracle-v1`
tag. This report distinguishes preserved game rules, corrections to the
first port, and remaining platform/presentation differences.

## Every timed game event is present

The production `Udalost` body retains the recovered DOS control flow.
There are five event effects, not five independent timers:

| Event | Preserved effect |
| --- | --- |
| Chechota disappears | `chechotaZije := false`; castle descriptions change accordingly. |
| Müllerová marries Blekota | Character 11 becomes `pani Blekotova`; a visible room is redescribed when appropriate. |
| Talking wolf steals | Takes a random held item except the crystal ball, places it in another unoccupied/item-free room in the same realm, and updates the hands. |
| Basilisk carries Petr away | Chooses another room in the same realm and sets `uvnitr := 0`. |
| Two characters exchange places | Swaps two distinct characters and moves the contents associated with their rooms; redescribes a visible affected room. |

The first **two** events are disappearance and marriage. Their order is
randomly selected by `chechota`. Then the wolf/basilisk/exchange cycle starts
at the randomly chosen `druhUdalosti`. A wolf event is skipped in favor of
the basilisk if the player has no eligible item (no hands, or only the ball).
The starting point is random; the later cycle is not a fresh random choice
each time. Character selection and room/item choices still consume the
original TP6 random sequence.

Timing is also specific:

* `zacatek` and `ted` are recorded before placement, introduction and the
  first room description. That output time counts toward the first event.
* First interval: 300 seconds. Subsequent intervals: 120, 180, 240, 300,
  360 seconds, increasing by 60 each time.
* The test is **`ted + odstup < Cas`**, with whole seconds. In a fixture
  starting at second zero, the first event cannot fire at 300 or 300.999
  seconds; it becomes eligible at second 301.
* `ted` uses the time sampled **before** the alarm and message. The time
  spent printing consumes part of the next interval.
* Events run while waiting with an empty command. They are deferred during
  a partially typed command, command execution, output, exit confirmation
  and score-name entry. Clearing a partial command makes events eligible
  again. There is no catch-up replay of every interval after a long delay.
* The alarm calls nine 30 ms waits: 440/660/880 Hz, repeated three times,
  totalling 270 ms before the notice. The waits are now preserved; the
  audible tones are still missing.

## What the first SDL3 milestone had lost, now corrected

| Difference in the first port | Current behavior |
| --- | --- |
| `Vypis` printed whole strings instantly. | Each non-space character gets the original `Delay(10)` then `Delay(50)`. Spaces have no wait. Punctuation gets the same wait as letters. |
| The input prompt appeared instantly. | `Zadej prikaz: ` is written at the same cadence; its 12 non-space characters consume 720 ms, as in the DOS source. |
| Delay calls in the event alarm did nothing. | The 270 ms alarm timing is restored. |
| Clicks executed commands immediately. | A click writes its command in the input line at the same character cadence, then submits it. Ball-query buttons animate their prefix and wait for the player to complete it. |
| Input was processed before an overdue event. | An empty-input frame checks the event first. Input arriving during the notice/output is discarded, matching the DOS output/input boundary. |
| Commands were trimmed before parsing. | Leading/trailing spaces remain significant. The original parser receives the actual command. |
| The game editor accepted extra characters and 120 bytes. | Normal commands retain the original ASCII letters/spaces and 60-character limit. UTF-8 remains supported for player names/rendering. |
| Escape interrupted a partial command. | Escape is effective with an empty command, as in the original editor. |
| Left arrow did nothing while editing. | It removes the last character. If that leaves an empty line, the same key can trigger west movement, preserving the DOS quirk. |
| Repeated Backspace/key-down events were ignored. | Editing repeats are accepted; the added F2 restart does not repeat. |
| Empty score names were refused. | Empty names are accepted, as by the original `ReadLn`. |
| The winning summary appeared after score-name entry. | Elapsed result and ranking are now shown before asking for the name; the table follows name entry. |
| Default RNG seeds came from ticks just after SDL startup. | Seeds now use the TP6 `Randomize` time-of-day byte layout: hour/minute and second/hundredth. `--seed` still provides exact reproducibility. |

Only calls to `Vypis` are slow. Original direct `Write`/`WriteLn` calls
(title, borders, some numeric score fields and keyboard echo) remain fast.
Keyboard shortcut autofill also remains instantaneous: the DOS
`DoplnPrikaz` uses `Write`, not `Vypis`. Mouse selection did not exist in
the DOS game; its requested animation is an intentional new interaction,
and its elapsed time counts toward the game clock.

There is no background text queue that lets the game run ahead of its
visible response. The existing Pascal call order is retained. `Delay`
calls a small SDL wait function that renders and pumps resize, scrolling,
pause and quit events while refusing reentrant gameplay input. No game
event is invoked from that wait. This also fixes a subtle score problem:
the final `Diky, Petre !` waits complete before the winning time is sampled.
Time spent entering a high-score name remains excluded.

UTF-8 characters are emitted as complete glyphs before a wait; a multibyte
name does not flicker through incomplete UTF-8 bytes. Silent command-list
refreshes do not add artificial delays. Cached text textures prevent the
entire history being rerendered for every character.

The target is the source's **nominal 60 ms cadence**, not bit-exact DOS
hardware timing. The original Crt `Delay` is a CPU-loop implementation
(load segment `0764`, offset `029C`); CPU/emulator calibration and drawing
overhead affect its physical duration. SDL display refresh also limits
which individual frames can be visible. The port is not an emulation of
the DOS display or PIT/PC speaker.

## Remaining differences and losses

| Area | Remaining difference | Assessment |
| --- | --- | --- |
| Sound | No 330 Hz typing clicks, 440/660/880 Hz notice alarm, or ending melody. `Sound`/`NoSound` are still silent. | A remaining presentation loss. Timing of typing and notices is restored separately. |
| Ending | The 30-note tune and its nominal 19.2 seconds of waits are absent; the native window stays available after completion. | Remaining loss/change. The score is already frozen before this tune in DOS, so it does not change scoring or timed events. |
| VGA intro | The ELEPS splash/palette/graphics sequence is omitted. | Previously agreed omission; historical files remain intact. |
| Clock | Monotonic elapsed seconds replace DOS wall time and its 16-bit expression overflow/midnight adjustment. | Required native design. Clock changes and the DOS overflow cannot stall native events or distort scores. |
| Background/focus | Losing focus pauses elapsed time and any active character wait. DOS has no corresponding app-suspension policy. | Intentional native/Android behavior; it changes whether offscreen time counts. |
| Rendering | Scalable UTF-8 font, viewport wrapping and scrollback replace 80x25 Crt geometry, exact line indentation and screen scrolling. | Intentional frontend change; no pixel-identical claim. |
| Commands/actions | Valid actions are continuously clickable, rather than requiring `?` to reveal help. F2 restart and direct window-close are additions. | Intentional convenience; action legality still comes from `MoznePrikazy`. |
| Input buffering | Busy output discards gameplay input. Ready-state SDL text chunks are accepted together; the DOS loop's per-key flush is not reproduced byte-for-byte for paste/IME. DOS A/N confirmation and score-name reads can retain keys pressed during preceding output; the native busy guard drops those too. | Remaining input adaptation. Wait for the confirmation/name prompt to finish. Ordinary command alphabet, limits and shortcuts are preserved. |
| Scores | Application-writable path, atomic replacement, file validation and zeroed unused records replace executable-relative files and leaked/uninitialized DOS tail bytes. UTF-8 names use the same 20-byte field. | Intentional storage adaptation; score ordering, ties and 11 entries are preserved. |
| Legacy names | No automatic OEM Czech-to-UTF-8 conversion when importing non-ASCII DOS player names. | Remaining interoperability gap. The supplied ASCII score file is supported. |
| Undefined storage | Native globals start clean; arbitrary inactive DOS bytes are not treated as game rules. | Deliberate. The DOS walkthrough fixture now explicitly initializes the unused query discriminator while `cil = -1`; changing probe layout exposed its uninitialized storage. |

Known strange gameplay constructs remain preserved: the placement routine's
`c := a + 1`, clearing only an object's x coordinate, retaining the previous
ball target after an unknown query, the two-hand limit, exchange rules,
special-location restrictions and the original event cycle. This work does
not repair those game rules or change the closed DOS reconstruction.

## Evidence and checks

`portable/build.ps1 -Tests -Oracle -VideoDriver windows` provides:

* The existing 63 command/event assertions and the 84-command walkthrough.
* Deterministic checks of both introductory event orders, every event type,
  increasing intervals, strict whole-second thresholds, excluded ball theft,
  character/alarm waits, score freeze and silent action refresh.
* The **same virtual-clock experiment** compiled against recovered TP6
  routines and native production routines: 27 samples containing elapsed
  milliseconds, event result, timer fields, RNG seed, positions and hands.
  The 7,290-byte `TIME.BIN` vectors match byte-for-byte, SHA-256
  `bdf1d1f8826ac2bf340a75cce4ba52d3d5ff717b3e538f1668cd9d984a3e881a`.
  Clock/delay instrumentation exists only in ignored generated DOS probe
  output; it does not alter the historical sources. This isolates semantics
  from wall-clock/CPU calibration and is not a hardware benchmark.
* A real SDL wait/render test: visible `A`, then `A B`, 10/50 ms waits,
  immediate spaces, busy-input rejection and resizing during animation.
* SDL checks for event-before-input ordering, deferral during partial input,
  editor limits/shortcuts and the complete winning sequence.

The large walkthrough smoke test is accelerated with a test-only clock/wait
configuration. Production builds always use the recovered typing waits.
Both the software test renderer and native Windows renderer are checked.
Linux and Android execution remain unverified.
