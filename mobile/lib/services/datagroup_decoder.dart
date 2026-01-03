import 'dart:convert';
import 'dart:typed_data';

/// Decoder for ID card NFC datagroups (DG2, DG7, DG11, DG12)
/// Provides offline decoding without server dependency
class DatagroupDecoder {
  // JPEG marker: FF D8 FF E0
  static const List<int> _jpegMarker = [0xFF, 0xD8, 0xFF, 0xE0];
  // JP2 marker: 00 00 00 0C 6A 50
  static const List<int> _jp2Marker = [0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50];

  /// ISO-8859-6 to Unicode lookup table for Arabic characters
  /// Characters 0x00-0x7F are same as ASCII
  /// Characters 0xA0-0xFF map to Arabic Unicode block
  static const Map<int, int> _iso8859_6ToUnicode = {
    0xA0: 0x00A0, // NO-BREAK SPACE
    0xA4: 0x00A4, // CURRENCY SIGN
    0xAC: 0x060C, // ARABIC COMMA
    0xAD: 0x00AD, // SOFT HYPHEN
    0xBB: 0x061B, // ARABIC SEMICOLON
    0xBF: 0x061F, // ARABIC QUESTION MARK
    0xC1: 0x0621, // ARABIC LETTER HAMZA
    0xC2: 0x0622, // ARABIC LETTER ALEF WITH MADDA ABOVE
    0xC3: 0x0623, // ARABIC LETTER ALEF WITH HAMZA ABOVE
    0xC4: 0x0624, // ARABIC LETTER WAW WITH HAMZA ABOVE
    0xC5: 0x0625, // ARABIC LETTER ALEF WITH HAMZA BELOW
    0xC6: 0x0626, // ARABIC LETTER YEH WITH HAMZA ABOVE
    0xC7: 0x0627, // ARABIC LETTER ALEF
    0xC8: 0x0628, // ARABIC LETTER BEH
    0xC9: 0x0629, // ARABIC LETTER TEH MARBUTA
    0xCA: 0x062A, // ARABIC LETTER TEH
    0xCB: 0x062B, // ARABIC LETTER THEH
    0xCC: 0x062C, // ARABIC LETTER JEEM
    0xCD: 0x062D, // ARABIC LETTER HAH
    0xCE: 0x062E, // ARABIC LETTER KHAH
    0xCF: 0x062F, // ARABIC LETTER DAL
    0xD0: 0x0630, // ARABIC LETTER THAL
    0xD1: 0x0631, // ARABIC LETTER REH
    0xD2: 0x0632, // ARABIC LETTER ZAIN
    0xD3: 0x0633, // ARABIC LETTER SEEN
    0xD4: 0x0634, // ARABIC LETTER SHEEN
    0xD5: 0x0635, // ARABIC LETTER SAD
    0xD6: 0x0636, // ARABIC LETTER DAD
    0xD7: 0x0637, // ARABIC LETTER TAH
    0xD8: 0x0638, // ARABIC LETTER ZAH
    0xD9: 0x0639, // ARABIC LETTER AIN
    0xDA: 0x063A, // ARABIC LETTER GHAIN
    0xE0: 0x0640, // ARABIC TATWEEL
    0xE1: 0x0641, // ARABIC LETTER FEH
    0xE2: 0x0642, // ARABIC LETTER QAF
    0xE3: 0x0643, // ARABIC LETTER KAF
    0xE4: 0x0644, // ARABIC LETTER LAM
    0xE5: 0x0645, // ARABIC LETTER MEEM
    0xE6: 0x0646, // ARABIC LETTER NOON
    0xE7: 0x0647, // ARABIC LETTER HEH
    0xE8: 0x0648, // ARABIC LETTER WAW
    0xE9: 0x0649, // ARABIC LETTER ALEF MAKSURA
    0xEA: 0x064A, // ARABIC LETTER YEH
    0xEB: 0x064B, // ARABIC FATHATAN
    0xEC: 0x064C, // ARABIC DAMMATAN
    0xED: 0x064D, // ARABIC KASRATAN
    0xEE: 0x064E, // ARABIC FATHA
    0xEF: 0x064F, // ARABIC DAMMA
    0xF0: 0x0650, // ARABIC KASRA
    0xF1: 0x0651, // ARABIC SHADDA
    0xF2: 0x0652, // ARABIC SUKUN
  };

  /// Decode bytes from ISO-8859-6 encoding to Unicode string
  static String _decodeIso8859_6(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else if (_iso8859_6ToUnicode.containsKey(byte)) {
        buffer.writeCharCode(_iso8859_6ToUnicode[byte]!);
      } else {
        buffer.writeCharCode(byte);
      }
    }
    return buffer.toString();
  }

  /// Find byte sequence in data
  static int _findSequence(Uint8List data, List<int> sequence) {
    outer:
    for (int i = 0; i <= data.length - sequence.length; i++) {
      for (int j = 0; j < sequence.length; j++) {
        if (data[i + j] != sequence[j]) {
          continue outer;
        }
      }
      return i;
    }
    return -1;
  }

  /// Decode image datagroup (DG2 for face, DG7 for signature)
  static Map<String, dynamic> decodeImageDatagroup(Uint8List bytes) {
    try {
      if (bytes.isEmpty) {
        return {'result': 'False', 'error': 'Empty data'};
      }

      int imageStart = _findSequence(bytes, _jpegMarker);
      if (imageStart == -1) {
        imageStart = _findSequence(bytes, _jp2Marker);
      }

      if (imageStart == -1) {
        return {'result': 'False', 'error': 'Image marker not found'};
      }

      final imageData = bytes.sublist(imageStart);
      final base64Image = base64Encode(imageData);

      return {
        'result': 'True',
        'image': base64Image,
        'format': 'base64/jpeg'
      };
    } catch (e) {
      return {'result': 'False', 'error': e.toString()};
    }
  }

  /// Decode DG2 (face photo)
  static Map<String, dynamic> decodeDG2(Uint8List bytes) {
    final result = decodeImageDatagroup(bytes);
    if (result['result'] == 'True') {
      return {
        'result': 'True',
        'face': result['image'],
        'format': result['format']
      };
    }
    return result;
  }

  /// Decode DG7 (signature)
  static Map<String, dynamic> decodeDG7(Uint8List bytes) {
    final result = decodeImageDatagroup(bytes);
    if (result['result'] == 'True') {
      return {
        'result': 'True',
        'signature': result['image'],
        'format': result['format']
      };
    }
    return result;
  }

  /// Clean text: keep printable chars and '&'
  static String _cleanText(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code > 31 || text[i] == '&') {
        buffer.write(text[i]);
      }
    }
    return buffer.toString().replaceAll(' ', '-');
  }

  /// Extract digits from string and format as date
  static String? _formatDate(String dateString) {
    final digits = RegExp(r'\d+').allMatches(dateString);
    final dateDigits = digits.map((m) => m.group(0)!).join();

    if (dateDigits.length != 8) {
      return null;
    }

    final year = dateDigits.substring(0, 4);
    final month = dateDigits.substring(4, 6);
    final day = dateDigits.substring(6, 8);

    return '$year/$month/$day';
  }

  /// Decode DG11 - Personal details
  static Map<String, dynamic> decodeDG11(Uint8List bytes) {
    try {
      if (bytes.isEmpty) {
        return {'result': 'False', 'error': 'Empty data'};
      }

      final decodedText = _decodeIso8859_6(bytes);
      final cleanedText = _cleanText(decodedText);
      final splitByUnderscore = cleanedText.split('_');
      final items = splitByUnderscore.map((word) => word.split('<<')).toList();

      if (items.length < 14) {
        return {'result': 'False', 'error': 'Insufficient data fields in DG11: ${items.length} items'};
      }

      final surnamesLatin = items[8].isNotEmpty ? items[8][0] : '';
      String surnamesArabic = '';
      if (items[8].length > 1 && items[8][1].isNotEmpty) {
        surnamesArabic = items[8][1].substring(0, items[8][1].length - 1);
      }

      final nameLatin = items[9].isNotEmpty ? items[9][0] : '';
      final nameArabic = items[9].length > 1 ? items[9][1] : '';
      final nin = items[10].isNotEmpty ? items[10][0] : '';

      final birthDateFormatted = _formatDate(items[11].isNotEmpty ? items[11][0] : '');
      if (birthDateFormatted == null) {
        return {'result': 'False', 'error': 'Invalid birth date format'};
      }

      final birthPlaceLatin = items[12].isNotEmpty ? items[12][0] : '';
      final birthPlaceArabic = items[12].length > 1 ? items[12][1] : '';

      String bloodType = '';
      String sexArabic = '';
      String sexLatin = '';

      if (items[13].isNotEmpty) {
        bloodType = items[13].last;
        if (items[13].length > 1) {
          sexArabic = items[13][items[13].length - 2];
        }
        if (items[13][0].isNotEmpty) {
          sexLatin = items[13][0][items[13][0].length - 1];
        }
      }

      return {
        'result': 'True',
        'surname_latin': surnamesLatin,
        'surname_arabic': surnamesArabic,
        'name_latin': nameLatin,
        'name_arabic': nameArabic,
        'birthplace_latin': birthPlaceLatin,
        'birthplace_arabic': birthPlaceArabic,
        'birth_date': birthDateFormatted,
        'sex_latin': sexLatin,
        'sex_arabic': sexArabic,
        'blood_type': bloodType,
        'nin': nin,
      };
    } catch (e) {
      return {'result': 'False', 'error': e.toString()};
    }
  }

  /// Decode DG12 - Document issuance information
  static Map<String, dynamic> decodeDG12(Uint8List bytes) {
    try {
      if (bytes.isEmpty) {
        return {'result': 'False', 'error': 'Empty data'};
      }

      final decodedText = _decodeIso8859_6(bytes);

      final buffer = StringBuffer();
      for (int i = 0; i < decodedText.length; i++) {
        final code = decodedText.codeUnitAt(i);
        if (code > 31 || decodedText[i] == '\n' || decodedText[i] == '&') {
          buffer.write(decodedText[i]);
        }
      }
      final cleanedText = buffer.toString().replaceAll(' ', '-');

      final splitByUnderscore = cleanedText.split('_');
      final items = splitByUnderscore.map((word) => word.split('<<')).toList();

      if (items.length == 9) {
        final i = 4;
        final delivDate = _formatDate(items[i + 2].isNotEmpty ? items[i + 2][0] : '');
        final expDate = _formatDate(items[i + 3].isNotEmpty ? items[i + 3][0] : '');

        if (delivDate == null || expDate == null) {
          return {'result': 'False', 'error': 'Invalid date format in DG12'};
        }

        return {
          'result': 'True',
          'daira': '--',
          'baladia_latin': items[i + 1].isNotEmpty ? items[i + 1][0] : '',
          'baladia_arabic': items[i + 1].length > 1 ? items[i + 1][1] : '',
          'delivery_date': delivDate,
          'expiry_date': expDate,
        };
      } else if (items.length == 10) {
        final i = 5;
        final delivDate = _formatDate(items[i + 2].isNotEmpty ? items[i + 2][0] : '');
        final expDate = _formatDate(items[i + 3].isNotEmpty ? items[i + 3][0] : '');

        if (delivDate == null || expDate == null) {
          return {'result': 'False', 'error': 'Invalid date format in DG12'};
        }

        String daira = '--';
        if (items[i].isNotEmpty && items[i][0].isNotEmpty) {
          daira = items[i][0].substring(1);
        }

        return {
          'result': 'True',
          'daira': daira,
          'baladia_latin': items[i + 1].isNotEmpty ? items[i + 1][0] : '',
          'baladia_arabic': items[i + 1].length > 1 ? items[i + 1][1] : '',
          'delivery_date': delivDate,
          'expiry_date': expDate,
        };
      } else {
        return {'result': 'False', 'error': 'Unexpected data format: ${items.length} items found'};
      }
    } catch (e) {
      return {'result': 'False', 'error': e.toString()};
    }
  }

  /// Decode all datagroups from raw bytes
  static Map<String, dynamic> decodeAll({
    Uint8List? dg2Bytes,
    Uint8List? dg7Bytes,
    Uint8List? dg11Bytes,
    Uint8List? dg12Bytes,
  }) {
    final results = <String, dynamic>{};

    if (dg2Bytes != null && dg2Bytes.isNotEmpty) {
      results['dg2'] = decodeDG2(dg2Bytes);
    }

    if (dg7Bytes != null && dg7Bytes.isNotEmpty) {
      results['dg7'] = decodeDG7(dg7Bytes);
    }

    if (dg11Bytes != null && dg11Bytes.isNotEmpty) {
      results['dg11'] = decodeDG11(dg11Bytes);
    }

    if (dg12Bytes != null && dg12Bytes.isNotEmpty) {
      results['dg12'] = decodeDG12(dg12Bytes);
    }

    return results;
  }
}
