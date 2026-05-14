import 'account_preset.dart';

class Account {
  Account({
    required this.name,
    this.preset,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now();

  final String id;
  final String name;
  final AccountPreset? preset;
  final DateTime createdAt;
}
