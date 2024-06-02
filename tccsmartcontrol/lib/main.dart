//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tccsmartcontrol/firebase_options.dart';

class IrrigationApp extends StatefulWidget {
  const IrrigationApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _IrrigationAppState createState() => _IrrigationAppState();
}

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();

//   print("Handling a background message: ${message.messageId}");
// }

class _IrrigationAppState extends State<IrrigationApp> {
  bool modoAutomatico = false;
  bool motorLigado = false;
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference();

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
                        'Dados da ultima irrigação',
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
                              'Agua utilizada: $aguaGasta litros',
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
  //final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  const String vapidKey =
      "BNd0JzkSmt1D_vHBijj4GSNTSmAdTEbs4cTtX4Ycw0GxtuI-BxcKgH2fjYTwm63tqc7vnc9mLRWWQCKpFjEFXd8";

  //String? fcmToken = await _firebaseMessaging.getToken(vapidKey: vapidKey);

  //print("Token FCM: $fcmToken");
  // _firebaseMessaging.onTokenRefresh.listen((String? newToken) {
  //print("Novo Token FCM: $newToken");
  //});
  //FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
  // TODO: If necessary send token to application server.
  //}).onError((err) {
  // Error getting token.
  // });
  // bool isAutoInitEnabled = FirebaseMessaging.instance.isAutoInitEnabled;
  // print("Auto Init Enabled: $isAutoInitEnabled");
  //await FirebaseMessaging.instance.setAutoInitEnabled(true);
//
  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MaterialApp(
    title: 'Irrigação Automática',
    theme: ThemeData(
      primaryColor: Colors.green,
    ),
    home: const IrrigationApp(),
  ));
}
