import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/appointment_card.dart';
import 'new_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAppointmentsForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (ctx, provider, _) {
            return Column(
              children: [
                // Header
                _buildHeader(provider),

                // Status filter chips
                _buildFilterChips(provider),

                // Calendar (collapsible)
                if (_showCalendar) _buildCalendar(provider),

                // Appointments list
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary))
                      : provider.appointments.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: AppTheme.primary,
                              backgroundColor: AppTheme.card,
                              onRefresh: () =>
                                  provider.loadAppointmentsForDate(
                                      provider.selectedDate),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: provider.appointments.length,
                                itemBuilder: (ctx, i) {
                                  final appt = provider.appointments[i];
                                  return AppointmentCard(
                                    appointment: appt,
                                    onStatusChange: (status) =>
                                        provider.updateStatus(appt.id, status),
                                    onDelete: () =>
                                        provider.deleteAppointment(appt.id),
                                  );
                                },
                              ),
                            ),
                ),
              ],
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
        label:
            const Text('Nueva', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
    final selectedDate = provider.selectedDate;
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Citas',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
                Text(
                  isToday
                      ? 'Hoy, ${DateFormat('d MMMM', 'es_MX').format(selectedDate)}'
                      : DateFormat('EEEE d MMMM', 'es_MX').format(selectedDate),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          // Calendar toggle
          GestureDetector(
            onTap: () => setState(() => _showCalendar = !_showCalendar),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _showCalendar
                    ? AppTheme.primary.withOpacity(0.15)
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showCalendar ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: _showCalendar
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppProvider provider) {
    final List<Map<String, String?>> filters = [
      {'value': null, 'label': 'Todas'},
      {'value': 'scheduled', 'label': 'Pendientes'},
      {'value': 'confirmed', 'label': 'Confirmadas'},
      {'value': 'completed', 'label': 'Completadas'},
      {'value': 'cancelled', 'label': 'Canceladas'},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isSelected = provider.statusFilter == f['value'];
          return GestureDetector(
            onTap: () => provider.setStatusFilter(f['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.15)
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: provider.selectedDate,
        selectedDayPredicate: (day) =>
            DateUtils.isSameDay(day, provider.selectedDate),
        onDaySelected: (selected, focused) {
          provider.loadAppointmentsForDate(selected);
          setState(() => _showCalendar = false);
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle:
              const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
          selectedTextStyle: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700),
          defaultTextStyle:
              const TextStyle(color: AppTheme.textPrimary),
          weekendTextStyle:
              const TextStyle(color: AppTheme.textSecondary),
          outsideTextStyle:
              const TextStyle(color: AppTheme.textMuted),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: AppTheme.textSecondary),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle:
              TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          weekendStyle:
              TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
            child: const Icon(Icons.event_busy_rounded,
                color: AppTheme.textMuted, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Sin citas',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'No hay citas para esta fecha\no con el filtro seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
