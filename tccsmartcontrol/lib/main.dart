import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

class IrrigationApp extends StatefulWidget {
  const IrrigationApp({Key? key}) : super(key: key);

  @override
  _IrrigationAppState createState() => _IrrigationAppState();
}

class _IrrigationAppState extends State<IrrigationApp> {
  bool modoAutomatico = false;
  bool motorLigado = false;

  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _updateDataFromFirebase() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const IrrigationApp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigação Automática'),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _updateDataFromFirebase,
        color: Colors.blue, // Cor do indicador
        backgroundColor: Colors.white, // Cor de fundo do indicador
        strokeWidth: 2.0, // Largura da linha do indicador
        displacement: 40.0, // Distância do indicador até o topo
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), // Adiciona esta linha
          itemCount: 1, // Defina o tamanho conforme necessário
          itemBuilder: (BuildContext context, int index) {
            return Column(
              children: <Widget>[
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FutureBuilder(
                        // Use o FutureBuilder para buscar e exibir dados do Firebase
                        future: _databaseReference
                            .child('dadosArduino/estadoMotor')
                            .once(),
                        builder:
                            (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                                'Carregando...'); // Exibir enquanto carrega
                          } else if (snapshot.hasError) {
                            return Text('Erro: ${snapshot.error}');
                          } else {
                            // Verificar se o valor é nulo antes de acessar 'value'
                            String estadoMotor =
                                snapshot.data?.snapshot.value as String;
                            return Text(
                              'Estado do Motor: $estadoMotor',
                              style: const TextStyle(fontSize: 20),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder(
                        // Use o FutureBuilder para buscar e exibir dados do Firebase
                        future: _databaseReference
                            .child('dadosArduino/temperatura')
                            .once(),
                        builder:
                            (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                                'Carregando...'); // Exibir enquanto carrega
                          } else if (snapshot.hasError) {
                            return Text('Erro: ${snapshot.error}');
                          } else {
                            // Verificar se o valor é nulo antes de acessar 'value'
                            String temperatura =
                                snapshot.data?.snapshot.value as String;
                            return Text(
                              'Temperatura: $temperatura' ' ºC',
                              style: const TextStyle(fontSize: 20),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder(
                        // Use o FutureBuilder para buscar e exibir dados do Firebase
                        future: _databaseReference
                            .child('dadosArduino/umidade')
                            .once(),
                        builder:
                            (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                                'Carregando...'); // Exibir enquanto carrega
                          } else if (snapshot.hasError) {
                            return Text('Erro: ${snapshot.error}');
                          } else {
                            // Verificar se o valor é nulo antes de acessar 'value'
                            String umidade =
                                snapshot.data?.snapshot.value as String;
                            return Text(
                              'Umidade: $umidade' ' %',
                              style: const TextStyle(fontSize: 20),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder(
                        // Use o FutureBuilder para buscar e exibir dados do Firebase
                        future: _databaseReference
                            .child('dadosArduino/umidadeSolo')
                            .once(),
                        builder:
                            (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                                'Carregando...'); // Exibir enquanto carrega
                          } else if (snapshot.hasError) {
                            return Text('Erro: ${snapshot.error}');
                          } else {
                            // Verificar se o valor é nulo antes de acessar 'value'
                            String umidadeSolo =
                                snapshot.data?.snapshot.value as String;
                            return Text(
                              'Umidade do Solo: $umidadeSolo' ' %',
                              style: const TextStyle(fontSize: 20),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Operação Manual'),
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            _databaseReference
                                .child('comandos/motorLigado')
                                .set(true);
                            setState(() {
                              motorLigado = true;
                            });
                          },
                          style:
                              ElevatedButton.styleFrom(primary: Colors.green),
                          child: const Text('Ligar Motor'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _databaseReference
                                .child('comandos/motorLigado')
                                .set(false);
                            setState(() {
                              motorLigado = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(primary: Colors.red),
                          child: const Text('Desligar Motor'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      modoAutomatico = !modoAutomatico;
                      if (modoAutomatico) {
                        _databaseReference
                            .child('comandos/modoAutomatico')
                            .set(true);
                      } else {
                        _databaseReference
                            .child('comandos/modoAutomatico')
                            .set(false);
                      }
                    });
                  },
                  child: Text(
                    modoAutomatico
                        ? 'Modo Automático: Ligado'
                        : 'Modo Automático: Desligado',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(
    title: 'Irrigação Automática',
    theme: ThemeData(
      primaryColor: Colors.green,
    ),
    home: const IrrigationApp(),
  ));
}
