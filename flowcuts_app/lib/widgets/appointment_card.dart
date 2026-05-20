import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/models.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Future<bool> Function(String status) onStatusChange;
  final Future<bool> Function() onDelete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(appointment.status);
    final timeFormat = DateFormat('hh:mm a');
    final startStr = timeFormat.format(appointment.startTime);
    final endStr = appointment.endTime != null
        ? timeFormat.format(appointment.endTime!)
        : null;

    return Slidable(
      key: Key('appt_${appointment.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.6,
        children: [
          // Confirm action
          if (appointment.status == 'scheduled')
            SlidableAction(
              onPressed: (_) => onStatusChange('confirmed'),
              backgroundColor: AppTheme.statusConfirmed,
              foregroundColor: Colors.white,
              icon: Icons.check_circle_rounded,
              label: 'Confirmar',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          // Complete action
          if (appointment.status == 'confirmed')
            SlidableAction(
              onPressed: (_) => onStatusChange('completed'),
              backgroundColor: AppTheme.statusCompleted,
              foregroundColor: Colors.white,
              icon: Icons.done_all_rounded,
              label: 'Completar',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          // Cancel action
          if (appointment.status != 'cancelled' &&
              appointment.status != 'completed')
            SlidableAction(
              onPressed: (_) => _confirmCancel(context),
              backgroundColor: AppTheme.statusCancelled,
              foregroundColor: Colors.white,
              icon: Icons.cancel_rounded,
              label: 'Cancelar',
            ),
          // Delete action
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: AppTheme.error.withOpacity(0.8),
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Borrar',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),

              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    startStr,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (endStr != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      endStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),

              // Divider
              Container(
                width: 1,
                height: 50,
                color: AppTheme.border,
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.clientName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.cut_rounded,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            appointment.serviceName,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          appointment.staffName,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: price + status chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${appointment.servicePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      AppTheme.statusLabel(appointment.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar cita?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Se cancelará la cita de ${appointment.clientName}.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onStatusChange('cancelled');
            },
            child: const Text('Cancelar cita',
                style: TextStyle(color: AppTheme.statusCancelled)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar cita?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Se eliminará permanentemente la cita de ${appointment.clientName}. Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
