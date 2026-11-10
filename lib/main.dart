import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter95/flutter95.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("No se pudieron cargar las cámaras: $e");
  }
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retro Editor 97',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      localizationsDelegates: const [
        ...material_ui.GlobalMaterialLocalizations.delegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RetroHomePage(cameras: cameras),
    );
  }
}

class RetroHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const RetroHomePage({super.key, required this.cameras});

  @override
  State<RetroHomePage> createState() => _RetroHomePageState();
}

class _RetroHomePageState extends State<RetroHomePage> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isAdvancedMode = false;

  Future<void> _openImage() async {
    const typeGroup = XTypeGroup(
      label: 'Imágenes',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  Future<void> _openMultipleImages() async {
    const typeGroup = XTypeGroup(
      label: 'Imágenes',
      extensions: ['png', 'jpg', 'jpeg'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;

    for (var file in files) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
      await _editImageAsync();
    }
  }

  void _showNewImageDialog() {
    final widthController = TextEditingController(text: '800');
    final heightController = TextEditingController(text: '600');
    Color bgColor = Colors.white;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 320,
              color: const Color(0xFFC0C0C0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 28,
                    color: const Color(0xFF000080),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Text(
                          'Nuevo Lienzo',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 20,
                            height: 20,
                            color: const Color(0xFFC0C0C0),
                            child: const Icon(Icons.close, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Ancho (px): ', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: TextField(
                                controller: widthController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Alto (px): ', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: TextField(
                                controller: heightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Fondo: ', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            _buildColorOption(Colors.white, bgColor, (c) => setDialogState(() => bgColor = c)),
                            const SizedBox(width: 4),
                            _buildColorOption(Colors.black, bgColor, (c) => setDialogState(() => bgColor = c)),
                            const SizedBox(width: 4),
                            _buildColorOption(Colors.transparent, bgColor, (c) => setDialogState(() => bgColor = c), isTransparent: true),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Button95(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Button95(
                              onTap: () async {
                                final w = int.tryParse(widthController.text) ?? 800;
                                final h = int.tryParse(heightController.text) ?? 600;
                                Navigator.of(context).pop();
                                
                                final bytes = await _generateBlankCanvas(w, h, bgColor);
                                setState(() {
                                  _imageBytes = bytes;
                                  _imageName = 'Lienzo_${w}x${h}.png';
                                });
                                _editImage();
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text('Crear'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorOption(Color color, Color selected, Function(Color) onSelect, {bool isTransparent = false}) {
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isTransparent ? Colors.grey[300] : color,
          border: Border.all(
            color: color == selected ? Colors.red : Colors.black,
            width: color == selected ? 2 : 1,
          ),
        ),
        child: isTransparent
            ? const Center(child: Text('X', style: TextStyle(fontSize: 10, color: Colors.red)))
            : null,
      ),
    );
  }

  Future<Uint8List> _generateBlankCanvas(int width, int height, Color color) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
    final ui.Image image = await recorder.endRecording().toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _takePhoto() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (widget.cameras.isEmpty) {
        _showSnackBar('No se encontraron cámaras en el dispositivo.');
        return;
      }
      final XFile? photo = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen(camera: widget.cameras.first)),
      );
      
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = 'Foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
        _editImage();
      }
    } else {
      _showSnackBar('La captura de cámara solo está disponible en Android/iOS.');
    }
  }

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/retro_edit_$timestamp.png';
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      _showSnackBar('Guardado en: $filePath');
    } catch (e) {
      _showSnackBar('Error al guardar: $e');
    }
  }

  Future<void> _openSaveFolder() async {
    if (Platform.isLinux) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        await Process.run('xdg-open', [directory.path]);
      } catch (e) {
        _showSnackBar('No se pudo abrir la carpeta: $e');
      }
    } else {
      _showSnackBar('Función disponible solo en Linux de escritorio.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF000080),
        ),
      );
    }
  }

  // Diálogo de capas corregido (sin rebuildController)
  void _showLayersDialog(ProImageEditorState editor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          height: 400,
          color: const Color(0xFFC0C0C0),
          child: Column(
            children: [
              Container(
                height: 28,
                color: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Text(
                      'Capas del Proyecto',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 20,
                        height: 20,
                        color: const Color(0xFFC0C0C0),
                        child: const Icon(Icons.close, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    // Leemos las capas activas directamente
                    final layers = editor.activeLayers;
                    if (layers.isEmpty) {
                      return const Center(child: Text('No hay capas añadidas.', style: TextStyle(fontSize: 12)));
                    }
                    final reversedLayers = layers.reversed.toList();
                    return ListView.builder(
                      itemCount: reversedLayers.length,
                      itemBuilder: (context, index) {
                        final layer = reversedLayers[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.layers, size: 16),
                          title: Text(
                            'Capa ${layers.length - index}: ${layer.runtimeType.toString().replaceAll('Layer', '')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            'ID: ${layer.id.substring(0, 5)}...',
                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editImageAsync() async {
    if (_imageBytes == null) return;

    final essentialTools = [
      SubEditorMode.paint,
      SubEditorMode.text,
      SubEditorMode.cropRotate,
      SubEditorMode.filter,
    ];
    
    final advancedTools = [
      SubEditorMode.paint,
      SubEditorMode.text,
      SubEditorMode.cropRotate,
      SubEditorMode.tune,
      SubEditorMode.filter,
      SubEditorMode.blur,
      SubEditorMode.emoji,
      SubEditorMode.sticker,
    ];

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          _imageBytes!,
          configs: ProImageEditorConfigs(
            mainEditor: MainEditorConfigs(
              widgets: MainEditorWidgets(
                appBar: (editor, rebuildStream) => ReactiveAppbar(
                  stream: rebuildStream,
                  builder: (_) => PreferredSize(
                    preferredSize: const Size.fromHeight(28),
                    child: Container(
                      height: 28,
                      color: const Color(0xFF000080),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Editor Retro',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showLayersDialog(editor),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 20,
                              height: 20,
                              color: const Color(0xFFC0C0C0),
                              child: const Icon(Icons.layers, size: 14),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final bytes = await editor.captureEditorImage();
                              if (bytes != null) {
                                await _saveImage(bytes);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 20,
                              height: 20,
                              color: const Color(0xFFC0C0C0),
                              child: const Icon(Icons.save, size: 14),
                            ),
                          ),
                          GestureDetector(
                            onTap: editor.closeEditor,
                            child: Container(
                              width: 20,
                              height: 20,
                              color: const Color(0xFFC0C0C0),
                              child: const Icon(Icons.close, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              tools: _isAdvancedMode ? advancedTools : essentialTools,
            ),
            filterEditor: FilterEditorConfigs(
              widgets: FilterEditorWidgets(
                appBar: (editor, rebuildStream) => ReactiveAppbar(
                  stream: rebuildStream,
                  builder: (_) => PreferredSize(
                    preferredSize: const Size.fromHeight(28),
                    child: Container(
                      height: 28,
                      color: const Color(0xFF000080),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => editor.close(),
                            child: Container(
                              width: 20,
                              height: 20,
                              color: const Color(0xFFC0C0C0),
                              child: const Icon(Icons.arrow_back, size: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtros',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => editor.close(),
                            child: Container(
                              width: 20,
                              height: 20,
                              color: const Color(0xFFC0C0C0),
                              child: const Icon(Icons.check, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {
              setState(() => _imageBytes = editedBytes);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _editImage() {
    _editImageAsync();
  }

  Widget _buildTopMenu() {
    return Container(
      height: 24,
      color: const Color(0xFFC0C0C0),
      child: Row(
        children: [
          _buildMenuTextButton('Nuevo Lienzo', _showNewImageDialog),
          _buildMenuTextButton('Abrir', _openImage),
          _buildMenuTextButton('Lote', _openMultipleImages),
          _buildMenuTextButton('Capturar', _takePhoto),
        ],
      ),
    );
  }

  Widget _buildMenuTextButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Scaffold95(
        title: 'Retro Editor 97',
        body: Container(
          color: const Color(0xFF008080),
          child: Column(
            children: [
              _buildTopMenu(),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          _buildDesktopIcon(
                            icon: Icons.insert_drive_file,
                            label: 'Nuevo',
                            onTap: _showNewImageDialog,
                          ),
                          _buildDesktopIcon(
                            icon: Icons.folder_open,
                            label: 'Abrir',
                            onTap: _openImage,
                          ),
                          _buildDesktopIcon(
                            icon: Icons.library_add,
                            label: 'Lote',
                            onTap: _openMultipleImages,
                          ),
                          _buildDesktopIcon(
                            icon: Icons.camera_alt,
                            label: 'Captura',
                            onTap: _takePhoto,
                          ),
                          _buildDesktopIcon(
                            icon: Icons.edit,
                            label: 'Editar',
                            onTap: _imageBytes != null ? _editImage : () {},
                          ),
                          _buildDesktopIcon(
                            icon: Icons.image,
                            label: 'Ver',
                            onTap: _imageBytes != null
                                ? () => _showViewer(context)
                                : () {},
                          ),
                          _buildDesktopIcon(
                            icon: Icons.delete,
                            label: 'Borrar',
                            onTap: () {
                              setState(() {
                                _imageBytes = null;
                                _imageName = null;
                              });
                            },
                          ),
                          _buildDesktopIcon(
                            icon: Icons.folder_special,
                            label: 'Guardados',
                            onTap: _openSaveFolder,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8, 
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0C0C0),
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 1),
                            left: BorderSide(color: Colors.white, width: 1),
                            bottom: BorderSide(color: Colors.black, width: 1),
                            right: BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        child: const Text(
                          'Desarrollado por José Rodríguez y Lenin Azañedo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                color: const Color(0xFFC0C0C0),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Button95(
                      onTap: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.window, size: 16),
                          SizedBox(width: 4),
                          Text('Inicio'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Text('Modo Esencial', style: TextStyle(fontSize: 12)),
                        Switch(
                          value: _isAdvancedMode,
                          activeColor: const Color(0xFF000080),
                          onChanged: (val) {
                            setState(() {
                              _isAdvancedMode = val;
                            });
                          },
                        ),
                        const Text('Modo Avanzado', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _imageName ?? 'Sin imagen',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          height: 400,
          color: const Color(0xFFC0C0C0),
          child: Column(
            children: [
              Container(
                height: 28,
                color: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      _imageName ?? 'Visor',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _saveImage(_imageBytes!);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 20,
                        height: 20,
                        color: const Color(0xFFC0C0C0),
                        child: const Icon(Icons.save, size: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 20,
                        height: 20,
                        color: const Color(0xFFC0C0C0),
                        child: const Icon(Icons.close, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF000080),
        title: const Text('Captura de Foto', style: TextStyle(fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                Container(
                  color: const Color(0xFFC0C0C0),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Button95(
                        onTap: () async {
                          try {
                            final XFile picture = await _controller.takePicture();
                            if (context.mounted) Navigator.of(context).pop(picture);
                          } catch (e) {
                            debugPrint('Error al tomar foto: $e');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.camera, size: 32),
                        ),
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
    );
  }
}
