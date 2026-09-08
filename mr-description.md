# Merge Request: Make "Copy Location" copy the plain path

## Summary

`Copy Location` (pathbar context menu, `view.copy-current-location`) currently
copies the current directory **as a file transfer** — `x-special/gnome-copied-files`,
`text/uri-list` and `application/vnd.portal.filetransfer` — i.e. the same
clipboard as Ctrl+C.

Apps that resolve pasted *files* then interpret the paste as "past the folder":
- A Chromium-based page (e.g. the DeepSeek Harness web client) turns the
  portal file transfer into `File` objects; chat/agent UIs then reject
  non-image files with *"Only PNG, JPG, WebP, and GIF images are supported"*,
- Messaging apps (Discord, Fractal, Signal, …) start a file upload instead of
  inserting the path.

Users reach for **Copy Location** expecting the path as text — exactly what
selecting the full path in the location entry (Ctrl+L) and copying produces.

## Change

`action_copy_current_location` now copies the location as plain text:
- local locations → absolute path (`g_file_get_path`),
- non-local locations (GVFS/SMB/…) → URI fallback (`g_file_get_uri`).

Copying files/folders with Ctrl+C / Cut is untouched, so paste-into-Files
operations keep working.

## Related

- !1987 (closed) proposed an optional "Copy Path" item for the same pain point.
- GNOME Discourse: *"Nautilus copy path of directory or file to clipboard
  (Workaround)"* — users work around the missing feature with extensions.

## Tested

- Patch applies cleanly to `main` (commit built on top of 301d1849).
- Same code path compiled and verified on the 50.2.2 tag on Omarchy
  (Arch-based) in daily use.
