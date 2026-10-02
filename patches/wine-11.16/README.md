# Wine 11.16 patch set

`0001`–`0031` are the 11.12 set, carried over **unchanged**, numbers included, so
`diff -r patches/wine-11.12 patches/wine-11.16` shows exactly what is new.

`0001-downgrade-dxcore-to-10_8` reports *"Reversed (or previously applied)"* on
11.16 and is skipped; `Build-Wine-11.16.sh` already treats that as success, and
`0002`/`0006` still apply on top. Leaving it in place keeps the numbering stable.

`0032`–`0049` are new: the Affinity patch set, in the order it is developed
and tested. They make a document open when it is double-clicked in a file
manager, and fix the interaction and exit bugs Affinity 3.3 hits under Wine.

| | |
|---|---|
| `0032` wintypes | `RoResolveNamespace` was a hard stub, so WinRT namespace resolution never happened |
| `0033`–`0037` widl | Five metadata defects. Two of Wine's own shipped winmds are invalid PE files without `0034` |
| `0038`–`0040` winex11 / win32u | Dockable panels: a floating panel can be dragged back into a dock; the move loop no longer outlives the button or the window |
| `0041` server | No Wine application could raise its own window while the focus was on a non-Wine window |
| `0042` winex11 | Wine never set `_NET_WM_STATE_MODAL`, so a modal dialog could stack behind the window it had disabled |
| `0043` comdlg32 | The portal file dialog was not modal, had no parent and no title |
| `0044` winex11 | The dead keyboard after a file dialog: Wine declined the focus offered to a still-disabled window |
| `0045` comdlg32 | Save As opens in the document's own folder rather than wherever the portal last was |
| `0046` comdlg32 | The focused control is restored after the portal dialog closes |
| `0047` ole32 | Reordering Studio tabs crashed Affinity: the drag loop dispatched mouse input instead of handling it |
| `0048` comdlg32 | A portal dialog the application titles itself ("Select Folder") is named for the application too, so a keep-above window rule can match it |
| `0049` ntdll | Affinity 3.3 never exited: at exit a destructor waits on an SRW lock whose owner `ExitProcess` killed. Windows ends the process there; Wine waited forever. From GE-Proton |

`0032` must not ship without `0035`: with the assembly name still set to the
output path, implementing `RoResolveNamespace` makes the CLR fail later and
harder than leaving it stubbed.

Verified against a pristine `wine-11.16.tar.xz` (2026-10-01): `0032`–`0049`
apply in order with no fuzz.
