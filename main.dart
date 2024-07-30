import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'package:intl/intl.dart';
import 'dart:ffi';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Scheduler App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController taskController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<Map<String, dynamic>> tasks = []; // タスクリストを保持するための変数

  void _showWindowsNotification(String title, String message) {
    final hWnd = FindWindow(nullptr, TEXT('Task Scheduler App'));

    final nID = 1;
    final uFlags = MB_OK;

    final lpCaption = TEXT(title);
    final lpText = TEXT(message);

    MessageBox(hWnd, lpText, lpCaption, uFlags);
  }

  void _scheduleNotification(String message, DateTime dateTime) {
    final now = DateTime.now();
    final delay = dateTime.difference(now).inMilliseconds;

    Future.delayed(Duration(milliseconds: delay), () {
      _showWindowsNotification('Task Scheduler', message);
    });
  }

  void _addTask() {
    final taskMessage = taskController.text;
    final notificationTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      tasks.add({
        'message': taskMessage,
        'dateTime': notificationTime,
      });
    });

    _scheduleNotification(taskMessage, notificationTime);

    taskController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('通知が設定されました')),
    );
  }

  void _showImmediateNotification() {
    _showWindowsNotification(
        'Immediate Notification', 'This is an immediate notification');
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  void _editTask(int index) async {
    taskController.text = tasks[index]['message'];
    selectedDate = tasks[index]['dateTime'];
    selectedTime = TimeOfDay.fromDateTime(tasks[index]['dateTime']);

    final Map<String, dynamic>? updatedTask = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('タスクを編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: InputDecoration(labelText: 'タスク内容'),
              ),
              ListTile(
                title: Text(
                  '通知日付: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  '通知時間: ${selectedTime.format(context)}',
                ),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // キャンセル時はnullを返す
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final updatedTask = {
                  'message': taskController.text,
                  'dateTime': DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
                };
                Navigator.of(context).pop(updatedTask);
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );

    if (updatedTask != null) {
      setState(() {
        tasks[index] = updatedTask;
      });
    }

    taskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Scheduler App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: taskController,
              decoration: InputDecoration(labelText: 'タスク内容'),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(
                '通知日付: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            ListTile(
              title: Text(
                '通知時間: ${selectedTime.format(context)}',
              ),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) {
                  setState(() {
                    selectedTime = picked;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('タスクを追加'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showImmediateNotification,
              child: Text('即時通知を表示'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(
                        'タスク: ${task['message']}, 日時: ${DateFormat('yyyy-MM-dd HH:mm').format(task['dateTime'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editTask(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteTask(index),
                        ),
                      ],
                    ),
                    onTap: () => _editTask(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

