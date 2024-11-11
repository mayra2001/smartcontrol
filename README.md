SmartControl - Sistema de Irrigação Automático

📜 Descrição do Projeto
O SmartControl é um aplicativo de controle de irrigação autônomo desenvolvido para monitorar e gerenciar o sistema de irrigação em plantações ou jardins. O projeto utiliza um microcontrolador (ESP32) e sensores de umidade e temperatura do solo, comunicando-se com um aplicativo mobile em Flutter. Através de uma interface intuitiva, o usuário consegue monitorar os dados em tempo real e receber notificações automáticas sobre o estado de irrigação.

📱 Funcionalidades
Monitoramento em Tempo Real: Veja a umidade e temperatura do solo diretamente no aplicativo.
Notificações Automáticas: Receba alertas sobre o estado do sistema, incluindo quando a irrigação está ativada ou desativada.
Histórico de Dados: Acesse dados históricos de irrigação e ambiente para otimizar o gerenciamento do sistema.
Controle Manual e Automático: Ative e desative o sistema de irrigação manualmente ou deixe que o sistema ative automaticamente com base nos dados do sensor.
Calculadora de Produtividade e Ganhos: Função para calcular produtividade e ganhos com base no uso do equipamento.
🛠️ Tecnologias Utilizadas
Flutter: Para o desenvolvimento da interface mobile.
Arduino e ESP32: Microcontrolador utilizado para conectar sensores e gerenciar a comunicação com o aplicativo.
Firebase: Base de dados em tempo real para armazenar e sincronizar os dados.
Dart: Linguagem de programação para o desenvolvimento do aplicativo.
🚀 Como Instalar e Executar
Clone este repositório:

git clone https://github.com/gregor-21/smartcontrol.git
Acesse a pasta do projeto:
cd smartcontrol
Instale as dependências:

flutter pub get
Conecte um dispositivo físico ou emulador e execute o aplicativo:

flutter run
Nota: Certifique-se de que o ESP32 esteja configurado corretamente com o código de monitoramento e que os dados estejam sendo enviados para o Firebase.

⚙️ Configuração do Microcontrolador
O microcontrolador ESP32 precisa ser configurado para coletar dados de umidade e temperatura do solo usando os sensores conectados. Ele deve enviar os dados para o Firebase para que o aplicativo possa acessar e exibir essas informações.
