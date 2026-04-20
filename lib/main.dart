import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '证件照制作',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const IdPhotoPage(),
    );
  }
}

class IdPhotoPage extends StatefulWidget {
  const IdPhotoPage({super.key});

  @override
  State<IdPhotoPage> createState() => _IdPhotoPageState();
}

class _IdPhotoPageState extends State<IdPhotoPage> {
  File? _imageFile;
  Color _bgColor = Colors.white;

  final List<Map<String, dynamic>> _sizes = [
    {"name": "一寸照", "width": 295, "height": 413},
    {"name": "二寸照", "width": 413, "height": 531},
    {"name": "护照照", "width": 354, "height": 472},
  ];

  Map<String, dynamic>? _selectedSize;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      _cropImage(File(pickedFile.path));
    }
  }

  Future<void> _cropImage(File image) async {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择证件照尺寸')),
      );
      return;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: CropAspectRatio(
        ratioX: _selectedSize!["width"].toDouble(),
        ratioY: _selectedSize!["height"].toDouble(),
      ),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪证件照',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: '裁剪证件照'),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }

  Future<void> _changeBackground() async {
    if (_imageFile == null) return;

    final imageBytes = await _imageFile!.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return;

    final newImage = img.Image(
      width: originalImage.width,
      height: originalImage.height,
      backgroundColor: img.ColorRgba8(
        (_bgColor.r * 255).round(),
        (_bgColor.g * 255).round(),
        (_bgColor.b * 255).round(),
        (_bgColor.a * 255).round(),
      ),
    );

    img.compositeImage(newImage, originalImage);

    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/id_photo_new.png';
    await File(tempPath).writeAsBytes(img.encodePng(newImage));

    setState(() {
      _imageFile = File(tempPath);
    });
  }

  void _selectColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择背景色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _bgColor,
            onColorChanged: (color) => setState(() => _bgColor = color),
            labelTypes: [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('证件照制作工具')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sizes.length,
                itemBuilder: (context, index) {
                  final size = _sizes[index];
                  final isSelected = _selectedSize == size;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                        foregroundColor: isSelected ? Colors.white : Colors.black,
                      ),
                      onPressed: () => setState(() {
                        _selectedSize = size;
                      }),
                      child: Text(size["name"]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _imageFile == null
                  ? const Center(child: Text('请选择/拍摄照片并裁剪'))
                  : Image.file(_imageFile!),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Row(
                    children: [Icon(Icons.camera_alt), Text('拍照')],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: const Row(
                    children: [Icon(Icons.photo_library), Text('选图')],
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectColor,
                  child: const Row(
                    children: [Icon(Icons.color_lens), Text('换背景')],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _changeBackground,
              child: const Text('生成证件照'),
            ),
          ],
        ),
      ),
    );
  }
}