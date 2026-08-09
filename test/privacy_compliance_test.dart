import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osm_genki/services/app_reset.dart';
import 'package:osm_genki/services/privacy_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('speech consent is versioned and can be withdrawn', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(PrivacyConsent.hasCurrentSpeechConsent(prefs), isFalse);
    await PrivacyConsent.grantSpeechConsent(prefs);
    expect(PrivacyConsent.hasCurrentSpeechConsent(prefs), isTrue);
    expect(
      prefs.getInt(PrivacyConsent.speechConsentVersionKey),
      PrivacyConsent.speechDisclosureVersion,
    );

    await PrivacyConsent.revokeSpeechConsent(prefs);
    expect(PrivacyConsent.hasCurrentSpeechConsent(prefs), isFalse);
  });

  test('declining consent performs no clipboard or URL action', () async {
    var externalActionCount = 0;

    final performed = await PrivacyConsent.runIfAccepted(false, () async {
      externalActionCount++;
    });

    expect(performed, isFalse);
    expect(externalActionCount, 0);
  });

  test(
    'factory-reset cleanup deletes private and temporary artifacts',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'osm_genki_reset_test',
      );
      final documents = await Directory('${root.path}/documents').create();
      final temporary = await Directory('${root.path}/temporary').create();
      final targets = [
        File('${documents.path}/osmgenki_last_recording.m4a'),
        File('${documents.path}/osmgenki_diary.json'),
        File('${documents.path}/osmgenki_diary.json.tmp'),
        File('${documents.path}/osmgenki_diary.json.corrupted-123'),
        File('${documents.path}/osmgenki_diary_reviews.json'),
        File('${temporary.path}/osmGenki_diary_20260718T0102.json'),
        File('${temporary.path}/osm_genki_speech_123.wav'),
        File('${temporary.path}/osm_genki_silence.wav'),
      ];
      for (final file in targets) {
        await file.writeAsString('private');
      }
      final unrelated = File('${temporary.path}/keep-me.txt');
      await unrelated.writeAsString('keep');

      await AppReset.deletePrivateArtifacts(
        documentsDirectory: documents,
        temporaryDirectory: temporary,
      );

      for (final file in targets) {
        expect(await file.exists(), isFalse, reason: file.path);
      }
      expect(await unrelated.exists(), isTrue);
      await root.delete(recursive: true);
    },
  );
}
