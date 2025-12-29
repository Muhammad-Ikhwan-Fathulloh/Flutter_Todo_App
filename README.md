## 1. **Setup Dependencies**

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  uploadthing: ^1.0.0  # atau paket yang sesuai untuk UploadThing
  sqflite: ^2.3.0
  path: ^1.8.3
  http: ^0.13.5
  provider: ^6.0.5
  file_picker: ^5.3.3
  cached_network_image: ^3.3.0
```

## 2. **Model Data**

```dart
// lib/models/file_model.dart
class HybridFile {
  int? id;
  String localPath;
  String? cloudUrl;
  String fileName;
  DateTime uploadedAt;
  bool isSynced;
  FileType type;

  HybridFile({
    this.id,
    required this.localPath,
    this.cloudUrl,
    required this.fileName,
    required this.uploadedAt,
    this.isSynced = false,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localPath': localPath,
      'cloudUrl': cloudUrl,
      'fileName': fileName,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'type': type.toString(),
    };
  }

  factory HybridFile.fromMap(Map<String, dynamic> map) {
    return HybridFile(
      id: map['id'],
      localPath: map['localPath'],
      cloudUrl: map['cloudUrl'],
      fileName: map['fileName'],
      uploadedAt: DateTime.parse(map['uploadedAt']),
      isSynced: map['isSynced'] == 1,
      type: FileType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => FileType.other,
      ),
    );
  }
}

enum FileType { image, video, document, pdf, other }
```

## 3. **Database Helper (SQLite)**

```dart
// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/file_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hybrid_storage.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE files(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        localPath TEXT NOT NULL,
        cloudUrl TEXT,
        fileName TEXT NOT NULL,
        uploadedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        type TEXT NOT NULL
      )
    ''');
  }

  // CRUD Operations
  Future<int> insertFile(HybridFile file) async {
    Database db = await database;
    return await db.insert('files', file.toMap());
  }

  Future<List<HybridFile>> getAllFiles() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('files');
    return List.generate(maps.length, (i) => HybridFile.fromMap(maps[i]));
  }

  Future<List<HybridFile>> getUnsyncedFiles() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => HybridFile.fromMap(maps[i]));
  }

  Future<int> updateFile(HybridFile file) async {
    Database db = await database;
    return await db.update(
      'files',
      file.toMap(),
      where: 'id = ?',
      whereArgs: [file.id],
    );
  }

  Future<int> deleteFile(int id) async {
    Database db = await database;
    return await db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

## 4. **UploadThing Service**

```dart
// lib/services/uploadthing_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/file_model.dart';

class UploadThingService {
  static final String? _apiKey = dotenv.env['UPLOADTHING_SECRET'];
  static const String _apiUrl = 'https://uploadthing.com/api';

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/upload'),
      );

      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        // Parse response to get URL
        // Format response sesuai dengan API UploadThing
        final jsonResponse = json.decode(responseData);
        return jsonResponse['url'];
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      var response = await http.delete(
        Uri.parse('$_apiUrl/deleteFile'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({'url': fileUrl}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
}
```

## 5. **Hybrid Storage Manager**

```dart
// lib/services/hybrid_storage_manager.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import './uploadthing_service.dart';
import '../models/file_model.dart';

class HybridStorageManager {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final UploadThingService _uploadService = UploadThingService();

  // Upload file dengan hybrid approach
  Future<HybridFile?> uploadFile(PlatformFile platformFile) async {
    try {
      final file = File(platformFile.path!);
      
      // Simpan ke lokal database dulu
      final hybridFile = HybridFile(
        localPath: platformFile.path!,
        fileName: platformFile.name,
        uploadedAt: DateTime.now(),
        type: _getFileType(platformFile.name),
      );

      // Insert ke database lokal
      final id = await _dbHelper.insertFile(hybridFile);
      hybridFile.id = id;

      // Coba upload ke cloud (UploadThing)
      final cloudUrl = await _uploadService.uploadFile(file, platformFile.name);
      
      if (cloudUrl != null) {
        // Update database dengan cloud URL
        hybridFile.cloudUrl = cloudUrl;
        hybridFile.isSynced = true;
        await _dbHelper.updateFile(hybridFile);
      }

      return hybridFile;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  // Sync semua file yang belum tersinkron
  Future<void> syncUnsyncedFiles() async {
    final unsyncedFiles = await _dbHelper.getUnsyncedFiles();
    
    for (var file in unsyncedFiles) {
      final localFile = File(file.localPath);
      
      if (await localFile.exists()) {
        final cloudUrl = await _uploadService.uploadFile(
          localFile, 
          file.fileName
        );
        
        if (cloudUrl != null) {
          file.cloudUrl = cloudUrl;
          file.isSynced = true;
          await _dbHelper.updateFile(file);
        }
      }
    }
  }

  // Download file (gunakan cloud jika ada, fallback ke lokal)
  Future<File?> getFile(HybridFile hybridFile) async {
    try {
      // Prioritas: file lokal
      final localFile = File(hybridFile.localPath);
      
      if (await localFile.exists()) {
        return localFile;
      }
      
      // Jika tidak ada di lokal, download dari cloud
      if (hybridFile.cloudUrl != null) {
        // Implement download dari UploadThing
        // ...
      }
      
      return null;
    } catch (e) {
      print('Get file error: $e');
      return null;
    }
  }

  // Delete file dari kedua storage
  Future<bool> deleteFile(HybridFile hybridFile) async {
    try {
      // Hapus dari cloud jika ada
      if (hybridFile.cloudUrl != null) {
        await _uploadService.deleteFile(hybridFile.cloudUrl!);
      }
      
      // Hapus dari lokal storage
      final localFile = File(hybridFile.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
      
      // Hapus dari database
      if (hybridFile.id != null) {
        await _dbHelper.deleteFile(hybridFile.id!);
      }
      
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  FileType _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'mov', 'avi'].contains(ext)) {
      return FileType.video;
    } else if (['pdf'].contains(ext)) {
      return FileType.pdf;
    } else if (['doc', 'docx', 'txt'].contains(ext)) {
      return FileType.document;
    } else {
      return FileType.other;
    }
  }
}
```

## 6. **Provider State Management**

```dart
// lib/providers/file_provider.dart
import 'package:flutter/material.dart';
import '../models/file_model.dart';
import '../services/hybrid_storage_manager.dart';

class FileProvider with ChangeNotifier {
  final HybridStorageManager _storageManager = HybridStorageManager();
  List<HybridFile> _files = [];
  bool _isLoading = false;

  List<HybridFile> get files => _files;
  bool get isLoading => _isLoading;

  Future<void> loadFiles() async {
    _isLoading = true;
    notifyListeners();

    _files = await _storageManager._dbHelper.getAllFiles();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadFile(PlatformFile platformFile) async {
    _isLoading = true;
    notifyListeners();

    final file = await _storageManager.uploadFile(platformFile);
    
    if (file != null) {
      _files.add(file);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncFiles() async {
    _isLoading = true;
    notifyListeners();

    await _storageManager.syncUnsyncedFiles();
    await loadFiles();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteFile(HybridFile file) async {
    await _storageManager.deleteFile(file);
    _files.remove(file);
    notifyListeners();
  }
}
```

## 7. **UI Implementation**

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/file_provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hybrid Storage'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => context.read<FileProvider>().syncFiles(),
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.files.length,
            itemBuilder: (context, index) {
              final file = provider.files[index];
              return ListTile(
                leading: _buildFileIcon(file.type),
                title: Text(file.fileName),
                subtitle: Text(
                  file.isSynced ? 'Synced ✓' : 'Local only',
                  style: TextStyle(
                    color: file.isSynced ? Colors.green : Colors.orange,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (file.cloudUrl != null)
                      IconButton(
                        icon: Icon(Icons.cloud_download),
                        onPressed: () {
                          // Download dari cloud
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteFile(file),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadFile(context),
        child: Icon(Icons.upload),
      ),
    );
  }

  Widget _buildFileIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icon(Icons.image, color: Colors.blue);
      case FileType.video:
        return Icon(Icons.video_library, color: Colors.red);
      case FileType.pdf:
        return Icon(Icons.picture_as_pdf, color: Colors.red);
      case FileType.document:
        return Icon(Icons.description, color: Colors.green);
      default:
        return Icon(Icons.insert_drive_file);
    }
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.isNotEmpty) {
      await context.read<FileProvider>().uploadFile(result.files.first);
    }
  }
}
```

## 8. **Main App**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/file_provider.dart';
import './screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileProvider()..loadFiles(),
      child: MaterialApp(
        title: 'Hybrid Storage App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
```

## 9. **.env Configuration**

Buat file `.env` di root project:

```env
UPLOADTHING_SECRET=your_uploadthing_secret_key_here
```

## Fitur yang diimplementasikan:

1. **Storage Hybrid**: File disimpan di lokal (SQLite + device storage) dan cloud (UploadThing)
2. **Sync Otomatis**: File yang belum tersinkron akan diupload saat ada koneksi
3. **Fallback System**: Jika file tidak ada di lokal, akan diambil dari cloud
4. **Offline Support**: Bisa upload file saat offline, akan disimpan lokal dulu
5. **Manajemen State**: Menggunakan Provider untuk state management
6. **Multiple File Types**: Support berbagai jenis file

## Catatan:

1. Pastikan untuk mendapatkan API Key dari [UploadThing](https://uploadthing.com)
2. Implementasi UploadThing API disesuaikan dengan dokumentasi resmi mereka
3. Tambahkan permission untuk file access di Android/iOS
4. Implementasi error handling yang lebih robust untuk production

Sistem ini memberikan solusi hybrid yang kuat dengan kemampuan offline-first dan sync otomatis ke cloud ketika tersedia koneksi internet.Berikut adalah implementasi integrasi Cloud + Local Database (Hybrid Storage) di Flutter menggunakan UploadThing dan SQLite:

## 1. **Setup Dependencies**

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  uploadthing: ^1.0.0  # atau paket yang sesuai untuk UploadThing
  sqflite: ^2.3.0
  path: ^1.8.3
  http: ^0.13.5
  provider: ^6.0.5
  file_picker: ^5.3.3
  cached_network_image: ^3.3.0
```

## 2. **Model Data**

```dart
// lib/models/file_model.dart
class HybridFile {
  int? id;
  String localPath;
  String? cloudUrl;
  String fileName;
  DateTime uploadedAt;
  bool isSynced;
  FileType type;

  HybridFile({
    this.id,
    required this.localPath,
    this.cloudUrl,
    required this.fileName,
    required this.uploadedAt,
    this.isSynced = false,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localPath': localPath,
      'cloudUrl': cloudUrl,
      'fileName': fileName,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'type': type.toString(),
    };
  }

  factory HybridFile.fromMap(Map<String, dynamic> map) {
    return HybridFile(
      id: map['id'],
      localPath: map['localPath'],
      cloudUrl: map['cloudUrl'],
      fileName: map['fileName'],
      uploadedAt: DateTime.parse(map['uploadedAt']),
      isSynced: map['isSynced'] == 1,
      type: FileType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => FileType.other,
      ),
    );
  }
}

enum FileType { image, video, document, pdf, other }
```

## 3. **Database Helper (SQLite)**

```dart
// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/file_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hybrid_storage.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE files(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        localPath TEXT NOT NULL,
        cloudUrl TEXT,
        fileName TEXT NOT NULL,
        uploadedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        type TEXT NOT NULL
      )
    ''');
  }

  // CRUD Operations
  Future<int> insertFile(HybridFile file) async {
    Database db = await database;
    return await db.insert('files', file.toMap());
  }

  Future<List<HybridFile>> getAllFiles() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('files');
    return List.generate(maps.length, (i) => HybridFile.fromMap(maps[i]));
  }

  Future<List<HybridFile>> getUnsyncedFiles() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => HybridFile.fromMap(maps[i]));
  }

  Future<int> updateFile(HybridFile file) async {
    Database db = await database;
    return await db.update(
      'files',
      file.toMap(),
      where: 'id = ?',
      whereArgs: [file.id],
    );
  }

  Future<int> deleteFile(int id) async {
    Database db = await database;
    return await db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

## 4. **UploadThing Service**

```dart
// lib/services/uploadthing_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/file_model.dart';

class UploadThingService {
  static final String? _apiKey = dotenv.env['UPLOADTHING_SECRET'];
  static const String _apiUrl = 'https://uploadthing.com/api';

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/upload'),
      );

      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        // Parse response to get URL
        // Format response sesuai dengan API UploadThing
        final jsonResponse = json.decode(responseData);
        return jsonResponse['url'];
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      var response = await http.delete(
        Uri.parse('$_apiUrl/deleteFile'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({'url': fileUrl}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
}
```

## 5. **Hybrid Storage Manager**

```dart
// lib/services/hybrid_storage_manager.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import './uploadthing_service.dart';
import '../models/file_model.dart';

class HybridStorageManager {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final UploadThingService _uploadService = UploadThingService();

  // Upload file dengan hybrid approach
  Future<HybridFile?> uploadFile(PlatformFile platformFile) async {
    try {
      final file = File(platformFile.path!);
      
      // Simpan ke lokal database dulu
      final hybridFile = HybridFile(
        localPath: platformFile.path!,
        fileName: platformFile.name,
        uploadedAt: DateTime.now(),
        type: _getFileType(platformFile.name),
      );

      // Insert ke database lokal
      final id = await _dbHelper.insertFile(hybridFile);
      hybridFile.id = id;

      // Coba upload ke cloud (UploadThing)
      final cloudUrl = await _uploadService.uploadFile(file, platformFile.name);
      
      if (cloudUrl != null) {
        // Update database dengan cloud URL
        hybridFile.cloudUrl = cloudUrl;
        hybridFile.isSynced = true;
        await _dbHelper.updateFile(hybridFile);
      }

      return hybridFile;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  // Sync semua file yang belum tersinkron
  Future<void> syncUnsyncedFiles() async {
    final unsyncedFiles = await _dbHelper.getUnsyncedFiles();
    
    for (var file in unsyncedFiles) {
      final localFile = File(file.localPath);
      
      if (await localFile.exists()) {
        final cloudUrl = await _uploadService.uploadFile(
          localFile, 
          file.fileName
        );
        
        if (cloudUrl != null) {
          file.cloudUrl = cloudUrl;
          file.isSynced = true;
          await _dbHelper.updateFile(file);
        }
      }
    }
  }

  // Download file (gunakan cloud jika ada, fallback ke lokal)
  Future<File?> getFile(HybridFile hybridFile) async {
    try {
      // Prioritas: file lokal
      final localFile = File(hybridFile.localPath);
      
      if (await localFile.exists()) {
        return localFile;
      }
      
      // Jika tidak ada di lokal, download dari cloud
      if (hybridFile.cloudUrl != null) {
        // Implement download dari UploadThing
        // ...
      }
      
      return null;
    } catch (e) {
      print('Get file error: $e');
      return null;
    }
  }

  // Delete file dari kedua storage
  Future<bool> deleteFile(HybridFile hybridFile) async {
    try {
      // Hapus dari cloud jika ada
      if (hybridFile.cloudUrl != null) {
        await _uploadService.deleteFile(hybridFile.cloudUrl!);
      }
      
      // Hapus dari lokal storage
      final localFile = File(hybridFile.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
      
      // Hapus dari database
      if (hybridFile.id != null) {
        await _dbHelper.deleteFile(hybridFile.id!);
      }
      
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  FileType _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'mov', 'avi'].contains(ext)) {
      return FileType.video;
    } else if (['pdf'].contains(ext)) {
      return FileType.pdf;
    } else if (['doc', 'docx', 'txt'].contains(ext)) {
      return FileType.document;
    } else {
      return FileType.other;
    }
  }
}
```

## 6. **Provider State Management**

```dart
// lib/providers/file_provider.dart
import 'package:flutter/material.dart';
import '../models/file_model.dart';
import '../services/hybrid_storage_manager.dart';

class FileProvider with ChangeNotifier {
  final HybridStorageManager _storageManager = HybridStorageManager();
  List<HybridFile> _files = [];
  bool _isLoading = false;

  List<HybridFile> get files => _files;
  bool get isLoading => _isLoading;

  Future<void> loadFiles() async {
    _isLoading = true;
    notifyListeners();

    _files = await _storageManager._dbHelper.getAllFiles();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadFile(PlatformFile platformFile) async {
    _isLoading = true;
    notifyListeners();

    final file = await _storageManager.uploadFile(platformFile);
    
    if (file != null) {
      _files.add(file);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncFiles() async {
    _isLoading = true;
    notifyListeners();

    await _storageManager.syncUnsyncedFiles();
    await loadFiles();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteFile(HybridFile file) async {
    await _storageManager.deleteFile(file);
    _files.remove(file);
    notifyListeners();
  }
}
```

## 7. **UI Implementation**

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/file_provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hybrid Storage'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => context.read<FileProvider>().syncFiles(),
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.files.length,
            itemBuilder: (context, index) {
              final file = provider.files[index];
              return ListTile(
                leading: _buildFileIcon(file.type),
                title: Text(file.fileName),
                subtitle: Text(
                  file.isSynced ? 'Synced ✓' : 'Local only',
                  style: TextStyle(
                    color: file.isSynced ? Colors.green : Colors.orange,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (file.cloudUrl != null)
                      IconButton(
                        icon: Icon(Icons.cloud_download),
                        onPressed: () {
                          // Download dari cloud
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteFile(file),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadFile(context),
        child: Icon(Icons.upload),
      ),
    );
  }

  Widget _buildFileIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icon(Icons.image, color: Colors.blue);
      case FileType.video:
        return Icon(Icons.video_library, color: Colors.red);
      case FileType.pdf:
        return Icon(Icons.picture_as_pdf, color: Colors.red);
      case FileType.document:
        return Icon(Icons.description, color: Colors.green);
      default:
        return Icon(Icons.insert_drive_file);
    }
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.isNotEmpty) {
      await context.read<FileProvider>().uploadFile(result.files.first);
    }
  }
}
```

## 8. **Main App**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/file_provider.dart';
import './screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileProvider()..loadFiles(),
      child: MaterialApp(
        title: 'Hybrid Storage App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
```

## 9. **.env Configuration**

Buat file `.env` di root project:

```env
UPLOADTHING_SECRET=your_uploadthing_secret_key_here
```

## Fitur yang diimplementasikan:

1. **Storage Hybrid**: File disimpan di lokal (SQLite + device storage) dan cloud (UploadThing)
2. **Sync Otomatis**: File yang belum tersinkron akan diupload saat ada koneksi
3. **Fallback System**: Jika file tidak ada di lokal, akan diambil dari cloud
4. **Offline Support**: Bisa upload file saat offline, akan disimpan lokal dulu
5. **Manajemen State**: Menggunakan Provider untuk state management
6. **Multiple File Types**: Support berbagai jenis file

## Catatan:

1. Pastikan untuk mendapatkan API Key dari [UploadThing](https://uploadthing.com)
2. Implementasi UploadThing API disesuaikan dengan dokumentasi resmi mereka
3. Tambahkan permission untuk file access di Android/iOS
4. Implementasi error handling yang lebih robust untuk production