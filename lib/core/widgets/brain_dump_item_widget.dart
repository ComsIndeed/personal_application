import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/asset_item.dart';
import 'package:personal_application/core/models/common_note_item.dart';
import 'package:personal_application/core/services/storage_service.dart';
import 'package:intl/intl.dart';

class BrainDumpItemWidget extends StatelessWidget {
  final CommonNoteItem item;

  const BrainDumpItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final text = item.textContent ?? '';
    final assetIds = item.assetIds;
    final isSingleMedia = assetIds.length == 1 && text.length < 250;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withAlpha(128)
            : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isSingleMedia
          ? _buildSingleMediaLayout(context)
          : _buildTextHeavyLayout(context),
    );
  }

  Widget _buildSingleMediaLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Media Part
          SizedBox(
            width: 120,
            height: 120,
            child: _AssetPreview(assetId: item.assetIds.first),
          ),
          // Content Part
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.title != null && item.title!.isNotEmpty)
                    Text(
                      item.title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.textContent != null && item.textContent!.isNotEmpty)
                    Text(
                      item.textContent!,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextHeavyLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.title != null && item.title!.isNotEmpty) ...[
            Text(
              item.title!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
          ],
          if (item.textContent != null && item.textContent!.isNotEmpty) ...[
            Text(
              item.textContent!,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
              maxLines: item.assetIds.isEmpty ? 10 : 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          if (item.assetIds.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.assetIds.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _AssetPreview(assetId: item.assetIds[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, h:mm a').format(item.createdAt);

    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 4),
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class _AssetPreview extends StatelessWidget {
  final String assetId;

  const _AssetPreview({required this.assetId});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final storage = StorageService();

    return FutureBuilder<AssetItem?>(
      future: (db.select(
        db.assetItems,
      )..where((t) => t.id.equals(assetId))).getSingleOrNull(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final asset = snapshot.data!;
        return FutureBuilder<Uint8List>(
          future: storage.getBytes(asset),
          builder: (context, byteSnapshot) {
            if (!byteSnapshot.hasData) {
              return Container(
                color: Colors.black12,
                child: const Icon(Icons.downloading, size: 20),
              );
            }

            if (asset.mimeType.startsWith('image/')) {
              return Image.memory(byteSnapshot.data!, fit: BoxFit.cover);
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
