import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../core/freemium/freemium_service.dart';

/// A "Save Scenario" button that pins the current calculator result.
///
/// - **Premium users**: shows a name-entry dialog before saving.
/// - **Free users**: saves immediately without a label (3 max pinned slots).
///
/// Usage:
/// ```dart
/// SaveScenarioButton(
///   onSave: (label) => context.read<USProvider>().saveScenario(label: label),
/// )
/// ```
class SaveScenarioButton extends StatefulWidget {
  /// Called when the user confirms the save. [label] is null for free users.
  final Future<void> Function(String? label) onSave;

  const SaveScenarioButton({super.key, required this.onSave});

  @override
  State<SaveScenarioButton> createState() => _SaveScenarioButtonState();
}

class _SaveScenarioButtonState extends State<SaveScenarioButton> {
  bool _saving = false;

  Future<void> _handleTap() async {
    String? label;

    if (freemiumService.hasFullAccess) {
      // Premium: show name dialog
      label = await _showNameDialog();
      if (label == null) return; // user cancelled
      if (label.trim().isEmpty) label = null;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(label);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label != null && label.isNotEmpty
                ? 'Scenario "$label" saved'
                : 'Scenario saved',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Scenario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Scenario name (optional)',
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _saving ? null : _handleTap,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bookmark_add_outlined, size: 18),
          label: Text(_saving ? 'Saving…' : 'Save Scenario'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
