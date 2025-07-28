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

import $ from 'jquery'
import {isNaN, isEmpty, extend} from 'lodash'

import Backbone from '@canvas/backbone'
import template from '../../jst/outcomeCalculationMethodForm.handlebars'
import exampleTemplate from '../../../jst/_calculationMethodExample.handlebars'
import numberHelper from '@canvas/i18n/numberHelper'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import {createRoot} from 'react-dom/client'
import {createElement} from 'react';
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'

export default class CalculationMethodFormView extends Backbone.View {
  static initClass() {
    this.optionProperty('el')
    this.optionProperty('model')
    this.optionProperty('state')

    this.prototype.template = template

    this.prototype.els = {'#calculation_int': '$calculation_int'}
    this.prototype.events = {
      'blur #calculation_int': 'blur',
      'keyup #calculation_int': 'keyup',
    }
  }

  attach() {
    return this.model.on('change:calculation_method', this.render, this)
  }

  blur(e) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    return this.change(e)
  }

  change(e) {
    const val = parseInt(numberHelper.parse($(e.target).val()), 10)
    if (isNaN(val)) return
    const data = this.model.present()
    if (data.calculation_method === 'decaying_average' && (val < 1 || val > 99)) return
    if (data.calculation_method === 'n_mastery' && (val < 1 || val > 10)) return
    this.model.set({
      calculation_int: val,
    })
    return this.renderExample()
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
    this.undelegateEvents()
    super.render(...arguments)
    this.createInstUIInput()
    this.calculationIntInstUIInput.render()
    this.renderExample()
    this.trigger('instUIInputCreated', this.calculationIntInstUIInput)
    return this.delegateEvents()
  }

  renderExample() {
    this.$('#calculation_int_example_container').html(exampleTemplate(this.model.present()))
  }

  createInstUIInput() {
    this.calculationIntInstUIInput = {
      root: (() => {
        const el = this.$('#calculation_int_container')[0]
        if(!el) return null
        return {
          rootElement: createRoot(el),
          initialValue: el.dataset.initialValue,
          label: el.dataset.label.replace(/: ?$/g, ''),
          calculationIntDescription: el.dataset.calculationIntDescription,
        }
      })(),
      render: (errorMessages) => {
        this.calculationIntInstUIInput.root?.rootElement.render(
          createElement(View, {as: 'div', margin: 'none none small none'},
            createElement(TextInput, {
              name: 'calculation_int',
              id: 'calculation_int',
              defaultValue: this.calculationIntInstUIInput.root?.initialValue,
              as: 'span',
              display: 'inline-block',
              htmlSize: 2,
              renderLabel: ()=> createElement(Text, { weight: 'normal', size: 'small' },
                this.calculationIntInstUIInput.root?.label),
              messages: [
                { text: this.calculationIntInstUIInput.root?.calculationIntDescription, type: 'hint' },
                ...(errorMessages
                    ? errorMessages.map((m) => ({ text: m.message, type: 'newError' }))
                    : [])
              ],
            })
          )
        )
      },
      inputElement: () => this.$('#calculation_int')[0],
    }
  }

  toJSON() {
    let data
    if (ENV.ACCOUNT_LEVEL_MASTERY_SCALES && ENV.MASTERY_SCALE?.outcome_calculation_method) {
      const methodModel = new CalculationMethodContent(ENV.MASTERY_SCALE.outcome_calculation_method)
      data = {...ENV.MASTERY_SCALE.outcome_calculation_method, ...methodModel.present()}
    } else {
      data = super.toJSON(...arguments)
    }

    return extend(data, {
      state: this.state,
      writeStates: ['add', 'edit'],
    })
  }
}
CalculationMethodFormView.initClass()
