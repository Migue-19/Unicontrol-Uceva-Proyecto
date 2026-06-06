import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:unicontrol_app/services/firma_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';

class FirmaValidacionDialog extends StatefulWidget {
  const FirmaValidacionDialog({super.key});

  @override
  State<FirmaValidacionDialog> createState() => _FirmaValidacionDialogState();
}

class _FirmaValidacionDialogState extends State<FirmaValidacionDialog> {
  late final SignatureController _controller;
  bool _isValidating = false;
  double? _similitud;
  bool? _esValida;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validarFirma() async {
    if (_controller.isEmpty) {
      showAppSnackBar(context, 'Por favor dibuja tu firma', isError: true);
      return;
    }

    setState(() {
      _isValidating = true;
      _similitud = null;
      _esValida = null;
    });

    try {
      // Exportación explícita del canvas para estabilizar captura en web/móvil.
      final Uint8List? bytes = await _controller.toPngBytes(
        height: 400,
        width: 800,
      );
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        setState(() => _isValidating = false);
        showAppSnackBar(context, 'Error al capturar la firma', isError: true);
        return;
      }

      debugPrint('Firma capturada: ${bytes.length} bytes');

      final similitud = await FirmaService().calcularSimilitud(bytes);
      final valida = FirmaService().esValida(similitud);

      if (!mounted) return;

      if (valida) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _similitud = similitud;
        _esValida = false;
        _isValidating = false;
      });
    } catch (e) {
      debugPrint('Error validando firma: $e');
      if (!mounted) return;
      setState(() => _isValidating = false);
      showAppSnackBar(context, 'Error: $e', isError: true);
    }
  }

  void _limpiar() {
    _controller.clear();
    setState(() {
      _similitud = null;
      _esValida = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.draw_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Validación de Firma',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Firma en el recuadro para confirmar tu decisión',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedForeground,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isValidating ? null : _limpiar,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isValidating
                            ? null
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isValidating ? null : _validarFirma,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor:
                              AppTheme.primary.withOpacity(0.55),
                          disabledForegroundColor: Colors.white,
                        ),
                        icon: _isValidating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                _esValida == false
                                    ? Icons.restart_alt_rounded
                                    : Icons.check_circle_rounded,
                              ),
                        label: Text(
                          _isValidating
                              ? 'Validando'
                              : (_esValida == false
                                  ? 'Intentar de nuevo'
                                  : 'Validar'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_esValida == false && _similitud != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.destructive.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '❌ Firma no válida',
                        style: TextStyle(
                          color: AppTheme.destructive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Similitud calculada: ${_similitud!.toStringAsFixed(1)}%',
                        style: TextStyle(color: AppTheme.destructive),
                      ),
                    ],
                  ),
                ),
              if (_similitud != null && _esValida == true)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.success.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '✅ Firma validada con ${_similitud!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isValidating
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}