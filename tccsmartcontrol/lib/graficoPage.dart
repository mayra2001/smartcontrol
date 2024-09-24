import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int mesSelecionado = DateTime.now().month;
  bool incluirEsgoto = false;
  double valorGasto = 0.0;
  double litrosTotaisMes = 0.0;
  int _chartKey = 0;
  String tempoTotalIrrigacao = "0 min 0 seg";

  @override
  void initState() {
    super.initState();
    _carregarDados(mesSelecionado);
    _calcularValorGasto(mesSelecionado);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos de Irrigação')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selecione o mês: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  DropdownButton<int>(
                    value: mesSelecionado,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text('Mês ${index + 1}'),
                      );
                    }),
                    onChanged: (newMes) {
                      setState(() {
                        mesSelecionado = newMes!;
                        _carregarDados(mesSelecionado);
                        _calcularValorGasto(mesSelecionado);
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                key: ValueKey<int>(_chartKey),
                LineChartData(
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        getTitlesWidget: (value, meta) {
                          return Text((value + 1).toInt().toString());
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text((value + 1).toInt().toString());
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        litrosGastos.length,
                        (index) =>
                            FlSpot(index.toDouble(), litrosGastos[index]),
                      ),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      belowBarData: BarAreaData(show: false),
                    ),
                    //LineChartBarData(
                    // spots: List.generate(
                    //   tempoIrrigacao.length,
                    //   (index) =>
                    //       FlSpot(index.toDouble(), tempoIrrigacao[index]),
                    // ),
                    // isCurved: true,
                    //barWidth: 2,
                    // color: Colors.green,
                    //  belowBarData: BarAreaData(show: false),
                    // ),
                    LineChartBarData(
                      spots: List.generate(
                        umidadeAr.length,
                        (index) => FlSpot(index.toDouble(), umidadeAr[index]),
                      ),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.purple,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        temperatura.length,
                        (index) => FlSpot(index.toDouble(), temperatura[index]),
                      ),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.green,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        umidadeSolo.length,
                        (index) => FlSpot(index.toDouble(), umidadeSolo[index]),
                      ),
                      isCurved: true,
                      barWidth: 1,
                      color: Colors.brown,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(5.0),
              child: Text(
                'Legenda de dados por irrigação:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  _buildLegendItem(Colors.blue, 'Litros Gastos'),
                  // _buildLegendItem(Colors.green, 'Tempo de Irrigação'),
                  _buildLegendItem(Colors.purple, 'Umidade do Ar'),
                  _buildLegendItem(Colors.green, 'Temperatura'),
                  _buildLegendItem(Colors.brown, 'Umidade do Solo'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Se em sua localidade é cobrado a taxa de esgoto, selecione para calcular o valor total de irrigação por mês.',
                      softWrap: true,
                    ),
                  ),
                  Checkbox(
                    value: incluirEsgoto,
                    onChanged: (bool? value) {
                      setState(() {
                        incluirEsgoto = value!;
                        _calcularValorGasto(mesSelecionado);
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Valor total gasto: R\$${valorGasto.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Litros gastos no mês selecionado: ${_formatarLitrosOuMetrosCubicos(litrosTotaisMes)}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tempo total de irrigação no mês: $tempoTotalIrrigacao',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 10,
          color: color,
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
