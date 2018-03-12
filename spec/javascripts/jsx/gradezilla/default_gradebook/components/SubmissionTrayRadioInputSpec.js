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
import { mount } from 'enzyme'
import SubmissionTrayRadioInput from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInput'
import NumberInput from '@instructure/ui-core/lib/components/NumberInput'

let wrapper
let updateSubmission

function mountComponent (customProps) {
  const props = {
    checked: false,
    color: '#FEF7E5',
    disabled: false,
    latePolicy: { lateSubmissionInterval: 'day' },
    locale: 'en',
    onChange () {},
    submission: { secondsLate: 0 },
    text: 'Missing',
    updateSubmission () {},
    value: 'missing',
    ...customProps
  }
  return mount(<SubmissionTrayRadioInput {...props} />)
}

function numberInputContainer () {
  return wrapper.find('.NumberInput__Container')
}

function numberInput () {
  return numberInputContainer().find('input')
}

function numberInputDescription () {
  return numberInputContainer().find('span[role="presentation"]').node.textContent
}

function numberInputLabel () {
  return numberInputContainer().find('label').node.textContent
}

function radioInput () {
  return wrapper.find('input[type="radio"]')
}

function radioInputContainer () {
  return wrapper.find('.SubmissionTray__RadioInput')
}

QUnit.module('SubmissionTrayRadioInput', function (hooks) {
  hooks.beforeEach(() => {
    updateSubmission = sinon.stub()
  })

  hooks.afterEach(() => {
    wrapper.unmount()
  })

  test('renders a radio option with a name of "SubmissionTrayRadioInput"', function () {
    wrapper = mountComponent()
    strictEqual(radioInput().node.name, 'SubmissionTrayRadioInput')
  })

  test('renders with a background color specified by the "color" prop', function () {
    wrapper = mountComponent({ color: 'green' })
    const { style } = radioInputContainer().node
    strictEqual(style.getPropertyValue('background-color'), 'green')
  })

  test('renders with a "transparent" background color if a color is not specified', function () {
    wrapper = mountComponent({ color: undefined })
    const { style } = radioInputContainer().node
    strictEqual(style.getPropertyValue('background-color'), 'transparent')
  })

  test('renders with the radio option enabled when disabled is false', function () {
    wrapper = mountComponent({ disabled: false })
    strictEqual(wrapper.find('RadioInput').props().disabled, false)
  })

  test('renders with the radio option disabled when disabled is true', function () {
    wrapper = mountComponent({ disabled: true })
    strictEqual(wrapper.find('RadioInput').props().disabled, true)
  })

  test('renders with the radio option selected when checked is true', function () {
    wrapper = mountComponent({ checked: true })
    strictEqual(radioInput().node.checked, true)
  })

  test('renders with the radio option deselected when checked is false', function () {
    wrapper = mountComponent()
    strictEqual(radioInput().node.checked, false)
  })

  test('calls onChange when the radio option is selected', function () {
    const onChange = sinon.stub()
    wrapper = mountComponent({ onChange })
    radioInput().simulate('change', { target: { checked: true } })
    strictEqual(onChange.callCount, 1)
  })

  QUnit.module('NumberInput', function () {
    test('does not render a NumberInput when value is not "late"', function () {
      wrapper = mountComponent()
      strictEqual(wrapper.find(NumberInput).length, 0)
    })

    test('renders with a NumberInput when value is "late" and checked is true', function () {
      wrapper = mountComponent({ value: 'late', checked: true })
      strictEqual(numberInput().length, 1)
    })

    test('renders without a NumberInput when value is "late" and checked is false', function () {
      wrapper = mountComponent({ value: 'late' })
      strictEqual(numberInput().length, 0)
    })

    test('renders with the NumberInput enabled when disabled is false', function () {
      wrapper = mountComponent({ value: 'late', checked: true })
      strictEqual(numberInput().props().disabled, false)
    })

    test('renders with the NumberInput disabled when disabled is true', function () {
      wrapper = mountComponent({ value: 'late', checked: true, disabled: true })
      strictEqual(numberInput().props().disabled, true)
    })

    test('the text next to the input reads "Day(s)" if the late policy interval is "day"', function () {
      wrapper = mountComponent({ value: 'late', checked: true })
      strictEqual(numberInputDescription(), 'Day(s)')
    })

    test('the text next to the input reads "Hour(s)" if the late policy interval is "day"', function () {
      wrapper = mountComponent({ value: 'late', checked: true, latePolicy: { lateSubmissionInterval: 'hour' } })
      strictEqual(numberInputDescription(), 'Hour(s)')
    })

    test('the label for the input reads "Days late" if the late policy interval is "day"', function () {
      wrapper = mountComponent({ value: 'late', checked: true })
      strictEqual(numberInputLabel(), 'Days late')
    })

    test('the label for the input reads "Hours late" if the late policy interval is "hour"', function () {
      wrapper = mountComponent({ value: 'late', checked: true, latePolicy: { lateSubmissionInterval: 'hour' } })
      strictEqual(numberInputLabel(), 'Hours late')
    })

    test('the default value for the input is converted to days if the late policy interval is "day"', function () {
      // two days in seconds
      const secondsLate = 172800
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        submission: { latePolicyStatus: 'late', secondsLate }
      })
      strictEqual(numberInput().props().defaultValue, '2')
    })

    test('the default value for the input is converted to hours if the late policy interval is "hour"', function () {
      // two days in seconds
      const secondsLate = 172800
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: { lateSubmissionInterval: 'hour' },
        submission: { latePolicyStatus: 'late', secondsLate }
      })
      strictEqual(numberInput().props().defaultValue, '48')
    })

    test('the default value for the input is rounded to two digits after the decimal point', function () {
      // two days and four minutes in seconds
      const secondsLate = 173040
      wrapper = mountComponent({
        value: 'late',
        checked: true,
        latePolicy: { lateSubmissionInterval: 'hour' },
        submission: { latePolicyStatus: 'late', secondsLate }
      })
      strictEqual(numberInput().props().defaultValue, '48.07')
    })

    QUnit.module('on blur', function () {
      test('does not call updateSubmission if the input value is an empty string', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '' } })
        input.simulate('blur')
        strictEqual(updateSubmission.callCount, 0)
      })

      test('does not call updateSubmission if the input value cannot be parsed as a number', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: 'foo' } })
        input.simulate('blur')
        strictEqual(updateSubmission.callCount, 0)
      })

      test('does not call updateSubmission if the input value matches the current value', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '0' } })
        input.simulate('blur')
        strictEqual(updateSubmission.callCount, 0)
      })

      test('does not call updateSubmission if the parsed value (2 decimals) matches the current value', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '0.004' } })
        input.simulate('blur')
        strictEqual(updateSubmission.callCount, 0)
      })

      test('calls updateSubmission if the parsed value (2 decimals) differs from the current value', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '2' } })
        input.simulate('blur')
        strictEqual(updateSubmission.callCount, 1)
      })

      test('calls updateSubmission with latePolicyStatus set to "late"', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '2' } })
        input.simulate('blur')
        strictEqual(updateSubmission.getCall(0).args[0].latePolicyStatus, 'late')
      })

      test('interval is hour: calls updateSubmission with the input converted to seconds', function () {
        wrapper = mountComponent({
          checked: true,
          latePolicy: { lateSubmissionInterval: 'hour' }, updateSubmission,
          value: 'late'
        })

        const input = numberInput()
        input.simulate('change', { target: { value: '2' } })
        input.simulate('blur')
        const expectedSeconds = 2 * 3600
        strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
      })

      test('interval is day: calls updateSubmission with the input converted to seconds', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '2' } })
        input.simulate('blur')
        const expectedSeconds = 2 * 86400
        strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
      })

      test('truncates the remainder if one exists', function () {
        wrapper = mountComponent({ value: 'late', checked: true, updateSubmission })
        const input = numberInput()
        input.simulate('change', { target: { value: '2.3737' } })
        input.simulate('blur')
        const expectedSeconds = Math.trunc(2.3737 * 86400)
        strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
      })
    })
  })
})
