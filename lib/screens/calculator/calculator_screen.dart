import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';

/// Kalkulator lengkap: operasi dasar, persen, kurung, riwayat.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  String? _error;
  final List<_HistoryItem> _history = [];
  bool _showHistory = false;
  bool _justEvaluated = false;

  static const List<String> _operators = ['+', '−', '×', '÷'];

  void _input(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;

      if (value == 'C') {
        _expression = '';
        _result = '0';
        return;
      }

      if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        return;
      }

      if (value == '=') {
        _evaluate();
        return;
      }

      // Setelah hasil muncul, ketik angka baru = mulai ekspresi baru.
      if (_justEvaluated) {
        final startsWithDigit = RegExp(r'^[0-9.]').hasMatch(value);
        if (startsWithDigit) {
          _expression = '';
          _result = '0';
        }
        _justEvaluated = false;
      }

      if (value == '%') {
        if (_expression.isEmpty) return;
        _expression += '%';
        return;
      }

      if (value == '±') {
        if (_expression.isEmpty) return;
        if (_expression.startsWith('-')) {
          _expression = _expression.substring(1);
        } else {
          _expression = '-$_expression';
        }
        return;
      }

      // Cegah dua operator berurutan.
      if (_operators.contains(value) && _expression.isNotEmpty) {
        final last = _expression.characters.last;
        if (_operators.contains(last)) {
          _expression =
              _expression.substring(0, _expression.length - 1) + value;
          return;
        }
      }

      // Cegah titik ganda dalam satu angka.
      if (value == '.') {
        final parts = _expression.split(RegExp(r'[+\-−×÷%()]'));
        if (parts.isNotEmpty && parts.last.contains('.')) return;
        if (_expression.isEmpty ||
            _operators.contains(_expression.characters.last) ||
            _expression.characters.last == '(') {
          _expression += '0.';
          return;
        }
      }

      _expression += value;
      // Tidak ada live preview: hasil hanya muncul setelah tombol "=".
    });
  }

  void _evaluate() {
    if (_expression.trim().isEmpty) return;
    try {
      final value = _compute(_expression);
      final formatted = _format(value);
      setState(() {
        _history.insert(
          0,
          _HistoryItem(expression: _expression, result: formatted),
        );
        _result = formatted;
        _expression = formatted;
        _error = null;
        _justEvaluated = true;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _error = e is FormatException ? e.message : 'Ekspresi tidak valid';
        _justEvaluated = false;
      });
    }
  }

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    var text = value.toStringAsFixed(10);
    text = text.replaceAll(RegExp(r'0+$'), '');
    text = text.replaceAll(RegExp(r'\.$'), '');
    return text;
  }

  double _compute(String input) {
    final normalized = input
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(',', '.');
    final parser = _Parser(normalized);
    final value = parser.parse();
    if (value.isNaN || value.isInfinite) {
      throw const FormatException('Hasil tidak terdefinisi');
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        withBlobs: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF1B1436),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kalkulator',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color:
                              isDark ? Colors.white : const Color(0xFF1B1436),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showHistory = !_showHistory),
                      style: IconButton.styleFrom(
                        backgroundColor: _showHistory
                            ? AppColors.primary.withValues(alpha: 0.16)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: _showHistory
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white
                                : const Color(0xFF1B1436)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ---------- Display ----------
              Expanded(
                flex: _showHistory ? 4 : 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _showHistory
                      ? _HistoryView(
                          items: _history,
                          onClear: () => setState(_history.clear),
                          onPick: (item) => setState(() {
                            _expression = item.result;
                            _result = item.result;
                            _showHistory = false;
                          }),
                        )
                      : _Display(
                          expression: _expression,
                          result: _result,
                          error: _error,
                        ),
                ),
              ),

              // ---------- Keypad ----------
              Container(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.72),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row(['C', '(', ')', '÷']),
                      _row(['7', '8', '9', '×']),
                      _row(['4', '5', '6', '−']),
                      _row(['1', '2', '3', '+']),
                      _row(['%', '0', '.', '=']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _CalcKey(
                label: key,
                onTap: () => _input(key),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Display extends StatelessWidget {
  final String expression;
  final String result;
  final String? error;

  const _Display({
    required this.expression,
    required this.result,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultSize = result.length > 12 ? 34.0 : (result.length > 8 ? 44.0 : 54.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (expression.isNotEmpty)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: expression));
              showAppSnack(context, 'Ekspresi disalin');
            },
            child: Text(
              expression,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF8B84AC),
              ),
            ),
          ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            error ?? result,
            maxLines: 1,
            style: TextStyle(
              fontSize: error != null ? 22 : resultSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: error != null
                  ? const Color(0xFFE5484D)
                  : (isDark ? Colors.white : const Color(0xFF1B1436)),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _HistoryView extends StatelessWidget {
  final List<_HistoryItem> items;
  final VoidCallback onClear;
  final ValueChanged<_HistoryItem> onPick;

  const _HistoryView({
    required this.items,
    required this.onClear,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Riwayat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1B1436),
              ),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              TextButton(
                onPressed: onClear,
                child: const Text('Hapus', style: TextStyle(fontSize: 12.5)),
              ),
          ],
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 46,
                        color: isDark ? Colors.white24 : const Color(0xFFD6D1E8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white38 : const Color(0xFFA9A3C2),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => onPick(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : const Color(0xFFEDEAF7),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.expression,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? Colors.white38
                                          : const Color(0xFFA9A3C2),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '= ${item.result}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1B1436),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.north_west_rounded,
                              size: 15,
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFC9C4DC),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CalcKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CalcKey({required this.label, required this.onTap});

  @override
  State<_CalcKey> createState() => _CalcKeyState();
}

class _CalcKeyState extends State<_CalcKey> {
  bool _pressed = false;

  bool get _isOperator => ['+', '−', '×', '÷', '%', '(', ')'].contains(
        widget.label,
      );
  bool get _isEquals => widget.label == '=';
  bool get _isClear => widget.label == 'C';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    if (_isEquals) {
      bg = Colors.transparent;
      fg = Colors.white;
    } else if (_isOperator) {
      bg = isDark
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.1);
      fg = isDark ? const Color(0xFFFFB27A) : AppColors.primary;
    } else if (_isClear) {
      bg = isDark
          ? AppColors.accent.withValues(alpha: 0.18)
          : AppColors.accent.withValues(alpha: 0.1);
      fg = AppColors.accent;
    } else {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.white;
      fg = isDark ? Colors.white : const Color(0xFF1B1436);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 62,
          decoration: BoxDecoration(
            color: _isEquals ? null : bg,
            gradient: _isEquals ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isEquals
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: _isEquals ? 24 : 21,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem {
  final String expression;
  final String result;

  _HistoryItem({required this.expression, required this.result});
}

/// Parser ekspresi matematika sederhana (recursive descent).
/// Mendukung: + - × ÷ %, tanda kurung, dan desimal.
class _Parser {
  _Parser(this.input);

  final String input;
  int _pos = 0;

  double parse() {
    final value = _parseExpression();
    _skipSpaces();
    if (_pos < input.length) {
      throw const FormatException('Karakter tidak dikenali');
    }
    return value;
  }

  void _skipSpaces() {
    while (_pos < input.length && input[_pos] == ' ') {
      _pos++;
    }
  }

  bool _match(String char) {
    _skipSpaces();
    if (_pos < input.length && input[_pos] == char) {
      _pos++;
      return true;
    }
    return false;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();
        if (divisor == 0) {
          throw const FormatException('Tidak bisa dibagi nol');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    var value = _parseUnary();
    while (_match('%')) {
      value = value / 100;
    }
    return value;
  }

  double _parseUnary() {
    if (_match('-')) return -_parseUnary();
    if (_match('+')) return _parseUnary();
    return _parsePrimary();
  }

  double _parsePrimary() {
    _skipSpaces();
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Kurung tidak seimbang');
      }
      return value;
    }

    _skipSpaces();
    final start = _pos;
    while (_pos < input.length &&
        (RegExp(r'[0-9.]').hasMatch(input[_pos]))) {
      _pos++;
    }
    if (start == _pos) {
      throw const FormatException('Ekspresi tidak valid');
    }
    final text = input.substring(start, _pos);
    final value = double.tryParse(text);
    if (value == null) {
      throw const FormatException('Angka tidak valid');
    }
    return value;
  }
}
