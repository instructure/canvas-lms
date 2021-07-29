/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {NumberInput} from '@instructure/ui-number-input'
import TimeLateInput from '@canvas/grading/TimeLateInput'

let wrapper
let onSecondsLateUpdated

function mountComponent(customProps) {
  const props = {
    id: '2501',
    lateSubmissionInterval: 'day',
    locale: 'en',
    renderLabelBefore: false,
    secondsLate: 0,
    onSecondsLateUpdated() {},
    width: '5rem',
    ...customProps
  }
  return mount(<TimeLateInput {...props} />)
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
  return numberInputContainer().find('label').instance().textContent
}

QUnit.module('TimeLateInput', hooks => {
  hooks.beforeEach(() => {
    onSecondsLateUpdated = sinon.stub()
  })

  hooks.afterEach(() => {
    wrapper.unmount()
  })

  test('the text next to the input reads "Day(s)" if the late policy interval is "day"', () => {
    wrapper = mountComponent()
    ok(numberInputDescription().includes('Day(s)'))
  })

  test('the text next to the input reads "Hour(s)" if the late policy interval is "hour"', () => {
    wrapper = mountComponent({
      lateSubmissionInterval: 'hour'
    })
    ok(numberInputDescription().includes('Hour(s)'))
  })

  test('the label for the input reads "Days late" if the late policy interval is "day"', () => {
    wrapper = mountComponent()
    strictEqual(numberInputLabel(), 'Days late')
  })

  test('the label for the input reads "Hours late" if the late policy interval is "hour"', () => {
    wrapper = mountComponent({
      lateSubmissionInterval: 'hour'
    })
    strictEqual(numberInputLabel(), 'Hours late')
  })

  test('the default value for the input is converted to days if the late policy interval is "day"', () => {
    // two days in seconds
    const secondsLate = 172800
    wrapper = mountComponent({secondsLate})
    strictEqual(numberInput().props().value, '2')
  })

  test('the default value for the input is converted to hours if the late policy interval is "hour"', () => {
    // two days in seconds
    const secondsLate = 172800
    wrapper = mountComponent({
      lateSubmissionInterval: 'hour',
      secondsLate
    })
    strictEqual(numberInput().props().value, '48')
  })

  test('the component is not rendered in the DOM when visible prop is "false"', () => {
    wrapper = mountComponent({visible: false})
    strictEqual(numberInputContainer().length, 0)
  })

  test('the default value for the input is rounded to two digits after the decimal point', () => {
    // two days and four minutes in seconds
    const secondsLate = 173040
    wrapper = mountComponent({
      lateSubmissionInterval: 'hour',
      secondsLate
    })
    strictEqual(numberInput().props().value, '48.07')
  })

  QUnit.module('on blur', () => {
    test('does not call onSecondsLateUpdated if the input value is an empty string', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput()
      input.simulate('blur', {target: {value: ''}})
      strictEqual(onSecondsLateUpdated.callCount, 0)
    })

    test('does not call onSecondsLateUpdated if the input value cannot be parsed as a number', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput()
      input.simulate('blur', {target: {value: 'foo'}})
      strictEqual(onSecondsLateUpdated.callCount, 0)
    })

    test('does not call onSecondsLateUpdated if the input value matches the current value', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput()
      input.simulate('blur', {target: {value: '0'}})
      strictEqual(onSecondsLateUpdated.callCount, 0)
    })

    test('does not call onSecondsLateUpdated if the parsed value (2 decimals) matches the current value', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput()
      input.simulate('blur', {target: {value: '0.004'}})
      strictEqual(onSecondsLateUpdated.callCount, 0)
    })

    test('calls onSecondsLateUpdated if the parsed value (2 decimals) differs from the current value', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput().find('input')
      input.simulate('blur', {target: {value: '2'}})
      strictEqual(onSecondsLateUpdated.callCount, 1)
    })

    test('calls onSecondsLateUpdated with latePolicyStatus set to "late"', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput().find('input')
      input.simulate('blur', {target: {value: '2'}})
      strictEqual(onSecondsLateUpdated.getCall(0).args[0].latePolicyStatus, 'late')
    })

    test('interval is hour: calls onSecondsLateUpdated with the input converted to seconds', () => {
      wrapper = mountComponent({
        lateSubmissionInterval: 'hour',
        onSecondsLateUpdated
      })

      const input = numberInput().find('input')
      input.simulate('blur', {target: {value: '2'}})
      const expectedSeconds = 2 * 3600
      strictEqual(onSecondsLateUpdated.getCall(0).args[0].secondsLateOverride, expectedSeconds)
    })

    test('interval is day: calls onSecondsLateUpdated with the input converted to seconds', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput().find('input')
      input.simulate('blur', {target: {value: '2'}})
      const expectedSeconds = 2 * 86400
      strictEqual(onSecondsLateUpdated.getCall(0).args[0].secondsLateOverride, expectedSeconds)
    })

    test('truncates the remainder if one exists', () => {
      wrapper = mountComponent({onSecondsLateUpdated})
      const input = numberInput().find('input')
      input.simulate('blur', {target: {value: '2.3737'}})
      const expectedSeconds = Math.trunc(2.3737 * 86400)
      strictEqual(onSecondsLateUpdated.getCall(0).args[0].secondsLateOverride, expectedSeconds)
    })
  })
})
