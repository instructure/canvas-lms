/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {render, fireEvent, cleanup, screen} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'

import {DEFAULT_LATE_POLICY_DATA} from '../../apis/GradebookSettingsModalApi'
import LatePoliciesTabPanel from '../LatePoliciesTabPanel'

const MAX = '100'
const MIN = '0'
const BORDER_VALUES = ['0', '0.01', '0.1', '99', '99.9', '99.99', '100']
const EXTRA_ZEROS_MAP = {
  0: ['00', '000000000', '0.0', '00.', '0.', '.0', '.00', '.000'],
  0.1: ['0.10', '0.100', '00.100', '000.10', '0000.1', '000.1000'],
  1: [
    '01',
    '001',
    '0001',
    '0001.0',
    '0001.00',
    '0001.000',
    '001.000',
    '01.000',
    '1.000',
    '1.00',
    '1.0',
  ],
}
const MAX_OUTLIER_VALUES = [
  '100.001',
  '100.01',
  '100.1',
  '101',
  '500',
  '1000000',
  '1e10',
  Number.MAX_SAFE_INTEGER.toString(),
]
const MIN_OUTLIER_VALUES = [
  '-0.001',
  '-0.01',
  '-0.1',
  '-1',
  '-500',
  '-1000000',
  '-1e10',
  Number.MIN_SAFE_INTEGER.toString(),
]

// Helper Functions

/**
 * Simulates changing the input value once and blurring.
 * @param {Object} params
 * @param {HTMLElement} params.input - The input element.
 * @param {string} params.value - The value to set.
 * @returns {Array} - Array of boolean results from fireEvent.
 */
function changeAndBlur({input, value}) {
  const events = []
  // Clear the input
  events.push(fireEvent.change(input, {target: {value: ''}}))
  // Update input with the new value in one event
  events.push(fireEvent.change(input, {target: {value: input.value.concat(value)}}))
  // Blur to finalize
  events.push(fireEvent.blur(input))
  return events
}

/**
 * Simulates building up the input value one character at a time and blurring.
 * @param {Object} params
 * @param {HTMLElement} params.input - The input element.
 * @param {string} params.value - The value to build up.
 * @returns {Array} - Array of boolean results from fireEvent.
 */
function buildUpChangeEventsAndBlur({input, value}) {
  const events = []
  // Clear the input
  events.push(fireEvent.change(input, {target: {value: ''}}))
  // Build up the value character by character
  value.split('').forEach(character => {
    events.push(fireEvent.change(input, {target: {value: input.value.concat(character)}}))
  })
  // Blur to finalize
  events.push(fireEvent.blur(input))
  return events
}

/**
 * Validates percentage input based on various scenarios.
 * @param {Object} params
 * @param {string} params.label - The label text to identify the input.
 */
function percentInputValidations({label}) {
  describe('Percentage Input Validations', () => {
    describe('Excess Zeros', () => {
      Object.keys(EXTRA_ZEROS_MAP).forEach(expectedValue => {
        EXTRA_ZEROS_MAP[expectedValue].forEach(value => {
          test(`accepts ${value} as ${expectedValue}`, () => {
            const input = screen.getByLabelText(label)
            changeAndBlur({input, value})
            expect(input.value).toBe(expectedValue)
          })
        })
      })
    })

    describe('Border Values', () => {
      BORDER_VALUES.forEach(value => {
        test(`accepts border value: ${value}`, () => {
          const input = screen.getByLabelText(label)
          changeAndBlur({input, value})
          expect(input.value).toBe(value)
        })
      })
    })

    describe('Maximum Outlier Values', () => {
      MAX_OUTLIER_VALUES.forEach(value => {
        test(`bounds values greater than the maximum (${MAX}): ${value}`, () => {
          const input = screen.getByLabelText(label)
          changeAndBlur({input, value})
          expect(input.value).toBe(MAX)
        })
      })
    })

    describe('Minimum Outlier Values', () => {
      MIN_OUTLIER_VALUES.forEach(value => {
        test(`bounds values lesser than the minimum (${MIN}): ${value}`, () => {
          const input = screen.getByLabelText(label)
          changeAndBlur({input, value})
          expect(input.value).toBe(MIN)
        })
      })
    })

    describe('Building Up Values One Keystroke at a Time', () => {
      test('accepts building up to 100', () => {
        const input = screen.getByLabelText(label)
        buildUpChangeEventsAndBlur({input, value: MAX})
        expect(input.value).toBe(MAX)
      })

      test('accepts building up to 99.99', () => {
        const input = screen.getByLabelText(label)
        const value = '99.99'
        buildUpChangeEventsAndBlur({input, value})
        expect(input.value).toBe(value)
      })

      test('accepts building up to "99.09"', () => {
        const input = screen.getByLabelText(label)
        const value = '99.09'
        buildUpChangeEventsAndBlur({input, value})
        expect(input.value).toBe(value)
      })

      test('accepts building up to 0.01', () => {
        const input = screen.getByLabelText(label)
        const value = '0.01'
        buildUpChangeEventsAndBlur({input, value})
        expect(input.value).toBe(value)
      })

      test('accepts building up to 0.01 without a preceding "0"', () => {
        const input = screen.getByLabelText(label)
        fireEvent.change(input, {target: {value: '.'}})
        fireEvent.change(input, {target: {value: '.0'}})
        fireEvent.change(input, {target: {value: '.01'}})
        fireEvent.blur(input)
        expect(input.value).toBe('0.01')
      })

      test('accepts building up to 0.01 in reverse', () => {
        const input = screen.getByLabelText(label)
        fireEvent.change(input, {target: {value: '1'}})
        fireEvent.change(input, {target: {value: '01'}})
        fireEvent.change(input, {target: {value: '.01'}})
        fireEvent.change(input, {target: {value: '0.01'}})
        fireEvent.blur(input)
        expect(input.value).toBe('0.01')
      })
    })
  })
}

// Main Test Suite
describe('Gradebook > Default Gradebook > Components > LatePoliciesTabPanelPercentageNumberInput', () => {
  let props

  /**
   * Wrapper component to manage props state and handle changeLatePolicy
   */
  const Wrapper = ({initialProps}) => {
    const [currentProps, setCurrentProps] = useState(initialProps)

    const changeLatePolicy = ({changes}) => {
      setCurrentProps(prevProps => ({
        ...prevProps,
        latePolicy: {
          ...prevProps.latePolicy,
          changes: {...prevProps.latePolicy.changes, ...changes},
        },
      }))
    }

    return <LatePoliciesTabPanel {...currentProps} changeLatePolicy={changeLatePolicy} />
  }

  beforeEach(() => {
    props = {
      latePolicy: {
        changes: {},
        validationErrors: {},
        // by default there is no data key, it gets added after first render
      },
      locale: 'en',
      showAlert: false,
    }
  })

  afterEach(() => {
    cleanup()
  })

  /**
   * Renders the LatePoliciesTabPanel component within the Wrapper.
   * @param {Object} componentProps - Props to pass to the component.
   */
  function renderComponent(componentProps = props) {
    render(<Wrapper initialProps={componentProps} />)

    // Update props with DEFAULT_LATE_POLICY_DATA
    render(
      <Wrapper
        initialProps={{
          ...componentProps,
          latePolicy: {
            ...componentProps.latePolicy,
            data: DEFAULT_LATE_POLICY_DATA,
          },
        }}
      />,
    )
  }

  /**
   * Sets up the component with default and updated props.
   * @param {Object} componentProps - Props to pass to the component.
   */
  function setupComponent(componentProps = props) {
    renderComponent(componentProps)
  }

  /**
   * Retrieves the "Automatically apply deduction to late submissions" checkbox.
   * @returns {HTMLElement} - The checkbox input element.
   */
  function getAutomaticallyApplyDeductionToLateSubmissionsCheckbox() {
    return screen.getByLabelText('Automatically apply deduction to late submissions')
  }

  // Begin Testing
  describe('Late Policies:', () => {
    beforeEach(() => {
      setupComponent(props)
    })

    describe('Missing Submissions', () => {
      describe('when the "Automatically apply grade for missing submissions" checkbox is toggled on and the "Grade percentage for missing submissions" is changed', () => {
        beforeEach(() => {
          const checkbox = getAutomaticallyApplyDeductionToLateSubmissionsCheckbox()
          fireEvent.click(checkbox)
        })

        percentInputValidations({label: 'Grade for missing submissions %'})
      })
    })

    describe('Late Submissions', () => {
      describe('when the "Automatically apply deduction to late submissions" checkbox is toggled on and the "Late submission deduction percent" is changed', () => {
        beforeEach(() => {
          const checkbox = getAutomaticallyApplyDeductionToLateSubmissionsCheckbox()
          fireEvent.click(checkbox)
        })

        percentInputValidations({label: 'Late submission deduction %'})
      })

      describe('when the "Automatically apply deduction to late submissions" checkbox is toggled on and the "Lowest possible grade percent" is changed', () => {
        beforeEach(() => {
          const checkbox = getAutomaticallyApplyDeductionToLateSubmissionsCheckbox()
          fireEvent.click(checkbox)
        })

        percentInputValidations({label: 'Lowest possible grade %'})
      })
    })
  })
})
