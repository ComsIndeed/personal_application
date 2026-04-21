import 'dart:typed_data';
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
    _assetFuture = (db.select(
      db.assetItems,
    )..where((t) => t.id.equals(widget.assetId))).getSingleOrNull();
    _lastAssetId = widget.assetId;
  }

  Future<Uint8List?> _getData(AssetItem asset) {
    if (_bytesFuture != null && _lastAssetId == widget.assetId) {
      return _bytesFuture!;
    }

    if (asset.mimeType.startsWith('video/')) {
      _bytesFuture = StorageService().getThumbnail(asset);
    } else {
      _bytesFuture = StorageService().getBytes(asset);
    }
    return _bytesFuture!;
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
          future: _getData(asset),
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
              return Stack(
                alignment: Alignment.center,
                fit: widget.fit == BoxFit.cover
                    ? StackFit.expand
                    : StackFit.loose,
                children: [
                  Image.memory(
                    data,
                    fit: widget.fit,
                    cacheWidth: widget.cacheWidth?.toInt(),
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                        'Image.memory failed for ${widget.assetId}: $error, bytes: ${data.length}',
                      );
                      return _buildErrorPlaceholder(asset, 'Invalid Data');
                    },
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
