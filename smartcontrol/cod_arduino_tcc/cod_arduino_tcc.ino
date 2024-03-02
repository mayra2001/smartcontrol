#include <DHT.h>

#define DHT_PIN 2 // Pino ao qual o sensor DHT está conectado
#define DHT_TYPE DHT11 // Tipo de sensor DHT (DHT11 ou DHT22)
DHT dht(DHT_PIN, DHT_TYPE);

const int pinoSensor = A0; // PINO UTILIZADO PELO SENSOR
int valorLido; // VARIÁVEL QUE ARMAZENA O PERCENTUAL DE UMIDADE DO SOLO

int analogSoloSeco = 400; // VALOR MEDIDO COM O SOLO SECO (VOCÊ PODE FAZER TESTES E AJUSTAR ESTE VALOR)
int analogSoloMolhado = 150; // VALOR MEDIDO COM O SOLO MOLHADO (VOCÊ PODE FAZER TESTES E AJUSTAR ESTE VALOR)
int percSoloSeco = 0; // MENOR PERCENTUAL DO SOLO SECO (0% - NÃO ALTERAR)
int percSoloMolhado = 100; // MAIOR PERCENTUAL DO SOLO MOLHADO (100% - NÃO ALTERAR)

bool modoAutomatico = false; // Estado do modo automático
bool motorAtivo = false; // Estado do motor de água

void setup() {
  Serial.begin(9600);
  dht.begin();
  Serial.println("Lendo a umidade do solo e a temperatura...");
  delay(2000);
}

void loop() {
  if (modoAutomatico) {
    if (verificarHorario()) {
      verificarUmidadeSolo();
    }
  }
  valorLido = constrain(analogRead(pinoSensor), analogSoloMolhado, analogSoloSeco);
  valorLido = map(valorLido, analogSoloMolhado, analogSoloSeco, percSoloMolhado, percSoloSeco);
  Serial.print("Umidade do solo: ");
  Serial.print(valorLido);
  Serial.println("%");

  float umidade = dht.readHumidity();
  float temperatura = dht.readTemperature();

    Serial.print("Umidade: ");
    Serial.print(umidade);
    Serial.println("%");
    Serial.print("Temperatura: ");
    Serial.print(temperatura);
    Serial.println("°C");
  
  // Código para ativar ou desativar o motor de água baseado nos botões do aplicativo
  // Adicione aqui a lógica para receber os comandos do aplicativo e atualizar o estado do motorAtivo

  delay(10000); // Verifica a cada 30 segundos
}

void verificarUmidadeSolo() {
  valorLido = constrain(analogRead(pinoSensor), analogSoloMolhado, analogSoloSeco);
  valorLido = map(valorLido, analogSoloMolhado, analogSoloSeco, percSoloMolhado, percSoloSeco);

  if (valorLido < 65 && !motorAtivo) {
    ativarMotorAgua();
  } else if (valorLido >= 95 && motorAtivo) {
    desativarMotorAgua();
  }
}

void ativarMotorAgua() {
  // Adicione aqui o código para acionar o motor de água
  motorAtivo = true;
  Serial.println("Motor de água ativado!");
}

void desativarMotorAgua() {
  // Adicione aqui o código para desligar o motor de água
  motorAtivo = false;
  Serial.println("Motor de água desativado!");
}

bool verificarHorario() {
  // Obtém a hora atual do sistema (considerando que você tenha um relógio RTC ou similar)
  int horaAtual = obterHoraAtual();

  // Verifica se está no horário permitido para a irrigação (7h-9h e 17h-20h)
  return (horaAtual >= 7 && horaAtual < 9) || (horaAtual >= 17 && horaAtual < 20);
}

int obterHoraAtual() {
  // Adicione aqui o código para obter a hora atual do sistema
  // Este código depende do hardware ou biblioteca que você está utilizando para obter a hora
  // Se estiver usando um RTC, por exemplo, seria algo como rtc.getHour()
  // Neste exemplo simples, usamos uma função fictícia que retorna a hora atual para demonstração
  return 8; // Retorna 8 como exemplo
}
