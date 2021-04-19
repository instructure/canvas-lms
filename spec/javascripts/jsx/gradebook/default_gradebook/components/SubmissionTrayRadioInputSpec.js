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
import SubmissionTrayRadioInput from 'ui/features/gradebook/react/default_gradebook/components/SubmissionTrayRadioInput.js'
import {NumberInput} from '@instructure/ui-number-input'

let wrapper
let updateSubmission

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
    ...customProps
  }
  return mount(<SubmissionTrayRadioInput {...props} />)
}

function numberInputContainer() {
  return wrapper.find('.NumberInput__Container')
}

function numberInput() {
  return numberInputContainer().find(NumberInput)
}

function numberInputDescription() {
  return numberInputContainer()
    .find('span.NumberInput__Container.NumberInput__Container-LeftIndent')
    .instance().textContent
}

function numberInputLabel() {
  return numberInputContainer()
    .find('label')
    .instance().textContent
}

function radioInput() {
  return wrapper.find('input[type="radio"]')
}

function radioInputContainer() {
  return wrapper.find('.SubmissionTray__RadioInput')
}

QUnit.module('SubmissionTrayRadioInput', hooks => {
  hooks.beforeEach(() => {
    updateSubmission = sinon.stub()
  })

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
    strictEqual(wrapper.find('RadioInput').props().disabled, false)
  })

  test('renders with the radio option disabled when disabled is true', () => {
    wrapper = mountComponent({disabled: true})
    strictEqual(wrapper.find('RadioInput').props().disabled, true)
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
      strictEqual(numberInput().props().disabled, false)
    })

    test('renders with the NumberInput disabled when disabled is true', () => {
      wrapper = mountComponent({value: 'late', checked: true, disabled: true})
      strictEqual(numberInput().props().disabled, true)
    })

    test('renders NumberInput when value is changed to "late"', () => {
      wrapper = mountComponent({value: 'late', checked: false})
      wrapper.setProps({checked: true})
      strictEqual(numberInput().length, 1)
    })

    test('the text next to the input reads "Day(s)" if the late policy interval is "day"', () => {
      wrapper = mountComponent({value: 'late', checked: true})
      strictEqual(numberInputDescription(), 'Days lateDay(s)')
    })

    test('the text next to the input reads "Hour(s)" if the late policy interval is "day"', () => {
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: {lateSubmissionInterval: 'hour'}
      })
      strictEqual(numberInputDescription(), 'Hours lateHour(s)')
    })

    test('the label for the input reads "Days late" if the late policy interval is "day"', () => {
      wrapper = mountComponent({value: 'late', checked: true})
      strictEqual(numberInputLabel(), 'Days late')
    })

    test('the label for the input reads "Hours late" if the late policy interval is "hour"', () => {
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: {lateSubmissionInterval: 'hour'}
      })
      strictEqual(numberInputLabel(), 'Hours late')
    })

    test('the default value for the input is converted to days if the late policy interval is "day"', () => {
      // two days in seconds
      const secondsLate = 172800
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        submission: {latePolicyStatus: 'late', secondsLate}
      })
      strictEqual(numberInput().props().value, '2')
    })

    test('the default value for the input is converted to hours if the late policy interval is "hour"', () => {
      // two days in seconds
      const secondsLate = 172800
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: {lateSubmissionInterval: 'hour'},
        submission: {latePolicyStatus: 'late', secondsLate}
      })
      strictEqual(numberInput().props().value, '48')
    })

    test('the default value for the input is rounded to two digits after the decimal point', () => {
      // two days and four minutes in seconds
      const secondsLate = 173040
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: {lateSubmissionInterval: 'hour'},
        submission: {latePolicyStatus: 'late', secondsLate}
      })
      strictEqual(numberInput().props().value, '48.07')
    })

    test('updates value when the submission changes', () => {
      // two days and four minutes in seconds
      const secondsLate = 173040
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: {lateSubmissionInterval: 'hour'},
        submission: {id: '2501', latePolicyStatus: 'late', secondsLate: 0}
      })
      wrapper.setProps({
        submission: {id: '2502', latePolicyStatus: 'late', secondsLate}
      })
      strictEqual(numberInput().props().value, '48.07')
    })

    QUnit.module('on blur', () => {
      test('does not call updateSubmission if the input value is an empty string', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput()
        input.simulate('blur', {target: {value: ''}})
        strictEqual(updateSubmission.callCount, 0)
      })

      test('does not call updateSubmission if the input value cannot be parsed as a number', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput()
        input.simulate('blur', {target: {value: 'foo'}})
        strictEqual(updateSubmission.callCount, 0)
      })

      test('does not call updateSubmission if the input value matches the current value', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput()
        input.simulate('blur', {target: {value: '0'}})
        strictEqual(updateSubmission.callCount, 0)
      })

      test('does not call updateSubmission if the parsed value (2 decimals) matches the current value', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput()
        input.simulate('blur', {target: {value: '0.004'}})
        strictEqual(updateSubmission.callCount, 0)
      })

      test('calls updateSubmission if the parsed value (2 decimals) differs from the current value', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput().find('input')
        input.simulate('blur', {target: {value: '2'}})
        strictEqual(updateSubmission.callCount, 1)
      })

      test('calls updateSubmission with latePolicyStatus set to "late"', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput().find('input')
        input.simulate('blur', {target: {value: '2'}})
        strictEqual(updateSubmission.getCall(0).args[0].latePolicyStatus, 'late')
      })

      test('interval is hour: calls updateSubmission with the input converted to seconds', () => {
        wrapper = mountComponent({
          checked: true,
          latePolicy: {lateSubmissionInterval: 'hour'},
          updateSubmission,
          value: 'late'
        })

        const input = numberInput().find('input')
        input.simulate('blur', {target: {value: '2'}})
        const expectedSeconds = 2 * 3600
        strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
      })

      test('interval is day: calls updateSubmission with the input converted to seconds', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput().find('input')
        input.simulate('blur', {target: {value: '2'}})
        const expectedSeconds = 2 * 86400
        strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
      })

      test('truncates the remainder if one exists', () => {
        wrapper = mountComponent({value: 'late', checked: true, updateSubmission})
        const input = numberInput().find('input')
        input.simulate('blur', {target: {value: '2.3737'}})
        const expectedSeconds = Math.trunc(2.3737 * 86400)
        strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
      })
    })
  })
})
