# ox_lib (ProByte UI)

This is a modified version of ox_lib 3.39.0 with a redesigned interface (ProByte UI) and an in-game editor for its appearance (`/pbui`). The resource is still named `ox_lib`, and other resources use it the same way as the original.

## Credit and license

ox_lib is made by Overextended: https://github.com/overextended/ox_lib

This package is a modified version of ox_lib. It is distributed under the same license as the original, the GNU Lesser General Public License version 3 (LGPL-3.0-or-later). The full text is in `LICENSE`.

## Redesigned components

- Notifications
- Context Menu, including submenus
- Input Dialog
- Alert Dialog
- Text UI
- Progress Bar and Progress Circle
- Skill Check
- List Menu (`lib.registerMenu` / `lib.showMenu`)
- Radial Menu

## Requirements

- FXServer build 7290 or newer
- OneSync enabled
- FiveM or RedM

The interface is already built (`web/build`); no build step is needed.

## Installation

1. Stop the server.
2. Replace your existing `ox_lib` folder with the `ox_lib` folder from this package. The folder must be named `ox_lib`.
3. If you already use the editor and want to keep your settings, keep your existing `data/ui_settings.json` instead of the default one in this package.
4. In `server.cfg`, ensure `ox_lib` before every resource that uses it:

   ```cfg
   ensure ox_lib
   ```

5. Start the server, or restart it if it was running.

## The /pbui editor

`/pbui` opens an editor for the look of the components. Only players with the ACE permission `probyte.ui` can open it or save. Grant it in `server.cfg`, for example:

```cfg
add_ace group.admin probyte.ui allow
```

A player without the permission gets an error notification instead.

What it edits:

- Targets: Global, Context Menu, Notifications, Input Dialog, Alert Dialog, Text UI, Progress, Skill Check, Radial Menu and List Menu. Every component uses the Global values unless it overrides them.
- Options: accent color, color intensity, background, transparency and corners.
- Component language: Global only.
- Perspective: Context Menu and Notifications only.
- A preview in the editor shows the unsaved changes.

Saving writes the settings to `data/ui_settings.json` inside the `ox_lib` folder and sends them to every connected player. No restart is needed. If the file is missing, the default settings are used. This package includes the default file.

The editor's own panel color and panel language are stored on each player's client, not in `data/ui_settings.json`.

## Languages

- The components can be shown in English or Arabic. Set the component language in `/pbui` under Global.
- Arabic switches the components to right-to-left and uses the Cairo font.
- The ox_lib locale files in `locales/` and the `ox:locale` convar work as in the original ox_lib.

## Credits

- ox_lib by Overextended, LGPL-3.0-or-later.
- Cairo font, licensed under the SIL Open Font License 1.1. The license is in `web/build/fonts/cairo/OFL.txt`.
