/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {fireEvent} from '@testing-library/react'

import {DEFAULT_LATE_POLICY_DATA} from 'ui/features/gradebook/react/default_gradebook/apis/GradebookSettingsModalApi'
import LatePoliciesTabPanel from 'ui/features/gradebook/react/default_gradebook/components/LatePoliciesTabPanel'

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

/*
 * same as buildUpChangeEventsAndBlur but only call change once for use when
 * not testing normal onChange workflows (normal being when input is typed
 * one key at a time)
 */
function changeAndBlur({input, value}) {
  const events = [fireEvent.change(input, {target: {value: ''}})] // clear
  // update input with value in one event
  events.concat(fireEvent.change(input, {target: {value: input.value.concat(value)}}))
  events.concat(fireEvent.blur(input)) // blur to finalize
  return events // returns booleans from fireEvent
}

function buildUpChangeEventsAndBlur({input, value}) {
  // need to first clear inputs otherwise we'll have pollution
  const events = [fireEvent.change(input, {target: {value: ''}})]
  // build up change events via each character in value.split('')
  events.concat(
    value
      .split('')
      .map(character => fireEvent.change(input, {target: {value: input.value.concat(character)}}))
  )
  // blur to finalize
  events.concat(fireEvent.blur(input))
  // returns booleans from fireEvent
  return events
}

function percentInputValidations({inputFn}) {
  QUnit.module('Percentage Input Validations', () => {
    QUnit.module('Excess Zeros', () => {
      Object.keys(EXTRA_ZEROS_MAP).forEach(expectedValue => {
        EXTRA_ZEROS_MAP[expectedValue].forEach(value => {
          test(`accepts ${value} as ${expectedValue}`, () => {
            const input = inputFn()
            changeAndBlur({input, value})
            strictEqual(input.value, expectedValue)
          })
        })
      })
    })

    QUnit.module('Border Values', () => {
      BORDER_VALUES.forEach(value => {
        test(`accepts border value: ${value}`, () => {
          const input = inputFn()
          changeAndBlur({input, value})
          strictEqual(input.value, value)
        })
      })
    })

    QUnit.module('Maximum outlier values', () => {
      MAX_OUTLIER_VALUES.forEach(value => {
        test(`bound values greater than the maximum (100): ${value}`, () => {
          const input = inputFn()
          changeAndBlur({input, value})
          strictEqual(input.value, MAX)
        })
      })
    })

    QUnit.module('Minimum outlier values', () => {
      MIN_OUTLIER_VALUES.forEach(value => {
        test(`bounds values lesser than the minimum (0): ${value}`, () => {
          const input = inputFn()
          changeAndBlur({input, value})
          strictEqual(input.value, MIN)
        })
      })
    })

    QUnit.module('building up values one keystroke at a time', () => {
      test('accepts building up to 100', () => {
        const input = inputFn()
        buildUpChangeEventsAndBlur({input, value: MAX})
        strictEqual(input.value, MAX)
      })

      test('accepts building up to 99.99', () => {
        const input = inputFn()
        const value = '99.99'
        buildUpChangeEventsAndBlur({input, value})
        strictEqual(input.value, value)
      })

      test('accepts building up to "99.09"', () => {
        const input = inputFn()
        const value = '99.09'
        buildUpChangeEventsAndBlur({input, value})
        strictEqual(input.value, value)
      })

      test('accepts building up to 0.01', () => {
        const input = inputFn()
        const value = '0.01'
        buildUpChangeEventsAndBlur({input, value})
        strictEqual(input.value, value)
      })

      test('accepts building up to 0.01 without a preceeding "0"', () => {
        const input = inputFn()
        fireEvent.change(input, {target: {value: '.'}})
        fireEvent.change(input, {target: {value: '.0'}})
        fireEvent.change(input, {target: {value: '.01'}})
        fireEvent.blur(input)
        strictEqual(input.value, '0.01')
      })

      test('accepts building up to 0.01 in reverse', () => {
        const input = inputFn()
        fireEvent.change(input, {target: {value: '1'}})
        fireEvent.change(input, {target: {value: '01'}})
        fireEvent.change(input, {target: {value: '.01'}})
        fireEvent.change(input, {target: {value: '0.01'}})
        fireEvent.blur(input)
        strictEqual(input.value, '0.01')
      })
    })
  })
}

QUnit.module(
  'Gradebook > Default Gradebook > Components > LatePoliciesTabPanelPercentageNumberInput',
  withoutEnzymeHooks => {
    let $container
    let props

    withoutEnzymeHooks.beforeEach(() => {
      $container = document.getElementById('fixtures').appendChild(document.createElement('div'))

      props = {
        latePolicy: {
          changes: {},
          validationErrors: {},
          // by default there is no data key, it gets added after first render
        },
        changeLatePolicy,
        locale: 'en',
        showAlert: false,
      }
    })

    withoutEnzymeHooks.afterEach(() => {
      ReactDOM.unmountComponentAtNode($container)
    })

    // this is to fake out how GradebookSettingsModal updates the state of props.latePolicy.changes
    function changeLatePolicy({changes}) {
      props.latePolicy.changes = changes
      mountComponent()
    }

    function mountComponent(componentProps = props) {
      ReactDOM.render(<LatePoliciesTabPanel {...componentProps} />, $container)
    }

    function setupComponent(componentProps = props) {
      mountComponent(componentProps)

      // yes actually update props at this point
      props = {
        ...componentProps,
        latePolicy: {
          ...componentProps.latePolicy,
          data: DEFAULT_LATE_POLICY_DATA,
        },
      }
      mountComponent(props)
    }

    function findLabel(label) {
      return [...$container.querySelectorAll('label')].find(el => el.innerText.trim() === label)
    }

    function findInput(label) {
      const labelEl = findLabel(label)
      return $container.querySelector(`input#${labelEl.getAttribute('for')}`)
    }

    function getLatePoliciesTabPanelContainer() {
      return document.getElementById('LatePoliciesTabPanel__Container')
    }

    function findCheckbox(label) {
      const $modal = getLatePoliciesTabPanelContainer()
      const $label = [...$modal.querySelectorAll('label')].find($el =>
        $el.textContent.includes(label)
      )
      return $modal.querySelector(`#${$label.getAttribute('for')}`)
    }

    function getAutomaticallyApplyDeductionToLateSubmissionsCheckbox() {
      return findCheckbox('Automatically apply deduction to late submissions')
    }

    function getGradePercentageForMissingSubmissionsInput() {
      return findInput('Grade for missing submissions')
    }

    function getLateSubmissionDeductionPercentInput() {
      return findInput('Late submission deduction')
    }

    function getLowestPossibleGradePercentInput() {
      return findInput('Lowest possible grade')
    }

    QUnit.module('Late Policies:', contextHooks => {
      contextHooks.beforeEach(() => {
        setupComponent(props)
      })

      QUnit.module('Missing Submissions', () => {
        QUnit.module(
          'when the "Automatically apply grade for missing submissions" checkbox is toggled on and the "Grade percentage for missing submissions" is changed',
          lateSubmissionDeductionPercentHooks => {
            lateSubmissionDeductionPercentHooks.beforeEach(() => {
              getAutomaticallyApplyDeductionToLateSubmissionsCheckbox().click()
            })

            percentInputValidations({inputFn: getGradePercentageForMissingSubmissionsInput})
          }
        )
      })

      QUnit.module('Late Submissions', () => {
        QUnit.module(
          'when the "Automatically apply deduction to late submissions" checkbox is toggled on and the "Late submission deduction percent" is changed',
          lateSubmissionDeductionPercentHooks => {
            lateSubmissionDeductionPercentHooks.beforeEach(() => {
              getAutomaticallyApplyDeductionToLateSubmissionsCheckbox().click()
            })

            percentInputValidations({inputFn: getLateSubmissionDeductionPercentInput})
          }
        )

        QUnit.module(
          'when the "Automatically apply deduction to late submissions" checkbox is toggled on and the "Lowest possible grade percent" is changed',
          lowestPossibleGradePercentHooks => {
            lowestPossibleGradePercentHooks.beforeEach(() => {
              getAutomaticallyApplyDeductionToLateSubmissionsCheckbox().click()
            })

            percentInputValidations({inputFn: getLowestPossibleGradePercentInput})
          }
        )
      })
    })
  }
)
