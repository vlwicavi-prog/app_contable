// lib/models/registro_contable.dart
import 'package:intl/intl.dart';

class RegistroContable {
  String? id;
  DateTime fecha;
  String detalle;
  double monto;
  String haber;
  String debe;
  DateTime? timestamp;
  
  RegistroContable({
    this.id,
    required this.fecha,
    required this.detalle,
    required this.monto,
    required this.haber,
    required this.debe,
    this.timestamp,
  });
  
  factory RegistroContable.crear({
    required DateTime fecha,
    required String detalle,
    required String montoTexto,
    required String haber,
    required String debe,
  }) {
    return RegistroContable(
      fecha: fecha,
      detalle: detalle,
      monto: double.tryParse(montoTexto) ?? 0.0,
      haber: haber.toUpperCase(),
      debe: debe.toUpperCase(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'fecha': DateFormat('dd/MM/yyyy').format(fecha),
      'fechaTimestamp': fecha.millisecondsSinceEpoch,
      'detalle': detalle,
      'monto': monto,
      'haber': haber,
      'debe': debe,
      'timestamp': timestamp ?? DateTime.now(),
    };
  }
  
  factory RegistroContable.fromFirestore(String id, Map<String, dynamic> data) {
    return RegistroContable(
      id: id,
      fecha: data['fechaTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['fechaTimestamp'])
          : DateTime.now(),
      detalle: data['detalle'] ?? '',
      monto: (data['monto'] is String)
          ? double.tryParse(data['monto']) ?? 0.0
          : (data['monto'] as num?)?.toDouble() ?? 0.0,
      haber: data['haber'] ?? '',
      debe: data['debe'] ?? '',
      timestamp: data['timestamp']?.toDate(),
    );
  }
  
  String get fechaFormateada => DateFormat('dd/MM/yyyy').format(fecha);
  String get montoFormateado => '\$${monto.toStringAsFixed(2)}';
}