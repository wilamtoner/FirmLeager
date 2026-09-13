import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Skills Validation & Link Integrity Tests', () {
    final rootDir = Directory.current;
    final skillsDir = Directory('${rootDir.path}/.agents/skills');

    test('Skills directory exists and contains known skill packs', () {
      expect(skillsDir.existsSync(), isTrue, reason: '.agents/skills must exist');
      final agentDir = Directory('${rootDir.path}/.agent/skills');
      expect(agentDir.existsSync(), isTrue, reason: '.agent/skills must exist and resolve');
      final subDirs = skillsDir.listSync().whereType<Directory>().toList();
      expect(subDirs.isNotEmpty, isTrue, reason: 'At least one skill must be registered');
    });

    test('Every skill contains a valid SKILL.md with frontmatter', () {
      final subDirs = skillsDir.listSync().whereType<Directory>().toList();
      for (final skillDir in subDirs) {
        final skillMd = File('${skillDir.path}/SKILL.md');
        expect(skillMd.existsSync(), isTrue, reason: 'Missing SKILL.md in ${skillDir.path}');

        final content = skillMd.readAsStringSync();
        final frontmatterMatch = RegExp(r'^---\n([\s\S]*?)\n---').firstMatch(content);
        expect(frontmatterMatch, isNotNull, reason: 'Missing YAML frontmatter in ${skillMd.path}');

        final yaml = frontmatterMatch!.group(1)!;
        expect(yaml.contains('name:'), isTrue, reason: 'Frontmatter missing name in ${skillMd.path}');
        expect(yaml.contains('description:'), isTrue, reason: 'Frontmatter missing description in ${skillMd.path}');
      }
    });

    test('All internal markdown links across skills resolve to existing files', () {
      final mdFiles = skillsDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
      final brokenLinks = <String>[];
      int totalLinksChecked = 0;

      for (final mdFile in mdFiles) {
        final content = mdFile.readAsStringSync();
        // Match [text](target)
        final matches = RegExp(r'\[([^\]]+)\]\(([^)]+)\)').allMatches(content);

        for (final m in matches) {
          final target = m.group(2) ?? '';
          // Ignore external web urls, anchors, and mailto
          if (target.startsWith('http://') ||
              target.startsWith('https://') ||
              target.startsWith('#') ||
              target.startsWith('mailto:')) {
            continue;
          }

          totalLinksChecked++;
          final pathOnly = target.split('#').first.trim();
          if (pathOnly.isEmpty) continue;

          // Resolve relative path
          final resolvedFile = File('${mdFile.parent.path}/$pathOnly');
          if (!resolvedFile.existsSync()) {
            // Also check relative to skill root
            final altFile = File('${skillsDir.path}/$pathOnly');
            if (!altFile.existsSync()) {
              brokenLinks.add('${mdFile.path} -> $target (missing: ${resolvedFile.path})');
            }
          }
        }
      }

      expect(totalLinksChecked, greaterThan(0), reason: 'Expected links to be checked');
      expect(brokenLinks, isEmpty, reason: 'Found broken links:\n${brokenLinks.join("\n")}');
    });

    test('skills-lock.json matches filesystem skill file hashes', () {
      final lockFile = File('${rootDir.path}/skills-lock.json');
      if (!lockFile.existsSync()) {
        // If not yet generated, skip or fail gracefully
        return;
      }

      final json = jsonDecode(lockFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json['schema_version'], equals('1.0.0'));
      final skills = json['skills'] as Map<String, dynamic>;

      for (final entry in skills.entries) {
        final skillData = entry.value as Map<String, dynamic>;
        final skillPath = skillData['path'] as String;
        final fullSkillDir = Directory('${rootDir.path}/$skillPath');
        expect(fullSkillDir.existsSync(), isTrue, reason: 'Skill dir $skillPath in lock file must exist');

        final filesMap = skillData['files'] as Map<String, dynamic>;
        for (final fileEntry in filesMap.entries) {
          final relPath = fileEntry.key;
          final expectedHash = fileEntry.value as String;
          final actualFile = File('${fullSkillDir.path}/$relPath');
          expect(actualFile.existsSync(), isTrue, reason: 'File $relPath must exist');
          final actualHash = sha256.convert(actualFile.readAsBytesSync()).toString();
          expect(actualHash, equals(expectedHash), reason: 'Hash mismatch for $relPath');
        }
      }
    });
  });
}
