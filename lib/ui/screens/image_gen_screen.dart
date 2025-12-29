import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({Key? key}) : super(key: key);

  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<String> _generatedImages = [];
  late AnimationController _animationController;

  // DeepAI API key
  final String _apiKey = "e37f4c1b-b537-4258-9f56-d5b5f71aa643";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Function to call DeepAI Text-to-Image API
  Future<void> _generateImages(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.deepai.org/api/text2img'),
        headers: {
          'api-key': _apiKey,
        },
        body: {
          'text': prompt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // DeepAI returns output_url inside 'output' list
        if (data['output'] != null && data['output'] is List && data['output'].isNotEmpty) {
          final String imageUrl = data['output'][0];
          setState(() {
            _generatedImages.insert(0, imageUrl);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No image URL returned from API.")),
          );
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unauthorized: Check your API key.")),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate image: ${errorData['err'] ?? response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Share image
  Future<void> _shareImage(String url) async {
    await Share.share(url, subject: "Check out this generated image!");
  }

  Widget _buildPromptInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: "Enter a prompt to generate an image...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _generateImages(_promptController.text),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Generate"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading.json',
        width: 150,
        height: 150,
        controller: _animationController,
        onLoaded: (composition) {
          _animationController
            ..duration = composition.duration
            ..repeat();
        },
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImageDialog(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 400,
                    color: Colors.grey.shade300,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _shareImage(imageUrl),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedImagesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GridView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _generatedImages.length,
        itemBuilder: (context, index) => _buildImageCard(_generatedImages[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty.json', width: 200, height: 200),
          const SizedBox(height: 20),
          const Text(
            "No images generated yet.\nEnter a prompt and create magic!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text("AI Image Generator"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        children: [
          _buildPromptInput(),
          Expanded(
            child: _isLoading
                ? _buildLoader()
                : _generatedImages.isEmpty
                    ? _buildEmptyState()
                    : _buildGeneratedImagesGrid(),
          ),
        ],
      ),
    );
  }
}
