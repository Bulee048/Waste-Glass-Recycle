import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/trip_summary_model.dart';
import '../providers/scan_collect_provider.dart';
import '../utils/trip_advance.dart';
import 'barcode_scanner_screen.dart';
import 'trip_report_screen.dart';

const _conditionOptions = ['Good', 'Contaminated', 'Damaged', 'Empty (No Glass)'];

class ScanCollectScreen extends ConsumerWidget {
  const ScanCollectScreen({super.key, required this.trip});

  final TripSummaryModel trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ScanCollectView(trip: trip);
  }
}

class _ScanCollectView extends ConsumerStatefulWidget {
  const _ScanCollectView({required this.trip});

  final TripSummaryModel trip;

  @override
  ConsumerState<_ScanCollectView> createState() => _ScanCollectViewState();
}

class _ScanCollectViewState extends ConsumerState<_ScanCollectView> {
  final _clearController = TextEditingController();
  final _colouredController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _condition = _conditionOptions.first;
  int? _lastStopSequence;

  @override
  void dispose() {
    _clearController.dispose();
    _colouredController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _clearController.clear();
    _colouredController.clear();
    setState(() => _condition = _conditionOptions.first);
  }

  Future<void> _openScanner() async {
    ref.read(scanCollectProvider(widget.trip).notifier).clearScanError();

    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (!mounted || scanned == null) {
      return;
    }

    ref.read(scanCollectProvider(widget.trip).notifier).handleScanResult(scanned);
    final state = ref.read(scanCollectProvider(widget.trip));

    if (state.scanVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Barcode verified'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmCollection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clearKg = double.parse(_clearController.text.trim());
    final colouredKg = double.parse(_colouredController.text.trim());

    final result =
        await ref.read(scanCollectProvider(widget.trip).notifier).confirmCollection(
              clearKg: clearKg,
              colouredKg: colouredKg,
              condition: _condition,
            );

    if (!mounted) {
      return;
    }

    if (!result.syncedToServer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved locally — will sync when online'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    if (result.tripComplete) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TripReportScreen(
            tripId: ref.read(scanCollectProvider(widget.trip)).trip.tripId,
          ),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    _resetForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Collection recorded — scan the next stop'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanCollectProvider(widget.trip));
    final stop = state.currentStop;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#0.0');

    if (stop != null && stop.sequenceOrder != _lastStopSequence) {
      _lastStopSequence = stop.sequenceOrder;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _resetForm();
        }
      });
    }

    if (state.isTripComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TripReportScreen(tripId: state.trip.tripId),
          ),
        );
      });
    }

    final completedCount = collectedStopCount(state.trip);
    final progressLabel = stop != null
        ? 'Stop ${stop.sequenceOrder} of ${state.trip.stops.length}'
        : 'All stops complete';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Collect'),
      ),
      body: stop == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                LinearProgressIndicator(
                  value: state.trip.stops.isEmpty
                      ? 0
                      : completedCount / state.trip.stops.length,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  progressLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next stop: ${stop.supplierName}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stop.address != null &&
                            stop.address!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  stop.address!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          stop.supplierCode,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isSubmitting ? null : _openScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (state.scanError != null) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.scanError!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (state.scanVerified) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Supplier verified — enter quantities below',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _clearController,
                          enabled: !state.isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Clear glass (kg)',
                            helperText:
                                'Expected: ${numberFormat.format(stop.expectedClearKg)} kg',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          validator: _validateKg,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _colouredController,
                          enabled: !state.isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Coloured glass (kg)',
                            helperText:
                                'Expected: ${numberFormat.format(stop.expectedColouredKg)} kg',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          validator: _validateKg,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey(stop.supplierCode),
                          initialValue: _condition,
                          decoration: const InputDecoration(
                            labelText: 'Condition',
                            border: OutlineInputBorder(),
                          ),
                          items: _conditionOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: state.isSubmitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _condition = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: state.isSubmitting || !_isFormValid()
                                ? null
                                : _confirmCollection,
                            icon: state.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              state.isSubmitting
                                  ? 'Saving…'
                                  : 'Confirm Collection',
                            ),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Text(
                    'Scan the supplier barcode to unlock quantity entry.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String? _validateKg(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a weight';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a number ≥ 0';
    }
    return null;
  }

  bool _isFormValid() {
    final clear = double.tryParse(_clearController.text.trim());
    final coloured = double.tryParse(_colouredController.text.trim());
    return clear != null &&
        clear >= 0 &&
        coloured != null &&
        coloured >= 0;
  }
}
