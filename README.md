# MouseDance

A tiny native macOS utility that nudges the mouse pointer by one pixel every
three seconds and immediately puts it back.

## Run it

Double-click `MouseDance.command` in Finder. Keep the Terminal window open while
it runs. Press **Control-C** in that window to stop it.

On first launch, macOS may ask for permission. Enable your terminal application
under **System Settings > Privacy & Security > Accessibility**, then launch
`MouseDance.command` again.

You can also run it from Terminal:

```sh
./MouseDance.command
```

The first launch compiles the small native program. Later launches reuse the
compiled binary unless the source changed. No third-party dependencies are
required; if the compiler is missing, install Apple's Command Line Tools
with `xcode-select --install`.

MouseDance keeps the computer receiving pointer activity, but Microsoft Teams
ultimately controls how presence is calculated, so its status is not guaranteed.
