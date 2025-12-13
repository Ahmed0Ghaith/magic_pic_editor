import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const ImageEditorApp());
}

class ImageEditorApp extends StatelessWidget {
  const ImageEditorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ImageEditorHome(),
    );
  }
}

class ImageEditorHome extends StatefulWidget {
  const ImageEditorHome({Key? key}) : super(key: key);

  @override
  State<ImageEditorHome> createState() => _ImageEditorHomeState();
}

class _ImageEditorHomeState extends State<ImageEditorHome> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _selectedFilter = 'None';
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  final GlobalKey _globalKey = GlobalKey();

  final List<String> _filters = [
    'None',
    'Grayscale',
    'Sepia',
    'Vintage',
    'Cool',
    'Warm',
    'High Contrast',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _resetFilters();
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = 'None';
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.png';
      File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to: $imagePath')),
        );
      }
    } catch (e) {
      _showError('Error saving image: $e');
    }
  }

  ColorFilter? _getColorFilter() {
    switch (_selectedFilter) {
      case 'Grayscale':
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Sepia':
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Vintage':
        return const ColorFilter.matrix([
          0.6, 0.3, 0.1, 0, 0,
          0.2, 0.7, 0.1, 0, 0,
          0.2, 0.3, 0.5, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Cool':
        return const ColorFilter.matrix([
          0.8, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Warm':
        return const ColorFilter.matrix([
          1.2, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'High Contrast':
        return const ColorFilter.matrix([
          1.5, 0, 0, 0, -50,
          0, 1.5, 0, 0, -50,
          0, 0, 1.5, 0, -50,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null;
    }
  }

  Widget _buildImageDisplay() {
    if (_image == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No image selected',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _globalKey,
      child: ColorFiltered(
        colorFilter: _getColorFilter() ??
            const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix([
            _contrast, 0, 0, 0, _brightness * 255,
            0, _contrast, 0, 0, _brightness * 255,
            0, 0, _contrast, 0, _brightness * 255,
            0, 0, 0, 1, 0,
          ]),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              0.213 + 0.787 * _saturation, 0.715 - 0.715 * _saturation, 0.072 - 0.072 * _saturation, 0, 0,
              0.213 - 0.213 * _saturation, 0.715 + 0.285 * _saturation, 0.072 - 0.072 * _saturation, 0, 0,
              0.213 - 0.213 * _saturation, 0.715 - 0.715 * _saturation, 0.072 + 0.928 * _saturation, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _image!,
                fit: BoxFit.contain,
                height: 400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        actions: [
          if (_image != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveImage,
              tooltip: 'Save Image',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageDisplay(),
            const SizedBox(height: 24),
            if (_image != null) ...[
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Adjustments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSlider('Brightness', _brightness, -1.0, 1.0, (val) {
                setState(() => _brightness = val);
              }),
              _buildSlider('Contrast', _contrast, 0.0, 2.0, (val) {
                setState(() => _contrast = val);
              }),
              _buildSlider('Saturation', _saturation, 0.0, 2.0, (val) {
                setState(() => _saturation = val);
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: () => _pickImage(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}