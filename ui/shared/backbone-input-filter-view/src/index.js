//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import InputView from '@canvas/backbone-input-view'

// Makes an input field that emits `input` and `select` events, and
// automatically selects itself if the user presses the enter key (don't have
// to backspace out the text, or if you do, it deletes all of it).
//
// Events:
//
//   input: Emits after a short delay so it doesn't fire off the event with
//   every keyup from the user, sends the value of the input in the event
//   parameters.
//
//   enter: Emits when the user hits enter in the field

class InputFilterView extends InputView {
  constructor(...args) {
    super(...args)
    this.onInput = this.onInput.bind(this)
  }

  onInput() {
    clearTimeout(this.onInputTimer)
    delete this.onInputTimer
    if (this.el.value !== this.lastValue) {
      this.updateModel()
      this.trigger('input', this.el.value)
    }
    this.lastValue = this.el.value
  }

  onEnter() {
    this.el.select()
    this.trigger('enter', this.el.value)
  }

  keyup(e) {
    if (typeof this.onInputTimer !== 'undefined') clearTimeout(this.onInputTimer)
    this.onInputTimer = setTimeout(this.onInput, this.options.onInputDelay)
    if (e.which !== null && typeof e.which !== 'undefined' && e.which === 13) this.onEnter()
    return null
  }
}

InputFilterView.prototype.events = {keyup: 'keyup', change: 'change'}
InputFilterView.prototype.change = InputFilterView.prototype.keyup

InputFilterView.prototype.defaults = {
  onInputDelay: 200,
  modelAttribute: 'filter',
  minLength: 3,
  allowSmallerNumbers: true,
}

export default InputFilterView
