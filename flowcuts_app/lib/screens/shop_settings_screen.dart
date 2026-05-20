import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppProvider>().loadShop();
      _fillFields();
    });
  }

  void _fillFields() {
    final shop = context.read<AppProvider>().shop;
    if (shop != null) {
      _nameCtrl.text = shop.name;
      _addressCtrl.text = shop.address ?? '';
      _hoursCtrl.text = shop.businessHours ?? '';
      _latCtrl.text = shop.latitude?.toString() ?? '';
      _lngCtrl.text = shop.longitude?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await context.read<AppProvider>().updateShop(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      businessHours: _hoursCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text.trim()),
      longitude: double.tryParse(_lngCtrl.text.trim()),
    );
    if (!mounted) return;
    setState(() { _saving = false; _editing = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? '✅ Datos actualizados' : '❌ Error al guardar'),
      backgroundColor: success ? AppTheme.statusConfirmed : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Mi Barbería'),
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.primary, size: 18),
              label: const Text('Editar',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600)),
            )
          else
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
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
          if (provider.isLoading && provider.shop == null) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop icon header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.content_cut_rounded,
                              color: Colors.black, size: 40),
                        ),
                        const SizedBox(height: 14),
                        if (provider.shop != null)
                          Text(provider.shop!.name,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('FlowCuts Admin',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _sectionTitle('Información General'),
                  const SizedBox(height: 12),

                  _buildField(
                    label: 'Nombre de la Barbería',
                    icon: Icons.store_outlined,
                    controller: _nameCtrl,
                    enabled: _editing,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Dirección',
                    icon: Icons.location_on_outlined,
                    controller: _addressCtrl,
                    enabled: _editing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Horario de Atención',
                    icon: Icons.access_time_rounded,
                    controller: _hoursCtrl,
                    enabled: _editing,
                    hint: 'Ej: Lunes a Sábado de 10:00 AM a 8:00 PM',
                  ),

                  const SizedBox(height: 28),
                  _sectionTitle('Coordenadas GPS'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'Latitud',
                          icon: Icons.my_location_rounded,
                          controller: _latCtrl,
                          enabled: _editing,
                          hint: '19.414000',
                          keyboardType: TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          label: 'Longitud',
                          icon: Icons.my_location_rounded,
                          controller: _lngCtrl,
                          enabled: _editing,
                          hint: '-102.052000',
                          keyboardType: TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),

                  if (_editing) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.black))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text('Guardar Cambios',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _editing = false);
                          _fillFields();
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
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

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.65,
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: AppTheme.textPrimary),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      ),
    );
  }
}
