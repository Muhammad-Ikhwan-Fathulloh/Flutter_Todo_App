## 📁 **STRUKTUR PROYEK 1: Firebase + Gemini API Chat App**

### **1. Struktur Folder**
```
lib/
 ┣ config/
 ┃ ┗ gemini_config.dart      # Konfigurasi API key
 ┣ models/
 ┃ ┗ chat_model.dart         # Model data chat
 ┣ services/
 ┃ ┣ gemini_service.dart     # Service Gemini API
 ┃ ┗ firebase_service.dart   # Service Firebase Auth & Firestore
 ┣ blocs/
 ┃ ┣ auth_cubit.dart        # Authentication logic
 ┃ ┗ chat_cubit.dart        # Chat logic
 ┣ pages/
 ┃ ┣ login_page.dart        # Halaman login
 ┃ ┣ register_page.dart     # Halaman register
 ┃ ┗ chat_page.dart         # Halaman chat
 ┣ widgets/
 ┃ ┗ chat_bubble.dart       # Widget bubble chat
 ┗ main.dart                # Entry point
```

### **2. pubspec.yaml**
```yaml
name: gemini_chat_app
description: Chat App with Gemini AI
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.13.1
  cloud_firestore: ^4.15.1
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  # Gemini AI - https://pub.dev/packages/google_generative_ai
  google_generative_ai: ^0.2.2
  # UI
  intl: ^0.18.1
  flutter_dotenv: ^5.1.0
  # Loading
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### **3. config/gemini_config.dart**
```dart
class GeminiConfig {
  static const String apiKey = 'YOUR_GEMINI_API_KEY'; // Ganti dengan API key Anda
  static const String modelName = 'gemini-pro';
  static const double temperature = 0.7;
  static const int maxOutputTokens = 1000;
}
```

### **4. models/chat_model.dart**
```dart
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? userId;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? true,
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'],
    );
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      title: map['title'] ?? 'New Chat',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      userId: map['userId'] ?? '',
    );
  }
}
```

### **5. services/gemini_service.dart**
```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: GeminiConfig.modelName,
          apiKey: GeminiConfig.apiKey,
          generationConfig: GenerationConfig(
            temperature: GeminiConfig.temperature,
            maxOutputTokens: GeminiConfig.maxOutputTokens,
          ),
        );

  Future<String> generateResponse(String prompt) async {
    try {
      final content = Content.text(prompt);
      final response = await _model.generateContent([content]);
      return response.text ?? 'Maaf, saya tidak dapat memproses permintaan ini.';
    } catch (e) {
      throw Exception('Gagal menghubungi Gemini AI: $e');
    }
  }

  Future<Stream<String>> generateStreamResponse(String prompt) async {
    try {
      final content = Content.text(prompt);
      final response = _model.generateContentStream([content]);
      
      final streamController = StreamController<String>();
      
      response.listen(
        (content) {
          if (content.text != null) {
            streamController.add(content.text!);
          }
        },
        onDone: () => streamController.close(),
        onError: (error) => streamController.addError(error),
      );
      
      return streamController.stream;
    } catch (e) {
      throw Exception('Gagal membuat stream response: $e');
    }
  }
}
```

### **6. services/firebase_service.dart**
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<User?> register(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': DateTime.now(),
        });
      }
      
      return result.user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Chat Operations
  Future<ChatSession> createChatSession(String userId, String title) async {
    final sessionRef = _firestore.collection('chatSessions').doc();
    final session = ChatSession(
      id: sessionRef.id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
    );
    
    await sessionRef.set(session.toMap());
    return session;
  }

  Future<void> saveMessage(ChatSession session, ChatMessage message) async {
    await _firestore
        .collection('chatSessions')
        .doc(session.id)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
    
    // Update session updatedAt
    await _firestore.collection('chatSessions').doc(session.id).update({
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<ChatSession>> getChatSessions(String userId) {
    return _firestore
        .collection('chatSessions')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  Stream<List<ChatMessage>> getChatMessages(String sessionId) {
    return _firestore
        .collection('chatSessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }
}
```

### **7. blocs/chat_cubit.dart**
```dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../models/chat_model.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GeminiService _geminiService;
  final FirebaseService _firebaseService;
  ChatSession? _currentSession;

  ChatCubit({
    required GeminiService geminiService,
    required FirebaseService firebaseService,
  })  : _geminiService = geminiService,
        _firebaseService = firebaseService,
        super(ChatInitial());

  Future<void> createNewChat(String userId, String initialMessage) async {
    try {
      emit(ChatLoading());
      
      _currentSession = await _firebaseService.createChatSession(
        userId,
        initialMessage.length > 30 
          ? '${initialMessage.substring(0, 30)}...' 
          : initialMessage,
      );
      
      // Save user message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: initialMessage,
        isUser: true,
        timestamp: DateTime.now(),
        userId: userId,
      );
      
      await _firebaseService.saveMessage(_currentSession!, userMessage);
      
      // Generate AI response
      emit(ChatStreaming());
      final response = await _geminiService.generateResponse(initialMessage);
      
      // Save AI response
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        userId: userId,
      );
      
      await _firebaseService.saveMessage(_currentSession!, aiMessage);
      
      emit(ChatSuccess(
        session: _currentSession!,
        messages: [userMessage, aiMessage],
      ));
      
    } catch (e) {
      emit(ChatError(message: 'Failed to create chat: $e'));
    }
  }

  Future<void> sendMessage(String message, String userId) async {
    try {
      if (_currentSession == null) {
        await createNewChat(userId, message);
        return;
      }
      
      emit(ChatLoading());
      
      // Save user message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        userId: userId,
      );
      
      await _firebaseService.saveMessage(_currentSession!, userMessage);
      
      // Get current state
      final currentState = state;
      List<ChatMessage> currentMessages = [];
      
      if (currentState is ChatSuccess) {
        currentMessages = currentState.messages;
      }
      
      // Generate AI response
      emit(ChatStreaming());
      final response = await _geminiService.generateResponse(message);
      
      // Save AI response
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        userId: userId,
      );
      
      await _firebaseService.saveMessage(_currentSession!, aiMessage);
      
      emit(ChatSuccess(
        session: _currentSession!,
        messages: [...currentMessages, userMessage, aiMessage],
      ));
      
    } catch (e) {
      emit(ChatError(message: 'Failed to send message: $e'));
    }
  }

  Future<void> loadChatSession(ChatSession session) async {
    try {
      emit(ChatLoading());
      _currentSession = session;
      
      final messagesStream = _firebaseService.getChatMessages(session.id);
      
      messagesStream.listen((messages) {
        emit(ChatSuccess(
          session: session,
          messages: messages,
        ));
      });
      
    } catch (e) {
      emit(ChatError(message: 'Failed to load chat: $e'));
    }
  }

  Stream<String> streamMessageResponse(String message) async* {
    try {
      final stream = await _geminiService.generateStreamResponse(message);
      await for (final chunk in stream) {
        yield chunk;
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }
}
```

### **8. pages/chat_page.dart** (Contoh)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chat_cubit.dart';
import '../models/chat_model.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  
  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Chat'),
        actions: [
          TextButton(
            onPressed: () {
              // New chat action
              context.read<ChatCubit>().emit(ChatInitial());
            },
            child: const Text('New Chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is ChatInitial) {
                  return const Center(
                    child: Text('Start a new conversation with Gemini AI'),
                  );
                }
                
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is ChatSuccess) {
                  final messages = state.messages;
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatBubble(
                        message: message.content,
                        isUser: message.isUser,
                        timestamp: message.timestamp,
                      );
                    },
                  );
                }
                
                if (state is ChatStreaming) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Gemini is thinking...'),
                      ],
                    ),
                  );
                }
                
                if (state is ChatError) {
                  return Center(
                    child: Text(state.message),
                  );
                }
                
                return Container();
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 10),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              return IconButton(
                onPressed: state is ChatLoading || state is ChatStreaming
                    ? null
                    : () {
                        final message = _messageController.text.trim();
                        if (message.isNotEmpty) {
                          context.read<ChatCubit>().sendMessage(message, widget.userId);
                          _messageController.clear();
                        }
                      },
                icon: const Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

## 📁 **STRUKTUR PROYEK 2: Firebase + Teachable Machine Image Classifier**

### **1. Struktur Folder**
```
lib/
 ┣ models/
 ┃ ┣ classification_model.dart  # Model hasil klasifikasi
 ┃ ┣ tm_model.dart             # Model Teachable Machine
 ┃ ┗ user_model.dart           # Model user
 ┣ services/
 ┃ ┣ teachable_machine_service.dart  # Service TM
 ┃ ┣ firebase_storage_service.dart   # Firebase Storage
 ┃ ┗ firebase_firestore_service.dart # Firestore
 ┣ blocs/
 ┃ ┣ auth_cubit.dart           # Authentication
 ┃ ┣ classification_cubit.dart # Klasifikasi gambar
 ┃ ┗ history_cubit.dart        # Riwayat klasifikasi
 ┣ pages/
 ┃ ┣ login_page.dart
 ┃ ┣ register_page.dart
 ┃ ┣ home_page.dart           # Home dengan kamera/gallery
 ┃ ┣ classification_page.dart # Hasil klasifikasi
 ┃ ┗ history_page.dart        # Riwayat
 ┣ widgets/
 ┃ ┣ image_picker_widget.dart
 ┃ ┣ camera_widget.dart
 ┃ ┣ classification_result_widget.dart
 ┃ ┗ history_item_widget.dart
 ┗ main.dart
```

### **2. pubspec.yaml**
```yaml
name: image_classifier_app
description: Image Classifier with Teachable Machine
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.13.1
  cloud_firestore: ^4.15.1
  firebase_storage: ^11.2.4
  # Teachable Machine
  tflite_flutter: ^0.10.0
  image_picker: ^1.0.4
  image: ^4.1.4
  # Camera
  camera: ^0.10.5+3
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  # UI
  carousel_slider: ^4.2.1
  flutter_charts: ^0.3.2
  # Permissions
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### **3. models/tm_model.dart**
```dart
class TMModelConfig {
  final String modelPath;
  final String labelsPath;
  final int inputSize;
  final List<String> labels;

  TMModelConfig({
    required this.modelPath,
    required this.labelsPath,
    required this.inputSize,
    required this.labels,
  });
}

class TeachableMachineModel {
  static final TMModelConfig foodClassifier = TMModelConfig(
    modelPath: 'assets/models/food_model.tflite',
    labelsPath: 'assets/models/food_labels.txt',
    inputSize: 224,
    labels: [
      'Pizza',
      'Burger',
      'Sushi',
      'Salad',
      'Pasta',
      'Steak',
      'Rice',
      'Soup',
    ],
  );

  static final TMModelConfig plantClassifier = TMModelConfig(
    modelPath: 'assets/models/plant_model.tflite',
    labelsPath: 'assets/models/plant_labels.txt',
    inputSize: 299,
    labels: [
      'Rose',
      'Tulip',
      'Sunflower',
      'Lily',
      'Orchid',
      'Cactus',
      'Fern',
      'Palm',
    ],
  );
}
```

### **4. services/teachable_machine_service.dart**
```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/tm_model.dart';

class TeachableMachineService {
  late Interpreter _interpreter;
  late List<String> _labels;
  int _inputSize = 224;

  Future<void> loadModel(TMModelConfig config) async {
    try {
      // Load model
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(config.modelPath, options: interpreterOptions);
      
      // Load labels
      final labelData = await rootBundle.loadString(config.labelsPath);
      _labels = labelData.split('\n');
      
      _inputSize = config.inputSize;
      
      print('Model loaded successfully');
      print('Input size: $_inputSize');
      print('Labels: $_labels');
      
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<Map<String, double>> classifyImage(File imageFile) async {
    try {
      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize image
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );
      
      // Convert to float32 array
      final input = _imageToByteList(resizedImage);
      
      // Run inference
      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter.run(input, output);
      
      // Get results
      final results = <String, double>{};
      for (int i = 0; i < _labels.length; i++) {
        results[_labels[i]] = output[0][i].toDouble();
      }
      
      // Sort by confidence
      final sortedResults = Map.fromEntries(
        results.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
      );
      
      return sortedResults;
      
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  Future<Map<String, double>> classifyImageFromBytes(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize image
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );
      
      // Convert to float32 array
      final input = _imageToByteList(resizedImage);
      
      // Run inference
      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter.run(input, output);
      
      // Get results
      final results = <String, double>{};
      for (int i = 0; i < _labels.length; i++) {
        results[_labels[i]] = output[0][i].toDouble();
      }
      
      // Sort by confidence
      final sortedResults = Map.fromEntries(
        results.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
      );
      
      return sortedResults;
      
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  Float32List _imageToByteList(img.Image image) {
    final convertedBytes = Float32List(_inputSize * _inputSize * 3);
    final pixelValues = image.getBytes();
    
    int pixelIndex = 0;
    for (int i = 0; i < _inputSize; i++) {
      for (int j = 0; j < _inputSize; j++) {
        final pixel = pixelValues[pixelIndex++];
        
        // Normalize pixel values to [-1, 1]
        convertedBytes[(i * _inputSize + j) * 3 + 0] = (pixel[0] - 127.5) / 127.5;
        convertedBytes[(i * _inputSize + j) * 3 + 1] = (pixel[1] - 127.5) / 127.5;
        convertedBytes[(i * _inputSize + j) * 3 + 2] = (pixel[2] - 127.5) / 127.5;
      }
    }
    
    return convertedBytes;
  }

  void dispose() {
    _interpreter.close();
  }
}
```

### **5. models/classification_model.dart**
```dart
class ClassificationResult {
  final String id;
  final String imageUrl;
  final String imagePath;
  final Map<String, double> predictions;
  final String topPrediction;
  final double confidence;
  final DateTime timestamp;
  final String userId;
  final String modelType;

  ClassificationResult({
    required this.id,
    required this.imageUrl,
    required this.imagePath,
    required this.predictions,
    required this.topPrediction,
    required this.confidence,
    required this.timestamp,
    required this.userId,
    required this.modelType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'predictions': predictions,
      'topPrediction': topPrediction,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'modelType': modelType,
    };
  }

  factory ClassificationResult.fromMap(Map<String, dynamic> map) {
    return ClassificationResult(
      id: map['id'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imagePath: map['imagePath'] ?? '',
      predictions: Map<String, double>.from(map['predictions'] ?? {}),
      topPrediction: map['topPrediction'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'] ?? '',
      modelType: map['modelType'] ?? '',
    );
  }
}

class ClassificationHistory {
  final List<ClassificationResult> results;
  final int totalCount;

  ClassificationHistory({
    required this.results,
    required this.totalCount,
  });
}
```

### **6. blocs/classification_cubit.dart**
```dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../models/classification_model.dart';
import '../services/teachable_machine_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/firebase_firestore_service.dart';

part 'classification_state.dart';

class ClassificationCubit extends Cubit<ClassificationState> {
  final TeachableMachineService _tmService;
  final FirebaseStorageService _storageService;
  final FirebaseFirestoreService _firestoreService;
  
  ClassificationCubit({
    required TeachableMachineService tmService,
    required FirebaseStorageService storageService,
    required FirebaseFirestoreService firestoreService,
  })  : _tmService = tmService,
        _storageService = storageService,
        _firestoreService = firestoreService,
        super(ClassificationInitial());

  Future<void> classifyImage(
    File imageFile, 
    String userId, 
    String modelType,
  ) async {
    try {
      emit(ClassificationLoading());
      
      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadImage(
        imageFile,
        userId,
        'classifications',
      );
      
      // Classify image
      final predictions = await _tmService.classifyImage(imageFile);
      
      // Get top prediction
      final topPrediction = predictions.keys.first;
      final confidence = predictions.values.first;
      
      // Create classification result
      final result = ClassificationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        imagePath: imageFile.path,
        predictions: predictions,
        topPrediction: topPrediction,
        confidence: confidence,
        timestamp: DateTime.now(),
        userId: userId,
        modelType: modelType,
      );
      
      // Save to Firestore
      await _firestoreService.saveClassification(result);
      
      emit(ClassificationSuccess(result: result));
      
    } catch (e) {
      emit(ClassificationError(message: 'Classification failed: $e'));
    }
  }

  Future<void> classifyImageFromBytes(
    List<int> imageBytes,
    String userId,
    String modelType,
  ) async {
    try {
      emit(ClassificationLoading());
      
      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadImageBytes(
        Uint8List.fromList(imageBytes),
        userId,
        'classifications',
      );
      
      // Classify image
      final predictions = await _tmService.classifyImageFromBytes(
        Uint8List.fromList(imageBytes),
      );
      
      // Get top prediction
      final topPrediction = predictions.keys.first;
      final confidence = predictions.values.first;
      
      // Create classification result
      final result = ClassificationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        imagePath: 'camera_capture',
        predictions: predictions,
        topPrediction: topPrediction,
        confidence: confidence,
        timestamp: DateTime.now(),
        userId: userId,
        modelType: modelType,
      );
      
      // Save to Firestore
      await _firestoreService.saveClassification(result);
      
      emit(ClassificationSuccess(result: result));
      
    } catch (e) {
      emit(ClassificationError(message: 'Classification failed: $e'));
    }
  }

  Future<void> loadModel(String modelType) async {
    try {
      emit(ModelLoading());
      
      // Load appropriate model based on type
      final modelConfig = modelType == 'food' 
        ? TeachableMachineModel.foodClassifier
        : TeachableMachineModel.plantClassifier;
      
      await _tmService.loadModel(modelConfig);
      
      emit(ModelLoaded(modelType: modelType));
      
    } catch (e) {
      emit(ClassificationError(message: 'Failed to load model: $e'));
    }
  }
}
```

### **7. widgets/camera_widget.dart**
```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CameraWidget extends StatefulWidget {
  final Function(List<int> imageBytes) onImageCaptured;
  
  const CameraWidget({super.key, required this.onImageCaptured});

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      
      final image = await _controller.takePicture();
      final imageBytes = await image.readAsBytes();
      
      widget.onImageCaptured(imageBytes);
      
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _controller.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  void _switchCamera() async {
    final cameras = await availableCameras();
    final newCamera = _controller.description.lensDirection == 
        CameraLensDirection.back
        ? cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front)
        : cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back);

    await _controller.dispose();
    
    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
    );
    
    await _controller.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Text('Close'),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _toggleFlash,
                            icon: Text(_isFlashOn ? 'Flash On' : 'Flash Off'),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: _switchCamera,
                            icon: const Text('Switch Camera'),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Text('Capture'),
      ),
    );
  }
}
```

### **8. pages/home_page.dart** (Contoh)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/classification_cubit.dart';
import '../widgets/camera_widget.dart';

class HomePage extends StatefulWidget {
  final String userId;
  
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedModel = 'food';

  @override
  void initState() {
    super.initState();
    // Load default model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassificationCubit>().loadModel(_selectedModel);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      
      // Classify image
      context.read<ClassificationCubit>().classifyImageFromBytes(
        bytes,
        widget.userId,
        _selectedModel,
      );
    }
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraWidget(
          onImageCaptured: (imageBytes) {
            Navigator.pop(context);
            
            // Classify captured image
            context.read<ClassificationCubit>().classifyImageFromBytes(
              imageBytes,
              widget.userId,
              _selectedModel,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Classifier'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedModel = value;
              });
              context.read<ClassificationCubit>().loadModel(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'food',
                child: Text('Food Classifier'),
              ),
              const PopupMenuItem(
                value: 'plant',
                child: Text('Plant Classifier'),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<ClassificationCubit, ClassificationState>(
        builder: (context, state) {
          if (state is ModelLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is ClassificationLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Classifying image...'),
                ],
              ),
            );
          }
          
          if (state is ClassificationSuccess) {
            // Navigate to results page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(
                context,
                '/classification',
                arguments: state.result,
              );
            });
          }
          
          if (state is ClassificationError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Selected Model: ${_selectedModel.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: 'Gallery',
                      label: 'Gallery',
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: 'Camera',
                      label: 'Camera',
                      onPressed: _openCamera,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                  child: const Text('View History'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(40),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Text(
              icon,
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
```

### **9. assets/ folder structure**
```
assets/
 ┣ models/
 ┃ ┣ food_model.tflite      # Model dari Teachable Machine
 ┃ ┣ food_labels.txt        # Label untuk food model
 ┃ ┣ plant_model.tflite     # Model dari Teachable Machine  
 ┃ ┗ plant_labels.txt       # Label untuk plant model
 ┗ images/
   ┗ placeholder.png
```

## 📋 **CARA MENGGUNAKAN**

### **Untuk Konsep 1 (Gemini API):**
1. Dapatkan API Key dari [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Ganti `YOUR_GEMINI_API_KEY` di `gemini_config.dart`
3. Jalankan `flutter pub get`
4. Konfigurasi Firebase
5. Jalankan `flutter run`

### **Untuk Konsep 2 (Teachable Machine):**
1. Buat model di [Teachable Machine](https://teachablemachine.withgoogle.com/)
2. Export model sebagai TensorFlow Lite
3. Letakkan file `.tflite` dan `labels.txt` di `assets/models/`
4. Update `pubspec.yaml` dengan path assets:
```yaml
flutter:
  assets:
    - assets/models/
    - assets/images/
```
5. Jalankan `flutter pub get`
6. Konfigurasi Firebase
7. Jalankan `flutter run`

## 🔗 **Link Package yang Diperlukan:**

### **Untuk Gemini API:**
- [google_generative_ai](https://pub.dev/packages/google_generative_ai) - Integrasi Gemini AI
- [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) - Environment variables

### **Untuk Teachable Machine:**
- [tflite_flutter](https://pub.dev/packages/tflite_flutter) - TensorFlow Lite
- [image_picker](https://pub.dev/packages/image_picker) - Pilih gambar
- [camera](https://pub.dev/packages/camera) - Akses kamera
- [image](https://pub.dev/packages/image) - Image processing
- [permission_handler](https://pub.dev/packages/permission_handler) - Permission handling
| **Cost** | API calls | Free (self-trained) |

Pilih konsep sesuai kebutuhan aplikasi Anda!
