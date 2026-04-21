import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/asset_item.dart';
import 'package:personal_application/core/services/storage_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetPreviewWidget extends StatefulWidget {
  final String assetId;
  final BoxFit fit;
  final double? cacheWidth;

  const AssetPreviewWidget({
    super.key,
    required this.assetId,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  @override
  State<AssetPreviewWidget> createState() => _AssetPreviewWidgetState();
}

class _AssetPreviewWidgetState extends State<AssetPreviewWidget> {
  Future<AssetItem?>? _assetFuture;
  Future<Uint8List?>? _bytesFuture;
  String? _lastAssetId;
  ui.Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _initFutures();
  }

  @override
  void didUpdateWidget(AssetPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      _initFutures();
    }
  }

  void _initFutures() {
    final db = context.read<AppDatabase>();
    _imageSize = null;
    _lastAssetId = widget.assetId;

    _assetFuture = (db.select(
      db.assetItems,
    )..where((t) => t.id.equals(widget.assetId))).getSingleOrNull();

    // Chain the bytes loading to the asset resolving for a stable future
    _bytesFuture = _assetFuture!.then((asset) async {
      if (asset == null) return null;
      final data = await (asset.mimeType.startsWith('video/')
          ? StorageService().getThumbnail(asset)
          : StorageService().getBytes(asset));

      if (data != null) {
        _resolveImageSize(data);
      }
      return data;
    });
  }

  void _resolveImageSize(Uint8List bytes) {
    if (_imageSize != null && _lastAssetId == widget.assetId) return;

    final provider = MemoryImage(bytes);
    final stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _imageSize = ui.Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetItem?>(
      future: _assetFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Skeletonizer(
            enabled: true,
            child: SizedBox(
              width: 300,
              height: double.infinity,
              child: Bone.square(size: double.infinity),
            ),
          );
        }

        final asset = snapshot.data!;
        return FutureBuilder<Uint8List?>(
          future: _bytesFuture,
          builder: (context, byteSnapshot) {
            if (byteSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: 300,
                height: double.infinity,
                color: Colors.white.withAlpha(5),
              );
            }

            final data = byteSnapshot.data;
            if (data != null) {
              final isVideo = asset.mimeType.startsWith('video/');

              return LayoutBuilder(
                builder: (context, constraints) {
                  // If we don't have the image size yet, fall back to simple rendering
                  if (_imageSize == null) {
                    return Center(
                      child: Image.memory(
                        data,
                        fit: widget.fit,
                        cacheWidth: widget.cacheWidth?.toInt(),
                      ),
                    );
                  }

                  final iw = _imageSize!.width;
                  final ih = _imageSize!.height;

                  final ratioImage = iw / ih;

                  // We calculate the scaleToCover based on a SQUARE aspect ratio (the passive state).
                  // By keeping this constant, the AnimatedScale has a stable target and won't "wobble"
                  // or overshoot while the container width is animating.
                  final scaleToCoverSquare = ratioImage > 1.0
                      ? ratioImage
                      : (1.0 / ratioImage);

                  final isCover = widget.fit == BoxFit.cover;

                  return ClipRect(
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        // Blurred background (fading in when in contain mode)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          opacity: isCover ? 0.0 : 1.0,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Fixed-size background to prevent scaling during container resize
                              Center(
                                child: SizedBox(
                                  width: 1200,
                                  height: 800,
                                  child: Image.memory(
                                    data,
                                    fit: BoxFit.cover,
                                    color: Colors.black.withAlpha(120),
                                    colorBlendMode: BlendMode.darken,
                                  ),
                                ),
                              ),
                              BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: Container(color: Colors.transparent),
                              ),
                            ],
                          ),
                        ),

                        // The Morphing Image
                        Center(
                          child: AnimatedScale(
                            scale: isCover ? scaleToCoverSquare : 1.0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.memory(
                                data,
                                filterQuality: FilterQuality.medium,
                                cacheWidth: widget.cacheWidth?.toInt(),
                              ),
                            ),
                          ),
                        ),

                        if (isVideo)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }

            return _buildErrorPlaceholder(asset, 'No Preview');
          },
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(AssetItem asset, String message) {
    return Container(
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            asset.mimeType.startsWith('video/')
                ? Icons.videocam_rounded
                : Icons.insert_drive_file_rounded,
            size: 32,
            color: Colors.white24,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              asset.displayName ?? message,
              style: const TextStyle(fontSize: 10, color: Colors.white24),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
