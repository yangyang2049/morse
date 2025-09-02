import 'package:flutter/material.dart';

class ExplanationTipsCard extends StatelessWidget {
  final String title;
  final String content;
  final Color? color;

  const ExplanationTipsCard({
    super.key,
    required this.title,
    required this.content,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = (color ?? Colors.orange) as MaterialColor;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 160, // 最大高度限制
        minHeight: 80, // 最小高度，确保短内容也有合适高度
      ),
      decoration: BoxDecoration(
        color: cardColor[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardColor.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 知识小贴士浮动在右上角
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor[400],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 3),
                    Text(
                      '知识小贴士',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 标题和内容从左上角开始
          Padding(
            padding:
                const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cardColor[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: TextStyle(
                        color: cardColor[700],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
