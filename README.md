# Calculator

A simple calculator app for macOS with a photo background, frosted-glass buttons and a live equation line (`8 × 5 =` shown above the answer).

## Download and run

1. Go to the **Releases** page of this repository and download `Calculator.zip`.
2. Double-click the zip to unzip it, then drag `Calculator.app` into your **Applications** folder.
3. Open it. The first time, macOS will say it *"could not verify"* the app, because it isn't signed with a paid Apple Developer account. To open it anyway:
   - Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the Calculator message.
   - Or, in Terminal: `xattr -dr com.apple.quarantine /Applications/Calculator.app`

**Requirements:** macOS 13 (Ventura) or newer. Works on both Apple Silicon (M1/M2/M3/M4) and Intel Macs.

## Using it

Click the buttons or use the keyboard:

| Key | Action |
|---|---|
| `0`–`9`, `.` | Enter a number |
| `+` `-` `*` `/` | Add, subtract, multiply, divide |
| `Return` or `=` | Calculate |
| `%` | Percent |
| `Delete` | Erase the last digit |
| `C` | Clear the current number |
| `Esc` | Clear everything |

Calculations run left to right, like a basic pocket calculator: `2 + 3 × 4 = 20`.

## Build it yourself

You need Apple's free command-line developer tools (run once):

```sh
xcode-select --install
```

Then:

```sh
git clone <this repository's URL>
cd Calculator
./build.sh
open build/Calculator.app
```

`build.sh` creates `build/Calculator.app` and `build/Calculator.zip` (the file to attach to a GitHub Release).

## Customizing

- **Background photo:** replace `6.jpg` with any JPEG (keep the name), then run `./build.sh` again.
- **App icon:** edit `make_icon.swift`, delete `AppIcon.icns`, then run `./build.sh` again.

## Project files

| File | What it does |
|---|---|
| `CalculatorApp.swift` | Starts the app and opens the window |
| `ContentView.swift` | The screen: background, display and buttons |
| `CalculatorEngine.swift` | The math and the equation line |
| `make_icon.swift` | Draws the app icon |
| `build.sh` | Builds the app and the release zip |
| `6.jpg` | Background photo |
| `AppIcon.icns` | App icon |
