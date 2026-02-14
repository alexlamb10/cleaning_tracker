import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/services/data_service.dart';

class AddTaskScreen extends StatefulWidget {
  final String? preselectedRoomId;

  const AddTaskScreen({super.key, this.preselectedRoomId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _frequencyController = TextEditingController();
  
  String? _selectedRoomId;
  bool _justCleaned = true;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.preselectedRoomId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer<DataService>(
              builder: (context, dataService, child) {
                if (dataService.rooms.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Please add a room first!'),
                    ),
                  );
                }

                final rooms = dataService.rooms;

                return DropdownButtonFormField<String>(
                  value: _selectedRoomId,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    border: OutlineInputBorder(),
                  ),
                  items: rooms.map((room) {
                    return DropdownMenuItem(
                      value: room.id,
                      child: Row(
                        children: [
                          Text(room.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(room.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoomId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a room';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency (days)',
                border: OutlineInputBorder(),
                helperText: 'How often should this task be done?',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter frequency';
                }
                final freq = int.tryParse(value);
                if (freq == null || freq <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              title: const Text('Just cleaned it'),
              subtitle: const Text('Task is up to date'),
              value: true,
              groupValue: _justCleaned,
              onChanged: (value) {
                setState(() {
                  _justCleaned = value!;
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('Needs cleaning now'),
              subtitle: const Text('Task is overdue'),
              value: false,
              groupValue: _justCleaned,
              onChanged: (value) {
                setState(() {
                  _justCleaned = value!;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final dataService = context.read<DataService>();
                  await dataService.addTask(
                    name: _nameController.text,
                    roomId: _selectedRoomId!,
                    frequencyDays: int.parse(_frequencyController.text),
                    justCleaned: _justCleaned,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add Task', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
