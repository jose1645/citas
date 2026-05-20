import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (ctx, provider, _) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${provider.staff.length} barbero${provider.staff.length != 1 ? 's' : ''} registrado${provider.staff.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // Staff list
                provider.isLoading && provider.staff.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildLoading())
                    : provider.staff.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmpty())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final member = provider.staff[i];
                                return FadeInUp(
                                  delay: Duration(milliseconds: i * 60),
                                  duration: const Duration(milliseconds: 350),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.goldGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            member.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        member.name,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        member.isActive ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                          color: member.isActive
                                              ? AppTheme.statusConfirmed
                                              : AppTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: member.isActive
                                              ? AppTheme.statusConfirmed
                                                  .withOpacity(0.12)
                                              : AppTheme.textMuted
                                                  .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: member.isActive
                                                ? AppTheme.statusConfirmed
                                                    .withOpacity(0.4)
                                                : AppTheme.textMuted
                                                    .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: member.isActive
                                                    ? AppTheme.statusConfirmed
                                                    : AppTheme.textMuted,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              member.isActive
                                                  ? 'Activo'
                                                  : 'Inactivo',
                                              style: TextStyle(
                                                color: member.isActive
                                                    ? AppTheme.statusConfirmed
                                                    : AppTheme.textMuted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: provider.staff.length,
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

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
          child:
              CircularProgressIndicator(color: AppTheme.primary)),
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
            child: const Icon(Icons.people_outline_rounded,
                color: AppTheme.textMuted, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Sin personal registrado',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Agrega barberos desde el panel\nde administración web.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
