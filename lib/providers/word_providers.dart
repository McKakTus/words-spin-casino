import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word.dart';

final wordListProvider = FutureProvider<List<Word>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/words.json');
  final dynamic decoded = jsonDecode(jsonString);
  if (decoded is! List) {
    throw FormatException('Expected a list of words in the JSON asset');
  }
  return decoded
      .map((dynamic item) => Word.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
});
