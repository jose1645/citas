import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final bool isLarge;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.gradient,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 18 : 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLarge
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        color: gradient == null ? color.withOpacity(0.15) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          color: gradient != null ? Colors.black : color,
                          size: 18),
                    ),
                    const Spacer(),
                    if (gradient != null)
                      ShaderMask(
                        shaderCallback: (b) => gradient!.createShader(b),
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}
