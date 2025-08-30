import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/my_task.dart'; // Assuming MyTask model is in a separate file
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';

class MyTaskEditorScreen extends StatefulWidget {
  final MyTask? task;

  const MyTaskEditorScreen({super.key, this.task});

  @override
  State<MyTaskEditorScreen> createState() => _MyTaskEditorScreenState();
}

class _MyTaskEditorScreenState extends State<MyTaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final isUpdating = widget.task != null;
    final url = isUpdating
        ? '${Environment.apiBaseUrl}/my_tasks/${widget.task!.id}'
        : '${Environment.apiBaseUrl}/my_tasks';
    
    final headers = await ApiHeaders.jsonHeaders();
    final body = json.encode({'title': _titleController.text});

    try {
      final response = isUpdating
          ? await http.put(Uri.parse(url), headers: headers, body: body)
          : await http.post(Uri.parse(url), headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context).pop(true); // Pop with a success flag
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? '新しいマイタスク' : 'タスクを編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タスク名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タスク名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isSaving)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
