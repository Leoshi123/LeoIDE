import 'package:flutter/material.dart';
import '../completion/models/completion_item.dart';
import '../completion/models/completion_context.dart';

/// Popup de autocompletado con fuzzy scoring.
///
/// Muestra resultados agrupados por tipo, con colores estilo VS Code.
/// Navegación con teclado (↑↓), selección con Tab/Enter.
class CompletionPopup extends StatefulWidget {
  final List<CompletionItem> items;
  final CompletionContext context;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismiss;
  final int selectedIndex;

  const CompletionPopup({
    super.key,
    required this.items,
    required this.context,
    required this.onSelected,
    required this.onDismiss,
    this.selectedIndex = 0,
  });

  @override
  State<CompletionPopup> createState() => _CompletionPopupState();
}

class _CompletionPopupState extends State<CompletionPopup> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: const Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black45,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFF252526),
          border: Border.all(color: const Color(0xFF454545)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: tipo de trigger
            _buildHeader(),
            // Lista de sugerencias
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) => _buildItem(index),
              ),
            ),
            // Footer: info
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final triggerLabel = switch (widget.context.trigger) {
      CompletionTrigger.word => 'Autocompletando',
      CompletionTrigger.dot => 'Miembros',
      CompletionTrigger.scope => 'Scope',
      CompletionTrigger.import_ => 'Módulos',
      CompletionTrigger.manual => 'Sugerencias',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Row(
        children: [
          Text(
            triggerLabel,
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (widget.context.prefix.isNotEmpty)
            Text(
              '"${widget.context.prefix}"',
              style: const TextStyle(
                color: Color(0xFF569CD6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '${widget.items.length} resultados',
            style: const TextStyle(
              color: Color(0xFF5A5A5A),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = widget.items[index];
    final isSelected = index == widget.selectedIndex;
    final iconColor = Color(item.colorHex);

    return Container(
      color: isSelected ? const Color(0xFF094771) : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelected(item.insertText),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              // Icono
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.icon,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Label
              Expanded(
                child: RichText(
                  text: _buildHighlightedText(item),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Detail
              Text(
                item.detail,
                style: const TextStyle(
                  color: Color(0xFF858585),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resalta el prefijo en el label con negrita.
  TextSpan _buildHighlightedText(CompletionItem item) {
    final prefix = widget.context.prefix;
    if (prefix.isEmpty || !item.label.toLowerCase().startsWith(prefix.toLowerCase())) {
      return TextSpan(
        text: item.label,
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      );
    }

    return TextSpan(
      children: [
        TextSpan(
          text: item.label.substring(0, prefix.length),
          style: const TextStyle(
            color: Color(0xFFD4D4D4),
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: item.label.substring(prefix.length),
          style: const TextStyle(
            color: Color(0xFF858585),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Row(
        children: [
          _keyHint('Tab', 'insertar'),
          const SizedBox(width: 12),
          _keyHint('↑↓', 'navegar'),
          const SizedBox(width: 12),
          _keyHint('Esc', 'cerrar'),
        ],
      ),
    );
  }

  Widget _keyHint(String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          action,
          style: const TextStyle(
            color: Color(0xFF5A5A5A),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
