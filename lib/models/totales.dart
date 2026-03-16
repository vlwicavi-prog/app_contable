import 'registro_contable.dart';

class TotalesContable {
  double totalHaber = 0.0;
  double totalDebe = 0.0;
  double diferencia = 0.0;
  
  TotalesContable();
  
  void calcular(List<RegistroContable> registros) {
    totalHaber = 0.0;
    totalDebe = 0.0;
    
    for (var registro in registros) {
      if (registro.esHaber) {
        totalHaber += registro.monto;
      }
      if (registro.esDebe) {
        totalDebe += registro.monto;
      }
    }
    
    diferencia = (totalHaber - totalDebe).abs();
  }
  
  bool get cuadra => totalHaber == totalDebe;
}
