/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {mount} from 'enzyme'
import SubmissionTrayRadioInput from 'ui/features/gradebook/react/default_gradebook/components/SubmissionTrayRadioInput'
import {NumberInput} from '@instructure/ui-number-input'

let wrapper

function mountComponent(customProps) {
  const props = {
    checked: false,
    color: '#FEF7E5',
    disabled: false,
    latePolicy: {lateSubmissionInterval: 'day'},
    locale: 'en',
    onChange() {},
    submission: {secondsLate: 0},
    text: 'Missing',
    updateSubmission() {},
    value: 'missing',
    ...customProps,
  }
  return mount(<SubmissionTrayRadioInput {...props} />)
}

function numberInputContainer() {
  return wrapper.find('.NumberInput__Container')
}

function numberInput() {
  return numberInputContainer().find(NumberInput)
}

function radioInput() {
  return wrapper.find('input[type="radio"]')
}

function radioInputContainer() {
  return wrapper.find('.SubmissionTray__RadioInput')
}

QUnit.module('SubmissionTrayRadioInput', hooks => {
  hooks.afterEach(() => {
    wrapper.unmount()
  })

  test('renders a radio option with a name of "SubmissionTrayRadioInput"', () => {
    wrapper = mountComponent()
    strictEqual(radioInput().instance().name, 'SubmissionTrayRadioInput')
  })

  test('renders with a background color specified by the "color" prop', () => {
    wrapper = mountComponent({color: 'green'})
    const {style} = radioInputContainer().instance()
    strictEqual(style.getPropertyValue('background-color'), 'green')
  })

  test('renders with a "transparent" background color if a color is not specified', () => {
    wrapper = mountComponent({color: undefined})
    const {style} = radioInputContainer().instance()
    strictEqual(style.getPropertyValue('background-color'), 'transparent')
  })

  test('renders with the radio option enabled when disabled is false', () => {
    wrapper = mountComponent({disabled: false})
    strictEqual(wrapper.find('RadioInput').first().props().disabled, false)
  })

  test('renders with the radio option disabled when disabled is true', () => {
    wrapper = mountComponent({disabled: true})
    strictEqual(wrapper.find('RadioInput').first().props().disabled, true)
  })

  test('renders with the radio option selected when checked is true', () => {
    wrapper = mountComponent({checked: true})
    strictEqual(radioInput().instance().checked, true)
  })

  test('renders with the radio option deselected when checked is false', () => {
    wrapper = mountComponent()
    strictEqual(radioInput().instance().checked, false)
  })

  test('calls onChange when the radio option is selected', () => {
    const onChange = sinon.stub()
    wrapper = mountComponent({onChange})
    radioInput().simulate('change', {target: {checked: true}})
    strictEqual(onChange.callCount, 1)
  })

  QUnit.module('NumberInput', () => {
    test('does not render a NumberInput when value is not "late"', () => {
      wrapper = mountComponent()
      strictEqual(wrapper.find(NumberInput).length, 0)
    })

    test('renders with a NumberInput when value is "late" and checked is true', () => {
      wrapper = mountComponent({value: 'late', checked: true})
      strictEqual(numberInput().length, 1)
    })

    test('renders without a NumberInput when value is "late" and checked is false', () => {
      wrapper = mountComponent({value: 'late'})
      strictEqual(numberInput().length, 0)
    })

    test('renders with the NumberInput enabled when disabled is false', () => {
      wrapper = mountComponent({value: 'late', checked: true})
      strictEqual(numberInput().props().interaction, 'enabled')
    })

    test('renders with the NumberInput disabled when disabled is true', () => {
      wrapper = mountComponent({value: 'late', checked: true, disabled: true})
      strictEqual(numberInput().props().interaction, 'disabled')
    })

    test('renders NumberInput when value is changed to "late"', () => {
      wrapper = mountComponent({value: 'late', checked: false})
      wrapper.setProps({checked: true})
      strictEqual(numberInput().length, 1)
    })
  })
})
