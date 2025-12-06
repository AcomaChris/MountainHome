# Mountain Home

A 2D hex-based board game built with Lua and Love2D. Players manage a homestead through 12 months of the year, making decisions about building, upgrading, and maintaining their property.

## Getting Started

### Prerequisites
- [Love2D](https://love2d.org/) (LÖVE) game framework installed

### Installation (Windows)

1. **Download Love2D:**
   - Visit https://love2d.org/
   - Download the Windows installer (64-bit recommended)
   - Run the installer and follow the setup wizard

2. **Add Love2D to PATH (for command line usage):**
   - During installation, check the option to "Add to PATH" if available
   - If not added automatically:
     - Find where Love2D was installed (usually `C:\Program Files\LOVE\` or `C:\Program Files (x86)\LOVE\`)
     - Copy the full path to the folder containing `love.exe`
     - Open System Properties → Environment Variables
     - Edit the "Path" variable under User variables
     - Add the Love2D installation path
     - Restart your terminal/PowerShell

3. **Verify Installation:**
   - Open a new PowerShell window
   - Run: `love --version`
   - You should see the Love2D version number

### Running the Game

**Option 1: Command Line (requires PATH setup)**
1. Navigate to the project directory
2. Run: `love .`

**Option 2: Drag and Drop (no PATH needed)**
1. Open File Explorer and navigate to the project folder
2. Drag the entire project folder onto `love.exe` (usually in `C:\Program Files\LOVE\`)

**Option 3: Direct Path (no PATH needed)**
1. Navigate to the project directory in PowerShell
2. Run: `& "C:\Program Files\LOVE\love.exe" .` (adjust path if needed)

The game should open in a window displaying "Mountain Home" text.
