import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../models/patient.dart';

class AddPatientScreen extends StatefulWidget {
  final Patient? patient;
  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _notesController;
  
  String _gender = 'Masculino';
  String? _bloodType;
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameController = TextEditingController(text: p?.name ?? '');
    _ageController = TextEditingController(text: p?.age.toString() ?? '');
    _heightController = TextEditingController(text: p?.height?.toString() ?? '');
    _weightController = TextEditingController(text: p?.weight?.toString() ?? '');
    _allergiesController = TextEditingController(text: p?.allergies ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _gender = p?.gender ?? 'Masculino';
    _bloodType = p?.bloodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      final patient = Patient(
        id: widget.patient?.id,
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _gender,
        height: _heightController.text.isEmpty ? null : double.parse(_heightController.text),
        weight: _weightController.text.isEmpty ? null : double.parse(_weightController.text),
        bloodType: _bloodType,
        allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.patient?.createdAt,
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<PatientProvider>(context, listen: false);
      if (widget.patient == null) {
        await provider.addPatient(patient);
      } else {
        await provider.updatePatient(patient);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Nuevo Paciente' : 'Editar Paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _savePatient,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Edad',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Masculino', 'Femenino', 'Otro']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Estatura (cm)',
                      prefixIcon: Icon(Icons.height),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: const InputDecoration(
                labelText: 'Tipo de sangre',
                prefixIcon: Icon(Icons.bloodtype),
                border: OutlineInputBorder(),
              ),
              items: _bloodTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Alergias',
                prefixIcon: Icon(Icons.warning_amber),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
