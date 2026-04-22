import 'package:flutter/material.dart';

class SearchHeaderWidget extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const SearchHeaderWidget({super.key, required this.hintText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: Colors.white38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hintText,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
