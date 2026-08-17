# PEMS Advanced API Contract

## Meter status

`GET /api/v1/meters/demo-meter-01/status`

Minimum fields supported by the original demo firmware:

```json
{
  "meterId": "demo-meter-01",
  "deviceOnline": true,
  "balanceKwh": 6.667,
  "balanceGhs": 10.00,
  "ratePerKwh": 1.50,
  "isRelayOn": true,
  "lastReadingAt": "2026-07-14T00:10:20Z",
  "lowBalanceThresholdKwh": 3.333
}
```

Advanced optional fields:

```json
{
  "voltage": 231.4,
  "current": 0.83,
  "power": 189.6,
  "energyKwh": 4.31245,
  "frequency": 50.0,
  "powerFactor": 0.96,
  "tamperActive": false,
  "sensorFault": false,
  "protectionState": "normal"
}
```

The Flutter parser treats these advanced fields as optional so the application can still run against the original firmware.
