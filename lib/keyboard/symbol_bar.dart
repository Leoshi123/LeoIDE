import 'package:flutter/material.dart';
import 'symbol_data.dart';

/// Barra de símbolos sobre el teclado móvil.
///
/// El teclado móvil estándar no tiene teclas para `{}`, `[]`, `;`, etc.
/// Esta barra proporciona acceso rápido a los símbolos de programación
/// más usados, contextualizados según el lenguaje.
class SymbolBar extends StatelessWidget {
  /// Callback cuando el usuario toca un símbolo.
  final ValueChanged<String> onSymbolTap;

  /// Extensión del archivo actual para filtrar símbolos relevantes.
  final String fileExtension;

  /// Altura de la barra.
  final double height;

  /// Color de fondo.
  final Color backgroundColor;

  /// Color de los botones.
  final Color buttonColor;

  /// Color del texto de los símbolos.
  final Color symbolColor;

  const SymbolBar({
    super.key,
    required this.onSymbolTap,
    this.fileExtension = '.dart',
    this.height = 44.0,
    this.backgroundColor = const Color(0xFF2D2D2D),
    this.buttonColor = const Color(0xFF3C3C3C),
    this.symbolColor = const Color(0xFFCCCCCC),
  });

  @override
  Widget build(BuildContext context) {
    final symbols = SymbolData.forLanguage(fileExtension);

    return Container(
      height: height,
      color: backgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: symbols.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          return _SymbolButton(
            symbol: symbol,
            color: buttonColor,
            textColor: symbolColor,
            onTap: () => onSymbolTap(symbol),
          );
        },
      ),
    );
  }
}

class _SymbolButton extends StatelessWidget {
  final String symbol;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _SymbolButton({
    required this.symbol,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            symbol,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
