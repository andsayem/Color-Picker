import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class SavedColorsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> savedColors;

  const SavedColorsScreen({super.key, required this.savedColors});

  @override
  State<SavedColorsScreen> createState() => _SavedColorsScreenState();
}

class _SavedColorsScreenState extends State<SavedColorsScreen> {
  void _copyColor(Map<String, dynamic> item) async {
    final text =
        "🎨 ${item["name"]}\n"
        "HEX: ${item["hex"]}\n"
        "RGB: ${item["rgb"]}\n"
        "Match: ${item["match"].toStringAsFixed(1)}%";

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
  }

  void _shareColor(Map<String, dynamic> item) {
    final text =
        "🎨 ${item["name"]}\n\n"
        "HEX: ${item["hex"]}\n"
        "RGB: ${item["rgb"]}\n"
        "Match: ${item["match"].toStringAsFixed(1)}%";

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Text(
                      "Saved Colors",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "${widget.savedColors.length}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: widget.savedColors.isEmpty
                  ? const Center(
                      child: Text(
                        "No Saved Colors",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.savedColors.length,
                      itemBuilder: (context, index) {
                        final item = widget.savedColors[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // COLOR CIRCLE
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: item["color"],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["name"],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item["hex"]),
                                    Text(item["rgb"]),
                                    Text(
                                      "Match ${item["match"].toStringAsFixed(1)}%",
                                    ),
                                  ],
                                ),
                              ),

                              // ACTIONS
                              Column(
                                children: [
                                  _actionButton(
                                    icon: Icons.copy,
                                    color: Colors.blue,
                                    onTap: () => _copyColor(item),
                                  ),
                                  const SizedBox(height: 10),
                                  _actionButton(
                                    icon: Icons.share,
                                    color: Colors.green,
                                    onTap: () => _shareColor(item),
                                  ),
                                  const SizedBox(height: 10),
                                  _actionButton(
                                    icon: Icons.delete,
                                    color: Colors.red,
                                    onTap: () {
                                      setState(() {
                                        widget.savedColors.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
