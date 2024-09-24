import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficoPage extends StatefulWidget {
  @override
  _GraficoPageState createState() => _GraficoPageState();
}

class _GraficoPageState extends State<GraficoPage> {
  List<double> litrosGastos = [];
  List<double> tempoIrrigacao = [];
  DateTime dataAtual = DateTime.now();
  int diasSelecionados = 30;
  double valorGasto = 0.0;
  double litrosTotaisMes = 0.0;
  int mesSelecionado = DateTime.now().month;
  bool incluirEsgoto = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _calcularValorGasto(mesSelecionado);
  }

  Future<void> _carregarDados() async {
    litrosGastos.clear();
    tempoIrrigacao.clear();

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('dadosIrrigacao').get();

    for (var doc in snapshot.docs) {
      DateTime dataIrrigacao = DateTime.parse(doc.id);

      if (_isDataDentroDoPeriodo(dataIrrigacao, diasSelecionados)) {
        double litros = (doc['aguagasta'] is String)
            ? double.tryParse(doc['aguagasta']) ?? 0
            : (doc['aguagasta'] as double);

        double tempo = _converterTempoParaDouble(doc['tempoligado']);
        litrosGastos.add(litros);
        tempoIrrigacao.add(tempo);
      }
    }
    setState(() {});
  }

  bool _isDataDentroDoPeriodo(DateTime dataIrrigacao, int dias) {
    DateTime dataLimite = dataAtual.subtract(Duration(days: dias));
    return dataIrrigacao.isAfter(dataLimite);
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
      valorTotal += 10.18;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráficos de Irrigação'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                diasSelecionados = value;
                _carregarDados();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 7, child: Text('Últimos 7 dias')),
              PopupMenuItem(value: 15, child: Text('Últimos 15 dias')),
              PopupMenuItem(value: 30, child: Text('Últimos 30 dias')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
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
                        _calcularValorGasto(mesSelecionado);
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Incluir esgoto: ',
                    style: TextStyle(fontSize: 16),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Litros gastos no mês selecionado: ${_formatarLitrosOuMetrosCubicos(litrosTotaisMes)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Valor gasto no mês selecionado: R\$ ${valorGasto.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildChart('Litros Gastos', litrosGastos, Colors.blue),
            _buildChart(
                'Tempo de Irrigação (segundos)', tempoIrrigacao, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String title, List<double> data, Color color) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 300,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      return Text((value.toInt() + 1).toString());
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: data.length.toDouble() - 1,
              minY: 0,
              maxY: data.isNotEmpty
                  ? data.reduce((a, b) => a > b ? a : b) + 1
                  : 1,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(data.length,
                      (index) => FlSpot(index.toDouble(), data[index])),
                  isCurved: true,
                  barWidth: 3,
                  color: color,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
