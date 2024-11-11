import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'global_state.dart';

class GraficoPage extends StatefulWidget {
  const GraficoPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GraficoPageState createState() => _GraficoPageState();
}

class _GraficoPageState extends State<GraficoPage> {
  List<double> litrosGastos = [];
  List<double> tempoIrrigacao = [];
  List<double> umidadeAr = [];
  List<double> temperatura = [];
  List<double> umidadeSolo = [];
  List<double> litrosGastosPorMes = List.filled(12, 0);
  int mesSelecionado = DateTime.now().month;
  final incluirEsgoto = GlobalState.incluirEsgoto;
  double valorGasto = 0.0;
  double litrosTotaisMes = 0.0;
  int _chartKey = 0;
  String tempoTotalIrrigacao = "0 min 0 seg";
  bool showLitros = true;
  bool showUmidadeAr = true;
  bool showTemperatura = true;
  bool showUmidadeSolo = true;

  @override
  void initState() {
    super.initState();
    _carregarDados(mesSelecionado);
    _calcularValorGasto(mesSelecionado);
    _carregarDadosAno();
  }

  Future<void> _carregarDados(int mes) async {
    List<double> litrosPorDia = List.filled(31, 0);
    List<double> tempoPorDia = List.filled(31, 0);
    List<List<double>> umidadePorDia = List.generate(31, (_) => []);
    List<List<double>> temperaturaPorDia = List.generate(31, (_) => []);
    List<List<double>> umidadeSoloAtualizada = List.generate(31, (_) => []);

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('dadosIrrigacao').get();

    for (var doc in snapshot.docs) {
      DateTime dataIrrigacao = DateTime.parse(doc.id);

      if (dataIrrigacao.month == mes) {
        int dia = dataIrrigacao.day - 1;
        double litros = (doc['aguagasta'] is String)
            ? double.tryParse(doc['aguagasta']) ?? 0
            : (doc['aguagasta'] as double);

        double tempo = _converterTempoParaDouble(doc['tempoligado']);
        double umidade = doc['umidade'] is String
            ? double.tryParse(doc['umidade']) ?? 0
            : doc['umidade'];
        double temp = doc['temperatura'] is String
            ? double.tryParse(doc['temperatura']) ?? 0
            : doc['temperatura'];
        double umidadeSoloValor = doc['umidadesolo'] is String
            ? double.tryParse(doc['umidadesolo']) ?? 0
            : doc['umidadesolo'];
        litrosPorDia[dia] += litros;
        tempoPorDia[dia] += tempo;
        umidadeSoloAtualizada[dia].add(umidadeSoloValor);
        umidadePorDia[dia].add(umidade);
        temperaturaPorDia[dia].add(temp);
      }
    }

    setState(() {
      litrosGastos = litrosPorDia;
      tempoIrrigacao = tempoPorDia;
      umidadeSolo = umidadeSoloAtualizada
          .map((umidadesolo) =>
              umidadesolo.isNotEmpty ? umidadesolo.first.toDouble() : 0.0)
          .toList();
      umidadeAr = umidadePorDia
          .map((umidades) =>
              umidades.isNotEmpty ? umidades.first.toDouble() : 0.0)
          .toList();
      temperatura = temperaturaPorDia
          .map((temperaturas) =>
              temperaturas.isNotEmpty ? temperaturas.first.toDouble() : 0.0)
          .toList();
      _chartKey++;
    });
    tempoTotalIrrigacao = _somarTempos(tempoIrrigacao
        .map((t) => '${(t ~/ 60)} min ${(t % 60).toInt()} seg')
        .toList());
  }

  Future<void> _carregarDadosAno() async {
    List<double> litrosPorMes = List.filled(12, 0);

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('dadosIrrigacao').get();

    for (var doc in snapshot.docs) {
      DateTime dataIrrigacao = DateTime.parse(doc.id);

      int mes = dataIrrigacao.month - 1;
      double litros = (doc['aguagasta'] is String)
          ? double.tryParse(doc['aguagasta']) ?? 0
          : (doc['aguagasta'] as double);

      litrosPorMes[mes] += litros;
    }

    setState(() {
      litrosGastosPorMes = litrosPorMes;
    });
  }

  double _calcularMaxYconsumo() {
    double maxLitros = litrosGastosPorMes.isNotEmpty
        ? litrosGastosPorMes.reduce((a, b) => a > b ? a : b)
        : 0;
    double max = maxLitros / 1000;
    return max * 1.19;
  }

  List<LineChartBarData> _construirLineBarsData() {
    List<LineChartBarData> lineBars = [];

    if (showLitros) {
      lineBars.add(
        LineChartBarData(
          spots: List.generate(
            litrosGastos.length,
            (index) => FlSpot(index.toDouble(), litrosGastos[index]),
          ),
          isCurved: true,
          barWidth: 2,
          color: Colors.blue,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (showUmidadeAr) {
      lineBars.add(
        LineChartBarData(
          spots: List.generate(
            umidadeAr.length,
            (index) => FlSpot(index.toDouble(), umidadeAr[index]),
          ),
          isCurved: true,
          barWidth: 2,
          color: Colors.purple,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (showTemperatura) {
      lineBars.add(
        LineChartBarData(
          spots: List.generate(
            temperatura.length,
            (index) => FlSpot(index.toDouble(), temperatura[index]),
          ),
          isCurved: true,
          barWidth: 2,
          color: Colors.green,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (showUmidadeSolo) {
      lineBars.add(
        LineChartBarData(
          spots: List.generate(
            umidadeSolo.length,
            (index) => FlSpot(index.toDouble(), umidadeSolo[index]),
          ),
          isCurved: true,
          barWidth: 2,
          color: Colors.brown,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return lineBars;
  }

  String _somarTempos(List<String> tempos) {
    int totalSegundos = 0;

    for (var tempo in tempos) {
      final regex = RegExp(r'(\d+) min (\d+) seg');
      final match = regex.firstMatch(tempo);
      if (match != null) {
        int minutos = int.parse(match.group(1) ?? '0');
        int segundos = int.parse(match.group(2) ?? '0');
        totalSegundos += minutos * 60 + segundos;
      }
    }
    int totalHoras = totalSegundos ~/ 3600;
    int totalMinutos = (totalSegundos % 3600) ~/ 60;
    int restanteSegundos = totalSegundos % 60;
    if (totalHoras > 0) {
      return "$totalHoras h $totalMinutos min $restanteSegundos seg";
    } else if (totalMinutos > 0) {
      return "$totalMinutos min $restanteSegundos seg";
    } else {
      return "$restanteSegundos seg";
    }
  }

  double _converterTempoParaDouble(String tempoString) {
    final regex = RegExp(r'(\d+) min (\d+) seg');
    final match = regex.firstMatch(tempoString);
    if (match != null) {
      int minutos = int.parse(match.group(1) ?? '0');
      int segundos = int.parse(match.group(2) ?? '0');
      return minutos * 60 + segundos.toDouble();
    }
    return 0;
  }

  Future<void> _calcularValorGasto(int mes) async {
    double litrosTotais = 0.0;

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('dadosIrrigacao').get();

    for (var doc in snapshot.docs) {
      DateTime dataIrrigacao = DateTime.parse(doc.id);

      if (dataIrrigacao.month == mes) {
        double litros = (doc['aguagasta'] is String)
            ? double.tryParse(doc['aguagasta']) ?? 0
            : (doc['aguagasta'] as double);
        litrosTotais += litros;
      }
    }
    litrosTotaisMes = litrosTotais;
    double metrosCubicos = litrosTotais / 1000;
    double valorTotal = 0.0;

    if (metrosCubicos <= 7) {
      valorTotal = metrosCubicos * 3.76;
    } else if (metrosCubicos <= 13) {
      valorTotal = (7 * 3.76) + ((metrosCubicos - 7) * 4.51);
    } else if (metrosCubicos <= 20) {
      valorTotal = (7 * 3.76) + (6 * 4.51) + ((metrosCubicos - 13) * 8.94);
    } else if (metrosCubicos <= 30) {
      valorTotal =
          (7 * 3.76) + (6 * 4.51) + (7 * 8.94) + ((metrosCubicos - 20) * 12.97);
    }

    valorTotal += 10.18;

    if (incluirEsgoto) {
      valorTotal = (valorTotal * 2);
    }
    setState(() {
      valorGasto = valorTotal;
    });
  }

  String _formatarLitrosOuMetrosCubicos(double litros) {
    if (litros >= 1000) {
      return '${(litros / 1000).toStringAsFixed(1)} m³';
    } else {
      return '${litros.toStringAsFixed(0)} litros';
    }
  }

  double _calcularMaxY() {
    double maxLitros = litrosGastos.isNotEmpty
        ? litrosGastos.reduce((a, b) => a > b ? a : b)
        : 0;
    double maxUmidade =
        umidadeAr.isNotEmpty ? umidadeAr.reduce((a, b) => a > b ? a : b) : 0;
    double maxTemperatura = temperatura.isNotEmpty
        ? temperatura.reduce((a, b) => a > b ? a : b)
        : 0;
    return [maxLitros, maxUmidade, maxTemperatura]
            .reduce((a, b) => a > b ? a : b) *
        1.2;
  }

  Widget _buildCheckbox(
      String label, Color color, bool value, Function(bool?)? onChanged,
      {required TextStyle style}) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          checkColor: Colors.white,
          activeColor: color,
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Controle de Dados', softWrap: true),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 100.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selecione o mês',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_left, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        mesSelecionado =
                            mesSelecionado > 1 ? mesSelecionado - 1 : 12;
                        _carregarDados(mesSelecionado);
                        _calcularValorGasto(mesSelecionado);
                      });
                    },
                  ),
                  Text(
                    '$mesSelecionado',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        mesSelecionado =
                            mesSelecionado < 12 ? mesSelecionado + 1 : 1;
                        _carregarDados(mesSelecionado);
                        _calcularValorGasto(mesSelecionado);
                      });
                    },
                  ),
                ],
              ),
            ),
            Card(
              elevation: 4,
              color: Colors.blueGrey[700],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor gasto: R\$${valorGasto.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Litros gastos: ${_formatarLitrosOuMetrosCubicos(litrosTotaisMes)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tempo total de irrigação: $tempoTotalIrrigacao',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ExpansionTile(
              title: const Text('Grafico dos dados de irrigação mensal',
                  style: TextStyle(color: Colors.white)),
              children: [
                Column(
                  children: [
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(19.0),
                      child: LineChart(
                        key: ValueKey<int>(_chartKey),
                        LineChartData(
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    (value + 1).toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    (value + 1).toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          minX: 0,
                          maxX: 30,
                          minY: 0,
                          maxY: _calcularMaxY(),
                          lineBarsData: _construirLineBarsData(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selecionar dados a serem exibidos:',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    _buildCheckbox('Litros Gastos', Colors.blue, showLitros,
                        style: const TextStyle(color: Colors.white), (val) {
                      setState(() {
                        showLitros = val!;
                        _chartKey++;
                      });
                    }),
                    _buildCheckbox(
                        'Umidade do Ar', Colors.purple, showUmidadeAr,
                        style: const TextStyle(color: Colors.white), (val) {
                      setState(() {
                        showUmidadeAr = val!;
                        _chartKey++;
                      });
                    }),
                    _buildCheckbox('Temperatura', Colors.green, showTemperatura,
                        style: const TextStyle(color: Colors.white), (val) {
                      setState(() {
                        showTemperatura = val!;
                        _chartKey++;
                      });
                    }),
                    _buildCheckbox(
                        'Umidade do Solo', Colors.brown, showUmidadeSolo,
                        style: const TextStyle(color: Colors.white), (val) {
                      setState(() {
                        showUmidadeSolo = val!;
                        _chartKey++;
                      });
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Consumo de Agua Anual',
                  style: TextStyle(color: Colors.white)),
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Consumo em metros cúbicos ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(
                                  color: Color.fromARGB(255, 175, 176, 177),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                );
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: Text(
                                    _mesString(value.toInt()),
                                    style: style,
                                  ),
                                );
                              },
                              interval: 1,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 175, 176, 177),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 175, 176, 177),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 175, 176, 177),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Color.fromARGB(255, 175, 176, 177),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: 11,
                        minY: 0,
                        maxY: _calcularMaxYconsumo(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              litrosGastosPorMes.length,
                              (index) => FlSpot(index.toDouble(),
                                  litrosGastosPorMes[index] / 1000),
                            ),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _mesString(int mesIndex) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return meses[mesIndex];
  }
}
