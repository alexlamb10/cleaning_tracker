import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleaning_tracker/services/data_service.dart';
import 'package:cleaning_tracker/models/models.dart';

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
  
  FrequencyUnit _frequencyUnit = FrequencyUnit.weeks;
  String? _selectedRoomId;
  int _initialCleanliness = 100; // 0 to 100 percent

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.preselectedRoomId;
    _frequencyController.text = '1'; 
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
                      child: Text(room.name),
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
            // Frequency selector with +/- buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Do every',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {
                            final current = int.tryParse(_frequencyController.text) ?? 1;
                            if (current > 1) {
                              setState(() {
                                _frequencyController.text = (current - 1).toString();
                              });
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Number display
                      SizedBox(
                        width: 60,
                        child: Text(
                          _frequencyController.text.isEmpty ? '1' : _frequencyController.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Plus button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            final current = int.tryParse(_frequencyController.text) ?? 1;
                            setState(() {
                              _frequencyController.text = (current + 1).toString();
                            });
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Unit Selection (Days/Weeks)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _frequencyUnit = FrequencyUnit.days),
                        child: Text(
                          'Day',
                          style: TextStyle(
                            fontSize: 18,
                            color: _frequencyUnit == FrequencyUnit.days ? const Color(0xFF5FCBAA) : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('|', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setState(() => _frequencyUnit = FrequencyUnit.weeks),
                        child: Text(
                          'Week',
                          style: TextStyle(
                            fontSize: 18,
                            color: _frequencyUnit == FrequencyUnit.weeks ? const Color(0xFF5FCBAA) : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(initialItem: 100),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      // Index 0 = 0%, Index 100 = 100%
                      // Clamped to 0-100 just in case
                      _initialCleanliness = index.clamp(0, 100);
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 100) return null;
                      final isSelected = _initialCleanliness == index;
                      return Center(
                        child: Text(
                          '$index% ${index == 100 ? "(Freshly Cleaned)" : index == 0 ? "(Needs Cleaning)" : ""}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF5FCBAA) : Colors.grey,
                          ),
                        ),
                      );
                    },
                    childCount: 101,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set the current cleanliness level from 0% to 100%',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final dataService = context.read<DataService>();
                  await dataService.addTask(
                    name: _nameController.text,
                    roomId: _selectedRoomId!,
                    frequencyValue: int.parse(_frequencyController.text),
                    frequencyUnit: _frequencyUnit,
                    initialCleanliness: _initialCleanliness / 100.0,
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
