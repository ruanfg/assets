import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/account_preset.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  AccountPreset? _selectedPreset;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectPreset(AccountPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _nameController.text = preset.name;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final account = Account(name: name, preset: _selectedPreset);
    Navigator.pop(context, account);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建新账户'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('快捷命名'),
                  const SizedBox(height: 12),
                  _buildPresetGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('账户名称'),
                  const SizedBox(height: 12),
                  _buildNameInput(),
                ],
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPresetGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: AccountPreset.all.map((preset) {
        final isSelected = _selectedPreset == preset;
        return GestureDetector(
          onTap: () => _selectPreset(preset),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: preset.color.withValues(alpha: 0.5), width: 2)
                  : Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: preset.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    preset.iconLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preset.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      onChanged: (_) {
        if (_selectedPreset != null &&
            _nameController.text != _selectedPreset!.name) {
          setState(() => _selectedPreset = null);
        }
      },
      decoration: InputDecoration(
        hintText: '请输入账户名称',
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8C6E9),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '完成创建',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
