import 'package:flutter/material.dart';
import '../services/document_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
final DocumentService _documentService = DocumentService();
@override
void initState() {
  super.initState();
  _loadDocuments();
}
Future<void> _loadDocuments() async {
  try {
    debugPrint("Loading documents...");

    final documents = await _documentService.getDocuments();

    debugPrint("Found ${documents.length} documents");

    for (final document in documents) {
      debugPrint(document.name);
      debugPrint(document.uri);
    }
  } catch (e, stackTrace) {
    debugPrint("Error: $e");
    debugPrint(stackTrace.toString());
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EasyDocs"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search documents...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.description_outlined,
                      size: 72,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 20),

                    Text(
                      "No documents found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 8),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Your documents will appear here after scanning your device.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}