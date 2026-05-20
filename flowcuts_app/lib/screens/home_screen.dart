import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/appointment_card.dart';
import 'appointments_screen.dart';
import 'staff_screen.dart';
import 'services_screen.dart';
import 'shop_settings_screen.dart';
import 'new_appointment_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    AppointmentsScreen(),
    StaffScreen(),
    ServicesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Citas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Personal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cut_outlined),
              activeIcon: Icon(Icons.cut_rounded),
              label: 'Servicios',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Tab ──────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.loadDashboard();
      provider.loadAppointmentsForDate(DateTime.now());
    });
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (ctx, provider, _) {
            return RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.card,
              onRefresh: () async {
                await provider.loadDashboard();
                await provider.loadAppointmentsForDate(DateTime.now());
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppTheme.goldGradient.createShader(b),
                                  child: const Text(
                                    'FlowCuts',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE d MMMM, yyyy', 'es_MX')
                                      .format(DateTime.now()),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Settings button
                          IconButton(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ShopSettingsScreen())),
                            icon: const Icon(Icons.store_outlined,
                                color: AppTheme.textSecondary),
                          ),
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: provider.isLoading && provider.dashboard == null
                          ? _buildSkeletonStats()
                          : _buildStatsGrid(provider),
                    ),
                  ),

                  // Today's appointments header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Citas de Hoy',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Ver todo',
                                style: TextStyle(color: AppTheme.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Appointments list
                  provider.appointments.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyAppointments())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final appt = provider.appointments[i];
                              return FadeInUp(
                                delay: Duration(milliseconds: i * 60),
                                duration: const Duration(milliseconds: 350),
                                child: AppointmentCard(
                                  appointment: appt,
                                  onStatusChange: (status) =>
                                      provider.updateStatus(appt.id, status),
                                  onDelete: () =>
                                      provider.deleteAppointment(appt.id),
                                ),
                              );
                            },
                            childCount: provider.appointments.length > 5
                                ? 5
                                : provider.appointments.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NewAppointmentScreen())),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Cita',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }

  Widget _buildStatsGrid(AppProvider provider) {
    final d = provider.dashboard;
    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: FadeInLeft(
                duration: const Duration(milliseconds: 500),
                child: StatsCard(
                  title: 'Hoy',
                  value: '${d?.todayAppointments ?? 0}',
                  subtitle: 'citas del día',
                  icon: Icons.calendar_today_rounded,
                  color: AppTheme.primary,
                  gradient: AppTheme.goldGradient,
                  isLarge: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInRight(
                duration: const Duration(milliseconds: 500),
                child: StatsCard(
                  title: 'Este Mes',
                  value: '${d?.totalAppointmentsMonth ?? 0}',
                  subtitle: 'citas totales',
                  icon: Icons.bar_chart_rounded,
                  color: AppTheme.info,
                  isLarge: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: FadeInLeft(
                delay: const Duration(milliseconds: 100),
                child: StatsCard(
                  title: 'Pendientes',
                  value: '${d?.pendingAppointments ?? 0}',
                  icon: Icons.schedule_rounded,
                  color: AppTheme.statusScheduled,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Confirmadas',
                value: '${d?.confirmedAppointments ?? 0}',
                icon: Icons.check_circle_rounded,
                color: AppTheme.statusConfirmed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInRight(
                delay: const Duration(milliseconds: 100),
                child: StatsCard(
                  title: 'Canceladas',
                  value: '${d?.cancelledAppointments ?? 0}',
                  icon: Icons.cancel_rounded,
                  color: AppTheme.statusCancelled,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonStats() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _skeletonBox(height: 100)),
          const SizedBox(width: 12),
          Expanded(child: _skeletonBox(height: 100)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _skeletonBox(height: 80)),
          const SizedBox(width: 12),
          Expanded(child: _skeletonBox(height: 80)),
          const SizedBox(width: 12),
          Expanded(child: _skeletonBox(height: 80)),
        ]),
      ],
    );
  }

  Widget _skeletonBox({double height = 80}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: AppTheme.textMuted, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Sin citas hoy',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('No hay citas programadas para hoy',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
