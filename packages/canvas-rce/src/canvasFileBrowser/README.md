# This is a terrible hack

In the interest of time, we originally imported the
`canvas-lms/app/jsx/shared/rce/FileBrowser` by dot-doting
our way out of the canvas-rce package. While it worked,
it also prevented canvas-rce from being used outside of
canvas.

Welcome to hack 2, where `FileBrowser.js` and its dependencies
are copied into this package to make us self-contained
again.

This must be redone, but solves an immediate problem.
