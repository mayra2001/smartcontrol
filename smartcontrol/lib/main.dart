import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class IrrigationApp extends StatefulWidget {
  @override
  _IrrigationAppState createState() => _IrrigationAppState();
}

class _IrrigationAppState extends State<IrrigationApp> {
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    // Conectar ao servidor do Arduino
    socket = IO.io('http://endereco_do_seu_arduino:porta');
    socket.connect();

    // Ouvir mensagens do servidor
    socket.on('message', (data) {
      print('Mensagem recebida: $data');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Irrigação Automática'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Enviar mensagem para ligar o motor
                socket.emit('ligar_motor', 'ligar');
              },
              child: Text('Ligar Motor'),
            ),
            ElevatedButton(
              onPressed: () {
                // Enviar mensagem para desligar o motor
                socket.emit('desligar_motor', 'desligar');
              },
              child: Text('Desligar Motor'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Irrigação Automática',
    home: IrrigationApp(),
  ));
}
