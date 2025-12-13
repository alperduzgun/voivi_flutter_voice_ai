import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

import '../services/config_service.dart';

/// STT (Speech-to-Text) Test Screen
///
/// Comprehensive testing interface for STT API features:
/// - File upload with validation
/// - Basic transcription
/// - Speaker diarization
/// - Customer detection
/// - Word-level timings
/// - Cost tracking
/// - Error handling
///
/// ARCHITECTURE: Stateful widget with clean separation of concerns
/// SECURITY: File validation before upload
/// OBSERVABILITY: Comprehensive error messages and logging
class STTTestScreen extends StatefulWidget {
  const STTTestScreen({super.key});

  @override
  State<STTTestScreen> createState() => _STTTestScreenState();
}

class _STTTestScreenState extends State<STTTestScreen> {
  final _apiService = VoiviApiService();

  // State
  File? _selectedFile;
  bool _isLoading = false;
  STTResponse? _response;
  String? _errorMessage;

  // Options
  String _selectedLanguage = 'tr-TR';
  bool _enableDiarization = false;
  bool _enableCustomerDetection = false;
  bool _includeWordTimings = false;

  // Supported values
  final List<String> _supportedLanguages = [
    'tr-TR',
    'en-US',
    'en-GB',
    'de-DE',
    'fr-FR',
    'es-ES',
  ];

  @override
  void dispose() {
    // RESOURCE CLEANUP: Dispose API service
    _apiService.dispose();
    super.dispose();
  }

  /// Pick audio file from device
  /// SECURITY: Validates file type and size
  Future<void> _pickAudioFile() async {
    try {
      // FAIL-FAST: Check configuration first
      if (!ConfigService.isConfigured) {
        _showError('Please configure API credentials in ConfigService');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav', 'mp3', 'm4a', 'webm', 'ogg', 'flac'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // SECURITY: Validate file size (100MB max)
        final fileSize = await file.length();
        const maxSize = 100 * 1024 * 1024; // 100MB

        if (fileSize > maxSize) {
          _showError(
            'File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB '
            '(max: ${maxSize / 1024 / 1024}MB)',
          );
          return;
        }

        if (fileSize == 0) {
          _showError('File is empty');
          return;
        }

        setState(() {
          _selectedFile = file;
          _response = null; // Clear previous results
          _errorMessage = null;
        });

        _showSuccess('File selected: ${result.files.single.name}');
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  /// Transcribe selected audio file
  /// OBSERVABILITY: Logs all steps and errors
  Future<void> _transcribeAudio() async {
    // FAIL-FAST: Validate preconditions
    if (_selectedFile == null) {
      _showError('Please select an audio file first');
      return;
    }

    if (!ConfigService.isConfigured) {
      _showError('Please configure API credentials in ConfigService');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _response = null;
    });

    try {
      // Create request
      final request = STTTranscribeRequest(
        audioFile: _selectedFile!,
        language: _selectedLanguage,
        enableDiarization: _enableDiarization,
        enableCustomerDetection: _enableCustomerDetection,
        includeWordTimings: _includeWordTimings,
      );

      // Validate request (fail-fast)
      await request.validate();

      // Call API
      final response = await _apiService.transcribeAudio(
        baseUrl: ConfigService.baseUrl,
        request: request,
        apiKey: ConfigService.apiKey,
      );

      // OBSERVABILITY: Log success
      debugPrint('✅ Transcription completed: ${response.text.length} chars');

      setState(() {
        _response = response;
        _isLoading = false;
      });

      _showSuccess('Transcription completed successfully!');
    } catch (e) {
      // OBSERVABILITY: Log error with context
      debugPrint('❌ Transcription error: $e');

      setState(() {
        _errorMessage = _formatError(e);
        _isLoading = false;
      });

      _showError(_errorMessage!);
    }
  }

  /// Format error message for user display
  /// SECURITY: Avoid exposing sensitive information
  String _formatError(dynamic error) {
    if (error is ArgumentError) {
      return 'Invalid input: ${error.message}';
    } else if (error.toString().contains('Unauthorized')) {
      return 'Authentication failed. Check your API key.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('File too large')) {
      return 'File exceeds 100MB limit';
    } else if (error.toString().contains('Unsupported')) {
      return 'Unsupported audio format';
    } else {
      return 'Error: ${error.toString()}';
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STT Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'About STT',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration status
            _buildConfigurationCard(),
            const SizedBox(height: 16),

            // File picker
            _buildFilePickerCard(),
            const SizedBox(height: 16),

            // Options
            if (_selectedFile != null) ...[
              _buildOptionsCard(),
              const SizedBox(height: 16),
            ],

            // Transcribe button
            if (_selectedFile != null) _buildTranscribeButton(),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading) _buildLoadingCard(),

            // Error message
            if (_errorMessage != null && !_isLoading) _buildErrorCard(),

            // Results
            if (_response != null && !_isLoading) ...[
              _buildResultsCard(),
              const SizedBox(height: 16),
              if (_response!.speakerSegments != null &&
                  _response!.speakerSegments!.isNotEmpty)
                _buildSpeakerSegmentsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    final isConfigured = ConfigService.isConfigured;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfigured ? Icons.check_circle : Icons.warning,
                  color: isConfigured ? Colors.grey : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isConfigured ? 'Configuration OK' : 'Configuration Required',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Environment: ${ConfigService.isProduction ? 'Production' : 'Development'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Base URL: ${ConfigService.baseUrl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!isConfigured) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ Please update ConfigService with your credentials',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio File',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_selectedFile == null) ...[
              const Text('No file selected'),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.audiotrack, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFile!.path.split('/').last,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _response = null;
                        _errorMessage = null;
                      });
                    },
                    tooltip: 'Remove file',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: _selectedFile!.length(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final sizeMB = snapshot.data! / 1024 / 1024;
                    return Text(
                      'Size: ${sizeMB.toStringAsFixed(2)} MB',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAudioFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_selectedFile == null ? 'Pick Audio File' : 'Change File'),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported: WAV, MP3, M4A, WEBM, OGG, FLAC (max 100MB)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transcription Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Language selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  items: _supportedLanguages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedLanguage = value!;
                          });
                        },
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Language',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),

            // Diarization
            SwitchListTile(
              title: const Text('Speaker Diarization'),
              subtitle: const Text('Identify different speakers'),
              value: _enableDiarization,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _enableDiarization = value;
                      });
                    },
            ),

            // Customer detection
            SwitchListTile(
              title: const Text('Customer Detection'),
              subtitle: const Text('Detect primary customer'),
              value: _enableCustomerDetection,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _enableCustomerDetection = value;
                      });
                    },
            ),

            // Word timings
            SwitchListTile(
              title: const Text('Word-Level Timings'),
              subtitle: const Text('Include word timestamps'),
              value: _includeWordTimings,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _includeWordTimings = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscribeButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _transcribeAudio,
      icon: const Icon(Icons.send),
      label: const Text('Transcribe Audio'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Transcribing audio...'),
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transcription Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Transcribed text
            _buildResultRow('Text', _response!.text),
            const Divider(),

            // Metadata
            _buildResultRow('Language', _response!.language),
            _buildResultRow(
              'Duration',
              '${_response!.duration.toStringAsFixed(2)}s',
            ),
            _buildResultRow(
              'Confidence',
              '${(_response!.confidence * 100).toStringAsFixed(1)}%',
            ),
            _buildResultRow('Provider', _response!.provider),

            // Cost
            const Divider(),
            _buildResultRow(
              'Processing Cost',
              '\$${_response!.audioProcessingCost.toStringAsFixed(6)} USD',
            ),

            // Speaker info
            if (_response!.diarizationEnabled) ...[
              const Divider(),
              _buildResultRow('Speakers Detected', '${_response!.speakerCount}'),
              if (_response!.primaryCustomerId != null)
                _buildResultRow(
                  'Primary Customer',
                  _response!.primaryCustomerId!,
                ),
            ],

            // Audio info
            if (_response!.audioInfo != null) ...[
              const Divider(),
              _buildResultRow('Audio Format', _response!.audioInfo!.format),
              _buildResultRow(
                'Sample Rate',
                '${_response!.audioInfo!.sampleRate} Hz',
              ),
              _buildResultRow('Channels', '${_response!.audioInfo!.channels}'),
              _buildResultRow('Bit Depth', '${_response!.audioInfo!.bitDepth}-bit'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerSegmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Speaker Segments (${_response!.speakerSegments!.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _response!.speakerSegments!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final segment = _response!.speakerSegments![index];
                return _buildSpeakerSegmentTile(segment);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerSegmentTile(SpeakerSegmentDto segment) {
    final isPrimaryCustomer =
        _response!.primaryCustomerId != null &&
        segment.speakerId == _response!.primaryCustomerId;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isPrimaryCustomer ? Colors.grey : Colors.grey,
        child: Text(
          segment.speakerId.replaceAll('Person', 'P').replaceAll('Speaker', 'S'),
          style: const TextStyle(fontSize: 12),
        ),
      ),
      title: Text(segment.text),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${segment.startTimeSeconds.toStringAsFixed(2)}s - '
            '${segment.endTimeSeconds.toStringAsFixed(2)}s '
            '(${segment.durationSeconds.toStringAsFixed(2)}s)',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            'Confidence: ${(segment.confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11),
          ),
          if (isPrimaryCustomer)
            const Text(
              '👤 Primary Customer',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About STT'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Speech-to-Text API Test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Test the STT API with various options:'),
              SizedBox(height: 8),
              Text('• Basic transcription'),
              Text('• Speaker diarization'),
              Text('• Customer detection'),
              Text('• Word-level timings'),
              SizedBox(height: 12),
              Text(
                'Supported Formats',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('WAV, MP3, M4A, WEBM, OGG, FLAC'),
              SizedBox(height: 12),
              Text(
                'File Size Limit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('100 MB maximum'),
              SizedBox(height: 12),
              Text(
                'Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Files are validated before upload'),
              Text('API authentication required'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
