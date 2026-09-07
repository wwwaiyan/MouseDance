# MouseDance for macOS

MouseDance is a tiny menu-bar app that gently nudges the pointer to keep the Mac
active. It also provides separate scroll directions for a mouse and trackpad.
It has no third-party dependencies and does not need Git.

## Easiest option for regular users

### DMG installer

Download `MouseDance-macOS.dmg`, open it, and drag **MouseDance** onto the
**Applications** shortcut. This is the most familiar installation method.

### One-line install

Paste this into Terminal to download the latest release, verify its checksum,
install it for the current user, and start it:

```sh
curl -fsSL https://raw.githubusercontent.com/wwwaiyan/MouseDance/main/install.sh | bash
```

This installs to `~/Applications`, so it does not need an administrator password.
When upgrading, the installer stops the running older version before replacing
and relaunching it.

### Portable ZIP

Download and unzip `MouseDance-macOS-portable.zip`, then either:

- Double-click `MouseDance.app` to run it portably from any folder.
- Double-click `Install MouseDance.command` to copy it to `~/Applications` and
  start it.

The app is not notarized. On first launch, if macOS blocks it, Control-click
`MouseDance.app`, choose **Open**, then choose **Open** again.

## Use the app

The mouse icon in the macOS menu bar opens the controls:

- Turn **Move pointer automatically** on or off. It is off by default.
- Choose **Move pointer now** to test it immediately.
- Keep **Keep Mac awake while moving** checked to prevent idle display and
  system sleep whenever automatic movement is enabled.
- Choose 3, 5, 10, 30, or 60 seconds.
- Choose **Custom…** for any interval from 0.2 to 3600 seconds.
- Keep **Independent scrolling** enabled to control both devices separately.
- Set **Mouse wheel direction** to Natural or Standard.
- Set **Trackpad direction** to Natural or Standard.
- Choose **Uninstall MouseDance…** to move the app to Trash.
- Choose **Quit MouseDance** to exit.

Independent scrolling defaults to **Standard** for a mouse wheel and **Natural**
for a trackpad. MouseDance automatically compensates for the current macOS
Natural Scrolling value, so users do not have to change that system setting.
Independent scrolling works even when automatic pointer movement is disabled.

When enabled, the pointer follows a visible, smooth arc across 36 pixels and
alternates left and right. If the user starts moving the pointer during the
animation, MouseDance cancels that animation instead of fighting for control.

The keep-awake option uses macOS power assertions. It prevents normal idle
display and system sleep while automatic movement is running, but it cannot
override closing the MacBook lid, manually locking the Mac, low-battery safety
behavior, or organization-managed security policies.

Settings are remembered between launches. macOS may ask for Accessibility
permission because MouseDance moves the pointer. Enable it in **System Settings
> Privacy & Security > Accessibility**.

## Uninstall

Choose **Uninstall MouseDance…** from the mouse menu, or double-click
`Uninstall MouseDance.command` in the downloaded package.

Terminal users can uninstall with one line:

```sh
curl -fsSL https://raw.githubusercontent.com/wwwaiyan/MouseDance/main/uninstall.sh | bash
```

That command preserves saved settings. To remove the app and its settings:

```sh
curl -fsSL https://raw.githubusercontent.com/wwwaiyan/MouseDance/main/uninstall.sh | bash -s -- --purge
```

The app is moved to Trash rather than permanently deleted.

## Build from source

Developers can run:

```sh
./build.sh
./package.sh
```

`build.sh` creates a universal `MouseDance.app` for Apple Silicon and Intel Macs.
`package.sh` creates the shareable ZIP and drag-to-Applications DMG under `dist/`.

## GitHub builds and releases

GitHub Actions packages the app on pushes to `main`, pull requests, and manual
workflow runs. Pushing a version tag such as `v2.4.0` creates a GitHub Release
containing the portable ZIP, DMG, and their SHA-256 checksums. See
[`RELEASING.md`](RELEASING.md) for the release steps.

MouseDance distinguishes ordinary mouse wheels from trackpads using macOS's
continuous-scrolling event flag. Some smooth-scrolling mice, including some
third-party drivers and Magic Mouse behavior, may appear trackpad-like to macOS.

Microsoft Teams ultimately controls its own presence calculation, so a green
status is not guaranteed.
