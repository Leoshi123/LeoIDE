import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Panel de terminal inferior para salida de ejecución.
///
/// Muestra logs con estilo de terminal, con opciones para:
/// - Copiar todo al portapapeles
/// - Limpiar contenido
/// - Seleccionar texto
class TerminalPanel extends StatelessWidget {
  final List<String> logs;
  final bool isDark;
  final VoidCallback onClear;

  const TerminalPanel({
    super.key,
    required this.logs,
    required this.isDark,
    required this.onClear,
  });

  void _copyAll(BuildContext context) {
    final text = logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Terminal copiado al portapapeles'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final titleBarBg =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFDDDDDD);
    final titleColor =
        isDark ? const Color(0xFF858585) : const Color(0xFF666666);
    final iconColor =
        isDark ? const Color(0xFF858585) : const Color(0xFF666666);
    final emptyColor =
        isDark ? const Color(0xFF555555) : const Color(0xFF999999);
    final textColor =
        isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Barra de título ──
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: titleBarBg,
            child: Row(
              children: [
                Icon(Icons.terminal, size: 14, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  'TERMINAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                if (logs.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _copyAll(context),
                    child: Icon(Icons.copy, size: 14, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                ],
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.delete_outline, size: 16, color: iconColor),
                ),
              ],
            ),
          ),
          // ── Contenido ──
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'Presiona ▶ Run para ejecutar código',
                      style: TextStyle(
                        color: emptyColor,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      logs.join('\n'),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                        color: textColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
