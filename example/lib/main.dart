import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_super_resolution/flutter_super_resolution.dart';

void main() {
  runApp(SuperResolutionDemoApp());
}

class SuperResolutionDemoApp extends StatefulWidget {
  @override
  _SuperResolutionDemoAppState createState() => _SuperResolutionDemoAppState();
}

class _SuperResolutionDemoAppState extends State<SuperResolutionDemoApp> {
  ui.Image? _originalImage;
  ui.Image? _upscaledImage;
  double _progress = 0.0;
  String _progressMessage = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
  }

  Future<void> _loadDefaultImage() async {
    final ByteData data = await rootBundle.load('assets/sample_image.jpg');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();

    setState(() {
      _originalImage = fi.image;
    });
  }

  Future<void> _upscaleImage() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _progressMessage = '';
    });

    final upscaler = FlutterUpscaler(
      tileSize: 128,
      overlap: 8,
    );

    try {
      // Initialize model from assets
      await upscaler.initializeModel('assets/super_resolution_model.onnx');

      // Upscale image with progress tracking
      final upscaledImage = await upscaler.upscaleImage(
        _originalImage!,
        scale: 2,
        onProgress: (progress, message) {
          setState(() {
            _progress = progress;
            _progressMessage = message;
          });
        },
      );

      setState(() {
        _upscaledImage = upscaledImage;
        _isProcessing = false;
      });

      upscaler.dispose();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('Upscaling failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Super Resolution Demo'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_originalImage != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('Original Image'),
                      Image(image: ui.ImageForRenderObject(image: _originalImage!)),
                    ],
                  ),
                  if (_upscaledImage != null)
                    Column(
                      children: [
                        Text('Upscaled Image'),
                        Image(image: ui.ImageForRenderObject(image: _upscaledImage!)),
                      ],
                    ),
                ],
              ),
            if (_isProcessing)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  Text(_progressMessage),
                ],
              ),
            ElevatedButton(
              onPressed: _isProcessing ? null : _upscaleImage,
              child: Text('Upscale Image'),
            ),
          ],
        ),
      ),
    );
  }
}