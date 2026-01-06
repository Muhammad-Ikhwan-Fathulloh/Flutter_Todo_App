## 📱 **DEPLOY APK (Android Application Package)**

### **Langkah 1: Persiapan di VS Code**

1. **Buka terminal di VS Code** (`Ctrl + `` `)
2. **Periksa environment Flutter**:
```bash
flutter doctor
```
Pastikan semua checklist hijau, terutama:
- Flutter SDK ✓
- Android toolchain ✓
- Android Studio ✓
- Android device/emulator ✓

3. **Update dependencies**:
```bash
flutter pub get
```

### **Langkah 2: Konfigurasi Android**

4. **Edit `android/app/build.gradle`**:

```gradle
android {
    namespace "com.example.yourapp"
    compileSdk 34  // Update ke versi terbaru

    defaultConfig {
        applicationId "com.example.yourapp"  // Ganti dengan package name unik
        minSdk 21  // Minimum Android 5.0
        targetSdk 34
        versionCode 1  // Increment setiap update
        versionName "1.0.0"
    }

    buildTypes {
        release {
            // Tambahkan di dalam release
            signingConfig signingConfigs.debug  // Untuk testing, ganti nanti
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

5. **Edit `android/app/src/main/AndroidManifest.xml`**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA" /> <!-- Jika pakai kamera -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <application
        android:label="Nama Aplikasi Anda"  <!-- Ganti -->
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:theme="@style/LaunchTheme">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:hardwareAccelerated="true"
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### **Langkah 3: Build APK**

6. **Clean project**:
```bash
flutter clean
```

7. **Build APK debug** (untuk testing):
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

8. **Build APK release** (untuk publish):
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

9. **Build APK split per ABI** (ukuran lebih kecil):
```bash
flutter build apk --release --split-per-abi
```
Output:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (x86)

### **Langkah 4: Generate Key Store (Untuk signing APK)**

10. **Buka terminal di folder android**:
```bash
cd android
```

11. **Generate keystore**:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Isi informasi yang diminta:
- Password: (simpan dengan aman!)
- Nama: Nama Anda
- Organizational Unit: Departemen
- Organization: Perusahaan
- City: Kota
- State: Provinsi
- Country: Kode negara (ID untuk Indonesia)

12. **Edit `android/key.properties`** (buat file baru):
```properties
storePassword=password_anda
keyPassword=password_anda
keyAlias=upload
storeFile=../upload-keystore.jks
```

13. **Edit `android/app/build.gradle`** tambahkan di bagian atas:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release  // Ganti dengan ini
        }
    }
}
```

14. **Build APK dengan signing**:
```bash
flutter build apk --release
```

### **Langkah 5: Build App Bundle (AAB) untuk Google Play Store**

15. **Build AAB**:
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

16. **Verifikasi AAB**:
```bash
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks
```

### **Langkah 6: Deploy ke Google Play Store**

17. **Daftar di [Google Play Console](https://play.google.com/console)**
18. **Bayar biaya pendaftaran** ($25 sekali)
19. **Buat aplikasi baru**
20. **Upload AAB file** (`app-release.aab`)
21. **Isi metadata**:
   - Deskripsi
   - Screenshot
   - Ikon aplikasi
   - Kategori
   - Konten rating
22. **Setup pricing** (gratis/berbayar)
23. **Submit untuk review** (2-7 hari)

---

## 🌐 **DEPLOY KE NETLIFY (Web Version)**

### **Langkah 1: Persiapan Build Web**

1. **Pastikan support web**:
```bash
flutter doctor
```
Pastikan ada: `Chrome - develop for the web`

2. **Enable web support** (jika belum):
```bash
flutter config --enable-web
```

3. **Build untuk web**:
```bash
flutter build web --release
```
Output: `build/web/`

### **Langkah 2: Optimasi Build Web**

4. **Edit `web/index.html`** untuk SEO:
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta content="width=device-width, initial-scale=1.0" name="viewport">
    <meta name="description" content="Deskripsi aplikasi Anda">
    <meta name="keywords" content="flutter, aplikasi, web">
    <title>Nama Aplikasi Anda</title>
    <link rel="manifest" href="manifest.json">
    <link rel="icon" type="image/png" href="icons/icon-192.png">
    
    <!-- Open Graph -->
    <meta property="og:title" content="Nama Aplikasi">
    <meta property="og:description" content="Deskripsi aplikasi">
    <meta property="og:image" content="icons/icon-512.png">
    <meta property="og:url" content="https://your-app.netlify.app">
    
    <!-- PWA -->
    <link rel="apple-touch-icon" href="icons/icon-192.png">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    
    <!-- Flutter resources -->
    <script src="flutter.js" defer></script>
</head>
<body>
    <script>
        window.addEventListener('load', function(ev) {
            // Download main.dart.js
            _flutter.loader.loadEntrypoint({
                serviceWorker: {
                    serviceWorkerVersion: serviceWorkerVersion,
                }
            }).then(function(engineInitializer) {
                return engineInitializer.initializeEngine();
            }).then(function(appRunner) {
                return appRunner.runApp();
            });
        });
    </script>
</body>
</html>
```

5. **Edit `web/manifest.json`**:
```json
{
  "name": "Nama Aplikasi",
  "short_name": "AppShort",
  "description": "Deskripsi aplikasi",
  "start_url": ".",
  "display": "standalone",
  "theme_color": "#2196F3",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png"
    },
    {
      "src": "icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png"
    },
    {
      "src": "icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png"
    },
    {
      "src": "icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png"
    },
    {
      "src": "icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png"
    },
    {
      "src": "icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png"
    },
    {
      "src": "icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### **Langkah 3: Konfigurasi Firebase untuk Web**

6. **Tambahkan Firebase Web**:
- Buka [Firebase Console](https://console.firebase.google.com/)
- Pilih project
- Klik ⚙️ > Project settings
- Scroll ke "Your apps"
- Klik `</>` untuk tambah web app
- Register app (nama: "web")
- Copy konfigurasi

7. **Edit `web/index.html`** tambahkan sebelum `</body>`:
```html
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-storage.js"></script>

<script>
  const firebaseConfig = {
    apiKey: "AIzaSy...",
    authDomain: "your-app.firebaseapp.com",
    projectId: "your-app",
    storageBucket: "your-app.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef"
  };
  
  // Initialize Firebase
  firebase.initializeApp(firebaseConfig);
</script>
```

8. **Update Firebase Rules untuk web**:
```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}

// Storage Rules
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **Langkah 4: Deploy ke Netlify**

9. **Install Netlify CLI**:
```bash
npm install -g netlify-cli
```

10. **Login ke Netlify**:
```bash
netlify login
```
Akan terbuka browser untuk authorization.

11. **Initialize Netlify di project**:
```bash
netlify init
```
Pilih:
- Create & configure a new site
- Team: Personal (atau pilih team)
- Site name: (biarkan kosong untuk random)

12. **Deploy langsung**:
```bash
netlify deploy --prod --dir=build/web
```

13. **Atau deploy dengan drag & drop**:
- Buka [app.netlify.com](https://app.netlify.com/)
- Drag folder `build/web` ke area deploy
- Tunggu proses selesai

### **Langkah 5: Setup Custom Domain (Opsional)**

14. **Di dashboard Netlify**:
- Site settings > Domain management
- Add custom domain
- Tambahkan domain Anda
- Ikuti instruksi untuk setup DNS

15. **Setup SSL otomatis**:
Netlify akan otomatis generate SSL certificate via Let's Encrypt.

### **Langkah 6: Continuous Deployment (CD)**

16. **Connect dengan GitHub**:
- Di Netlify: Deploys > Link to Git
- Pilih repository
- Configure build settings:
  - Build command: `flutter build web --release`
  - Publish directory: `build/web`
  - Branch: `main`

17. **Setup environment variables** (jika ada):
- Site settings > Environment variables
- Tambahkan:
  - FIREBASE_API_KEY
  - FIREBASE_AUTH_DOMAIN
  - dll

### **Langkah 7: Optimasi Performance Web**

18. **Edit `flutter.js` untuk caching**:
```javascript
// web/flutter.js
{
  serviceWorker: {
    serviceWorkerVersion: serviceWorkerVersion,
    timeoutMillis: 4000,
  }
}
```

19. **Add `_headers` file di `web/`**:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: no-referrer-when-downgrade
  
  # Cache static assets
  /assets/*
    Cache-Control: public, max-age=31536000, immutable
  
  /icons/*
    Cache-Control: public, max-age=31536000, immutable
  
  /version.json
    Cache-Control: no-cache
```

20. **Add `_redirects` file di `web/`**:
```
/*    /index.html   200
```

---

## 📊 **TABEL PERBANDINGAN DEPLOYMENT**

| **Aspek** | **APK (Android)** | **Netlify (Web)** |
|-----------|-------------------|-------------------|
| **Target Platform** | Android devices | Semua browser |
| **Build Command** | `flutter build apk` | `flutter build web` |
| **Output File** | `.apk` atau `.aab` | Folder `build/web/` |
| **Distribution** | Play Store/Manual | URL publik |
| **Update Method** | Upload baru ke Play Store | Auto-deploy via Git |
| **Review Process** | 2-7 hari (Google) | Instant |
| **Cost** | $25 sekali | Free tier available |
| **Analytics** | Play Console | Netlify Analytics |
| **Testing** | Internal/Alpha/Beta | Preview deploy |
| **Size Limit** | 150MB (Play Store) | 100GB bandwidth (free) |

---

## 🚀 **SCRIPT AUTOMASI (VS Code)**

### **1. `deploy_scripts.sh`**
```bash
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Flutter Deployment Script${NC}"
echo "=============================="

# Function to build APK
build_apk() {
    echo -e "${YELLOW}Building APK...${NC}"
    flutter clean
    flutter pub get
    flutter build apk --release
    echo -e "${GREEN}APK built at: build/app/outputs/flutter-apk/app-release.apk${NC}"
}

# Function to build App Bundle
build_aab() {
    echo -e "${YELLOW}Building App Bundle...${NC}"
    flutter clean
    flutter pub get
    flutter build appbundle --release
    echo -e "${GREEN}AAB built at: build/app/outputs/bundle/release/app-release.aab${NC}"
}

# Function to build Web
build_web() {
    echo -e "${YELLOW}Building for Web...${NC}"
    flutter clean
    flutter pub get
    flutter build web --release
    echo -e "${GREEN}Web built at: build/web/${NC}"
}

# Function to deploy to Netlify
deploy_netlify() {
    echo -e "${YELLOW}Deploying to Netlify...${NC}"
    build_web
    netlify deploy --prod --dir=build/web
}

# Menu
echo "Select deployment option:"
echo "1. Build APK"
echo "2. Build App Bundle (AAB)"
echo "3. Build Web"
echo "4. Deploy to Netlify"
echo "5. All (APK + AAB + Web)"
echo -n "Enter choice [1-5]: "
read choice

case $choice in
    1) build_apk ;;
    2) build_aab ;;
    3) build_web ;;
    4) deploy_netlify ;;
    5) 
        build_apk
        build_aab
        build_web
        ;;
    *) echo -e "${RED}Invalid option${NC}" ;;
esac
```

### **2. `package.json` untuk automation**
```json
{
  "name": "flutter-deploy",
  "version": "1.0.0",
  "scripts": {
    "clean": "flutter clean",
    "get": "flutter pub get",
    "analyze": "flutter analyze",
    "test": "flutter test",
    "build:apk": "flutter build apk --release",
    "build:aab": "flutter build appbundle --release",
    "build:web": "flutter build web --release",
    "deploy:netlify": "netlify deploy --prod --dir=build/web",
    "deploy:all": "npm run build:apk && npm run build:aab && npm run build:web"
  }
}
```

### **3. VS Code Tasks (`.vscode/tasks.json`)**
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build APK Release",
      "type": "shell",
      "command": "flutter",
      "args": ["build", "apk", "--release"],
      "group": {
        "kind": "build",
        "isDefault": false
      },
      "problemMatcher": []
    },
    {
      "label": "Build Web Release",
      "type": "shell",
      "command": "flutter",
      "args": ["build", "web", "--release"],
      "group": {
        "kind": "build",
        "isDefault": false
      },
      "problemMatcher": []
    },
    {
      "label": "Deploy to Netlify",
      "type": "shell",
      "command": "netlify",
      "args": ["deploy", "--prod", "--dir=build/web"],
      "group": {
        "kind": "build",
        "isDefault": false
      },
      "dependsOn": ["Build Web Release"],
      "problemMatcher": []
    }
  ]
}
```

---

## 🔧 **TROUBLESHOOTING UMUM**

### **Masalah Build APK:**
```bash
# Error: minSdk version
# Edit android/app/build.gradle
minSdk 21  # Pastikan minimal 21

# Error: MultiDex
# Edit android/app/build.gradle
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### **Masalah Build Web:**
```bash
# Error: CORS Firebase
# Tambahkan di firebase.json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          }
        ]
      }
    ]
  }
}

# Error: Blank screen
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
```

### **Masalah Netlify:**
```bash
# Build fail: File too large
# Add netlify.toml
[build]
  publish = "build/web"
  command = "flutter build web --release"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

# Enable large media
[build.environment]
  FLUTTER_WEB = "true"
```

---

## 📈 **MONITORING SETELAH DEPLOY**

### **Untuk APK:**
1. **Google Play Console**:
   - Statistics > Installs
   - Quality > Crashes & ANRs
   - Reviews > User feedback

2. **Firebase Crashlytics** (tambahkan di pubspec.yaml):
```yaml
firebase_crashlytics: ^3.0.24
```

### **Untuk Netlify:**
1. **Netlify Analytics**:
   - Unique visitors
   - Bandwidth usage
   - Deploy history

2. **Google Analytics** (tambahkan di web/index.html):
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```
- [ ] robots.txt

Dengan panduan ini, Anda bisa deploy aplikasi Flutter ke Android sebagai APK dan ke web via Netlify langsung dari VS Code. Selamat mencoba! 🚀
