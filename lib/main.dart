// main.dart - VERSIÓN CORREGIDA (sin totales por Haber/Debe)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'firebase/config.dart';
import 'models/registro_contable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.firebaseConfig['apiKey']!,
        authDomain: FirebaseConfig.firebaseConfig['authDomain']!,
        projectId: FirebaseConfig.firebaseConfig['projectId']!,
        storageBucket: FirebaseConfig.firebaseConfig['storageBucket']!,
        messagingSenderId: FirebaseConfig.firebaseConfig['messagingSenderId']!,
        appId: FirebaseConfig.firebaseConfig['appId']!,
      ),
    );
    print('✅ Firebase inicializado');
  } catch (e) {
    print('❌ Error Firebase: $e');
  }
  
  runApp(const TablaContableApp());
}

class TablaContableApp extends StatelessWidget {
  const TablaContableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '📊 Libro Diario Contable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference _movimientosRef =
      FirebaseFirestore.instance.collection('movimientos');
  
  final TextEditingController _detalleController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _haberController = TextEditingController();
  final TextEditingController _debeController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  
  DateTime _fechaSeleccionada = DateTime.now();
  bool _cargando = false;
  String _error = '';
  List<RegistroContable> _registros = [];
  double _totalGeneral = 0.0;
  
  // Listas predefinidas de cuentas comunes
  final List<String> _cuentasHaber = [
    'CAJA',
    'BANCOS',
    'VENTAS',
    'CLIENTES',
    'PROVEEDORES',
    'CAPITAL',
    'PRESTAMOS',
    'OTROS',
  ];
  
  final List<String> _cuentasDebe = [
    'GASTOS',
    'COMPRAS',
    'SUELDOS',
    'ALQUILERES',
    'SERVICIOS',
    'IMPUESTOS',
    'INVERSIONES',
    'OTROS',
  ];
  
  @override
  void initState() {
    super.initState();
    _actualizarFechaTexto();
    _cargarMovimientos();
  }
  
  void _actualizarFechaTexto() {
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
  }
  
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        _actualizarFechaTexto();
      });
    }
  }
  
  Future<void> _cargarMovimientos() async {
    if (_cargando) return;
    
    setState(() => _cargando = true);
    
    try {
      final snapshot = await _movimientosRef
          .orderBy('fechaTimestamp', descending: true)
          .limit(50)
          .get();
      
      _registros = snapshot.docs.map((doc) {
        return RegistroContable.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
      
      // Calcular total general (suma de todos los montos)
      _totalGeneral = 0.0;
      for (var registro in _registros) {
        _totalGeneral += registro.monto;
      }
      
      _error = '';
    } catch (e) {
      _error = 'Error al cargar: $e';
      print(_error);
    } finally {
      setState(() => _cargando = false);
    }
  }
  
  Future<void> _guardarMovimiento() async {
    // Validar
    if (_detalleController.text.isEmpty) {
      setState(() => _error = 'El detalle es requerido');
      return;
    }
    
    if (_montoController.text.isEmpty) {
      setState(() => _error = 'El monto es requerido');
      return;
    }
    
    if (_haberController.text.isEmpty) {
      setState(() => _error = 'La cuenta Haber es requerida');
      return;
    }
    
    if (_debeController.text.isEmpty) {
      setState(() => _error = 'La cuenta Debe es requerida');
      return;
    }
    
    setState(() {
      _cargando = true;
      _error = '';
    });
    
    try {
      final registro = RegistroContable.crear(
        fecha: _fechaSeleccionada,
        detalle: _detalleController.text,
        montoTexto: _montoController.text,
        haber: _haberController.text,
        debe: _debeController.text,
      );
      
      await _movimientosRef.add(registro.toFirestore());
      
      await _cargarMovimientos();
      
      _detalleController.clear();
      _montoController.clear();
      _haberController.clear();
      _debeController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Asiento guardado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
      print('❌ Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }
  
  Future<void> _eliminarMovimiento(String id) async {
    try {
      await _movimientosRef.doc(id).delete();
      await _cargarMovimientos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Asiento eliminado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Widget para selector de cuenta Haber
  Widget _buildSelectorHaber() {
    return DropdownButtonFormField<String>(
      value: _haberController.text.isEmpty ? null : _haberController.text,
      decoration: const InputDecoration(
        labelText: 'Haber (Cuenta que se acredita)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.arrow_upward, color: Colors.green),
      ),
      items: _cuentasHaber.map((cuenta) {
        return DropdownMenuItem(
          value: cuenta,
          child: Text(cuenta),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _haberController.text = value ?? '';
        });
      },
    );
  }
  
  // Widget para selector de cuenta Debe
  Widget _buildSelectorDebe() {
    return DropdownButtonFormField<String>(
      value: _debeController.text.isEmpty ? null : _debeController.text,
      decoration: const InputDecoration(
        labelText: 'Debe (Cuenta que se debita)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.arrow_downward, color: Colors.red),
      ),
      items: _cuentasDebe.map((cuenta) {
        return DropdownMenuItem(
          value: cuenta,
          child: Text(cuenta),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _debeController.text = value ?? '';
        });
      },
    );
  }
  
  // Widget para mostrar el total general
  Widget _buildTotalCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '💰 TOTAL MOVIMIENTOS:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${_totalGeneral.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.white),
            SizedBox(width: 10),
            Text('Libro Diario Contable'),
          ],
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMovimientos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulario
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'NUEVO ASIENTO CONTABLE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fecha
                    TextField(
                      controller: _fechaController,
                      decoration: InputDecoration(
                        labelText: 'Fecha',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _seleccionarFecha,
                        ),
                      ),
                      readOnly: true,
                      onTap: _seleccionarFecha,
                    ),
                    const SizedBox(height: 12),
                    
                    // Detalle
                    TextField(
                      controller: _detalleController,
                      decoration: const InputDecoration(
                        labelText: 'Detalle / Concepto',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Pago de servicios',
                      ),
                      maxLength: 40,
                    ),
                    const SizedBox(height: 12),
                    
                    // Monto
                    TextField(
                      controller: _montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    
                    // Selectores de cuentas
                    _buildSelectorHaber(),
                    const SizedBox(height: 12),
                    _buildSelectorDebe(),
                    
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : _guardarMovimiento,
                        icon: _cargando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_cargando ? 'GUARDANDO...' : 'GUARDAR ASIENTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Total General
            _buildTotalCard(),
            
            const SizedBox(height: 20),
            
            // Lista de asientos
            const Text(
              'ASIENTOS REGISTRADOS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: _registros.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay asientos registrados'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _registros.length,
                      itemBuilder: (context, index) {
                        final registro = _registros[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              registro.detalle,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Fecha: ${registro.fechaFormateada}'),
                                Text('Monto: ${registro.montoFormateado}'),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'HABER: ${registro.haber}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'DEBE: ${registro.debe}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarMovimiento(registro.id!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _detalleController.dispose();
    _montoController.dispose();
    _haberController.dispose();
    _debeController.dispose();
    _fechaController.dispose();
    super.dispose();
  }
}