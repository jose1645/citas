import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (ctx, provider, _) {
            final services = provider.services;
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Servicios',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${services.length} servicio${services.length != 1 ? 's' : ''} disponible${services.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // Services grid
                provider.isLoading && services.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary)),
                        ))
                    : services.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmpty())
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.88,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  return FadeInUp(
                                    delay: Duration(milliseconds: i * 60),
                                    duration:
                                        const Duration(milliseconds: 350),
                                    child: _ServiceCard(
                                        service: services[i]),
                                  );
                                },
                                childCount: services.length,
                              ),
                            ),
                          ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.cut_outlined,
                color: AppTheme.textMuted, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Sin servicios',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Agrega servicios desde el panel\nde administración web.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    // Pick icon color based on price range
    final Color accentColor =
        service.price > 300 ? AppTheme.primary : AppTheme.info;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.25)),
              ),
              child: Icon(Icons.cut_rounded, color: accentColor, size: 22),
            ),
            const SizedBox(height: 14),

            // Name
            Text(
              service.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                service.description!,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Spacer(),

            // Duration + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${service.durationMinutes} min',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
