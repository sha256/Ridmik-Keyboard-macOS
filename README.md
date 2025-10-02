# Ridmik Keyboard for macOS

Bangla input methods for macOS.

## Features

- **Multiple Input Methods**: 
    - **অভ্র** (Avro Phonetic)
    - **জাতীয়** (Jatiyo)
    - **সহজ** (Phonetic using only lowercase letters)
    - **প্রভাত** (Probhat)
- **Native macOS Integration**: Works system-wide in all applications
- **Old style -kars**: Supports switching to old style kars (ে + ক => কে) in জাতীয় (Jatiyo)

## Installation

### Download and Install

1. **Download the latest release**
   - Go to [Releases](https://github.com/sha256/Ridmik-Keyboard-macOS/releases)
   - Download the latest `.pkg` file

2. **Install the package**
   - Double-click the downloaded `.pkg` file
   - Follow the installer instructions
   - Click "Install" to complete the installation

3. **Enable the input method**
   - **Logout from your Mac and log-in again** (important!)
   - Open **System Settings** (or System Preferences on older macOS)
   - Go to **Keyboard** → **Input Sources** → Click **Edit** button
   - Click the **+** button to add a new input source
   - Select **Bangla** from the left panel
   - Choose your preferred input method from the right panel
   - Click **Add**

4. **Start typing**
   - Open any text field
   - Click the language icon in the menu bar (top-right corner)
   - Select your Ridmik input method
   - Start typing in Bangla!


## Usage

Once installed and enabled:

1. Switch input methods using the menu bar language icon
2. Or use keyboard shortcut (default: `⌘ + Space`, then select input method)
3. Type phonetically and see Bangla characters appear
4. Different input methods have different key mappings - choose the one you're comfortable with

## Development

### Prerequisites

- macOS 15.4 or later
- Xcode 16.0 or later
- Swift 5.0 or later

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/sha256/Ridmik-Keyboard-macOS.git
   cd Ridmik-Keyboard-macOS
   ```

2. **Build the project**
   ```bash
   xcodebuild -project Ridmik.xcodeproj -scheme Ridmik -configuration Release build
   ```

3. **Install locally for testing**
   ```bash
   # Copy to Input Methods directory
   sudo cp -R build/Release/Ridmik.app ~/Library/Input\ Methods/

   # Logout and login again to register the input method
   ```

### Development Workflow

1. **Make changes** to the source code
2. **Build** using the Run button, which places the output `.app` file in the destination. The build scheme has pre- and post-actions to handle this properly. 
4. **Logout and login** after the first build or after updating the `Info.plist`
5. **Debug** by checking Console.app for logs

### Creating a Release

1. **Set up environment variables**
   ```bash
   export DEVELOPER_NAME="Your Name"
   export TEAM_ID="YOUR_TEAM_ID"
   export APPLE_ID="your-apple-id@example.com"
   export APP_PASSWORD="your-app-specific-password"
   ```

2. **Run the release build script**
   ```bash
   ./release_build.sh
   ```

3. **Output files**
   - `release/Ridmik-YYYY.MM.DD.pkg` - Signed installer package
   - `release/Ridmik-YYYY.MM.DD.dmg` - DMG for distribution

The script will:
- Build a Universal binary (Intel + Apple Silicon)
- Sign the app with Developer ID
- Create a PKG installer
- Notarize with Apple
- Create a DMG for distribution

### Adding a New Input Method

1. Create a new Swift file in `Keyboard/Methods/`
2. Implement the `InputMethodProtocol`
3. Define your key mappings
4. Register the input method in `InputMethodController.swift`
5. Update `Info.plist` to include the new input mode
6. Logout and login again to reflect changes from Info.plist

## Troubleshooting

### Input method not appearing

- Make sure you've logged out and logged back in after installation
- Check if the app exists in `~/Library/Input Methods/Ridmik.app`
- Try restarting your Mac

### Input method not working

- Check Console.app for error messages
- Verify the input method is selected in System Settings
- Try removing and re-adding the input source


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

GPLv3

