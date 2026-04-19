import 'dart:typed_data';
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
  Future<Uint8List>? _bytesFuture;
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

  Future<Uint8List> _getBytes(AssetItem asset) {
    if (_bytesFuture != null && _lastAssetId == widget.assetId) {
      return _bytesFuture!;
    }
    _bytesFuture = StorageService().getBytes(asset);
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
            child: Bone.square(size: double.infinity),
          );
        }

        final asset = snapshot.data!;
        return FutureBuilder<Uint8List>(
          future: _getBytes(asset),
          builder: (context, byteSnapshot) {
            if (!byteSnapshot.hasData) {
              return const Skeletonizer(
                enabled: true,
                child: Bone.square(size: double.infinity),
              );
            }

            if (asset.mimeType.startsWith('image/')) {
              return Image.memory(
                byteSnapshot.data!,
                fit: widget.fit,
                cacheWidth: widget.cacheWidth?.toInt(),
              );
            }

            return Container(
              color: Colors.black26,
              child: const Icon(Icons.insert_drive_file_rounded),
            );
          },
        );
      },
    );
  }
}
