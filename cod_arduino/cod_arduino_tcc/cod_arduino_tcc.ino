#include <Arduino.h>
#if defined(ESP32) || defined(ARDUINO_RASPBERRY_PI_PICO_W)
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#elif __has_include(<WiFiNINA.h>)
#include <WiFiNINA.h>
#elif __has_include(<WiFi101.h>)
#include <WiFi101.h>
#elif __has_include(<WiFiS3.h>)
#include <WiFiS3.h>
#endif
#include <Firebase_ESP_Client.h>

#include <addons/TokenHelper.h>

#include <addons/RTDBHelper.h>
#include <DHT.h>
#define DHT_PIN 4 // pino D4
#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);

const int pinoSensor = A0; // PINO UTILIZADO PELO SENSOR DE UMIDADE DO SOLO (POLO "vp" NO ESP32)

#define WIFI_SSID "LIKE-SALA"
#define WIFI_PASSWORD "992714904"
#define API_KEY "AIzaSyD2IheRLezcWjNxckC1I1X_PWzySil-v6M"
#define DATABASE_URL "https://tccsmartcontrol-default-rtdb.firebaseio.com/"
#define USER_EMAIL "gregoryuri09@gmail.com"
#define USER_PASSWORD "xsara01"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
unsigned long count = 0;
int LED_BUILTIN = 2;
int valorLido;

int analogSoloSeco = 4095;    // VALOR MEDIDO COM O SOLO SECO
int analogSoloMolhado = 1500; // VALOR MEDIDO COM O SOLO MOLHADO
int percSoloSeco = 0;
int percSoloMolhado = 100;

bool modoAutomatico = false;
bool motorLigado = false;

unsigned long tempoInicial = 0;
unsigned long tempoFinal = 0;
unsigned long tempoTotal = 0;
String estadoMotor;

void setup()
{
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.println("ESP-32: Inicializado");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("ESP-32: Conectando ao Wi-Fi");

  unsigned long ms = millis();
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(300);
    if (millis() - ms > 10000)
      break;
  }
  Serial.println();
  Serial.print("ESP-32: Conectado com IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  Serial.printf("ESP-32: Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  Firebase.reconnectNetwork(true);

  fbdo.setBSSLBufferSize(4096, 1024);
  fbdo.setResponseSize(2048);

  Firebase.begin(&config, &auth);

  Firebase.setDoubleDigits(5);

  config.timeout.serverResponse = 10 * 1000;

  dht.begin();
}

void loop()
{

  lerSensores();
  if (Firebase.RTDB.getBool(&fbdo, F("/comandos/modoAutomatico")))
  {
    modoAutomatico = fbdo.boolData();
    if (modoAutomatico)
    {
      Serial.println("modoAutomatico é verdadeiro");
      digitalWrite(LED_BUILTIN, HIGH);
      modoautomatico();
    }
    else
    {
      Serial.println("modoAutomatico é falso");
      digitalWrite(LED_BUILTIN, LOW);
    }
    Serial.println("Valor de modoAutomatico obtido com sucesso do Firebase");
  }
  else
  {
    Serial.print("Erro ao obter o valor de modoAutomatico: ");
    Serial.println(fbdo.errorReason());
  }

  if (Firebase.RTDB.getBool(&fbdo, F("/comandos/motorLigado")))
  {
    bool ligarmotor = fbdo.boolData();
    if (ligarmotor)
    {
      estadoMotor = "Ligado";
      Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
      Serial.println("motor ligado modo manual");
      motorLigado = true;
      delay(1000);
      Firebase.RTDB.setBool(&fbdo, F("/comandos/atualiza"), true);
      Firebase.RTDB.setBool(&fbdo, F("/comandos/atualiza"), false);
    }
    else
    {
      estadoMotor = "Desligado";
      Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
      Serial.println("motor desligado modo manual");
      motorLigado = false;
      delay(1000);
      Firebase.RTDB.setBool(&fbdo, F("/comandos/atualiza"), true);
      Firebase.RTDB.setBool(&fbdo, F("/comandos/atualiza"), false);
    }
    Serial.println("Valor de ligar motor modo manual obtido com sucesso do Firebase");
  }
  else
  {
    Serial.print("Erro ao obter o valor de ligar motor modo manual: ");
    Serial.println(fbdo.errorReason());
  }
  delay(2000);
}
void lerSensores()
{
  String umidadeSolo = lerUmidadeSolo();
  String temperatura = lerTemperatura();
  String umidade = lerUmidade();
  Serial.print("Umidade: ");
  Serial.print(umidade);
  Serial.println("%");
  Serial.print("Temperatura: ");
  Serial.print(temperatura);
  Serial.println("°C");
  Serial.print("Umidade do solo: ");
  Serial.print(umidadeSolo);
  Serial.println("%");

  // Envia os dados para o Firebase
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/umidadeSolo"), umidadeSolo.c_str());
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/temperatura"), temperatura.c_str());
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/umidade"), umidade.c_str());
  // Firebase.RTDB.setString(&fbdo, F("/dadosArduino/aguaGasta"), agua.c_str());
}

String lerUmidadeSolo()
{
  valorLido = analogRead(pinoSensor);
  valorLido = constrain(valorLido, analogSoloMolhado, analogSoloSeco);
  valorLido = map(valorLido, analogSoloMolhado, analogSoloSeco, percSoloMolhado, percSoloSeco);
  return String(valorLido);
}

String lerTemperatura()
{
  float temperatura = dht.readTemperature();
  return String(temperatura, 1); // 1 decimal de precisão
}

String lerUmidade()
{
  float umidade = dht.readHumidity();
  return String(umidade, 0); // sem casas decimais
}

void modoautomatico()
{
  String estadoMotor;
  estadoMotor = Firebase.RTDB.getString(&fbdo, F("/dadosArduino/estadoMotor"));
  bool irrigando;
  if (estadoMotor == "Ligado")
  {
    irrigando = true;
  }
  else if (estadoMotor == "Desligado")
  {
    irrigando = false;
  }
  // String umidadesolo = lerUmidadeSolo();
  int umidadesolo = lerUmidadeSolo().toInt();
  if (umidadesolo < 45 && !irrigando)
  {
    motorLigado = true;
    tempoInicial = millis();
    estadoMotor = "Ligado";
    Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
    Firebase.RTDB.setBool(&fbdo, F("/dadosArduino/mandaNotificacao"), false);
  }
  else if (umidadesolo > 95 && irrigando)
  {
    motorLigado = false;
    estadoMotor = "Desligado";
    Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
    tempoFinal = millis();
    tempoTotal = (tempoFinal - tempoInicial) / 1000; // Tempo total em segundos
    enviarTempoParaFirebase();
  }
}

void enviarTempoParaFirebase()
{
  unsigned long minutos = tempoTotal / 60;
  unsigned long segundos = tempoTotal % 60;
  String tempoLigado = String(minutos) + " min " + String(segundos) + " seg";
  Serial.println("TempoLigado");
  Serial.println(tempoLigado);
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/tempoLigado"), tempoLigado.c_str());
  Firebase.RTDB.setBool(&fbdo, F("/dadosArduino/mandaNotificacao"), true);
}
