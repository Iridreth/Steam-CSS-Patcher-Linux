# Steam CSS Patcher (Linux)

A simple, interactive Bash script for customising the Steam client UI on Linux by patching Steam’s compiled CSS files.

I prefer a minimalist aesthetic, and one day became annoyed by the subjective bloat on Steam's Library page. I came across a Powershell script by xtcrefugee (https://github.com/xtcrefugee) and decided to adapt it so that I could use it on Linux. I threw it into an AI server I had built and decided to vibecode it into an interactive script.  This is the result.

This script allows you to:
- Hide the 'What’s New' section
- Remove the 'Add Shelf' feature
- Hide the Left Column
- Safely backup, restore, and clean up CSS changes

⚠️⚠️⚠️ Use at your own risk — Steam updates may overwrite CSS files at any time. ⚠️⚠️⚠️

Make sure to keep a backup of the original. On my Arch system it can be found here:

    ~/.steam/steam/steamui/css/chunk~2dcc5aaf7.css

---

## Features

- Interactive menu-driven interface
- Automatic detection of the active css file
- Optional backups before patching
- Selective enable/disable of the Steam Library page UI elements. Each CSS change is optional and confirmed interactively.
- Restore from a previous backup
- Ensures Steam is not running before modifying files
- Writes changes to a temporary file and only replaces the original if changes were made

---

## Requirements

- Linux
- Bash (tested with bash 5+)
- Steam 

Expected Steam CSS path:

    ~/.steam/steam/steamui/css/

---

## Installation

Clone the repository:

    git clone https://github.com/yourusername/steam-css-patcher.git
    cd steam-css-patcher

Make the script executable:

    chmod +x steam-css-patcher.sh

---

## Usage

Run the script in your preferred Linux terminal:

    ./steam-css-patcher.sh

### Main Menu Options

- Apply CSS changes
- Reverse CSS changes
- Restore from backup
- Clean old backups
- Quit

---

## Backups

- Backups are stored alongside the CSS file:

    chunk~xxxxx.css.backup  
    chunk~xxxxx.css.backup.1  
    chunk~xxxxx.css.backup.2  

- Each backup includes a timestamp in the menu
- You can restore or delete backups from within the script

---

## Important Notes

- Steam updates may overwrite patched CSS files, so you may need to re-run the script after Steam updates if the Library UI reverts back to the Steam default
- This script relies on exact CSS matches — if Steam changes class names, patches may stop working
- Always keep at least one backup

---

## 📜 License

MIT License — use, modify, and share freely.

---

## ❓ Disclaimer

This project is not affiliated with Valve or Steam.  
All trademarks belong to their respective owners.

---

Original inspiration came from the original PowerShell script by xtcrefugee:
https://github.com/xtcrefugee
