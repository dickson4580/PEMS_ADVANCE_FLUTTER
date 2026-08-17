# PEMS Advanced Flutter App

This package is the advanced Flutter replacement for the original Expo/React Native PEMS demo app.

It keeps the working ESP32 local API while expanding the mobile application into a tenant/landlord energy-management client.

## Included

- Tenant dashboard with wallet balance, supply state, live energy metrics, protection state and device status.
- Usage analytics with a lightweight custom Flutter chart.
- Wallet top-up screen connected to the existing ESP32 endpoint.
- Transaction history.
- Alerts for low balance, relay disconnection, device offline, tamper, high voltage and low voltage.
- Tenant account/device information.
- Landlord overview with room/device operational cards.
- Device-management screen.
- Local ESP32 mode and cloud-ready mode.
- Polling of the ESP32 meter status every 3 seconds.
- Companion firmware that adds advanced fields to the existing `/meters/demo-meter-01/status` response.

## Existing local API

Default local base URL:

`http://192.168.4.1/api/v1`

Expected endpoints:

- `POST /auth/login`
- `POST /auth/refresh`
- `GET /tenants/me`
- `GET /meters/demo-meter-01/status`
- `GET /meters/demo-meter-01/usage`
- `GET /meters/demo-meter-01/transactions`
- `POST /payments/topup`

The app remains compatible with the original demo firmware. Advanced metrics such as voltage/current/power will display `--` until the companion advanced firmware is uploaded.

## Quick start on Fedora/Linux

Make sure Flutter is installed and available in your terminal:

```bash
flutter --version
```

Then extract this package and run:

```bash
cd PEMS_Advanced_Flutter
chmod +x bootstrap.sh
./bootstrap.sh
flutter run
```

The bootstrap script creates missing Flutter platform files, restores the PEMS source, enables local HTTP access for Android development, and runs `flutter pub get`.

## Run on an Android phone

1. Enable Developer Options and USB debugging on the Android phone.
2. Connect the phone by USB.
3. Confirm Flutter can see it:

```bash
flutter devices
```

4. Connect the phone to the ESP32 Wi-Fi network:

- SSID: `PEMS_DEMO`
- Password: `pems12345`

5. Run:

```bash
flutter run
```

6. In the app choose:

- Connection: `Local ESP32`
- Role: `Tenant` or `Landlord`

The ESP32 demo accepts any email/password through the current demo `/auth/login` route.

## Build a standalone APK

```bash
flutter build apk --release
```

The APK is normally created at:

`build/app/outputs/flutter-apk/app-release.apk`

For a production release, replace the broad cleartext HTTP development setting with a more restrictive Android network security configuration or HTTPS backend.

## Advanced firmware

The file:

`firmware/PEMS_Advanced_Firmware.ino`

is based on the working demo firmware and extends the status response with:

- `voltage`
- `current`
- `power`
- `energyKwh`
- `frequency`
- `powerFactor`
- `tamperActive`
- `sensorFault`
- `protectionState`

It keeps the verified ESP32/PZEM UART mapping:

- PZEM TX -> ESP32 GPIO16 (RX2)
- PZEM RX -> ESP32 GPIO17 (TX2)

The firmware only reports a voltage protection state. A production mains protection device should be implemented using appropriately rated certified hardware and supervised installation rather than relying only on software.

## Cloud mode

`lib/src/config/app_config.dart` contains:

```dart
static const cloudBaseUrl = 'https://api.example.com/api/v1';
```

Replace that URL when the real PEMS backend is available.

The intended production flow is:

Flutter app -> PEMS cloud backend -> payment provider/database/device messaging -> PEMS device

The ESP32 should not independently validate real financial payments in production.
