import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/interfaces/tabs/brain_dump/brain_dump_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class BrainDumpInput extends StatefulWidget {
  const BrainDumpInput({super.key});

  @override
  State<BrainDumpInput> createState() => _BrainDumpInputState();
}

class _BrainDumpInputState extends State<BrainDumpInput> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<BrainDumpCubit>().updateText(_textController.text);
  }

  void _addFiles(
    List<PlatformFile> currentFiles, [
    List<PlatformFile>? newFiles,
  ]) async {
    if (newFiles == null) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (!mounted) return;
      if (result != null) {
        newFiles = result.files;
      }
    }

    if (newFiles != null && newFiles.isNotEmpty) {
      context.read<BrainDumpCubit>().updateFiles([
        ...currentFiles,
        ...newFiles,
      ]);
    }
  }

  Future<void> _handlePaste(List<PlatformFile> currentFiles) async {
    // 1. Try files
    final files = await Pasteboard.files();
    if (files.isNotEmpty) {
      final platformFiles = files.map((path) {
        final file = File(path);
        return PlatformFile(
          path: path,
          name: path.split(Platform.pathSeparator).last,
          size: file.lengthSync(),
        );
      }).toList();
      _addFiles(currentFiles, platformFiles);
      return;
    }

    // 2. Try image
    final imageBytes = await Pasteboard.image;
    if (imageBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'pasted_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      final platformFile = PlatformFile(
        path: file.path,
        name: fileName,
        size: imageBytes.length,
        bytes: imageBytes,
      );
      _addFiles(currentFiles, [platformFile]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<BrainDumpCubit, BrainDumpState>(
      listenWhen: (prev, curr) => prev.text != curr.text && curr.text.isEmpty,
      listener: (context, state) {
        if (_textController.text != state.text) {
          _textController.text = state.text;
        }
      },
      builder: (context, state) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
                _handlePaste(state.files),
            const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () =>
                _handlePaste(state.files),
          },
          child: Focus(
            canRequestFocus: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (state.files.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.files.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final file = state.files[index];
                          return FilePreviewItem(
                            file: file,
                            onRemove: () {
                              final newFiles = List<PlatformFile>.from(
                                state.files,
                              )..remove(file);
                              context.read<BrainDumpCubit>().updateFiles(
                                newFiles,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0B1120)
                                : Colors.black.withAlpha(5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : Colors.black.withAlpha(10),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 22),
                                onPressed: () => _addFiles(state.files),
                                tooltip: 'Add files',
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  maxLines: 5,
                                  minLines: 1,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Dump anything here...',
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Outlined Button
                      _SideButton(
                        icon: Icons.auto_awesome_outlined,
                        isOutlined: true,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      // Filled Button
                      _SideButton(
                        icon: Icons.send_rounded,
                        isOutlined: false,
                        onPressed: () =>
                            context.read<BrainDumpCubit>().sendRaw(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FilePreviewItem extends StatefulWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const FilePreviewItem({
    super.key,
    required this.file,
    required this.onRemove,
  });

  @override
  State<FilePreviewItem> createState() => _FilePreviewItemState();
}

class _FilePreviewItemState extends State<FilePreviewItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: widget.file.name,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () {
            // TODO: Implement file viewing
          },
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHovering
                        ? theme.colorScheme.primary
                        : (isDark
                              ? Colors.white.withAlpha(25)
                              : Colors.black.withAlpha(25)),
                    width: 1.5,
                  ),
                  color: isDark
                      ? Colors.white.withAlpha(5)
                      : Colors.black.withAlpha(5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildPreview(),
              ),
              if (_isHovering)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 150.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final ext = widget.file.extension?.toLowerCase();
    final path = widget.file.path;

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext) &&
        path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildIcon(Icons.image),
      );
    }

    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return _buildIcon(Icons.videocam_rounded);
    }

    if (['mp3', 'wav', 'm4a', 'flac', 'ogg'].contains(ext)) {
      return _buildIcon(Icons.audiotrack_rounded);
    }

    if ([
      'pdf',
      'doc',
      'docx',
      'txt',
      'md',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(ext)) {
      return _buildIcon(Icons.description_rounded);
    }

    return _buildIcon(Icons.insert_drive_file_rounded);
  }

  Widget _buildIcon(IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Icon(
        icon,
        size: 32,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _SideButton({
    required this.icon,
    required this.isOutlined,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isOutlined) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: theme.colorScheme.primary),
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        // No shadow to avoid "ghostly" overlay effects
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: theme.colorScheme.onPrimary),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}
