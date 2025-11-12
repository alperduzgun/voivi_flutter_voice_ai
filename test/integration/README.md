# Integration Tests

Bu klasör, gerçek Voivi API ile çalışan integration testlerini içerir.

## ⚙️ Kurulum

Integration testlerini çalıştırmadan önce, `test/test_config.dart` dosyasını gerçek API bilgilerinizle güncellemelisiniz:

```dart
class TestConfig {
  static const String baseUrl = 'http://localhost:5065';
  static const String apiKey = 'your-actual-api-key';
  static const String organizationId = 'org_your_actual_org_id';

  // ... diğer ayarlar
}
```

## 🚀 Testleri Çalıştırma

### Tüm Integration Testleri

```bash
flutter test test/integration/
```

### Belirli Bir Test Dosyası

```bash
# Assistant API testleri
flutter test test/integration/assistant_api_integration_test.dart

# Full chat workflow testleri
flutter test test/integration/full_chat_integration_test.dart
```

### Verbose Mod (Detaylı Loglar)

Test config'de `verboseLogs = true` olduğundan tüm adımlar konsolda görüntülenecektir.

## 📋 Test Listesi

### `assistant_api_integration_test.dart`

1. **List Assistants**: Tüm assistantları listeler
2. **Get Specific Assistant**: Belirli bir assistant'ın detaylarını çeker
3. **Invalid Assistant ID**: Geçersiz ID ile hata yönetimini test eder
4. **Invalid Credentials**: Geçersiz credentials ile hata yönetimini test eder

### `full_chat_integration_test.dart`

1. **Complete Workflow**: Tam akış testi
   - Assistant listesi çek
   - Bir assistant seç
   - Chat engine'i başlat
   - Bağlan
   - Mesaj gönder
   - Yanıt al
   - Bağlantıyı kes

2. **Reconnection**: Yeniden bağlanma senaryosu
   - Bağlan
   - Bağlantıyı kes
   - Tekrar bağlan

## 🔧 Test Konfigürasyonu

### Config Parametreleri

```dart
// API Bilgileri
baseUrl          // Backend URL'i
apiKey           // API authentication key
organizationId   // Organization ID

// Opsiyonel
assistantId      // Belirli bir assistant test etmek için
testUserId       // Test user ID'si

// Timeout'lar
connectionTimeout  // Bağlantı timeout'u (default: 30s)
messageTimeout     // Mesaj yanıt timeout'u (default: 10s)

// Kontroller
runIntegrationTests  // Integration testleri çalıştır (true/false)
verboseLogs          // Detaylı log göster (true/false)
```

## 🎯 Örnek Test Çıktısı

```
=== Test Configuration ===
Base URL: http://localhost:5065
API Key: aac01db8***
Organization ID: org_xxx
Assistant ID: Will fetch dynamically
Run Integration Tests: true
========================

📋 Step 1: Fetching available assistants...
✅ Found 3 assistants

🎯 Step 2: Selected assistant: Customer Support Bot
   ID: ast_123abc

⚙️  Step 3: Creating chat configuration...
✅ Configuration created

🔧 Step 4: Initializing chat engine...
✅ Chat engine initialized

👂 Step 5: Setting up message listeners...
✅ Listeners configured

🔌 Step 6: Connecting to chat service...
🔄 State: Connected=true, Processing=false, Messages=0
✅ Connected to chat service

📤 Step 7: Sending test message...
✅ Message sent

⏳ Step 8: Waiting for assistant response...
📨 Received message: [userText] Hello! This is an integration test...
📨 Received message: [assistantText] Hi! How can I help you today?
✅ Received response: Hi! How can I help you today?

🔍 Step 9: Verifying final state...
✅ Final state verified
   Messages in state: 2
   Conversation ID: conv_xyz789

🧹 Cleaning up...
✅ Cleanup complete

=== Test Completed Successfully ===

00:32 +1: All tests passed!
```

## ⚠️ Önemli Notlar

1. **API Credentials**: Test config'inizdeki API key'i **asla** git'e commit etmeyin!

2. **Rate Limiting**: Çok sık test çalıştırırsanız API rate limit'e takılabilirsiniz.

3. **Network Bağımlılığı**: Bu testler gerçek API'ye bağlandığından internet bağlantısı gerektirir.

4. **Timeout'lar**: Yavaş bağlantılarda timeout'ları artırmanız gerekebilir:
   ```dart
   static const Duration connectionTimeout = Duration(seconds: 60);
   static const Duration messageTimeout = Duration(seconds: 30);
   ```

5. **Test Ortamı**: Production API'ye karşı değil, development/staging ortamına karşı test edin.

## 🐛 Sorun Giderme

### "Test configuration is not set up" Hatası

`test/test_config.dart` dosyasındaki placeholder değerleri gerçek bilgilerinizle değiştirin.

### Timeout Hataları

```dart
// Config'de timeout'ları artırın
static const Duration connectionTimeout = Duration(seconds: 60);
static const Duration messageTimeout = Duration(seconds: 30);
```

### "No assistants found" Hatası

Backend'inizde en az bir assistant olduğundan emin olun.

### Connection Hataları

- Backend'in çalıştığından emin olun
- `baseUrl` değerinin doğru olduğunu kontrol edin
- Firewall/proxy ayarlarını kontrol edin

## 📝 Yeni Test Ekleme

Yeni bir integration test eklemek için:

1. `test/integration/` klasöründe yeni bir dosya oluşturun
2. `test_config.dart`'ı import edin
3. Test setup/teardown'ları ekleyin
4. Config kontrollerini ekleyin:

```dart
test('my test', () async {
  if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
    print('⏭️  Skipping test - not configured');
    return;
  }

  // Test kodunuz...
});
```

## 🔒 Güvenlik

**UYARI**: `test_config.dart` dosyası gerçek API credentials içerdiğinden:

1. `.gitignore`'a eklendiğinden emin olun
2. Public repo'lara push etmeyin
3. CI/CD'de environment variable'lar kullanın
4. Production keys kullanmayın, sadece test keys kullanın

## 📚 Daha Fazla Bilgi

- [Voivi Chat Documentation](../../README.md)
- [Unit Test Examples](../models/)
- [API Reference](../../README.md#-api-reference)
