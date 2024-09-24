import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tccsmartcontrol/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tccsmartcontrol/graficoPage.dart';

class IrrigationApp extends StatefulWidget {
  const IrrigationApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _IrrigationAppState createState() => _IrrigationAppState();
}

class _IrrigationAppState extends State<IrrigationApp> {
  final String userEmail = "gregoryuri09@gmail.com";
  final String userPassword = "xsara01";
  late User? user;
  bool modoAutomatico = false;
  bool motorLigado = false;
  List<String> irrigacaoIds = [];
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Future<void> _updateDataFromFirebase() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // ignore: use_build_context_synchronously
    _databaseReference.child('comandos/atualiza').set(true);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initializeLocalNotificationsPlugin();
    _loginWithEmailPassword();

    _databaseReference.child('dadosArduino').onChildChanged.listen((event) {
      if (event.snapshot.key == 'mandaNotificacao') {
        final bool? mostraNotificacao = event.snapshot.value as bool?;
        if (mostraNotificacao != null && mostraNotificacao) {
          _showLocalNotification(
              'Irrigação finalizada', 'Venha conferir no app o que foi gasto');
        }
      }
    });
  }

  @pragma('vm:entry-point')
  Future<void> _initializeLocalNotificationsPlugin() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loginWithEmailPassword() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );
      user = userCredential.user;
      print('Usuário autenticado: ${user?.email}');
      _fetchFirestoreData();
    } catch (e) {
      print('Erro ao autenticar: $e');
    }
  }

  Future<void> _fetchFirestoreData() async {
    if (user != null) {
      try {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection('dadosIrrigacao').get();
        for (var doc in snapshot.docs) {
          print('ID: ${doc.id}');
          print('Dados: ${doc.data()}');
        }
      } catch (e) {
        print('Erro ao buscar dados: $e');
      }
    } else {
      print('Usuário não autenticado.');
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: 'item x');
  }

  // ignore: unused_element
  Future<Map<String, String>> _fetchData() async {
    final estadoMotorSnapshot =
        await _databaseReference.child('dadosArduino/estadoMotor').once();
    final temperaturaSnapshot =
        await _databaseReference.child('dadosArduino/temperatura').once();
    final umidadeSnapshot =
        await _databaseReference.child('dadosArduino/umidade').once();
    final umidadeSoloSnapshot =
        await _databaseReference.child('dadosArduino/umidadeSolo').once();
    final tempoLigadoSnapshot =
        await _databaseReference.child('dadosArduino/tempoLigado').once();
    final aguaGastaSnapshot =
        await _databaseReference.child('dadosArduino/aguaGasta').once();

    return {
      'estadoMotor': estadoMotorSnapshot.snapshot.value as String,
      'temperatura': temperaturaSnapshot.snapshot.value as String,
      'umidade': umidadeSnapshot.snapshot.value as String,
      'umidadeSolo': umidadeSoloSnapshot.snapshot.value as String,
      'tempoLigado': tempoLigadoSnapshot.snapshot.value as String,
      'aguaGasta': aguaGastaSnapshot.snapshot.value as String,
    };
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
          color: Colors.blue,
          backgroundColor: Colors.white,
          strokeWidth: 2.0,
          displacement: 40.0,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 1,
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
                          future:
                              Future.delayed(const Duration(milliseconds: 300))
                                  .then((value) {
                            return _databaseReference
                                .child('dadosArduino/estadoMotor')
                                .once();
                          }),
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Carregando...',
                                  style: TextStyle(fontSize: 20));
                            } else if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            } else {
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
                          future:
                              Future.delayed(const Duration(milliseconds: 350))
                                  .then((value) {
                            return _databaseReference
                                .child('dadosArduino/temperatura')
                                .once();
                          }),
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Carregando...',
                                  style: TextStyle(fontSize: 20));
                            } else if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            } else {
                              String temperatura =
                                  snapshot.data?.snapshot.value as String;
                              return Text(
                                'Temperatura: $temperatura °C',
                                style: const TextStyle(fontSize: 20),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future:
                              Future.delayed(const Duration(milliseconds: 400))
                                  .then((value) {
                            return _databaseReference
                                .child('dadosArduino/umidade')
                                .once();
                          }),
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Carregando...',
                                  style: TextStyle(fontSize: 20));
                            } else if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            } else {
                              String umidade =
                                  snapshot.data?.snapshot.value as String;
                              return Text(
                                'Umidade: $umidade %',
                                style: const TextStyle(fontSize: 20),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future:
                              Future.delayed(const Duration(milliseconds: 450))
                                  .then((value) {
                            return _databaseReference
                                .child('dadosArduino/umidadeSolo')
                                .once();
                          }),
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Carregando...',
                                  style: TextStyle(fontSize: 20));
                            } else if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            } else {
                              String umidadeSolo =
                                  snapshot.data?.snapshot.value as String;
                              return Text(
                                'Umidade do Solo: $umidadeSolo %',
                                style: const TextStyle(fontSize: 20),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dados da última irrigação',
                          style: TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future:
                              Future.delayed(const Duration(milliseconds: 500))
                                  .then((value) {
                            return _databaseReference
                                .child('dadosArduino/tempoLigado')
                                .once();
                          }),
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Carregando...',
                                  style: TextStyle(fontSize: 20));
                            } else if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            } else {
                              String tempoGasto =
                                  snapshot.data?.snapshot.value as String;
                              return Text(
                                'Tempo total de irrigação: $tempoGasto',
                                style: const TextStyle(fontSize: 20),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future:
                              Future.delayed(const Duration(milliseconds: 550))
                                  .then((value) {
                            return _databaseReference
                                .child('dadosArduino/aguaGasta')
                                .once();
                          }),
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Carregando...',
                                  style: TextStyle(fontSize: 20));
                            } else if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            } else {
                              String aguaGasta =
                                  snapshot.data?.snapshot.value as String;
                              return Text(
                                'Água utilizada: $aguaGasta litros',
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
                                  .set(false);
                              setState(() {
                                motorLigado = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Parada de Emergência'),
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
                        _databaseReference
                            .child('comandos/modoAutomatico')
                            .set(modoAutomatico);
                      });
                    },
                    child: Text(
                      modoAutomatico
                          ? 'Modo Automático: Ligado'
                          : 'Modo Automático: Desligado',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GraficoPage()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart, size: 40),
                          SizedBox(width: 10),
                          Text(
                            'Gráficos',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ignore: unused_local_variable
  const String vapidKey =
      "BNd0JzkSmt1D_vHBijj4GSNTSmAdTEbs4cTtX4Ycw0GxtuI-BxcKgH2fjYTwm63tqc7vnc9mLRWWQCKpFjEFXd8";

  runApp(MaterialApp(
    title: 'Irrigação Automática',
    theme: ThemeData(
      primaryColor: Colors.green,
    ),
    home: const IrrigationApp(),
  ));
}
