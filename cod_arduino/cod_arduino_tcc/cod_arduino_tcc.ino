#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
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
#define DHT_PIN 4      // Pino ao qual o sensor DHT está conectado
#define DHT_TYPE DHT11 // Tipo de sensor DHT (DHT11 ou DHT22)
DHT dht(DHT_PIN, DHT_TYPE);

const int pinoSensor = A0; // PINO UTILIZADO PELO SENSOR DE UMIDADE DO SOLO    vp
const int pinoMotor = 23;
const int pinoNivel = 2;

#define WIFI_SSID "LIKE-SALA"
#define WIFI_PASSWORD "992714904"
#define API_KEY "AIzaSyD2IheRLezcWjNxckC1I1X_PWzySil-v6M"
#define DATABASE_URL "https://tccsmartcontrol-default-rtdb.firebaseio.com/"
#define USER_EMAIL "gregoryuri09@gmail.com"
#define USER_PASSWORD "xsara01"
#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels
#define OLED_RESET -1    // Reset pin # (or -1 if sharing Arduino reset pin)
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
unsigned long count = 0;
int LED_BUILTIN = 2;
int valorLido; // VARIÁVEL QUE ARMAZENA O PERCENTUAL DE UMIDADE DO SOLO

int analogSoloSeco = 4095;    // VALOR MEDIDO COM O SOLO SECO (VOCÊ PODE FAZER TESTES E AJUSTAR ESTE VALOR)
int analogSoloMolhado = 1500; // VALOR MEDIDO COM O SOLO MOLHADO (VOCÊ PODE FAZER TESTES E AJUSTAR ESTE VALOR)
int percSoloSeco = 0;         // MENOR PERCENTUAL DO SOLO SECO (0% - NÃO ALTERAR)
int percSoloMolhado = 100;    // MAIOR PERCENTUAL DO SOLO MOLHADO (100% - NÃO ALTERAR)

bool modoAutomatico = false; // Estado do modo automático
bool motorLigado = false;    // Estado do motor de água

unsigned long tempoInicial = 0;
unsigned long tempoFinal = 0;
unsigned long tempoTotal = 0;
String estadoMotor;

// Variáveis e constantes para o sensor de fluxo
const int INTERRUPCAO_SENSOR = 0;
const int pinoFluxo = 13;
unsigned long contador = 0;
const float FATOR_CALIBRACAO = 4.5;
float fluxo = 0;
float volume = 0;
float volume_total = 0;
unsigned long tempo_antes = 0;

void contador_pulso()
{
  contador++;
}

void setup()
{
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.println("ESP-32: Inicializado");
  // Inicializa o display OLED
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C))
  { // Endereço I2C padrão 0x3C
    Serial.println(F("SSD1306 allocation failed"));
    for (;;)
      ;
  }
  display.display();
  delay(1000); // Espera para que o display seja inicializado
  display.clearDisplay();

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
  // Configura o pino do sensor de fluxo como entrada
  pinMode(pinoFluxo, INPUT_PULLUP);

  pinMode(pinoMotor, OUTPUT);

  pinMode(pinoNivel, INPUT);

  // Configura a interrupção para o sensor de fluxo
  attachInterrupt(digitalPinToInterrupt(pinoFluxo), contador_pulso, FALLING);
}

void loop()
{
  lerSensores();
  if (Firebase.RTDB.getBool(&fbdo, F("/comandos/modoAutomatico")))
  {
    modoAutomatico = fbdo.boolData();
    if (modoAutomatico)
    {
      Serial.println("modoAutomatico acionado");
      modoautomatico();
    }
    else
    {
      digitalWrite(pinoMotor, LOW);
    }
  }
  // modo manual parada motor
  if (Firebase.RTDB.getBool(&fbdo, F("/comandos/motorLigado")))
  {
    bool ligarmotor = fbdo.boolData();
    if (!ligarmotor)
    {                               // parada de emergencia
      digitalWrite(pinoMotor, LOW); // 13  DESLIGAMOTOR
      estadoMotor = "Desligado";
      Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
      Serial.println("motor desligado para emergencia");
      motorLigado = false;
      Firebase.RTDB.setBool(&fbdo, F("/comandos/atualiza"), true);
      Firebase.RTDB.setBool(&fbdo, F("/comandos/atualiza"), false);
    }
    atualizarDisplay();
  }
}
void lerSensores()
{
  String nivel = lerNivel(); // por no app tambem
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
  Serial.print("Nivel do reservatorio: ");
  Serial.println(nivel);

  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/umidadeSolo"), umidadeSolo.c_str());
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/temperatura"), temperatura.c_str());
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/umidade"), umidade.c_str());
  Firebase.RTDB.setString(&fbdo, F("/dadosArduino/nivel"), nivel.c_str());
}

String lerUmidadeSolo()
{
  valorLido = analogRead(pinoSensor);
  valorLido = constrain(valorLido, analogSoloMolhado, analogSoloSeco);
  valorLido = map(valorLido, analogSoloMolhado, analogSoloSeco, percSoloMolhado, percSoloSeco);
  return String(valorLido);
}

String lerNivel()
{
  int leitura = digitalRead(pinoNivel);
  String nivelBaixo = "Baixo";
  String nivelNormal = "Normal";
  if (leitura == LOW)
  {
    return (nivelBaixo);
  }
  else
  {
    return (nivelNormal);
  }
}

String lerTemperatura()
{
  float temperatura = dht.readTemperature();
  return String(temperatura, 1);
}

String lerUmidade()
{
  float umidade = dht.readHumidity();
  return String(umidade, 0);
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
  // Verificar o nível do reservatório
  String nivel = lerNivel();
  if (nivel == "Baixo")
  {
    if (motorLigado)
    {
      // Se a bomba estiver ligada, desligue-a imediatamente
      digitalWrite(pinoMotor, LOW);
      Serial.println("Desligando bomba - nível do reservatório baixo");
      motorLigado = false;
      estadoMotor = "Desligado";
      Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
      Firebase.RTDB.setBool(&fbdo, F("/dadosArduino/mandaNotificacao"), true);
      tempoFinal = millis();
      tempoTotal = (tempoFinal - tempoInicial) / 1000; // Tempo total em segundos
      enviarTempoParaFirebase();
    }
    return; // Sai da função, não faz mais nada se o nível estiver baixo
  }

  // Verifica a umidade do solo e controla o motor
  int umidadesolo = lerUmidadeSolo().toInt();
  if (umidadesolo < 45 && !irrigando)
  {
    motorLigado = true;
    Serial.println("Ligando bomba...");
    digitalWrite(pinoMotor, HIGH); // Ativa a bomba
    volume_total = 0;              // Zera a contagem do volume total
    tempo_antes = millis();        // Reinicia o tempo
    tempoInicial = millis();
    estadoMotor = "Ligado";
    Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
    Firebase.RTDB.setBool(&fbdo, F("/dadosArduino/mandaNotificacao"), false);
  }

  // Verifica continuamente a umidade do solo e o nível do reservatório
  if (motorLigado)
  {
    while (motorLigado)
    {
      umidadesolo = lerUmidadeSolo().toInt(); // Atualize o valor da umidade do solo
      nivel = lerNivel();                     // Atualiza o valor do nível do reservatório

      if (umidadesolo > 65 || nivel == "Baixo")
      {
        Serial.println("Desligando bomba...");
        digitalWrite(pinoMotor, LOW); // Desativa a bomba
        motorLigado = false;
        estadoMotor = "Desligado";
        Firebase.RTDB.setString(&fbdo, F("/dadosArduino/estadoMotor"), estadoMotor);
        tempoFinal = millis();
        tempoTotal = (tempoFinal - tempoInicial) / 1000; // Tempo total em segundos
        enviarTempoParaFirebase();
      }

      // Ler o fluxo de água enquanto a bomba estiver ligada
      if (motorLigado)
      {
        lerFluxo();
      }

      // Delay curto para evitar sobrecarga de leitura contínua
      delay(500); // Ajuste o tempo conforme necessário
    }
  }
}

void lerFluxo()
{
  if ((millis() - tempo_antes) > 1000)
  {
    detachInterrupt(digitalPinToInterrupt(pinoFluxo));
    fluxo = ((1000.0 / (millis() - tempo_antes)) * contador) / FATOR_CALIBRACAO;
    volume = fluxo / 60;
    volume_total += volume;
    Serial.print("Volume: ");
    Serial.print(volume_total);
    Serial.println(" L");
    Serial.println();
    contador = 0;
    tempo_antes = millis();
    attachInterrupt(digitalPinToInterrupt(pinoFluxo), contador_pulso, FALLING);
  }
}

void atualizarDisplay()
{
  display.clearDisplay();

  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Irrigacao");

  // Estado do motor
  display.print("Bomba: ");
  display.println(estadoMotor);

  // Temperatura
  String temperatura = lerTemperatura();
  display.print("Temp: ");
  display.print(temperatura);
  display.println(" C");

  // Umidade do ar
  String umidade = lerUmidade();
  display.print("Umid. Ar: ");
  display.print(umidade);
  display.println(" %");

  // Umidade do solo
  String umidadeSolo = lerUmidadeSolo();
  display.print("Umid. Solo: ");
  display.print(umidadeSolo);
  display.println(" %");

  String nivel = lerNivel();
  display.print("Reservatorio: ");
  display.println(nivel);

  display.println("Ultima irrigacao");
  display.print("Agua gasta: ");
  display.print(volume_total);
  display.println(" L");

  display.display();
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
