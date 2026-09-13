// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  stdout.writeln('🔍 Scanning for skills in .agent/skills, .agents/skills, and skills/...');

  final rootDir = Directory.current;
  final searchDirs = [
    Directory('${rootDir.path}/.agents/skills'),
    Directory('${rootDir.path}/.agent/skills'),
    Directory('${rootDir.path}/skills'),
  ];

  final skillsMap = <String, Map<String, dynamic>>{};
  int totalFilesHashed = 0;

  for (final dir in searchDirs) {
    if (!dir.existsSync()) continue;

    final subDirs = dir.listSync().whereType<Directory>();
    for (final skillDir in subDirs) {
      final skillName = skillDir.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .last;

      if (skillsMap.containsKey(skillName)) continue;

      final skillMd = File('${skillDir.path}/SKILL.md');
      if (!skillMd.existsSync()) continue;

      // Extract frontmatter
      final content = skillMd.readAsStringSync();
      final frontmatterMatch = RegExp(r'^---\n([\s\S]*?)\n---').firstMatch(content);
      String description = '';
      if (frontmatterMatch != null) {
        final yaml = frontmatterMatch.group(1) ?? '';
        final descMatch = RegExp(r'description:\s*(?:>-|>)?\s*([\s\S]*?)(?=\n\w+:|$)').firstMatch(yaml);
        if (descMatch != null) {
          description = descMatch.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
        }
      }

      // Hash all files in skill directory
      final fileHashes = <String, String>{};
      final skillFiles = skillDir
          .listSync(recursive: true)
          .whereType<File>()
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      final compositeBytes = <int>[];

      for (final file in skillFiles) {
        final relativePath = file.path
            .substring(skillDir.path.length + 1)
            .replaceAll(Platform.pathSeparator, '/');
        final bytes = file.readAsBytesSync();
        final digest = sha256.convert(bytes).toString();
        fileHashes[relativePath] = digest;
        compositeBytes.addAll(utf8.encode(relativePath));
        compositeBytes.addAll(bytes);
        totalFilesHashed++;
      }

      final compositeHash = sha256.convert(compositeBytes).toString();

      skillsMap[skillName] = {
        'name': skillName,
        'path': _relativeToRoot(rootDir.path, skillDir.path),
        'description': description,
        'file_count': fileHashes.length,
        'composite_hash': compositeHash,
        'files': fileHashes,
      };

      stdout.writeln('  ✓ Indexed skill: $skillName (${fileHashes.length} files, hash: ${compositeHash.substring(0, 12)}...)');
    }
  }

  final lockFile = File('${rootDir.path}/skills-lock.json');
  final lockData = {
    'schema_version': '1.0.0',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'skills_count': skillsMap.length,
    'total_files': totalFilesHashed,
    'skills': skillsMap,
  };

  const encoder = JsonEncoder.withIndent('  ');
  lockFile.writeAsStringSync('${encoder.convert(lockData)}\n');

  stopwatch.stop();
  stdout.writeln('✅ Successfully updated skills-lock.json (${skillsMap.length} skills, $totalFilesHashed files) in ${stopwatch.elapsedMilliseconds}ms');
}

String _relativeToRoot(String root, String path) {
  if (path.startsWith(root)) {
    var rel = path.substring(root.length);
    if (rel.startsWith('/') || rel.startsWith('\\')) rel = rel.substring(1);
    return rel.replaceAll(Platform.pathSeparator, '/');
  }
  return path;
}
