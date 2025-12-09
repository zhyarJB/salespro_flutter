# Running Flutter App on Physical Mobile Device

## Step 1: Find Your Computer's IP Address

### Windows:
1. Open Command Prompt (cmd)
2. Type: `ipconfig`
3. Look for "IPv4 Address" under your active network adapter
4. Example: `192.168.1.100`

### Mac/Linux:
1. Open Terminal
2. Type: `ifconfig` (Mac) or `ip addr` (Linux)
3. Look for your network interface (usually `en0` on Mac, `wlan0` on Linux)
4. Find the `inet` address (e.g., `192.168.1.100`)

## Step 2: Update API URL in Code

1. Open `lib/services/auth_service.dart`
2. Find the line: `static const String _localNetworkIp = 'YOUR_COMPUTER_IP';`
3. Replace `YOUR_COMPUTER_IP` with your actual IP (e.g., `'192.168.1.100'`)
4. Example: `static const String _localNetworkIp = '192.168.1.100';`

## Step 3: Make Sure Laravel Server is Accessible

1. Start your Laravel server:
   ```bash
   cd salespro-dashboard
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   The `--host=0.0.0.0` makes it accessible from other devices on your network.

2. Test from your phone's browser:
   - Open browser on your phone
   - Go to: `http://YOUR_COMPUTER_IP:8000`
   - You should see the Laravel welcome page

## Step 4: Connect Your Device

### For Android (Samsung S25 Ultra):

#### Option 1: Wireless Debugging (Recommended - No USB Cable Needed!)

1. **Enable Developer Options:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options
   - Enable "USB Debugging" (needed even for wireless)

2. **Enable Wireless Debugging:**
   - In Developer Options, find "Wireless debugging"
   - Turn it ON
   - Tap on "Wireless debugging" to open settings
   - Tap "Pair device with pairing code"
   - Note the IP address and port (e.g., 192.168.1.105:XXXXX)
   - Note the 6-digit pairing code

3. **Connect from Computer:**
   - Make sure your computer and phone are on the **same WiFi network**
   - Open Command Prompt (Windows) or Terminal (Mac/Linux)
   - Run this command (replace with your phone's IP and port):
     ```bash
     adb pair YOUR_PHONE_IP:PAIRING_PORT
     ```
   - Example: `adb pair 192.168.1.105:XXXXX`
   - Enter the pairing code when prompted
   - After pairing, you'll see a new IP and port, run:
     ```bash
     adb connect YOUR_PHONE_IP:DEBUG_PORT
     ```
   - Example: `adb connect 192.168.1.105:XXXXX`

4. **Verify Connection:**
   ```bash
   flutter devices
   ```
   - You should see your device listed

#### Option 2: USB Cable (Alternative)

1. **Enable Developer Options:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect via USB:**
   - Connect phone to computer with USB cable
   - On phone, allow USB debugging when prompted
   - Verify connection:
     ```bash
     flutter devices
     ```
   - You should see your device listed

### For iOS:

1. **Connect via USB:**
   - Connect iPhone/iPad to Mac with USB cable
   - On iPhone, trust the computer when prompted
   - Verify connection:
     ```bash
     flutter devices
     ```

2. **Requirements:**
   - Must use a Mac (iOS development requires Xcode)
   - Need Apple Developer account (free account works for testing)
   - Xcode must be installed

## Step 5: Run the App

1. **Make sure you're in the Flutter project directory:**
   ```bash
   cd salespro_flutter
   ```

2. **Run on connected device:**
   ```bash
   flutter run
   ```
   
   Or specify device:
   ```bash
   flutter run -d <device-id>
   ```

3. **For release build (faster, no debug features):**
   ```bash
   flutter run --release
   ```

## Step 6: Troubleshooting

### Device Not Detected:
- Make sure USB debugging is enabled (Android)
- Try different USB cable/port
- Restart adb: `adb kill-server && adb start-server`
- Check `flutter doctor` for issues

### Can't Connect to API:
- Make sure phone and computer are on the same WiFi network
- Check firewall settings on your computer (allow port 8000)
- Verify Laravel server is running with `--host=0.0.0.0`
- Double-check IP address in `auth_service.dart`
- Test API from phone browser first

### Build Errors:
- Run `flutter clean`
- Run `flutter pub get`
- Check `flutter doctor` for missing dependencies

## Quick Reference

**Find IP Address:**
- Windows: `ipconfig`
- Mac/Linux: `ifconfig` or `ip addr`

**List Connected Devices:**
```bash
flutter devices
```

**Run App:**
```bash
flutter run
```

**Check Flutter Setup:**
```bash
flutter doctor
```

## Notes

- Your computer and phone must be on the **same WiFi network**
- The IP address might change if you reconnect to WiFi
- For production, you'd use a real server/domain, not local IP
- This setup is only for development/testing, not deployment

