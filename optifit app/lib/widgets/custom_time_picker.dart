import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class TimePickerMock extends StatefulWidget {
  const TimePickerMock({
    super.key,
    this.initialTime = const TimeOfDay(hour: 7, minute: 0),
    this.onChanged,
  });

  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay>? onChanged;

  @override
  State<TimePickerMock> createState() => _TimePickerMockState();
}

class _TimePickerMockState extends State<TimePickerMock> {
  late int _hour12;
  late int _minute;
  late bool _isAm;
  _Mode _mode = _Mode.hour;
  bool _isEditingHour = false;
  bool _isEditingMinute = false;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late FocusNode _hourFocusNode;
  late FocusNode _minuteFocusNode;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAm = h < 12;
    _hour12 = ((h % 12) == 0) ? 12 : (h % 12);
    _minute = widget.initialTime.minute;
    
    _hourController = TextEditingController(text: _hour12.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: _minute.toString().padLeft(2, '0'));
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();
    
    _hourFocusNode.addListener(() {
      if (!_hourFocusNode.hasFocus && _isEditingHour) {
        _finishEditingHour();
      }
    });
    
    _minuteFocusNode.addListener(() {
      if (!_minuteFocusNode.hasFocus && _isEditingMinute) {
        _finishEditingMinute();
      }
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  void _notify() {
    final hour24 = (_isAm)
        ? (_hour12 == 12 ? 0 : _hour12)
        : (_hour12 == 12 ? 12 : _hour12 + 12);
    widget.onChanged?.call(TimeOfDay(hour: hour24, minute: _minute));
  }

  void _startEditingHour() {
    setState(() {
      _isEditingHour = true;
      _mode = _Mode.hour;
    });
    _hourController.text = _hour12.toString().padLeft(2, '0');
    _hourController.selection = TextSelection.fromPosition(
      TextPosition(offset: _hourController.text.length),
    );
    _hourFocusNode.requestFocus();
  }

  void _startEditingMinute() {
    setState(() {
      _isEditingMinute = true;
      _mode = _Mode.minute;
    });
    _minuteController.text = _minute.toString().padLeft(2, '0');
    _minuteController.selection = TextSelection.fromPosition(
      TextPosition(offset: _minuteController.text.length),
    );
    _minuteFocusNode.requestFocus();
  }

  void _finishEditingHour() {
    final hour = int.tryParse(_hourController.text);
    if (hour != null && hour >= 1 && hour <= 12) {
      setState(() {
        _hour12 = hour;
        _isEditingHour = false;
      });
      _notify();
    } else {
      _hourController.text = _hour12.toString().padLeft(2, '0');
      setState(() {
        _isEditingHour = false;
      });
    }
  }

  void _finishEditingMinute() {
    final minute = int.tryParse(_minuteController.text);
    if (minute != null && minute >= 0 && minute <= 59) {
      setState(() {
        _minute = minute;
        _isEditingMinute = false;
      });
      _notify();
    } else {
      _minuteController.text = _minute.toString().padLeft(2, '0');
      setState(() {
        _isEditingMinute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 14,
                child: GestureDetector(
                  onTap: () => setState(() => _mode = _Mode.hour),
                  onDoubleTap: _startEditingHour,
                  child: _isEditingHour ? _EditableNumberChip(
                    controller: _hourController,
                    focusNode: _hourFocusNode,
                    background: _mode == _Mode.hour ? AppTheme.primary.withOpacity(0.1) : AppTheme.chipBackground,
                    textColor: _mode == _Mode.hour ? AppTheme.primary : AppTheme.textPrimary,
                    height: 86,
                    baseFontSize: 68,
                    onSubmitted: (value) => _finishEditingHour(),
                  ) : _NumberChip(
                    background: _mode == _Mode.hour ? AppTheme.primary.withOpacity(0.1) : AppTheme.chipBackground,
                    textColor: _mode == _Mode.hour ? AppTheme.primary : AppTheme.textPrimary,
                    valueText: _hour12.toString().padLeft(2, '0'),
                    height: 86,
                    baseFontSize: 68,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              SizedBox(
                width: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 54, 
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                flex: 14,
                child: GestureDetector(
                  onTap: () => setState(() => _mode = _Mode.minute),
                  onDoubleTap: _startEditingMinute,
                  child: _isEditingMinute ? _EditableNumberChip(
                    controller: _minuteController,
                    focusNode: _minuteFocusNode,
                    background: _mode == _Mode.minute ? AppTheme.primary.withOpacity(0.1) : AppTheme.chipBackground,
                    textColor: _mode == _Mode.minute ? AppTheme.primary : AppTheme.textPrimary,
                    height: 86,
                    baseFontSize: 56,
                    onSubmitted: (value) => _finishEditingMinute(),
                  ) : _NumberChip(
                    background: _mode == _Mode.minute ? AppTheme.primary.withOpacity(0.1) : AppTheme.chipBackground,
                    textColor: _mode == _Mode.minute ? AppTheme.primary : AppTheme.textPrimary,
                    valueText: _minute.toString().padLeft(2, '0'),
                    height: 86,
                    baseFontSize: 56,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Container(
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AmPmItem(
                      label: 'AM',
                      selected: _isAm,
                      onTap: () {
                        setState(() => _isAm = true);
                        _notify();
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
                    _AmPmItem(
                      label: 'PM',
                      selected: !_isAm,
                      onTap: () {
                        setState(() => _isAm = false);
                        _notify();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (_, constraints) {
                return GestureDetector(
                  onPanStart: (d) => _handlePoint(d.localPosition, constraints.biggest),
                  onPanUpdate: (d) => _handlePoint(d.localPosition, constraints.biggest),
                  onTapDown: (d) => _handlePoint(d.localPosition, constraints.biggest),
                  child: CustomPaint(
                    painter: _ClockFacePainter(
                      mode: _mode,
                      selectedHour: _hour12,
                      minute: _minute,
                      numberColor: AppTheme.textSecondary,
                      handColor: AppTheme.primary,
                      knobFill: AppTheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handlePoint(Offset p, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final v = p - center;
    if (v.distance < size.width * 0.18) return;

    var deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    if (deg < 0) deg += 360;

    if (_mode == _Mode.hour) {
      final slot = (deg / 30).round();
      var h = (slot + 3) % 12;
      if (h == 0) h = 12;
      setState(() => _hour12 = h);
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _mode = _Mode.minute);
        }
      });
    } else {
      final minuteAngle = (deg + 90) % 360;
      final m = ((minuteAngle / 6).round()) % 60;
      setState(() => _minute = m);
    }
    _notify();
  }
}

enum _Mode { hour, minute }

class _EditableNumberChip extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color background;
  final Color textColor;
  final double height;
  final double baseFontSize;
  final ValueChanged<String> onSubmitted;

  const _EditableNumberChip({
    required this.controller,
    required this.focusNode,
    required this.background,
    required this.textColor,
    required this.height,
    required this.baseFontSize,
    required this.onSubmitted,
  });

  @override
  State<_EditableNumberChip> createState() => _EditableNumberChipState();
}

class _EditableNumberChipState extends State<_EditableNumberChip>
    with TickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cursorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.linear),
    );
    _cursorController.repeat(reverse: true);
    
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _cursorController.repeat(reverse: true);
    } else {
      _cursorController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          color: widget.background,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => widget.focusNode.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.controller.text,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.baseFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _cursorAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: widget.focusNode.hasFocus ? _cursorAnimation.value : 0.0,
                            child: Container(
                              width: 2,
                              height: widget.baseFontSize * 0.8,
                              color: widget.textColor,
                              margin: const EdgeInsets.only(left: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.transparent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: widget.onSubmitted,
                      onChanged: (value) => setState(() {}),
                      maxLength: 2,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  final Color background;
  final Color textColor;
  final String valueText;
  final double height;
  final double baseFontSize;

  const _NumberChip({
    required this.background,
    required this.textColor,
    required this.valueText,
    required this.height,
    this.baseFontSize = 68,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          color: background,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valueText,
              style: TextStyle(
                color: textColor,
                fontSize: baseFontSize,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmPmItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmPmItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ClockFacePainter extends CustomPainter {
  final _Mode mode;
  final int selectedHour; // 1..12
  final int minute; // 0..55
  final Color numberColor;
  final Color handColor;
  final Color knobFill;

  _ClockFacePainter({
    required this.mode,
    required this.selectedHour,
    required this.minute,
    required this.numberColor,
    required this.handColor,
    required this.knobFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    final bgPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Compute hand angle first (needed for positioning)
    double angleDeg;
    if (mode == _Mode.hour) {
      angleDeg = (selectedHour - 3) * 30;
    } else {
      // Use precise minute angle (6 degrees per minute)
      angleDeg = (minute - 15) * 6; // -15 to start at 12 o'clock position
    }
    final angle = angleDeg * math.pi / 180;

    // Hand
    final handEnd = Offset(
      center.dx + radius * 0.8 * math.cos(angle),
      center.dy + radius * 0.8 * math.sin(angle),
    );
    final handPaint = Paint()
      ..color = handColor
      ..strokeWidth = 2;
    canvas.drawLine(center, handEnd, handPaint);

    final numberStyle = TextStyle(fontSize: 18, color: numberColor);

    // Draw numbers around ring
    for (int i = 1; i <= 12; i++) {
      final angle = (i - 3) * 30 * math.pi / 180;
      final pos = Offset(
        center.dx + radius * 0.8 * math.cos(angle),
        center.dy + radius * 0.8 * math.sin(angle),
      );

      final label = (mode == _Mode.hour)
          ? i.toString()
          : ((i % 12) * 5).toString(); // 12->0

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: numberStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw knob and knob text last so they appear on top
    final knobPaint = Paint()..color = knobFill;
    canvas.drawCircle(handEnd, 20, knobPaint);

    // Draw small center circle (opposite end of the hand)
    final centerCirclePaint = Paint()..color = knobFill;
    canvas.drawCircle(center, 6, centerCirclePaint);

    final knobText = TextPainter(
      text: TextSpan(
        text: mode == _Mode.hour
            ? selectedHour.toString()
            : minute.toString(), // Show exact minute, not rounded
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    knobText.paint(
      canvas,
      handEnd - Offset(knobText.width / 2, knobText.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ClockFacePainter old) =>
      old.mode != mode ||
      old.selectedHour != selectedHour ||
      old.minute != minute ||
      old.numberColor != numberColor ||
      old.handColor != handColor ||
      old.knobFill != knobFill;
}
