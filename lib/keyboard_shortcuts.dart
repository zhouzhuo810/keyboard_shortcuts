library keyboard_shortcuts;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

List<_KeyBoardShortcuts> _keyBoardShortcuts = [];
IconData? _customIcon;

class KeyBoardShortcuts extends StatefulWidget {
  final Widget child;

  /// You can use shortCut function with BasicShortCuts to avoid write data by yourself
  final Set<LogicalKeyboardKey> keysToPress;

  /// Function when keys are pressed
  final VoidCallback onKeysPressed;

  /// Label who will be displayed in helper
  final String? helpLabel;

  KeyBoardShortcuts(
      {required this.keysToPress,
      required this.onKeysPressed,
      this.helpLabel,
      required this.child,
      Key? key})
      : super(key: key);

  @override
  _KeyBoardShortcuts createState() => _KeyBoardShortcuts();
}

class _KeyBoardShortcuts extends State<KeyBoardShortcuts> {
  FocusScopeNode? focusScopeNode;
  bool listening = false;
  Key? key;

  @override
  void initState() {
    _attachKeyboardIfDetached();
    key = widget.key ?? UniqueKey();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _detachKeyboardIfAttached();
  }

  void _attachKeyboardIfDetached() {
    if (listening) return;
    _keyBoardShortcuts.add(this);
    RawKeyboard.instance.addListener(listener);
    listening = true;
  }

  void _detachKeyboardIfAttached() {
    if (!listening) return;
    _keyBoardShortcuts.remove(this);
    RawKeyboard.instance.removeListener(listener);
    listening = false;
  }

  void listener(RawKeyEvent v) async {
    if (!mounted) return;

    Set<LogicalKeyboardKey> keysPressed = RawKeyboard.instance.keysPressed;
    if (v.runtimeType == RawKeyDownEvent) {
      // when user type keysToPress
      if (_isPressed(keysPressed, widget.keysToPress)) {
        widget.onKeysPressed.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: key!,
      child: widget.child,
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1)
          _attachKeyboardIfDetached();
        else
          _detachKeyboardIfAttached();
      },
    );
  }

  bool _isPressed(Set<LogicalKeyboardKey> keysPressed,
      Set<LogicalKeyboardKey> keysToPress) {
    //when we type shift on chrome flutter's core return two pressed keys : Shift Left && Shift Right. So we need to delete one on the set to run the action
    var rights = keysPressed
        .where((element) => element.debugName?.contains("Right") ?? false);
    var lefts = keysPressed.where((element) => element.debugName?.contains("Left") ?? false);
    var toRemove = [];

    for (final rightElement in rights) {
      LogicalKeyboardKey? leftElement;
      if (lefts.isNotEmpty) {
        try {
          lefts.firstWhere(
                        (element) =>
                    element.debugName != null &&
                        rightElement.debugName != null &&
                        element.debugName!.split(" ")[0] ==
                            rightElement.debugName!.split(" ")[0]);
        } catch (e) {
        }
      }
      if (leftElement != null) {
        var actualKey = keysToPress.where((element) =>
            element.debugName?.split(" ")[0] ==
            rightElement.debugName?.split(" ")[0]);
        if (actualKey.length > 0 &&
            (actualKey.first.debugName?.isNotEmpty ?? false))
          (actualKey.first.debugName?.contains("Right") ?? false)
              ? toRemove.add(leftElement)
              : toRemove.add(rightElement);
      }
    }

    keysPressed.removeWhere((e) => toRemove.contains(e));

    return keysPressed.containsAll(keysToPress) &&
        keysPressed.length == keysToPress.length;
  }

}
