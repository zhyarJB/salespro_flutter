# Fix ADB Not Found Error on Windows

## Quick Fix: Find and Use ADB

### Option 1: Find ADB Location (Recommended)

ADB is usually installed with Android Studio or Flutter. Let's find it:

1. **Common locations:**
   - `C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe`
   - `C:\Android\Sdk\platform-tools\adb.exe`
   - `C:\Program Files\Android\Android Studio\platform-tools\adb.exe`

2. **Search for it:**
   - Open File Explorer
   - Go to `C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\platform-tools\`
   - Look for `adb.exe`

### Option 2: Use Full Path (Quick Solution)

Instead of just `adb`, use the full path:

```powershell
# Replace YOUR_USERNAME with your actual Windows username
C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe pair 192.168.1.105:XXXXX
```

**Example:**
```powershell
C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe pair 192.168.1.105:XXXXX
```

### Option 3: Add ADB to PATH (Permanent Solution)

1. **Find your ADB path** (use Option 1 above)
   - Example: `C:\Users\HP\AppData\Local\Android\Sdk\platform-tools`

2. **Add to PATH:**
   - Press `Win + X` → System
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\Users\HP\AppData\Local\Android\Sdk\platform-tools`
   - Click OK on all windows
   - **Close and reopen** Command Prompt/PowerShell

3. **Verify:**
   ```powershell
   adb version
   ```

### Option 4: Use Flutter's ADB

Flutter has its own ADB. Try:

```powershell
flutter devices
```

This should automatically detect your device if it's connected wirelessly.

---

## Quick Commands with Full Path

Replace `YOUR_USERNAME` with your Windows username:

```powershell
# Pair device
C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe pair 192.168.1.105:XXXXX

# Connect
C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe connect 192.168.1.105:XXXXX

# List devices
C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe devices

# Or use Flutter
flutter devices
```

---

## Alternative: Use Flutter Directly

You might not need ADB at all! Try:

1. **Enable Wireless Debugging on your phone** (as per the guide)
2. **Use Flutter directly:**
   ```powershell
   flutter devices
   ```
   
   Flutter might automatically detect your device!

3. **If Flutter detects it, just run:**
   ```powershell
   flutter run
   ```

---

## Find Your Username

To find your Windows username:
```powershell
echo %USERNAME%
```

Then use that in the path above.

