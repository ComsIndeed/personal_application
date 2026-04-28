import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/message/enums.dart';
import 'storage_service.dart';

class TestDataSeeder {
  final AppDatabase db;
  final StorageService storage = StorageService();

  TestDataSeeder(this.db);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progress => _progressController.stream;

  static const String _baseUrl =
      'https://raw.githubusercontent.com/ComsIndeed/personal_application/main/test_assets/';

  final List<String> _images = [
    'admin_receipt.jpg',
    'admin_schedule.png',
    'bio_diagram.jpg',
    'coding.jpg',
    'digital_diagram_flow.png',
    'fun_book_cover.png',
    'fun_hobby_project.png',
    'infographic.jpg',
    'landscape_1.png',
    'physics_diagram.jpg',
    'school_notebook_scribble.jpg',
    'school_whiteboard_math.jpg',
    'school_whiteboard_math_2.jpg',
  ];

  Future<void> run() async {
    final rand = Random();
    int totalSteps = 60; // 5 groups * 6 variations * 2 multiplicity
    int currentStep = 0;

    // Prefetch all images into the app's local storage/cache first
    // This simulates the "download" part
    final Map<String, String> assetIdMap = {};
    for (var img in _images) {
      try {
        final resp = await http.get(Uri.parse('$_baseUrl$img'));
        if (resp.statusCode == 200) {
          final asset = await storage.importBytes(
            resp.bodyBytes,
            img,
            _guessMime(img),
            displayName: img,
            group: 'test_data',
          );
          assetIdMap[img] = asset.id;
          print('TestDataSeeder: Downloaded and imported $img -> ${asset.id}');
        } else {
          print(
            'TestDataSeeder: Failed to download $img - Status: ${resp.statusCode}',
          );
        }
      } catch (e) {
        print('TestDataSeeder: Error downloading $img: $e');
      }
    }

    print('TestDataSeeder: Starting record insertion for 60 items...');

    // Seeding Matrix
    final groups = [
      _SeedGroup('braindump', TabCategory.braindump, null),
      _SeedGroup('notes', TabCategory.notes, null),
      _SeedGroup('admin', TabCategory.tasks, 'admin'),
      _SeedGroup('fun', TabCategory.tasks, 'fun'),
      _SeedGroup('important', TabCategory.tasks, 'important'),
    ];

    int insertedCount = 0;
    await db.transaction(() async {
      for (var group in groups) {
        for (var variation = 0; variation < 6; variation++) {
          for (var i = 0; i < 2; i++) {
            await _seedItem(group, variation, assetIdMap, rand);
            currentStep++;
            insertedCount++;
            _progressController.add(currentStep / totalSteps);
          }
        }
      }
    });

    print('TestDataSeeder: Finished. Total items attempted: $insertedCount');
  }

  Future<void> _seedItem(
    _SeedGroup group,
    int variation,
    Map<String, String> assetMap,
    Random rand,
  ) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final category = group.category;

    String? title;
    String? textContent;
    List<String> assetIds = [];
    TaskType? priority;
    DateTime? dueDate;
    int? criticality;
    int? resistance;

    // Basic fields based on group
    if (category == TabCategory.tasks) {
      title = _generateTaskTitle(group.key, rand);
      if (group.key == 'important') {
        priority = TaskType.important;
        criticality = rand.nextInt(3) + 8; // 8-10
        resistance = rand.nextInt(5) + 5; // 5-9
        dueDate = now.add(Duration(days: rand.nextInt(3))); // 0-2 days away
      } else if (group.key == 'admin') {
        priority = TaskType.admin;
        criticality = rand.nextInt(5) + 1; // 1-5
        resistance = rand.nextInt(4) + 1; // 1-4
        // Some admin tasks are grouped
        final subGroups = ['Messenger', 'Email', 'School', 'Taxes'];
        group.groupName = subGroups[rand.nextInt(subGroups.length)];
      } else if (group.key == 'fun') {
        priority = TaskType.fun;
        criticality = 2;
        resistance = 2;
      }
    } else if (category == TabCategory.notes) {
      title = _generateNoteTitle(rand);
    } else {
      // Braindump
      textContent = _generateLazyDump(rand);
    }

    // Variation Logic
    switch (variation) {
      case 0: // Long MD + No Media
        textContent = _generateLongMarkdown(false, [], rand);
        break;
      case 1: // Long MD + 1 Media
        final img = _images[rand.nextInt(_images.length)];
        if (assetMap.containsKey(img)) assetIds.add(assetMap[img]!);
        textContent = _generateLongMarkdown(false, [], rand);
        break;
      case 2: // Long MD + Many Media
        final imgs = _getRandomImages(3, rand);
        for (var img in imgs) {
          if (assetMap.containsKey(img)) assetIds.add(assetMap[img]!);
        }
        textContent = _generateLongMarkdown(false, [], rand);
        break;
      case 3: // No text + 1 Media
        textContent = null;
        final img = _images[rand.nextInt(_images.length)];
        if (assetMap.containsKey(img)) assetIds.add(assetMap[img]!);
        break;
      case 4: // No text + Many Media
        textContent = null;
        final imgs = _getRandomImages(4, rand);
        for (var img in imgs) {
          if (assetMap.containsKey(img)) assetIds.add(assetMap[img]!);
        }
        break;
      case 5: // Text + Inline MD Media
        final imgs = _getRandomImages(2, rand);
        final List<String> inlineIds = [];
        for (var img in imgs) {
          if (assetMap.containsKey(img)) {
            assetIds.add(assetMap[img]!);
            inlineIds.add(assetMap[img]!);
          }
        }
        textContent = _generateLongMarkdown(true, inlineIds, rand);
        break;
    }

    // Override text for tasks if text was generated as MD
    if (category == TabCategory.tasks &&
        textContent != null &&
        textContent.length > 100) {
      textContent = _formatTaskContent(textContent, rand);
    }

    try {
      await db
          .into(db.commonNoteItems)
          .insert(
            CommonNoteItemsCompanion.insert(
              id: Value(id),
              userId: Value(_userId),
              updatedAt: Value(now),
              deleted: const Value(false),
              category: category,
              title: Value(title),
              textContent: Value(textContent),
              assetIds: Value(assetIds),
              createdAt: Value(
                now.subtract(Duration(minutes: rand.nextInt(1000))),
              ),
              priority: Value(priority),
              group: Value(group.groupName),
              criticality: Value(criticality),
              resistance: Value(resistance),
              dueDate: Value(dueDate),
            ),
          );
    } catch (e) {
      print('TestDataSeeder: FAILED to insert entry $id. Error: $e');
      rethrow;
    }
  }

  String _generateTaskTitle(String key, Random rand) {
    if (key == 'important') {
      return [
        'Submit Thesis Final',
        'Finish Backend Core',
        'Logic Exam prep',
        'Deploy V1',
      ].elementAt(rand.nextInt(4));
    }
    if (key == 'admin') {
      return [
        'Reply to Email',
        'Check Mailbox',
        'Organize Files',
        'Sync DB',
      ].elementAt(rand.nextInt(4));
    }
    return [
      'Buy new caps',
      'Play some games',
      'Read Science paper',
      'Exercise',
    ].elementAt(rand.nextInt(4));
  }

  String _generateNoteTitle(Random rand) {
    return [
      'System Design 101',
      'Markdown Guide',
      'Meeting Recap',
      'Hobby Ideas',
    ].elementAt(rand.nextInt(4));
  }

  String _generateLazyDump(Random rand) {
    return [
      'precal quiz fri',
      'f6 mon',
      'buy milk',
      'check this: https://google.com',
      'arrange notes',
    ].elementAt(rand.nextInt(5));
  }

  String _generateLongMarkdown(
    bool inline,
    List<String> assetIds,
    Random rand,
  ) {
    String md = """# Overview of the Cognitive OS

The system is designed to handle high-velocity input via the **Brain Dump** and allow refinement into **Structured Notes** or **Actionable Tasks**.

## Core Concepts
- **Entropy**: Handling the messiness of raw data.
- **Cognitive Load**: Reducing friction between thought and capture.

### Why it matters
1. Better recall
2. Lower stress
3. Visual organization

```dart
void main() {
  print("Hello Cognitive OS");
}
```

> "The mind is for having ideas, not holding them." — David Allen

""";

    if (inline && assetIds.isNotEmpty) {
      for (var id in assetIds) {
        md += "\n\n### Attached Reference\n![Reference]($id)\n";
      }
    }

    md +=
        "\n\nFinal thoughts on the implementation details follows here with a very long paragraph to test the wrapping of the text within the card previews and the full view modes of the application. This should be long enough to trigger scrollbars if the height was constrained.";

    return md;
  }

  String _formatTaskContent(String md, Random rand) {
    return """**GIST**: ${md.split('\n').first.replaceAll('#', '').trim()}

**INSTRUCTIONS**: 
- Step 1: Initialize the seeder.
- Step 2: Download assets from GitHub.
- Step 3: Verify the UI.

**EXTRA NOTES**: Use the dark theme for better contrast when viewing diagrams.

**NICE TO HAVES**: Add a sound effect on completion.""";
  }

  List<String> _getRandomImages(int count, Random rand) {
    final list = List<String>.from(_images)..shuffle(rand);
    return list.take(count).toList();
  }

  String _guessMime(String filename) {
    if (filename.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }
}

class _SeedGroup {
  final String key;
  final TabCategory category;
  String? groupName;
  _SeedGroup(this.key, this.category, this.groupName);

  TaskType? get type {
    if (key == 'important') return TaskType.important;
    if (key == 'admin') return TaskType.admin;
    if (key == 'fun') return TaskType.fun;
    return null;
  }
}
