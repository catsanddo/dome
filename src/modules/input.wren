import "vector" for Vector
import "dome" for StringUtils

class Input {
  // This sets up the whole module's event loop behaviour
  foreign static f_captureVariables()

  construct init() {
    _down = false
    _current = false
    _previous = false
    _halfTransitions = 0
    _repeats = 0
  }
  commit() {
    _previous = _down
    _down = _current
    if (_down && _previous == _down) {
      _repeats = _repeats + 1
    } else {
      _repeats = 0
    }
  }

  update(state) {
    _current = state
  }

  down { _down }
  previous { _previous }
  repeats { _repeats }
}

class Keyboard {
  static isKeyDown(key) {
    return Keyboard[StringUtils.toLowercase(key)].down
  }
  static init_() {
    __keys = {}
  }

  static [name] {
    name = StringUtils.toLowercase(name)
    if (!__keys.containsKey(name)) {
      update(name, false)
    }
    return __keys[name]
  }

  // PRIVATE, called by game loop
  static update(keyName, state) {
    if (!__keys.containsKey(keyName)) {
      __keys[keyName] = Input.init()
    }
    __keys[keyName].update(state)
  }

  static commit() {
    __keys.values.each {|key| key.commit() }
  }
}


class Mouse {
  foreign static x
  foreign static y

  foreign static hidden
  foreign static hidden=(value)

  static isButtonPressed(key) {
    return Mouse[StringUtils.toLowercase(key)].down
  }

  static init_() {
    __buttons = {}
  }
  static [name] {
    name = StringUtils.toLowercase(name)
    if (!__buttons.containsKey(name)) {
      update(name, false)
    }
    return __buttons[name]
  }

  // PRIVATE, called by game loop
  static update(keyName, state) {
    if (!__buttons.containsKey(keyName)) {
      __buttons[keyName] = Input.init()
    }
    __buttons[keyName].update(state)
  }

  static commit() {
    __buttons.values.each {|button| button.commit() }
  }
}

foreign class SystemGamePad {
  construct open(index) {}

  foreign close()

  foreign attached
  foreign id
  foreign name

  foreign f_getAnalogStick(side)
  foreign getTrigger(side)

  getAnalogStick(side) {
    var stick = f_getAnalogStick(side)
    return Vector.new(stick[0], stick[1])
  }
  foreign static f_getGamePadIds()
}

class GamePad {

  construct open(index) {
    _pad = SystemGamePad.open(index)
    _buttons = {}
  }

  close() {
    _pad.close()
  }

  attached { _pad.attached }
  id { _pad.id }
  name { _pad.name }

  [button] {
    var name = StringUtils.toLowercase(button)
    if (!_buttons.containsKey(name)) {
      _buttons[name] = Input.init()
    }
    return _buttons[name]
  }

  isButtonPressed(key) {
    return this[key].down
  }

  getTrigger(side) { _pad.getTrigger(side) }
  getAnalogStick(side) { _pad.getAnalogStick(side) }

  // PRIVATE, called by game loop
  update(buttonName, state) {
    var button = this[buttonName]
    button.update(state)
  }
  commit() {
    _buttons.values.each {|button| button.commit() }
  }


  static init_() {
    __pads = {}
    __dummy = GamePad.open(-1)
    SystemGamePad.f_getGamePadIds().each {|id|
      addGamePad(id)
    }
  }

  static [n] {
    if (!__pads[n]) {
      return __dummy
    }
    return __pads[n]
  }

  static all { __pads.values }


  static commit() {
    __pads.values.where {|pad| pad.attached }.each {|pad|
      pad.commit()
    }
  }

  static next {
    if (__pads.count > 0) {
      return __pads.values.where {|pad| pad.attached }.toList[0]
    } else {
      return __dummy
    }
  }

  static addGamePad(joystickId) {
    var pad = GamePad.open(joystickId)
    __pads[pad.id] = pad
  }

  static removeGamePad(instanceId) {
    __pads[instanceId].close()
    __pads.remove(instanceId)
  }

}

// Module Setup
Input.f_captureVariables()
GamePad.init_()
Keyboard.init_()
Mouse.init_()
