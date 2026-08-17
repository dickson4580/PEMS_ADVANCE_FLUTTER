/*
  PEMS Advanced Firmware
  Project: Prepaid Energy Management System - Advanced App Companion
  Course: Embedded Systems - UMaT

  Hardware layout:
  - ESP32 38-pin board
  - PZEM-004T energy meter module
  - 16x2 LCD with I2C backpack
  - 2-channel 5V relay module
  - 3 or 4 LEDs with one resistor per LED
  - Active buzzer
  - Rocker switch 1 for tamper/manual fault simulation
  - Rocker switch 2 or push button for top-up simulation

  Safety note:
  This sketch only controls the low-voltage ESP32 side. AC wiring for the
  PZEM, MCB, relay contacts and bulb must be handled separately and safely.
*/

#include <Arduino.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <PZEM004Tv30.h>
#include <Preferences.h>
#include <WiFi.h>
#include <WebServer.h>

// ========================= PIN LAYOUT =========================
// PZEM-004T TTL side
#define PZEM_RX_PIN 16        // ESP32 RX2. Connect to PZEM TX
#define PZEM_TX_PIN 17        // ESP32 TX2. Connect to PZEM RX

// LCD I2C
#define LCD_SDA_PIN 21
#define LCD_SCL_PIN 22
#define LCD_ADDRESS 0x27      // If LCD does not show text, try 0x3F

// Relay module
#define RELAY1_PIN 26         // Controls bulb/test load
#define RELAY2_PIN 27         // Spare channel

// IMPORTANT: Some relay modules are active LOW. If your relay behaves opposite,
// change these two lines to: RELAY_ON LOW and RELAY_OFF HIGH.
#define RELAY_ON HIGH
#define RELAY_OFF LOW

// LEDs
#define GREEN_LED_PIN 14      // Normal/system running
#define YELLOW_LED_PIN 12     // Low balance warning
#define RED_LED_PIN 13        // Disconnected/fault/tamper
#define BLUE_LED_PIN 25       // Alive/Wi-Fi future indicator

// Buzzer and switches
#define BUZZER_PIN 33
#define TAMPER_SWITCH_PIN 32  // Rocker switch: GPIO32 -> switch -> GND
#define TOPUP_SWITCH_PIN 23   // Rocker/button: GPIO23 -> switch -> GND

// ========================= MOBILE APP / WIFI API SETTINGS =========================
// Default mode: ESP32 creates its own Wi-Fi hotspot.
// Phone connects to this hotspot and the mobile app uses http://192.168.4.1/api/v1
const char* WIFI_AP_SSID = "PEMS_DEMO";
const char* WIFI_AP_PASSWORD = "pems12345";
const char* DEMO_METER_ID = "demo-meter-01";
const char* DEMO_TENANT_NAME = "PEMS Demo Tenant";
const char* DEMO_ROOM = "Room 1";

WebServer server(80);

// ========================= BILLING SETTINGS =========================
float walletBalance = 10.00;          // Starting balance for demo, in GHS
const float COST_PER_KWH = 1.50;      // Demo tariff in GHS per kWh
const float LOW_BALANCE_LIMIT = 5.00; // Warning threshold
const float TOPUP_AMOUNT = 5.00;      // Amount added when top-up switch is triggered

// With a small LED bulb, kWh rises slowly. This multiplier makes demo deduction visible.
// Use 1.0 when doing a more realistic test.
const float DEMO_DEDUCTION_MULTIPLIER = 50.0;

// ========================= OBJECTS =========================
LiquidCrystal_I2C lcd(LCD_ADDRESS, 16, 2);
PZEM004Tv30 pzem(Serial2, PZEM_RX_PIN, PZEM_TX_PIN);
Preferences prefs;

// ========================= STATE VARIABLES =========================
float lastPzemEnergyKwh = 0.0;
bool firstEnergyReading = true;
bool relayConnected = false;
bool tamperActive = false;
bool sensorFault = false;

float lastVoltage = 0.0;
float lastCurrent = 0.0;
float lastPower = 0.0;
float lastEnergy = 0.0;
float lastFrequency = 0.0;
float lastPowerFactor = 0.0;

unsigned long lastReadingTime = 0;
unsigned long lastLcdUpdate = 0;
unsigned long lastAliveBlink = 0;
bool blueLedState = false;
String lastTransactionReference = "demo-initial";
float lastTopupAmountGhs = 0.0;
unsigned long lastTopupMillis = 0;
float lastConsumptionCostGhs = 0.0;
float lastConsumptionKwh = 0.0;

// Top-up edge detection
bool lastTopupState = HIGH;
unsigned long lastTopupChange = 0;
const unsigned long TOPUP_DEBOUNCE_MS = 100;

// ========================= HELPER FUNCTIONS =========================
void saveBalance() {
  prefs.begin("pems", false);
  prefs.putFloat("balance", walletBalance);
  prefs.end();
}

void loadBalance() {
  prefs.begin("pems", false);
  walletBalance = prefs.getFloat("balance", walletBalance);
  prefs.end();
}

void beep(uint8_t times, uint16_t onMs = 120, uint16_t offMs = 100) {
  for (uint8_t i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(onMs);
    digitalWrite(BUZZER_PIN, LOW);
    if (i < times - 1) delay(offMs);
  }
}

void connectLoad() {
  digitalWrite(RELAY1_PIN, RELAY_ON);
  relayConnected = true;
}

void disconnectLoad() {
  digitalWrite(RELAY1_PIN, RELAY_OFF);
  relayConnected = false;
}

void updateLeds() {
  digitalWrite(GREEN_LED_PIN, HIGH);
  digitalWrite(YELLOW_LED_PIN, (walletBalance > 0 && walletBalance <= LOW_BALANCE_LIMIT) ? HIGH : LOW);
  digitalWrite(RED_LED_PIN, (!relayConnected || tamperActive || sensorFault) ? HIGH : LOW);

  // Blue LED blinks as a simple alive indicator in demo mode.
  if (millis() - lastAliveBlink >= 700) {
    lastAliveBlink = millis();
    blueLedState = !blueLedState;
    digitalWrite(BLUE_LED_PIN, blueLedState ? HIGH : LOW);
  }
}

void updateLcd() {
  if (millis() - lastLcdUpdate < 1000) return;
  lastLcdUpdate = millis();

  lcd.setCursor(0, 0);
  String line1 = "Bal:GHC " + String(walletBalance, 2);
  while (line1.length() < 16) line1 += " ";
  lcd.print(line1.substring(0, 16));

  lcd.setCursor(0, 1);
  String line2;
  if (tamperActive) {
    line2 = "TAMPER ALERT";
  } else if (sensorFault) {
    line2 = "PZEM NO READ";
  } else if (!relayConnected) {
    line2 = "Status: OFF";
  } else if (walletBalance <= LOW_BALANCE_LIMIT) {
    line2 = "LOW BAL " + String(lastPower, 0) + "W";
  } else {
    line2 = "P:" + String(lastPower, 0) + "W ON";
  }
  while (line2.length() < 16) line2 += " ";
  lcd.print(line2.substring(0, 16));
}

void handleTamperSwitch() {
  bool state = digitalRead(TAMPER_SWITCH_PIN); // INPUT_PULLUP: LOW means triggered
  tamperActive = (state == LOW);

  if (tamperActive) {
    // For demo, tamper does not permanently lock the system. It shows alert only.
    // To force disconnection on tamper, uncomment the next line:
    // disconnectLoad();
  }
}

void handleTopupSwitch() {
  bool currentState = digitalRead(TOPUP_SWITCH_PIN); // INPUT_PULLUP: LOW means switch/button active
  unsigned long now = millis();

  if (currentState != lastTopupState) {
    lastTopupChange = now;
  }

  // Add top-up once when switch/button moves from HIGH to LOW.
  if ((now - lastTopupChange) > TOPUP_DEBOUNCE_MS) {
    if (lastTopupState == HIGH && currentState == LOW) {
      walletBalance += TOPUP_AMOUNT;
      saveBalance();
      Serial.println("Top-up added: GHC " + String(TOPUP_AMOUNT, 2));
      beep(2, 80, 80);

      if (walletBalance > 0 && !tamperActive) {
        connectLoad();
      }
    }
  }

  lastTopupState = currentState;
}

void readEnergyAndBill() {
  if (millis() - lastReadingTime < 2000) return;
  lastReadingTime = millis();

  float voltage = pzem.voltage();
  float current = pzem.current();
  float power = pzem.power();
  float energy = pzem.energy();
  float frequency = pzem.frequency();
  float powerFactor = pzem.pf();

  if (isnan(voltage) || isnan(current) || isnan(power) || isnan(energy)) {
    sensorFault = true;
    Serial.println("PZEM read failed. Check VCC/GND/TX/RX and AC measurement side.");
    return;
  }

  sensorFault = false;
  lastVoltage = voltage;
  lastCurrent = current;
  lastPower = power;
  lastEnergy = energy;
  if (!isnan(frequency)) lastFrequency = frequency;
  if (!isnan(powerFactor)) lastPowerFactor = powerFactor;

  if (firstEnergyReading) {
    lastPzemEnergyKwh = energy;
    firstEnergyReading = false;
    Serial.println("Baseline kWh set: " + String(energy, 5));
    return;
  }

  float deltaKwh = energy - lastPzemEnergyKwh;
  if (deltaKwh < 0) deltaKwh = 0; // handles PZEM counter reset
  lastPzemEnergyKwh = energy;

  if (deltaKwh > 0 && walletBalance > 0 && relayConnected) {
    float cost = deltaKwh * COST_PER_KWH * DEMO_DEDUCTION_MULTIPLIER;
    lastConsumptionCostGhs = cost;
    lastConsumptionKwh = deltaKwh;
    walletBalance -= cost;
    if (walletBalance < 0) walletBalance = 0;
    saveBalance();

    Serial.print("Used: "); Serial.print(deltaKwh, 5);
    Serial.print(" kWh | Cost: GHC "); Serial.print(cost, 2);
    Serial.print(" | Balance: GHC "); Serial.println(walletBalance, 2);
  }

  if (walletBalance <= 0 && relayConnected) {
    disconnectLoad();
    beep(2, 250, 150);
    Serial.println("Balance finished. Load disconnected.");
  } else if (walletBalance > 0 && !relayConnected && !tamperActive) {
    connectLoad();
  }

  if (walletBalance > 0 && walletBalance <= LOW_BALANCE_LIMIT) {
    beep(1, 80, 0);
  }
}


// ========================= MOBILE APP API HELPERS =========================
void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type,Authorization");
}

void sendJson(int statusCode, const String& body) {
  sendCorsHeaders();
  server.send(statusCode, "application/json", body);
}

String isoTimeFromMillis() {
  // ESP32 demo has no real-time clock here. This timestamp is good enough for app display.
  unsigned long seconds = millis() / 1000;
  int minPart = (seconds / 60) % 60;
  int secPart = seconds % 60;
  char buffer[32];
  snprintf(buffer, sizeof(buffer), "2026-07-14T00:%02d:%02dZ", minPart, secPart);
  return String(buffer);
}

float extractJsonNumber(const String& json, const String& key, float fallbackValue) {
  int keyIndex = json.indexOf("\"" + key + "\"");
  if (keyIndex < 0) return fallbackValue;
  int colonIndex = json.indexOf(':', keyIndex);
  if (colonIndex < 0) return fallbackValue;
  int start = colonIndex + 1;
  while (start < json.length() && (json[start] == ' ' || json[start] == '\t' || json[start] == '"')) start++;
  int end = start;
  while (end < json.length() && (isDigit(json[end]) || json[end] == '.' || json[end] == '-')) end++;
  return json.substring(start, end).toFloat();
}

String meterStatusJson() {
  float balanceKwh = walletBalance / COST_PER_KWH;
  float lowKwh = LOW_BALANCE_LIMIT / COST_PER_KWH;
  String body = "{";
  body += "\"meterId\":\"" + String(DEMO_METER_ID) + "\",";
  body += "\"deviceOnline\":" + String(sensorFault ? "false" : "true") + ",";
  body += "\"balanceKwh\":" + String(balanceKwh, 3) + ",";
  body += "\"balanceGhs\":" + String(walletBalance, 2) + ",";
  body += "\"ratePerKwh\":" + String(COST_PER_KWH, 2) + ",";
  body += "\"isRelayOn\":" + String(relayConnected ? "true" : "false") + ",";
  body += "\"lastReadingAt\":\"" + isoTimeFromMillis() + "\",";
  body += "\"lowBalanceThresholdKwh\":" + String(lowKwh, 3) + ",";
  body += "\"voltage\":" + String(lastVoltage, 2) + ",";
  body += "\"current\":" + String(lastCurrent, 3) + ",";
  body += "\"power\":" + String(lastPower, 2) + ",";
  body += "\"energyKwh\":" + String(lastEnergy, 5) + ",";
  body += "\"frequency\":" + String(lastFrequency, 2) + ",";
  body += "\"powerFactor\":" + String(lastPowerFactor, 3) + ",";
  body += "\"tamperActive\":" + String(tamperActive ? "true" : "false") + ",";
  body += "\"sensorFault\":" + String(sensorFault ? "true" : "false") + ",";
  String protectionState = "normal";
  if (lastVoltage > 250.0) protectionState = "high_voltage";
  else if (lastVoltage > 0 && lastVoltage < 190.0) protectionState = "low_voltage";
  body += "\"protectionState\":\"" + protectionState + "\"";
  body += "}";
  return body;
}

void handleOptions() {
  sendCorsHeaders();
  server.send(204);
}

void handleLogin() {
  String body = "{";
  body += "\"accessToken\":\"pems-demo-token\",";
  body += "\"refreshToken\":\"pems-demo-refresh\",";
  body += "\"tenant\":{";
  body += "\"id\":\"tenant-demo-01\",";
  body += "\"fullName\":\"" + String(DEMO_TENANT_NAME) + "\",";
  body += "\"email\":\"demo@pems.local\",";
  body += "\"phone\":\"0240000000\",";
  body += "\"propertyName\":\"UMaT Embedded Systems Demo\",";
  body += "\"unitNumber\":\"" + String(DEMO_ROOM) + "\"";
  body += "}}";
  sendJson(200, body);
}

void handleRefresh() {
  sendJson(200, "{\"accessToken\":\"pems-demo-token\",\"refreshToken\":\"pems-demo-refresh\"}");
}

void handleProfile() {
  String body = "{";
  body += "\"id\":\"tenant-demo-01\",";
  body += "\"fullName\":\"" + String(DEMO_TENANT_NAME) + "\",";
  body += "\"email\":\"demo@pems.local\",";
  body += "\"phone\":\"0240000000\",";
  body += "\"propertyName\":\"UMaT Embedded Systems Demo\",";
  body += "\"unitNumber\":\"" + String(DEMO_ROOM) + "\"";
  body += "}";
  sendJson(200, body);
}

void handleStatus() {
  sendJson(200, meterStatusJson());
}

void handleUsage() {
  String body = "[";
  body += "{\"id\":\"usage-001\",\"meterId\":\"" + String(DEMO_METER_ID) + "\",\"kwhConsumed\":" + String(lastEnergy, 5) + ",\"recordedAt\":\"" + isoTimeFromMillis() + "\"}";
  body += "]";
  sendJson(200, body);
}

void handleTransactions() {
  String body = "[";
  if (lastTopupAmountGhs > 0) {
    body += "{\"id\":\"" + lastTransactionReference + "\",\"meterId\":\"" + String(DEMO_METER_ID) + "\",\"type\":\"topup\",\"amountGhs\":" + String(lastTopupAmountGhs, 2) + ",\"kwhCredited\":" + String(lastTopupAmountGhs / COST_PER_KWH, 3) + ",\"provider\":\"mtn\",\"reference\":\"" + lastTransactionReference + "\",\"status\":\"success\",\"createdAt\":\"" + isoTimeFromMillis() + "\"}";
  }
  if (lastConsumptionCostGhs > 0) {
    if (lastTopupAmountGhs > 0) body += ",";
    body += "{\"id\":\"consumption-last\",\"meterId\":\"" + String(DEMO_METER_ID) + "\",\"type\":\"consumption\",\"amountGhs\":" + String(lastConsumptionCostGhs, 2) + ",\"kwhCredited\":0,\"reference\":\"usage\",\"status\":\"success\",\"createdAt\":\"" + isoTimeFromMillis() + "\"}";
  }
  body += "]";
  sendJson(200, body);
}

void handleTopupApi() {
  String payload = server.arg("plain");
  float amount = extractJsonNumber(payload, "amountGhs", TOPUP_AMOUNT);
  if (amount <= 0) amount = TOPUP_AMOUNT;

  walletBalance += amount;
  saveBalance();
  lastTopupAmountGhs = amount;
  lastTopupMillis = millis();
  lastTransactionReference = "pems-demo-" + String(lastTopupMillis);

  if (walletBalance > 0 && !tamperActive) connectLoad();
  beep(2, 80, 80);

  String body = "{";
  body += "\"reference\":\"" + lastTransactionReference + "\",";
  body += "\"status\":\"success\"";
  body += "}";
  sendJson(200, body);
}

void handlePaymentStatus() {
  String body = "{\"reference\":\"" + lastTransactionReference + "\",\"status\":\"success\"}";
  sendJson(200, body);
}

void handleApiNotFound() {
  if (server.method() == HTTP_OPTIONS) {
    handleOptions();
    return;
  }
  String uri = server.uri();
  if (uri.startsWith("/api/v1/payments/") && uri.endsWith("/status")) {
    handlePaymentStatus();
    return;
  }
  sendJson(404, "{\"message\":\"PEMS ESP32 API route not found\"}");
}

void setupMobileAppApi() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(WIFI_AP_SSID, WIFI_AP_PASSWORD);
  IPAddress ip = WiFi.softAPIP();

  server.on("/api/v1/auth/login", HTTP_POST, handleLogin);
  server.on("/api/v1/auth/refresh", HTTP_POST, handleRefresh);
  server.on("/api/v1/tenants/me", HTTP_GET, handleProfile);
  server.on("/api/v1/meters/demo-meter-01/status", HTTP_GET, handleStatus);
  server.on("/api/v1/meters/demo-meter-01/usage", HTTP_GET, handleUsage);
  server.on("/api/v1/meters/demo-meter-01/transactions", HTTP_GET, handleTransactions);
  server.on("/api/v1/payments/topup", HTTP_POST, handleTopupApi);
  server.onNotFound(handleApiNotFound);
  server.begin();

  Serial.print("PEMS Wi-Fi AP started. SSID: "); Serial.println(WIFI_AP_SSID);
  Serial.print("Mobile app API: http://"); Serial.print(ip); Serial.println("/api/v1");
}

// ========================= SETUP =========================
void setup() {
  Serial.begin(115200);
  delay(300);

  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(GREEN_LED_PIN, OUTPUT);
  pinMode(YELLOW_LED_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BLUE_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(TAMPER_SWITCH_PIN, INPUT_PULLUP);
  pinMode(TOPUP_SWITCH_PIN, INPUT_PULLUP);

  digitalWrite(RELAY2_PIN, RELAY_OFF);
  digitalWrite(BUZZER_PIN, LOW);

  Wire.begin(LCD_SDA_PIN, LCD_SCL_PIN);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("PEMS Starting");
  lcd.setCursor(0, 1);
  lcd.print("UMaT Demo");

  loadBalance();

  if (walletBalance > 0) {
    connectLoad();
  } else {
    disconnectLoad();
  }

  beep(1, 100, 0);
  setupMobileAppApi();

  Serial.println("PEMS Advanced Firmware started.");
  Serial.println("Pin map: PZEM RX=16 TX=17, LCD SDA=21 SCL=22, Relay=26, Tamper=32, Topup=23");
}

// ========================= LOOP =========================
void loop() {
  server.handleClient();
  handleTamperSwitch();
  handleTopupSwitch();
  readEnergyAndBill();
  updateLeds();
  updateLcd();
}
