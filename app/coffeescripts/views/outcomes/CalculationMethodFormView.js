//
// Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'

import Backbone from 'Backbone'
import template from 'jst/outcomes/outcomeCalculationMethodForm'
import numberHelper from 'jsx/shared/helpers/numberHelper'

export default class CalculationMethodFormView extends Backbone.View {
  static initClass() {
    this.optionProperty('el')
    this.optionProperty('model')
    this.optionProperty('state')

    this.prototype.template = template

    this.prototype.els = {'#calculation_int': '$calculation_int'}
    this.prototype.events = {
      'blur #calculation_int': 'blur',
      'keyup #calculation_int': 'keyup'
    }
  }

  afterRender() {
    if (this.hadFocus) {
      this.$calculation_int.focus().val(this.$calculation_int.val())
      this.$calculation_int[0].selectionStart = this.selectionStart
    }
    return (this.hadFocus = undefined)
  }

  attach() {
    return this.model.on('change:calculation_method', this.render)
  }

  blur(e) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    return this.change(e)
  }

  change(e) {
    const val = parseInt(numberHelper.parse($(e.target).val()))
    if (_.isNaN(val)) return
    this.model.set({
      calculation_int: val
    })
    return this.render()
  }

  keyup(e) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.timeout = setTimeout(() => this.change(e), 500)
  }

  // Three things we want to accomplish with this override:
  // 1 - capture whether or not the calculation int input field has
  //     focus (this will be true if we're rendering after a keyup
  //     event) so we can go back to it after re-render.
  // 2 - undelegateEvents so the re-render doesn't trigger blur if
  //     the calculation int input has focus.
  // 3 - delegateEvents again after render so that we are hooked up
  //     to handle the next round of events.
  render() {
    this.hadFocus =
      !_.isEmpty(this.$calculation_int) && document.activeElement === this.$calculation_int[0]
    if (this.hadFocus) {
      this.selectionStart = document.activeElement.selectionStart
    }
    this.undelegateEvents()
    super.render(...arguments)
    return this.delegateEvents()
  }

  toJSON() {
    return _.extend(super.toJSON(...arguments), {
      state: this.state,
      writeStates: ['add', 'edit']
    })
  }
}
CalculationMethodFormView.initClass()
