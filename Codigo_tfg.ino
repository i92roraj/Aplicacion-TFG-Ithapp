// ===== MKR WAN 1310 + DHT11 + Ventilador =====
// Modo MANUAL/AUTO con downlink ASCII y payload T/H/ITH (x100)

#include <MKRWAN.h>
#include "DHT.h"

// ---------- Pines y sensor ----------
#define DHTPIN   7
#define DHTTYPE  DHT11
DHT dht(DHTPIN, DHTTYPE);

const int PIN_FAN = 6;   // NPN low-side: HIGH = ON, LOW = OFF

// ---------- LoRaWAN (EU868) ----------
LoRaModem modem;
// Rellena con tus valores reales:
String appEui = "12345678901234AA";                 // JoinEUI / AppEUI
String appKey = "AAD4D0C2BE8FB85193A5203E35C10709"; // AppKey (32 hex)
const uint8_t UPLINK_FPORT = 1;

// ---------- Configuración de control ----------
const bool   DEFAULT_AUTO_MODE = false;   // Arranca en MANUAL
bool         autoMode = DEFAULT_AUTO_MODE;

float ithOn  = 75.0;   // Umbral ENCENDER (AUTO)
float ithOff = 73.0;   // Umbral APAGAR (AUTO) -> histéresis
bool  fanOn  = false;  // Estado actual del ventilador

// Intervalo de envío (ajusta para duty-cycle de tu red)
const unsigned long SEND_EVERY_MS = 30000UL;
unsigned long lastSend = 0;

// ---------- Utilidades ----------
void setFan(bool on) {
  fanOn = on;
  digitalWrite(PIN_FAN, on ? HIGH : LOW);
  if (Serial) Serial.println(on ? "Ventilador: ON" : "Ventilador: OFF");
}

float computeITH(float tC, float rh) {
  // Fórmula tradicional usada en tu memoria
  return (1.8 * tC + 32) - (0.55 - 0.55 * rh / 100.0) * (1.8 * tC - 26);
}

// Empaqueta con 2 decimales (x100) en 2 bytes: entero y centésimas [0..99]
void toBytes100(float v, byte outAB[2]) {
  if (v < 0) v = 0;
  if (v > 255.99) v = 255.99;
  int ent = (int)v;
  int cent = (int)round((v - ent) * 100.0);
  if (cent == 100) { ent += 1; cent = 0; }
  outAB[0] = (byte)ent;
  outAB[1] = (byte)cent;
}

String readDownlink(uint16_t windowMs = 6000) {
  String cmd = "";
  unsigned long t0 = millis();
  while (millis() - t0 < windowMs) {
    if (modem.available() > 0) {
      while (modem.available() > 0) {
        cmd += (char)modem.read();
      }
      break;
    }
    delay(40);
  }
  cmd.trim();
  return cmd;
}

String sanitize(String s) {
  s.trim();
  // Elimina espacios y \r\n y pasa a MAYÚSCULAS
  String r = "";
  for (size_t i = 0; i < s.length(); ++i) {
    char c = s.charAt(i);
    if (c == ' ' || c == '\r' || c == '\n' || c == '\t') continue;
    r += (char)toupper(c);
  }
  return r;
}

void handleCommand(String raw) {
  if (raw.length() == 0) return;

  String s = sanitize(raw);
  if (Serial) { Serial.print("Downlink recibido: "); Serial.println(s); }

  // Atajos ON/OFF (fuerzan MANUAL)
  if (s == "ON" || s == "ACTIVATE" || s == "1") {
    autoMode = false;
    setFan(true);
    return;
  }
  if (s == "OFF" || s == "DEACTIVATE" || s == "0") {
    autoMode = false;
    setFan(false);
    return;
  }

  // Soporta "MODE=AUTO;TH=75" y variantes separadas por ';'
  int start = 0;
  while (start < (int)s.length()) {
    int sep = s.indexOf(';', start);
    String tok = (sep == -1) ? s.substring(start) : s.substring(start, sep);
    start = (sep == -1) ? s.length() : sep + 1;

    if (tok.startsWith("MODE=")) {
      if (tok.endsWith("AUTO")) {
        autoMode = true;
        if (Serial) Serial.println("Modo: AUTO");
      } else if (tok.endsWith("MANUAL")) {
        autoMode = false;
        if (Serial) Serial.println("Modo: MANUAL");
      }
    } else if (tok.startsWith("TH=") || tok.startsWith("UMBRAL=")) {
      // Umbral para AUTO (enciende en ithOn y apaga en ithOff = ithOn-2)
      float th = tok.substring(tok.indexOf('=') + 1).toFloat();
      if (th > 0.0) {
        ithOn = th;
        ithOff = th - 2.0; // histéresis simple
        if (Serial) {
          Serial.print("Umbral AUTO actualizado: ON=");
          Serial.print(ithOn, 1);
          Serial.print("  OFF=");
          Serial.println(ithOff, 1);
        }
      }
    }
  }
}

void applyAutoControl(float ith) {
  if (!autoMode) return;
  if (!fanOn && ith >= ithOn) {
    setFan(true);
    if (Serial) Serial.println("[AUTO] ITH >= ON → Ventilador ON");
  } else if (fanOn && ith <= ithOff) {
    setFan(false);
    if (Serial) Serial.println("[AUTO] ITH <= OFF → Ventilador OFF");
  }
}

// ---------- Setup / Loop ----------
void setup() {
  Serial.begin(115200);
  unsigned long t0 = millis();
  while (!Serial && (millis() - t0) < 2000) { /* espera máx 2s */ }

  pinMode(PIN_FAN, OUTPUT);
  setFan(false);

  dht.begin();

  if (!modem.begin(EU868)) {
    if (Serial) Serial.println("ERROR: modem.begin(EU868)");
    delay(2000);
  }
  modem.setADR(true);
  modem.setPort(UPLINK_FPORT);

  if (Serial) Serial.println("Uniendo a TTN (OTAA)...");
  bool joined = false;
  for (int i = 0; i < 5 && !joined; i++) {
    if (modem.joinOTAA(appEui, appKey)) {
      joined = true;
    } else {
      if (Serial) Serial.println("Join fallido. Reintento en 10 s...");
      delay(10000);
    }
  }
  if (Serial) Serial.println(joined ? "Conectado a TTN" : "No se pudo unir (continuará intentando enviar)");
}

void loop() {
  // Ritmo de envío
  if (millis() - lastSend < SEND_EVERY_MS) {
    delay(50);
    return;
  }
  lastSend = millis();

  // Lectura sensor
  float t = dht.readTemperature();  // °C
  float h = dht.readHumidity();     // %
  if (isnan(t) || isnan(h)) {
    if (Serial) Serial.println("Lectura DHT11 inválida. Mantengo estado del ventilador.");
    // No cambiamos ventilador; reintento en siguiente ciclo
    return;
  }

  float ith = computeITH(t, h);

  // Control automático (si procede)
  applyAutoControl(ith);

  // Payload T/H/ITH (x100) -> 6 bytes
  byte payload[6];
  toBytes100(t,   &payload[0]);
  toBytes100(h,   &payload[2]);
  toBytes100(ith, &payload[4]);

  modem.beginPacket();
  modem.write(payload, sizeof(payload));
  int sent = modem.endPacket(false); // unconfirmed
  if (Serial) {
    Serial.print("Uplink ");
    Serial.println(sent > 0 ? "OK" : "FALLO");
    Serial.print("T=");   Serial.print(t, 1);
    Serial.print("  H="); Serial.print(h, 0); Serial.print("%");
    Serial.print("  ITH="); Serial.print(ith, 1);
    Serial.print("  MODO="); Serial.print(autoMode ? "AUTO" : "MANUAL");
    Serial.print("  FAN=");  Serial.println(fanOn ? "ON" : "OFF");
  }

  // Lee posible downlink durante RX1/RX2
  String cmd = readDownlink(6000);
  if (cmd.length() > 0) handleCommand(cmd);
}
