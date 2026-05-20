import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Staff? _selectedStaff;
  Service? _selectedService;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.staff.isEmpty) provider.loadStaff();
      if (provider.services.isEmpty) provider.loadServices();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.black,
            surface: AppTheme.card,
            onSurface: AppTheme.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.black,
            surface: AppTheme.card,
            onSurface: AppTheme.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppTheme.card,
            hourMinuteColor: AppTheme.surface,
            dialBackgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaff == null) {
      _showSnack('Selecciona un barbero', isError: true);
      return;
    }
    if (_selectedService == null) {
      _showSnack('Selecciona un servicio', isError: true);
      return;
    }

    setState(() => _loading = true);

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final success = await context.read<AppProvider>().createAppointment(
        staffId: _selectedStaff!.id,
        serviceId: _selectedService!.id,
        clientName: _nameCtrl.text.trim(),
        clientPhone: _phoneCtrl.text.trim(),
        startTime: dt.toIso8601String(),
      );

      if (!mounted) return;
      if (success) {
        _showSnack('✅ Cita creada exitosamente');
        Navigator.pop(context);
      } else {
        _showSnack('Error al crear la cita', isError: true);
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppTheme.error : AppTheme.statusConfirmed,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Nueva Cita'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary))
                : const Text('Guardar',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client info section
                  _sectionTitle('Datos del Cliente'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Ingresa el nombre del cliente'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '521234567890',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Ingresa el teléfono del cliente'
                        : null,
                  ),

                  const SizedBox(height: 28),

                  // Service & Staff section
                  _sectionTitle('Servicio y Barbero'),
                  const SizedBox(height: 12),

                  // Service selector
                  _buildDropdownField<Service>(
                    label: 'Servicio',
                    icon: Icons.cut_rounded,
                    value: _selectedService,
                    items: provider.services,
                    itemLabel: (s) =>
                        '${s.name}  •  \$${s.price.toStringAsFixed(0)} (${s.durationMinutes} min)',
                    onChanged: (v) => setState(() => _selectedService = v),
                    isLoading: provider.isLoading && provider.services.isEmpty,
                  ),
                  const SizedBox(height: 14),

                  // Staff selector
                  _buildDropdownField<Staff>(
                    label: 'Barbero',
                    icon: Icons.person_2_outlined,
                    value: _selectedStaff,
                    items: provider.staff
                        .where((s) => s.isActive)
                        .toList(),
                    itemLabel: (s) => s.name,
                    onChanged: (v) => setState(() => _selectedStaff = v),
                    isLoading: provider.isLoading && provider.staff.isEmpty,
                  ),

                  const SizedBox(height: 28),

                  // Date & Time section
                  _sectionTitle('Fecha y Hora'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerField(
                          label: 'Fecha',
                          value: DateFormat('d MMM yyyy', 'es_MX')
                              .format(_selectedDate),
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPickerField(
                          label: 'Hora',
                          value: _selectedTime.format(context),
                          icon: Icons.access_time_rounded,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Summary card
                  if (_selectedService != null || _selectedStaff != null)
                    _buildSummaryCard(),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.black))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Agendar Cita',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8));
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary)),
                SizedBox(width: 10),
                Text('Cargando...',
                    style: TextStyle(color: AppTheme.textMuted)),
              ]),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.card,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary),
                hint: Row(children: [
                  Icon(icon, size: 18, color: AppTheme.textMuted),
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 14)),
                ]),
                selectedItemBuilder: (ctx) => items
                    .map((item) => Row(children: [
                          Icon(icon, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(itemLabel(item),
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]))
                    .toList(),
                items: items
                    .map((item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(itemLabel(item),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 14)),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                  Text(value,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          if (_selectedService != null) ...[
            _summaryRow('Servicio', _selectedService!.name),
            _summaryRow('Precio',
                '\$${_selectedService!.price.toStringAsFixed(0)}'),
            _summaryRow('Duración',
                '${_selectedService!.durationMinutes} min'),
          ],
          if (_selectedStaff != null)
            _summaryRow('Barbero', _selectedStaff!.name),
          _summaryRow('Fecha & Hora',
              '${DateFormat('d MMM yyyy', 'es_MX').format(_selectedDate)} a las ${_selectedTime.format(context)}'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
