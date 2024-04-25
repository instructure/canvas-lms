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
import {fireEvent, render} from '@testing-library/react'
import SubmissionTrayRadioInput from '../SubmissionTrayRadioInput'

let wrapper: any
let props: any

function mountComponent(customProps?: any) {
  props = {
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
  return render(<SubmissionTrayRadioInput {...props} />)
}

function numberInput() {
  return wrapper.container.querySelector('.NumberInput__Container input[type="text"]')
}

function radioInput() {
  return wrapper.container.querySelector('input[type="radio"]')
}

function radioInputContainer() {
  return wrapper.container.querySelector('.SubmissionTray__RadioInput')
}

describe('SubmissionTrayRadioInput', () => {
  test('renders a radio option with a name of "SubmissionTrayRadioInput"', () => {
    wrapper = mountComponent()
    expect(radioInput().getAttribute('name')).toEqual('SubmissionTrayRadioInput')
  })

  test('renders with a background color specified by the "color" prop', () => {
    wrapper = mountComponent({color: 'green'})
    expect(radioInputContainer().getAttribute('style')).toContain('background-color: green')
  })

  test('renders with a "transparent" background color if a color is not specified', () => {
    wrapper = mountComponent({color: undefined})
    expect(radioInputContainer().getAttribute('style')).toContain('background-color: transparent')
  })

  test('renders with the radio option enabled when disabled is false', () => {
    wrapper = mountComponent({disabled: false})
    expect(radioInput()).not.toBeDisabled()
  })

  test('renders with the radio option disabled when disabled is true', () => {
    wrapper = mountComponent({disabled: true})
    expect(radioInput()).toBeDisabled()
  })

  test('renders with the radio option selected when checked is true', () => {
    wrapper = mountComponent({checked: true})
    expect(radioInput()).toBeChecked()
  })

  test('renders with the radio option deselected when checked is false', () => {
    wrapper = mountComponent()
    expect(radioInput()).not.toBeChecked()
  })

  test('calls onChange when the radio option is selected', () => {
    const onChange = jest.fn()
    wrapper = mountComponent({onChange})
    fireEvent.click(radioInput())
    expect(onChange).toHaveBeenCalledTimes(1)
  })

  describe('NumberInput', () => {
    test('does not render a NumberInput when value is not "late"', () => {
      wrapper = mountComponent()
      expect(numberInput()).not.toBeInTheDocument()
    })

    test('renders with a NumberInput when value is "late" and checked is true', () => {
      wrapper = mountComponent({value: 'late', checked: true})
      expect(numberInput()).toBeInTheDocument()
    })

    test('renders without a NumberInput when value is "late" and checked is false', () => {
      wrapper = mountComponent({value: 'late'})
      expect(numberInput()).not.toBeInTheDocument()
    })

    test('renders with the NumberInput enabled when disabled is false', () => {
      wrapper = mountComponent({value: 'late', checked: true})
      expect(numberInput()).not.toBeDisabled()
    })

    test('renders with the NumberInput disabled when disabled is true', () => {
      wrapper = mountComponent({value: 'late', checked: true, disabled: true})
      expect(numberInput()).toBeDisabled()
    })

    test('renders NumberInput when value is changed to "late"', () => {
      wrapper = render(<SubmissionTrayRadioInput {...props} value="late" checked={false} />)
      wrapper.rerender(<SubmissionTrayRadioInput {...props} value="late" checked={true} />)
      expect(numberInput()).toBeInTheDocument()
    })
  })
})
