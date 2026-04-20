import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'US ID Photo Maker',
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

// 美国官方证件标准 2×2 inch 600×600
class UsPhotoRule {
  static const int photoW = 600;
  static const int photoH = 600;

  static const Color whiteBg = Color(0xFFFFFFFF);
  static const Color blueBg = Color(0xFF4A90E2);
  static const Color redBg = Color(0xFFE53E3E);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _sourceImage;
  File? _resultImage;
  Color _curBg = UsPhotoRule.whiteBg;

  // 选择图片
  Future<void> pickImage(ImageSource source) async {
    final XFile? xFile = await _picker.pickImage(source: source);
    if (xFile == null) return;
    setState(() {
      _sourceImage = File(xFile.path);
      _resultImage = null;
    });
  }

  // 生成美国标准证件照
  Future<void> generateIdPhoto() async {
    if (_sourceImage == null) return;
    _showLoading();

    final bytes = await _sourceImage!.readAsBytes();
    final origin = img.decodeImage(bytes);
    if (origin == null) {
      _closeLoading();
      return;
    }

    // 固定美区尺寸
    final resized = img.copyResize(
      origin,
      width: UsPhotoRule.photoW,
      height: UsPhotoRule.photoH,
    );

    // 纯色背景画布
    final bgCanvas = img.Image(UsPhotoRule.photoW, UsPhotoRule.photoH);
    bgCanvas.fill(
      img.ColorRgba(
        _curBg.red,
        _curBg.green,
        _curBg.blue,
        255,
      ),
    );

    // 合成
    img.compositeImage(bgCanvas, resized);

    // 写入临时文件
    final tempDir = await getTemporaryDirectory();
    final saveFile = File("${tempDir.path}/us_id_photo_result.png");
    await saveFile.writeAsBytes(img.encodePng(bgCanvas));

    setState(() => _resultImage = saveFile);
    _closeLoading();
  }

  // 保存相册
  Future<void> saveToAlbum() async {
    if (_resultImage == null) return;
    await GallerySaver.saveImage(_resultImage!.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Save Success")),
      );
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _closeLoading() {
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("USA ID Photo")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _curBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _resultImage != null
                    ? Image.file(_resultImage!, fit: BoxFit.contain)
                    : _sourceImage != null
                        ? Image.file(_sourceImage!, fit: BoxFit.contain)
                        : const Center(child: Text("Select photo")),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bgBtn("White", UsPhotoRule.whiteBg),
                _bgBtn("Blue", UsPhotoRule.blueBg),
                _bgBtn("Red", UsPhotoRule.redBg),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Column(
                gap: 10,
                children: [
                  ElevatedButton(
                    onPressed: () => pickImage(ImageSource.camera),
                    child: const Text("Take Photo"),
                  ),
                  ElevatedButton(
                    onPressed: () => pickImage(ImageSource.gallery),
                    child: const Text("Gallery"),
                  ),
                  ElevatedButton(
                    onPressed: generateIdPhoto,
                    child: const Text("Generate US ID"),
                  ),
                  ElevatedButton(
                    onPressed: saveToAlbum,
                    child: const Text("Save"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _bgBtn(String text, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _curBg = color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black)),
      ),
    );
  }
}