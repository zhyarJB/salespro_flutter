# Wireless Setup for Samsung S25 Ultra

## Quick Guide: Connect Your Samsung S25 Ultra Wirelessly

### Prerequisites
- ✅ Phone and computer on the **same WiFi network**
- ✅ Developer Options enabled
- ✅ ADB installed (comes with Flutter/Android SDK)

---

## Step-by-Step Instructions

### Step 1: Enable Developer Options

1. Open **Settings** on your Samsung S25 Ultra
2. Scroll down to **About Phone**
3. Find **Build Number**
4. **Tap "Build Number" 7 times** (you'll see a countdown)
5. You'll see a message: "You are now a developer!"

### Step 2: Enable Wireless Debugging

1. Go back to **Settings**
2. Scroll down to **Developer Options** (now visible)
3. Turn ON **Developer Options** (toggle at top)
4. Find **USB Debugging** and turn it ON
5. Find **Wireless Debugging** and turn it ON
6. Tap on **"Wireless debugging"** to open its settings

### Step 3: Pair Your Phone

1. In Wireless Debugging settings, tap **"Pair device with pairing code"**
2. You'll see:
   - **IP address and port** (e.g., `192.168.1.105:XXXXX`)
   - **6-digit pairing code** (e.g., `123456`)
3. **Write these down** - you'll need them in the next step

### Step 4: Connect from Your Computer

1. Open **Command Prompt** (Windows) or **Terminal** (Mac/Linux)
2. Make sure you're on the **same WiFi network** as your phone
3. Run the pairing command:
   ```bash
   adb pair YOUR_PHONE_IP:PAIRING_PORT
   ```
   
   **Example:**
   ```bash
   adb pair 192.168.1.105:XXXXX
   ```
   
4. When prompted, enter the **6-digit pairing code** from your phone
5. You should see: "Successfully paired to..."

### Step 5: Connect for Debugging

1. After pairing, you'll see a new **IP address and port** in the Wireless Debugging settings
2. Run the connect command:
   ```bash
   adb connect YOUR_PHONE_IP:DEBUG_PORT
   ```
   
   **Example:**
   ```bash
   adb connect 192.168.1.105:XXXXX
   ```
   
3. You should see: "connected to..."

### Step 6: Verify Connection

Run this command to see your connected devices:
```bash
flutter devices
```

You should see your Samsung device listed! 🎉

### Step 7: Run Your App

```bash
cd salespro_flutter
flutter run
```

The app will install and launch on your phone wirelessly!

---

## Troubleshooting

### "adb: command not found"
- Make sure Android SDK is installed
- Add Android SDK platform-tools to your PATH
- Or use full path: `C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools\adb.exe`

### "Unable to connect"
- Make sure phone and computer are on **same WiFi network**
- Check firewall settings (allow ADB connections)
- Try disabling and re-enabling Wireless Debugging
- Restart ADB: `adb kill-server && adb start-server`

### "Device offline"
- Disconnect and reconnect: `adb disconnect` then `adb connect IP:PORT`
- Or restart wireless debugging on your phone

### Can't find "Wireless Debugging" option
- Make sure you're using Android 11 or later (S25 Ultra has it)
- Try updating your phone's software
- Some Samsung devices have it under "Wireless debugging" or "Wireless ADB"

### Connection drops
- Keep your phone screen on during connection
- Make sure WiFi doesn't go to sleep
- Reconnect if needed: `adb connect IP:PORT`

---

## Quick Commands Reference

```bash
# Pair device
adb pair IP:PORT

# Connect for debugging
adb connect IP:PORT

# List connected devices
flutter devices

# Disconnect
adb disconnect

# Restart ADB
adb kill-server && adb start-server

# Run app
flutter run
```

---

## Tips

1. **First time setup:** You might need to pair once, then connect each time
2. **Faster connection:** After first pairing, you can just use `adb connect` next time
3. **Keep it connected:** Don't close the terminal/command prompt while debugging
4. **Same network:** Both devices MUST be on the same WiFi (not mobile data)

---

## Alternative: Using QR Code (Android 13+)

If your phone supports it:
1. In Wireless Debugging, tap **"Pair device with pairing code"**
2. Look for **QR code option**
3. Use `adb pair` with QR code scanner (if available)

---

That's it! You can now develop and test on your Samsung S25 Ultra without a USB cable! 🚀

