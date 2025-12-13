import 'dart:developer' as developer;
import 'dart:io';

import 'package:meta/meta.dart';

/// Request configuration for audio transcription
///
/// This class encapsulates all parameters needed for a transcription request.
/// Follows SOLID principles with clear single responsibility.
class STTTranscribeRequest {
  STTTranscribeRequest({
    required this.audioFile,
    this.language = 'tr-TR',
    this.modelId = 'azure-speech-1',
    this.enableDiarization = false,
    this.enableCustomerDetection = false,
    this.minSpeakers,
    this.maxSpeakers,
    this.includeWordTimings = false,
  }) {
    // FAIL-FAST: Validate inputs in constructor
    if (language.length < 2) {
      throw ArgumentError('Language code must be at least 2 characters');
    }
    if (modelId.isEmpty) {
      throw ArgumentError('Model ID cannot be empty');
    }
    if (minSpeakers != null && minSpeakers! <= 0) {
      throw ArgumentError('minSpeakers must be positive if provided');
    }
    if (maxSpeakers != null && maxSpeakers! <= 0) {
      throw ArgumentError('maxSpeakers must be positive if provided');
    }
    if (minSpeakers != null &&
        maxSpeakers != null &&
        minSpeakers! > maxSpeakers!) {
      throw ArgumentError(
        'minSpeakers must be less than or equal to maxSpeakers',
      );
    }
  }

  /// Audio file to transcribe
  /// SECURITY: File validation should be done before creating this object
  final File audioFile;

  /// Language code (ISO 639-1, default: tr-TR for Turkish)
  final String language;

  /// STT model identifier
  final String modelId;

  /// Enable speaker diarization (identifies different speakers)
  final bool enableDiarization;

  /// Enable primary customer detection (identifies main customer)
  final bool enableCustomerDetection;

  /// Minimum number of speakers (for diarization)
  final int? minSpeakers;

  /// Maximum number of speakers (for diarization)
  final int? maxSpeakers;

  /// Include word-level timing information
  final bool includeWordTimings;

  /// Validate file before request
  /// SECURITY: Fail fast with clear validation
  Future<void> validate() async {
    if (!await audioFile.exists()) {
      throw ArgumentError('Audio file does not exist: ${audioFile.path}');
    }

    final fileSize = await audioFile.length();
    // SECURITY: Enforce file size limits (100MB max)
    const maxFileSize = 100 * 1024 * 1024;
    if (fileSize > maxFileSize) {
      throw ArgumentError(
        'Audio file too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB '
        '(max: ${maxFileSize / 1024 / 1024}MB)',
      );
    }

    if (fileSize == 0) {
      throw ArgumentError('Audio file is empty');
    }

    // SECURITY: Validate file extension
    final extension = audioFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['wav', 'mp3', 'm4a', 'webm', 'ogg', 'flac'];
    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError(
        'Unsupported audio format: $extension '
        '(allowed: ${allowedExtensions.join(", ")})',
      );
    }
  }

  @override
  String toString() {
    return 'STTTranscribeRequest('
        'file: ${audioFile.path.split('/').last}, '
        'language: $language, '
        'diarization: $enableDiarization, '
        'customerDetection: $enableCustomerDetection)';
  }
}

/// Main response from STT transcription API
///
/// Immutable value object with full null safety.
/// Contains all transcription results and metadata.
@immutable
class STTResponse {
  const STTResponse({
    required this.id,
    required this.text,
    required this.language,
    required this.duration,
    required this.confidence,
    required this.provider,
    this.object = 'transcription',
    this.created,
    this.model,
    this.segments,
    this.words,
    this.metadata,
    this.audioProcessingCost = 0.0,
    this.currency = 'USD',
    this.processingTimeMs,
    this.region,
    this.diarizationEnabled = false,
    this.speakerCount = 0,
    this.speakerSegments,
    this.customerDetectionEnabled = false,
    this.primaryCustomerId,
    this.audioInfo,
  })  : assert(duration >= 0, 'Duration cannot be negative'),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'Confidence must be between 0.0 and 1.0',
        ),
        assert(
          audioProcessingCost >= 0,
          'Audio processing cost cannot be negative',
        ),
        assert(speakerCount >= 0, 'Speaker count cannot be negative');

  factory STTResponse.fromJson(Map<String, dynamic> json) {
    try {
      // OBSERVABILITY: Log parsing for debugging
      developer.log(
        'Parsing STTResponse',
        name: 'STTResponse.fromJson',
      );

      return STTResponse(
        id: json['id'] as String? ?? '',
        object: json['object'] as String? ?? 'transcription',
        created: json['created'] as int?,
        model: json['model'] as String?,
        text: json['text'] as String? ?? '',
        language: json['language'] as String? ?? 'unknown',
        duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
        segments: json['segments'] != null
            ? (json['segments'] as List)
                .map((s) => STTSegment.fromJson(s as Map<String, dynamic>))
                .toList()
            : null,
        words: json['words'] != null
            ? (json['words'] as List)
                .map((w) => STTWord.fromJson(w as Map<String, dynamic>))
                .toList()
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
        audioProcessingCost:
            (json['audioProcessingCost'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'USD',
        processingTimeMs: json['processingTime'] != null
            ? _parseProcessingTime(json['processingTime'])
            : null,
        provider: json['provider'] as String? ?? 'unknown',
        region: json['region'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        diarizationEnabled: json['diarizationEnabled'] as bool? ?? false,
        speakerCount: json['speakerCount'] as int? ?? 0,
        speakerSegments: json['speakerSegments'] != null
            ? (json['speakerSegments'] as List)
                .map((s) =>
                    SpeakerSegmentDto.fromJson(s as Map<String, dynamic>))
                .toList()
            : null,
        customerDetectionEnabled:
            json['customerDetectionEnabled'] as bool? ?? false,
        primaryCustomerId: json['primaryCustomerId'] as String?,
        audioInfo: json['audioInfo'] != null
            ? AudioFileMetadata.fromJson(
                json['audioInfo'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e, stackTrace) {
      // OBSERVABILITY: Structured logging for failure
      developer.log(
        'Failed to parse STTResponse',
        name: 'STTResponse.fromJson',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Parse processing time from various formats (TimeSpan string or milliseconds)
  static int? _parseProcessingTime(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Try parsing TimeSpan format: "00:00:01.234"
      final parts = value.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = double.tryParse(parts[2]) ?? 0.0;
        return ((hours * 3600 + minutes * 60 + seconds) * 1000).toInt();
      }
    }
    return null;
  }

  /// Unique identifier for this transcription
  final String id;

  /// Object type (always "transcription")
  final String object;

  /// Unix timestamp when created
  final int? created;

  /// Model ID used for transcription
  final String? model;

  /// Full transcribed text
  final String text;

  /// Language code
  final String language;

  /// Audio duration in seconds
  final double duration;

  /// Transcription segments with timestamps
  final List<STTSegment>? segments;

  /// Word-level timestamps
  final List<STTWord>? words;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Cost of audio processing in USD
  final double audioProcessingCost;

  /// Currency for cost (default: USD)
  final String currency;

  /// Processing time in milliseconds
  final int? processingTimeMs;

  /// Provider name (e.g., "Azure Speech SDK")
  final String provider;

  /// Provider region (e.g., "westeurope")
  final String? region;

  /// Overall confidence score (0.0 - 1.0)
  final double confidence;

  /// Whether speaker diarization was enabled
  final bool diarizationEnabled;

  /// Number of unique speakers detected
  final int speakerCount;

  /// Speaker segments (only if diarization enabled)
  final List<SpeakerSegmentDto>? speakerSegments;

  /// Whether customer detection was enabled
  final bool customerDetectionEnabled;

  /// Primary customer speaker ID (if customer detection enabled)
  final String? primaryCustomerId;

  /// Audio file metadata
  final AudioFileMetadata? audioInfo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'object': object,
        if (created != null) 'created': created,
        if (model != null) 'model': model,
        'text': text,
        'language': language,
        'duration': duration,
        if (segments != null)
          'segments': segments!.map((s) => s.toJson()).toList(),
        if (words != null) 'words': words!.map((w) => w.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
        'audioProcessingCost': audioProcessingCost,
        'currency': currency,
        if (processingTimeMs != null) 'processingTimeMs': processingTimeMs,
        'provider': provider,
        if (region != null) 'region': region,
        'confidence': confidence,
        'diarizationEnabled': diarizationEnabled,
        'speakerCount': speakerCount,
        if (speakerSegments != null)
          'speakerSegments': speakerSegments!.map((s) => s.toJson()).toList(),
        'customerDetectionEnabled': customerDetectionEnabled,
        if (primaryCustomerId != null) 'primaryCustomerId': primaryCustomerId,
        if (audioInfo != null) 'audioInfo': audioInfo!.toJson(),
      };

  @override
  String toString() {
    return 'STTResponse('
        'id: $id, '
        'text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
        'duration: ${duration.toStringAsFixed(2)}s, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'speakers: $speakerCount, '
        'cost: \$$audioProcessingCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is STTResponse &&
        other.id == id &&
        other.text == text &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(id, text, duration);
}

/// Transcription segment with timing information
@immutable
class STTSegment {
  const STTSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
    this.temperature,
    this.avgLogProb,
    this.compressionRatio,
    this.noSpeechProb,
    this.speakerId,
  })  : assert(start >= 0, 'Start time cannot be negative'),
        assert(end >= start, 'End time must be >= start time');

  factory STTSegment.fromJson(Map<String, dynamic> json) {
    return STTSegment(
      id: json['id'] as int,
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble(),
      avgLogProb: (json['avgLogProb'] as num?)?.toDouble(),
      compressionRatio: (json['compressionRatio'] as num?)?.toDouble(),
      noSpeechProb: (json['noSpeechProb'] as num?)?.toDouble(),
      speakerId: json['speakerId'] as int?,
    );
  }

  final int id;
  final double start;
  final double end;
  final String text;
  final double? temperature;
  final double? avgLogProb;
  final double? compressionRatio;
  final double? noSpeechProb;
  final int? speakerId;

  /// Duration of this segment in seconds
  double get duration => end - start;

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'end': end,
        'text': text,
        if (temperature != null) 'temperature': temperature,
        if (avgLogProb != null) 'avgLogProb': avgLogProb,
        if (compressionRatio != null) 'compressionRatio': compressionRatio,
        if (noSpeechProb != null) 'noSpeechProb': noSpeechProb,
        if (speakerId != null) 'speakerId': speakerId,
      };

  @override
  String toString() {
    return 'STTSegment(id: $id, start: ${start.toStringAsFixed(2)}s, '
        'end: ${end.toStringAsFixed(2)}s, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is STTSegment &&
        other.id == id &&
        other.start == start &&
        other.end == end &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(id, start, end, text);
}

/// Word-level timing information
@immutable
class STTWord {
  const STTWord({
    required this.word,
    required this.start,
    required this.end,
    required this.probability,
    this.speakerId,
  })  : assert(start >= 0, 'Start time cannot be negative'),
        assert(end >= start, 'End time must be >= start time'),
        assert(
          probability >= 0.0 && probability <= 1.0,
          'Probability must be between 0.0 and 1.0',
        );

  factory STTWord.fromJson(Map<String, dynamic> json) {
    return STTWord(
      word: json['word'] as String? ?? '',
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      speakerId: json['speakerId'] as int?,
    );
  }

  final String word;
  final double start;
  final double end;
  final double probability;
  final int? speakerId;

  /// Duration of word pronunciation in seconds
  double get duration => end - start;

  Map<String, dynamic> toJson() => {
        'word': word,
        'start': start,
        'end': end,
        'probability': probability,
        if (speakerId != null) 'speakerId': speakerId,
      };

  @override
  String toString() {
    return 'STTWord(word: $word, start: ${start.toStringAsFixed(2)}s, '
        'end: ${end.toStringAsFixed(2)}s, prob: ${(probability * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is STTWord &&
        other.word == word &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(word, start, end);
}

/// Audio file metadata
@immutable
class AudioFileMetadata {
  const AudioFileMetadata({
    required this.fileSizeBytes,
    required this.format,
    required this.sampleRate,
    required this.channels,
    required this.bitDepth,
    this.durationSeconds,
  })  : assert(fileSizeBytes >= 0, 'File size cannot be negative'),
        assert(sampleRate > 0, 'Sample rate must be positive'),
        assert(channels > 0, 'Channels must be positive'),
        assert(bitDepth > 0, 'Bit depth must be positive'),
        assert(
          durationSeconds == null || durationSeconds >= 0,
          'Duration cannot be negative',
        );

  factory AudioFileMetadata.fromJson(Map<String, dynamic> json) {
    return AudioFileMetadata(
      fileSizeBytes: json['fileSizeBytes'] as int,
      format: json['format'] as String,
      sampleRate: json['sampleRate'] as int,
      channels: json['channels'] as int,
      bitDepth: json['bitDepth'] as int,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  /// File size in bytes
  final int fileSizeBytes;

  /// Audio format (wav, mp3, m4a, etc.)
  final String format;

  /// Sample rate in Hz (e.g., 16000, 44100)
  final int sampleRate;

  /// Number of audio channels (1=mono, 2=stereo)
  final int channels;

  /// Bit depth (8, 16, 24, 32)
  final int bitDepth;

  /// Audio duration in seconds
  final int? durationSeconds;

  /// File size in megabytes (formatted)
  String get fileSizeMB => (fileSizeBytes / 1024 / 1024).toStringAsFixed(2);

  Map<String, dynamic> toJson() => {
        'fileSizeBytes': fileSizeBytes,
        'format': format,
        'sampleRate': sampleRate,
        'channels': channels,
        'bitDepth': bitDepth,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      };

  @override
  String toString() {
    return 'AudioFileMetadata('
        'size: ${fileSizeMB}MB, '
        'format: $format, '
        'sampleRate: ${sampleRate}Hz, '
        'channels: $channels, '
        'bitDepth: $bitDepth-bit'
        '${durationSeconds != null ? ', duration: ${durationSeconds}s' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioFileMetadata &&
        other.fileSizeBytes == fileSizeBytes &&
        other.format == format &&
        other.sampleRate == sampleRate;
  }

  @override
  int get hashCode => Object.hash(fileSizeBytes, format, sampleRate);
}

/// Speaker segment with timing and text
@immutable
class SpeakerSegmentDto {
  const SpeakerSegmentDto({
    required this.speakerId,
    required this.text,
    required this.startTimeSeconds,
    required this.endTimeSeconds,
    required this.confidence,
    required this.speakerConfidence,
    this.wordTimings,
  })  : assert(
          startTimeSeconds >= 0,
          'Start time cannot be negative',
        ),
        assert(
          endTimeSeconds >= startTimeSeconds,
          'End time must be >= start time',
        ),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'Confidence must be between 0.0 and 1.0',
        ),
        assert(
          speakerConfidence >= 0.0 && speakerConfidence <= 1.0,
          'Speaker confidence must be between 0.0 and 1.0',
        );

  factory SpeakerSegmentDto.fromJson(Map<String, dynamic> json) {
    return SpeakerSegmentDto(
      speakerId: json['speakerId'] as String? ?? 'Unknown',
      text: json['text'] as String? ?? '',
      startTimeSeconds: (json['startTimeSeconds'] as num).toDouble(),
      endTimeSeconds: (json['endTimeSeconds'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      speakerConfidence: (json['speakerConfidence'] as num?)?.toDouble() ?? 0.0,
      wordTimings: json['wordTimings'] != null
          ? (json['wordTimings'] as List)
              .map((w) => WordTimingDto.fromJson(w as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Speaker identifier (e.g., "Person1", "Speaker0")
  final String speakerId;

  /// Transcribed text for this segment
  final String text;

  /// Start time in seconds
  final double startTimeSeconds;

  /// End time in seconds
  final double endTimeSeconds;

  /// Transcription confidence (0.0 - 1.0)
  final double confidence;

  /// Speaker identification confidence (0.0 - 1.0)
  final double speakerConfidence;

  /// Word-level timings (optional)
  final List<WordTimingDto>? wordTimings;

  /// Duration of this segment in seconds
  double get durationSeconds => endTimeSeconds - startTimeSeconds;

  Map<String, dynamic> toJson() => {
        'speakerId': speakerId,
        'text': text,
        'startTimeSeconds': startTimeSeconds,
        'endTimeSeconds': endTimeSeconds,
        'confidence': confidence,
        'speakerConfidence': speakerConfidence,
        if (wordTimings != null)
          'wordTimings': wordTimings!.map((w) => w.toJson()).toList(),
      };

  @override
  String toString() {
    return 'SpeakerSegmentDto('
        'speaker: $speakerId, '
        'start: ${startTimeSeconds.toStringAsFixed(2)}s, '
        'end: ${endTimeSeconds.toStringAsFixed(2)}s, '
        'text: ${text.length > 30 ? '${text.substring(0, 30)}...' : text})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeakerSegmentDto &&
        other.speakerId == speakerId &&
        other.startTimeSeconds == startTimeSeconds &&
        other.endTimeSeconds == endTimeSeconds &&
        other.text == text;
  }

  @override
  int get hashCode =>
      Object.hash(speakerId, startTimeSeconds, endTimeSeconds, text);
}

/// Word-level timing information
@immutable
class WordTimingDto {
  const WordTimingDto({
    required this.word,
    required this.startTimeSeconds,
    required this.endTimeSeconds,
    required this.confidence,
  })  : assert(
          startTimeSeconds >= 0,
          'Start time cannot be negative',
        ),
        assert(
          endTimeSeconds >= startTimeSeconds,
          'End time must be >= start time',
        ),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'Confidence must be between 0.0 and 1.0',
        );

  factory WordTimingDto.fromJson(Map<String, dynamic> json) {
    return WordTimingDto(
      word: json['word'] as String? ?? '',
      startTimeSeconds: (json['startTimeSeconds'] as num).toDouble(),
      endTimeSeconds: (json['endTimeSeconds'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Word text
  final String word;

  /// Start time in seconds
  final double startTimeSeconds;

  /// End time in seconds
  final double endTimeSeconds;

  /// Recognition confidence (0.0 - 1.0)
  final double confidence;

  Map<String, dynamic> toJson() => {
        'word': word,
        'startTimeSeconds': startTimeSeconds,
        'endTimeSeconds': endTimeSeconds,
        'confidence': confidence,
      };

  @override
  String toString() {
    return 'WordTimingDto(word: $word, '
        'start: ${startTimeSeconds.toStringAsFixed(2)}s, '
        'end: ${endTimeSeconds.toStringAsFixed(2)}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordTimingDto &&
        other.word == word &&
        other.startTimeSeconds == startTimeSeconds &&
        other.endTimeSeconds == endTimeSeconds;
  }

  @override
  int get hashCode =>
      Object.hash(word, startTimeSeconds, endTimeSeconds);
}

/// STT model information
@immutable
class STTModelInfo {
  const STTModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.supportedLanguages,
    required this.supportedFormats,
    this.description,
    this.maxFileSizeBytes,
    this.maxDurationSeconds,
    this.supportsDiarization = false,
    this.supportsCustomerDetection = false,
    this.supportsWordTimings = false,
  });

  factory STTModelInfo.fromJson(Map<String, dynamic> json) {
    return STTModelInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      description: json['description'] as String?,
      supportedLanguages: json['supportedLanguages'] != null
          ? List<String>.from(json['supportedLanguages'] as List)
          : [],
      supportedFormats: json['supportedFormats'] != null
          ? List<String>.from(json['supportedFormats'] as List)
          : [],
      maxFileSizeBytes: json['maxFileSizeBytes'] as int?,
      maxDurationSeconds: json['maxDurationSeconds'] as int?,
    );
  }

  /// Model ID
  final String id;

  /// Display name
  final String name;

  /// Provider name (e.g., "Azure", "OpenAI")
  final String provider;

  /// Model description
  final String? description;

  /// Supported language codes
  final List<String> supportedLanguages;

  /// Supported audio formats
  final List<String> supportedFormats;

  /// Maximum file size in bytes
  final int? maxFileSizeBytes;

  /// Maximum audio duration in seconds
  final int? maxDurationSeconds;

  /// Supports speaker diarization
  final bool supportsDiarization;

  /// Supports customer detection
  final bool supportsCustomerDetection;

  /// Supports word-level timings
  final bool supportsWordTimings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        if (description != null) 'description': description,
        'supportedLanguages': supportedLanguages,
        'supportedFormats': supportedFormats,
        if (maxFileSizeBytes != null) 'maxFileSizeBytes': maxFileSizeBytes,
        if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
        'supportsDiarization': supportsDiarization,
        'supportsCustomerDetection': supportsCustomerDetection,
        'supportsWordTimings': supportsWordTimings,
      };

  @override
  String toString() {
    return 'STTModelInfo(id: $id, name: $name, provider: $provider, '
        'languages: ${supportedLanguages.length}, '
        'formats: ${supportedFormats.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is STTModelInfo &&
        other.id == id &&
        other.provider == provider;
  }

  @override
  int get hashCode => Object.hash(id, provider);
}
