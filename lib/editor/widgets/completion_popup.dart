import 'package:flutter/material.dart';
import '../engine/symtable.dart';

/// Popup de autocompletado que aparece mientras el usuario escribe.
///
/// Muestra sugerencias de la SymTable filtradas por el prefijo actual.
/// Se posiciona cerca del cursor en el editor.
class CompletionPopup extends StatefulWidget {
  final SymTable symTable;
  final String currentText;
  final int cursorOffset;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;

  const CompletionPopup({
    super.key,
    required this.symTable,
    required this.currentText,
    required this.cursorOffset,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  State<CompletionPopup> createState() => _CompletionPopupState();
}

class _CompletionPopupState extends State<CompletionPopup> {
  late List<SymEntry> _suggestions;
  int _selectedIndex = 0;
  String _prefix = '';

  @override
  void initState() {
    super.initState();
    _updateSuggestions();
  }

  @override
  void didUpdateWidget(CompletionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentText != widget.currentText ||
        oldWidget.cursorOffset != widget.cursorOffset) {
      _updateSuggestions();
    }
  }

  void _updateSuggestions() {
    _prefix = _extractPrefix();
    _suggestions = widget.symTable.query(_prefix);
    _selectedIndex = 0;

    if (_suggestions.isEmpty) {
      widget.onDismiss();
    }
  }

  String _extractPrefix() {
    if (widget.cursorOffset <= 0) return '';

    final before = widget.currentText.substring(0, widget.cursorOffset);
    final match = RegExp(r'(\w+)$').firstMatch(before);
    return match?.group(1) ?? '';
  }

  void _select(int index) {
    if (index >= 0 && index < _suggestions.length) {
      final suggestion = _suggestions[index];
      final rest = suggestion.name.substring(_prefix.length);
      widget.onSelected(rest);
    }
  }

  void moveUp() {
    if (_selectedIndex > 0) {
      setState(() => _selectedIndex--);
    }
  }

  void moveDown() {
    if (_selectedIndex < _suggestions.length - 1) {
      setState(() => _selectedIndex++);
    }
  }

  void selectCurrent() => _select(_selectedIndex);

  bool get hasSuggestions => _suggestions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      color: const Color(0xFF252526),
      surfaceTintColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
        decoration: BoxDecoration(
          color: const Color(0xFF252526),
          border: Border.all(color: const Color(0xFF3C3C3C)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final entry = _suggestions[index];
            final isSelected = index == _selectedIndex;

            return Material(
              color: isSelected
                  ? const Color(0xFF094771)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => _select(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      // Icono según tipo
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _iconColor(entry.type).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.icon,
                          style: TextStyle(
                            color: _iconColor(entry.type),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nombre del símbolo
                      Expanded(
                        child: Text(
                          entry.name,
                          style: const TextStyle(
                            color: Color(0xFFD4D4D4),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Descripción
                      Text(
                        entry.description,
                        style: TextStyle(
                          color: const Color(0xFF858585),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _iconColor(SymType type) {
    switch (type) {
      case SymType.function:
        return const Color(0xFFDCDCAA); // Amarillo
      case SymType.keyword:
        return const Color(0xFF569CD6); // Azul
      case SymType.className:
        return const Color(0xFF4EC9B0); // Verde agua
      case SymType.variable:
        return const Color(0xFF9CDCFE); // Azul claro
      case SymType.module:
        return const Color(0xFFCE9178); // Naranja
    }
  }
}
