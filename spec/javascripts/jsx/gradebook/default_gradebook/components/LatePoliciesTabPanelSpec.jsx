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
import ReactDOM from 'react-dom'
import {fireEvent} from '@testing-library/react'
import {mount} from 'enzyme'

import {Alert} from '@instructure/ui-alerts'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Spinner} from '@instructure/ui-spinner'

import {DEFAULT_LATE_POLICY_DATA} from 'ui/features/gradebook/react/default_gradebook/apis/GradebookSettingsModalApi'
import LatePoliciesTabPanel from 'ui/features/gradebook/react/default_gradebook/components/LatePoliciesTabPanel'

const MIN = '0'

QUnit.module(
  'Gradebook > Default Gradebook > LatePoliciesTabPanel > without enzyme',
  withoutEnzymeHooks => {
    let $container
    let props
    let changeLatePolicySpy

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
        gradebookIsEditable: true,
        showAlert: false,
      }
      changeLatePolicySpy = sinon.spy(props, 'changeLatePolicy')
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

      /*
       * typically all props would be passed in on initial render, however
       * with this component the way it's been architected is to first render
       * and then fetch the data for the latePolicy and render again to update
       * those props. In order to accomplish this in test first we render the
       * component without `props.latePolicy.data` and then render it again
       * immediately to fake out the loading of this data but stil preserve
       * the double render behavior.
       */
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

    function findOption(label) {
      return [...document.querySelectorAll('[role=option]')].find(
        $el => $el.textContent.trim() === label
      )
    }

    function getAutomaticallyApplyGradeForMissingSubmissionsCheckbox() {
      return findCheckbox('Automatically apply grade for missing submissions')
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

    function getLateSubmissionDeductionIntervalInput() {
      return findInput('Deduction interval')
    }

    function getLowestPossibleGradePercentInput() {
      return findInput('Lowest possible grade')
    }

    QUnit.module('Late Policies', () => {
      QUnit.module('Missing Submissions', () => {
        test("the 'Automatically apply grade for missing submissions' checkbox displays what's passed in via props", () => {
          props.latePolicy.data = {
            ...DEFAULT_LATE_POLICY_DATA,
            missingSubmissionDeductionEnabled: true,
          }
          mountComponent(props)
          const checkbox = getAutomaticallyApplyGradeForMissingSubmissionsCheckbox()
          strictEqual(checkbox.checked, true)
        })

        test("the 'Grade percentage for missing submissions' displays what's passed in via props, adjusted for display", () => {
          props.latePolicy.data = {
            ...DEFAULT_LATE_POLICY_DATA,
            missingSubmissionDeduction: 42,
          }
          mountComponent(props)
          const input = getGradePercentageForMissingSubmissionsInput()
          strictEqual(input.value, '58')
        })

        test('input and checkbox are disabled if gradebook is not editable by user', () => {
          props.gradebookIsEditable = false
          setupComponent(props)
          strictEqual(getGradePercentageForMissingSubmissionsInput().disabled, true)
          strictEqual(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().disabled, true)
        })

        QUnit.module('given default props', contextHooks => {
          contextHooks.beforeEach(() => {
            setupComponent(props)
          })

          test("the 'Automatically apply grade for missing submissions' checkbox is not checked", () => {
            const checkbox = getAutomaticallyApplyGradeForMissingSubmissionsCheckbox()
            strictEqual(checkbox.value, '')
          })

          test("the 'Grade percentage for missing submissions' input is disabled by default", () => {
            const input = getGradePercentageForMissingSubmissionsInput()
            strictEqual(input.disabled, true)
          })

          test("clicking the 'Automatically apply grade for missing submissions' checkbox enables the 'Grade percentage for missing submissions' input", () => {
            getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().click()
            const {disabled} = getGradePercentageForMissingSubmissionsInput()
            strictEqual(disabled, false)
          })

          test("the 'Grade percentage for missing submissions' defaults to 0", () => {
            getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().click()
            const input = getGradePercentageForMissingSubmissionsInput()
            strictEqual(input.value, MIN)
          })

          test('when a single character is entered in the input, changeLatePolicy is called once', () => {
            getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().click()
            const input = getGradePercentageForMissingSubmissionsInput()
            const originalChangeLatePolicySpyCount = changeLatePolicySpy.callCount
            fireEvent.change(input, {target: {value: '1'}})
            strictEqual(changeLatePolicySpy.callCount - originalChangeLatePolicySpyCount, 1)
          })

          test('when a single character is entered in the input, and the input is blurred, changeLatePolicy is called twice', () => {
            getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().click()
            const input = getGradePercentageForMissingSubmissionsInput()
            const originalChangeLatePolicySpyCount = changeLatePolicySpy.callCount
            fireEvent.change(input, {target: {value: '1'}})
            fireEvent.blur(input)
            strictEqual(changeLatePolicySpy.callCount - originalChangeLatePolicySpyCount, 2)
          })

          test('when clearing the input and then typing one character followed by blurring the input, changeLatePolicy is calle three times', () => {
            getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().click()
            const input = getGradePercentageForMissingSubmissionsInput()
            fireEvent.change(input, {target: {value: '1'}}) // some initial value
            const originalChangeLatePolicySpyCount = changeLatePolicySpy.callCount
            fireEvent.change(input, {target: {value: ''}}) // clear
            fireEvent.change(input, {target: {value: '9'}}) // set value
            fireEvent.blur(input) // blur to finalize
            strictEqual(changeLatePolicySpy.callCount - originalChangeLatePolicySpyCount, 3)
          })

          test('changeLatePolicy passes the difference of 100 - missingSubmissionDeduction', () => {
            getAutomaticallyApplyGradeForMissingSubmissionsCheckbox().click()
            const input = getGradePercentageForMissingSubmissionsInput()
            fireEvent.change(input, {target: {value: '1.23'}})
            fireEvent.blur(input)
            const {missingSubmissionDeduction} = changeLatePolicySpy.lastCall.args[0].changes
            strictEqual(missingSubmissionDeduction, 98.77)
          })
        })
      })

      QUnit.module('Late Submissions', () => {
        test("the 'Automatically apply grade for missing submissions' checkbox displays what's passed in via props", () => {
          props.latePolicy.data = {
            ...DEFAULT_LATE_POLICY_DATA,
            lateSubmissionDeductionEnabled: true,
          }
          mountComponent(props)
          const checkbox = getAutomaticallyApplyDeductionToLateSubmissionsCheckbox()
          strictEqual(checkbox.checked, props.latePolicy.data.lateSubmissionDeductionEnabled)
        })

        test("the 'Late submission deduction percent' input displays what's passed in via props", () => {
          props.latePolicy.data = {
            ...DEFAULT_LATE_POLICY_DATA,
            lateSubmissionDeduction: 43,
          }
          mountComponent(props)
          const input = getLateSubmissionDeductionPercentInput()
          strictEqual(input.value, props.latePolicy.data.lateSubmissionDeduction.toString())
        })

        test("the 'Lowest Possible Grade Percent' input displays what's passed in via props", () => {
          props.latePolicy.data = {
            ...DEFAULT_LATE_POLICY_DATA,
            lateSubmissionMinimumPercent: 44,
          }
          mountComponent(props)
          const input = getLowestPossibleGradePercentInput()
          strictEqual(input.value, props.latePolicy.data.lateSubmissionMinimumPercent.toString())
        })

        /* eslint-disable-next-line qunit/no-identical-names */
        QUnit.module('given default props', defaultPropsHooks => {
          defaultPropsHooks.beforeEach(() => {
            setupComponent(props)
          })

          test('the "Automatically apply deductions to late submissions" checkbox is not checked by default', () => {
            const {value} = getAutomaticallyApplyDeductionToLateSubmissionsCheckbox()
            strictEqual(value, '')
          })

          test('the "Late submission deduction percent" input is disabled by default', () => {
            const {disabled} = getLateSubmissionDeductionPercentInput()
            strictEqual(disabled, true)
          })

          test('the "Late submission deduction interval" input is disabled by default', () => {
            const {disabled} = getLateSubmissionDeductionIntervalInput()
            strictEqual(disabled, true)
          })

          test('the "Lowest possible grade percent" input is disabled by default', () => {
            const {disabled} = getLowestPossibleGradePercentInput()
            strictEqual(disabled, true)
          })

          test("the 'Late submission deduction percent' input defaults to '0'", () => {
            const {value} = getLateSubmissionDeductionPercentInput()
            strictEqual(value, MIN)
          })

          test("the 'Late submission deduction interval' input defaults to 'Day'", () => {
            const {value} = getLateSubmissionDeductionIntervalInput()
            strictEqual(value, 'Day')
          })

          test("the 'Lowest possible grade percent' input defaults to '0'", () => {
            const {value} = getLowestPossibleGradePercentInput()
            strictEqual(value, MIN)
          })

          QUnit.module(
            'when the "Automatically apply deduction to late submissions" checkbox is toggled on',
            lateSubmissionsDeductionHooks => {
              lateSubmissionsDeductionHooks.beforeEach(() => {
                getAutomaticallyApplyDeductionToLateSubmissionsCheckbox().click()
              })

              test('inputs and checkbox are disabled if gradebook is not editable by user', () => {
                props.gradebookIsEditable = false
                setupComponent(props)
                strictEqual(
                  getAutomaticallyApplyDeductionToLateSubmissionsCheckbox().disabled,
                  true
                )
                strictEqual(getLowestPossibleGradePercentInput().disabled, true)
                strictEqual(getLateSubmissionDeductionPercentInput().disabled, true)
                strictEqual(getLateSubmissionDeductionIntervalInput().disabled, true)
              })

              test('passes "lateSubmissionDeductionEnabled" to parent', () => {
                const {lateSubmissionDeductionEnabled} =
                  changeLatePolicySpy.lastCall.args[0].changes
                strictEqual(lateSubmissionDeductionEnabled, true)
              })

              test('the "Late submission deduction interval" input is not disabled', () => {
                const {disabled} = getLateSubmissionDeductionIntervalInput()
                strictEqual(disabled, false)
              })

              test('the "Late submission deduction percent" input is not disabled', () => {
                const {disabled} = getLateSubmissionDeductionPercentInput()
                strictEqual(disabled, false)
              })

              test('the "Lowest possible grade percent" input is not disabled', () => {
                const {disabled} = getLowestPossibleGradePercentInput()
                strictEqual(disabled, false)
              })
            }
          )

          QUnit.module(
            'when the "Automatically apply deduction to late submissions" checkbox is toggled on and the "Late submission deduction interval" is changed',
            lateSubmissionDeductionIntervalHooks => {
              let input

              lateSubmissionDeductionIntervalHooks.beforeEach(() => {
                getAutomaticallyApplyDeductionToLateSubmissionsCheckbox().click()
                input = getLateSubmissionDeductionIntervalInput()
              })

              test('last call to changeLatePolicy is called with lateSubmissionInterval set to "hour"', () => {
                input.click()
                findOption('Hour').click()
                const {lateSubmissionInterval} = changeLatePolicySpy.lastCall.args[0].changes
                strictEqual(lateSubmissionInterval, 'hour')
              })

              test('last call to changeLatePolicy is not called when the same value as default is selected', () => {
                input.click()
                findOption('Day').click()
                const {changes} = changeLatePolicySpy.lastCall.args[0]
                strictEqual(changes.hasOwnProperty('lateSubmissionInterval'), false)
              })

              test('last call to changeLatePolicy is not called when toggled back to the initial value', () => {
                input.click()
                findOption('Day').click()
                input.click()
                findOption('Hour').click()
                input.click()
                findOption('Day').click()
                const {changes} = changeLatePolicySpy.lastCall.args[0]
                strictEqual(changes.hasOwnProperty('lateSubmissionInterval'), false)
              })

              test('sets Day', () => {
                input.click()
                findOption('Day').click()
                strictEqual(input.value, 'Day')
              })

              test('sets Hour', () => {
                input.click()
                findOption('Day').click()
                input.click()
                findOption('Hour').click()
                strictEqual(input.value, 'Hour')
              })

              test('sets Day when toggled several times', () => {
                input.click()
                findOption('Day').click()
                input.click()
                findOption('Hour').click()
                input.click()
                findOption('Day').click()
                strictEqual(input.value, 'Day')
              })
            }
          )
        })
      })
    })
  }
)

QUnit.module('Gradebook > Default Gradebook > LatePoliciesTabPanel > with enzyme', () => {
  function latePenaltiesForm(wrapper) {
    return wrapper.find(FormFieldGroup).at(1)
  }

  function missingPenaltiesForm(wrapper) {
    return wrapper.find(FormFieldGroup).at(0)
  }

  function lateDeductionCheckbox(wrapper) {
    return wrapper.find('input[type="checkbox"]').at(1)
  }

  function lateDeductionInput(wrapper) {
    return latePenaltiesForm(wrapper).find('input#late-submission-deduction').at(0)
  }

  function lateDeductionIntervalSelect(wrapper) {
    return latePenaltiesForm(wrapper).find('CanvasSelect').at(0)
  }

  function lateDeductionIntervalSelectInput(wrapper) {
    return latePenaltiesForm(wrapper).find('input').at(0)
  }

  function lateSubmissionMinimumPercentInput(wrapper) {
    return latePenaltiesForm(wrapper).find('input[type="text"]').at(2)
  }

  function missingDeductionCheckbox(wrapper) {
    return wrapper.find('input[type="checkbox"]').at(0)
  }

  function missingDeductionInput(wrapper) {
    return missingPenaltiesForm(wrapper)
      .find('NumberInput#missing-submission-grade')
      .find('input[type="text"]')
  }

  function gradedSubmissionsAlert(wrapper) {
    return wrapper
      .find(Alert)
      .filterWhere(n =>
        n.text().includes('Changing the late policy will affect previously graded submissions')
      )
  }

  function spinner(wrapper) {
    return wrapper.find(Spinner)
  }

  function changeLateDeductionIntervalSelect(wrapper, value) {
    // enzyme's simulate didn't work for 'change' on CanvasSelect for some unknown reason
    return lateDeductionIntervalSelect(wrapper).props().onChange({target: {value}}, value)
  }

  function mountComponent(latePolicyProps = {}, otherProps = {}) {
    const defaults = {
      changeLatePolicy() {},
      gradebookIsEditable: true,
      locale: 'en',
      showAlert: false,
    }
    props = {
      latePolicy: {
        changes: {},
        validationErrors: {},
        data: latePolicyData,
        ...latePolicyProps,
      },
      ...defaults,
      ...otherProps,
    }
    changeLatePolicySpy = sinon.spy(props, 'changeLatePolicy')
    return mount(<LatePoliciesTabPanel {...props} />, {
      attachTo: document.getElementById('fixtures'),
    })
  }

  const latePolicyData = {
    missingSubmissionDeductionEnabled: true,
    missingSubmissionDeduction: 0,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionDeduction: 0,
    lateSubmissionInterval: 'day',
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionMinimumPercent: 0,
  }
  let changeLatePolicySpy
  let props

  QUnit.module('LatePoliciesTabPanel: Alert', hooks => {
    let wrapper
    hooks.afterEach(() => {
      wrapper.unmount()
    })

    test('initializes with an alert showing if passed showAlert: true', () => {
      wrapper = mountComponent({}, {showAlert: true})
      strictEqual(gradedSubmissionsAlert(wrapper).length, 1)
    })

    test('does not initialize with an alert showing if passed showAlert: false', () => {
      wrapper = mountComponent({})
      strictEqual(gradedSubmissionsAlert(wrapper).length, 0)
    })

    test('focuses on the missing submission input when the alert closes', () => {
      wrapper = mountComponent({}, {showAlert: true})
      const instance = wrapper.instance()
      const input = instance.missingSubmissionDeductionInput
      sinon.stub(input, 'focus')
      instance.closeAlert()
      strictEqual(input.focus.callCount, 1)
      input.focus.restore()
    })

    test('does not focus on the missing submission checkbox when the alert closes', () => {
      wrapper = mountComponent({}, {showAlert: true})
      const instance = wrapper.instance()
      const checkbox = instance.missingSubmissionCheckbox
      sinon.stub(checkbox, 'focus')
      instance.closeAlert()
      strictEqual(checkbox.focus.callCount, 0)
      checkbox.focus.restore()
    })

    test(
      'focuses on the missing submission checkbox when the alert closes if the' +
        'missing submission input is disabled',
      () => {
        const data = {...latePolicyData, missingSubmissionDeductionEnabled: false}
        wrapper = mountComponent({data}, {showAlert: true})
        const instance = wrapper.instance()
        const checkbox = instance.missingSubmissionCheckbox
        sinon.stub(checkbox, 'focus')
        instance.closeAlert()
        strictEqual(checkbox.focus.callCount, 1)
        checkbox.focus.restore()
      }
    )

    test(
      'does not focus on the missing submission input when the alert closes if the' +
        'missing submission input is disabled',
      () => {
        const data = {...latePolicyData, missingSubmissionDeductionEnabled: false}
        wrapper = mountComponent({data}, {showAlert: true})
        const instance = wrapper.instance()
        const input = instance.missingSubmissionDeductionInput
        sinon.stub(input, 'focus')
        instance.closeAlert()
        strictEqual(input.focus.callCount, 0)
        input.focus.restore()
      }
    )
  })

  QUnit.module('LatePoliciesTabPanel: spinner', {
    teardown() {
      this.wrapper.unmount()
    },
  })

  test('shows a spinner if no data is present', function () {
    this.wrapper = mountComponent({data: undefined})
    strictEqual(spinner(this.wrapper).length, 1)
  })

  test('does not show a spinner if data is present', function () {
    this.wrapper = mountComponent()
    strictEqual(spinner(this.wrapper).length, 0)
  })

  QUnit.module('LatePoliciesTabPanel: validations', {
    teardown() {
      this.wrapper.unmount()
    },
  })

  test('shows a message if missing deduction validation errors are passed', function () {
    this.wrapper = mountComponent({validationErrors: {missingSubmissionDeduction: 'An Error'}})
    ok(this.wrapper.text().includes('An Error'))
  })

  test('shows a message if late deduction validation errors are passed', function () {
    this.wrapper = mountComponent({validationErrors: {lateSubmissionDeduction: 'An Error'}})
    ok(this.wrapper.text().includes('An Error'))
  })

  QUnit.module('LatePoliciesTabPanel: missing submission deduction checkbox', {
    teardown() {
      this.wrapper.unmount()
    },
  })

  test('calls the changeLatePolicy function when the missing submission deduction checkbox is changed', function () {
    this.wrapper = mountComponent()
    missingDeductionCheckbox(this.wrapper).simulate('change', {target: {checked: false}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes,
      {missingSubmissionDeductionEnabled: false},
      'sends the changes'
    )
  })

  test('does not send any changes to the changeLatePolicy function on the second action if the missing submission deduction checkbox is unchecked and then checked', function () {
    this.wrapper = mountComponent()
    const checkbox = missingDeductionCheckbox(this.wrapper)
    checkbox.simulate('change', {target: {checked: false}})
    checkbox.simulate('change', {target: {checked: true}})
    strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy')
    deepEqual(changeLatePolicySpy.getCall(1).args[0].changes, {}, 'does not send any changes')
  })

  QUnit.module('LatePoliciesTabPanel: missing submission deduction input', {
    teardown() {
      this.wrapper.unmount()
    },
  })

  test('missing submission input has label describing it', function () {
    this.wrapper = mountComponent()
    const input = missingPenaltiesForm(this.wrapper).find('#missing-submission-grade').at(0)
    strictEqual(input.text(), 'Grade for missing submissions')
  })

  test('enables the missing deduction input if the missing deduction checkbox is checked', function () {
    this.wrapper = mountComponent()
    notOk(missingDeductionInput(this.wrapper).prop('disabled'))
  })

  test('disables the missing deduction input if the missing deduction checkbox is unchecked', function () {
    const data = {...latePolicyData, missingSubmissionDeductionEnabled: false}
    this.wrapper = mountComponent({data})
    strictEqual(missingDeductionInput(this.wrapper).prop('disabled'), true)
  })

  test('calls the changeLatePolicy function with a new deduction when the missing submission deduction input is changed and is valid', function () {
    this.wrapper = mountComponent()
    missingDeductionInput(this.wrapper).simulate('change', {target: {value: '22'}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes,
      {missingSubmissionDeduction: 78},
      'sends the changes'
    )
  })

  test('does not send any changes to the changeLatePolicy function when the missing submission deduction input is changed back to its initial value', function () {
    this.wrapper = mountComponent()
    const input = missingDeductionInput(this.wrapper)
    input.simulate('change', {target: {value: '22'}})
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].changes,
      {missingSubmissionDeduction: 78},
      'sends changed values, with missing deduction subtracted from 100'
    )
    input.simulate('change', {target: {value: '100'}})
    strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy when value changed')
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].changes,
      {missingSubmissionDeduction: 0},
      'sends changed values, missing deduction subtracted from 100'
    )
    input.simulate('blur')
    strictEqual(
      changeLatePolicySpy.callCount,
      2,
      'does not call changeLatePolicy on blur when no change'
    )
  })

  test('calls the changeLatePolicy function with a validationError if the missing submission deduction input is changed and is not numeric', function () {
    this.wrapper = mountComponent()
    missingDeductionInput(this.wrapper).simulate('change', {target: {value: 'abc'}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes.missingSubmissionDeduction,
      NaN,
      'passes NaN on change'
    )

    const newProps = {...this.wrapper.props()}
    newProps.latePolicy.changes = {missingSubmissionDeduction: NaN}
    this.wrapper.setProps(newProps)

    missingDeductionInput(this.wrapper).simulate('blur')
    strictEqual(
      changeLatePolicySpy.callCount,
      2,
      'calls changeLatePolicy on blur when changes have been made'
    )
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].validationErrors,
      {},
      'no validation errors on firstCall'
    )
    deepEqual(
      changeLatePolicySpy.secondCall.args[0].validationErrors,
      {missingSubmissionDeduction: 'Missing submission grade must be numeric'},
      'sends validation errors on secondCall'
    )
  })

  test('calls the changeLatePolicy function without a validationError for missing submission deduction if a valid input is entered after an invalid input is entered', function () {
    this.wrapper = mountComponent({
      changes: {
        missingSubmissionDeduction: 0,
      },
      validationErrors: {
        missingSubmissionDeduction: 'Missing submission grade must be between 0 and 100',
      },
    })
    missingDeductionInput(this.wrapper).simulate('blur')
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].validationErrors,
      {},
      'does not send validation errors for missingSubmissionDeduction on onBlur'
    )
  })

  QUnit.module('LatePoliciesTabPanel: late submission deduction checkbox', {
    teardown() {
      this.wrapper.unmount()
    },
  })

  test('calls the changeLatePolicy function when the late submission deduction checkbox is changed', function () {
    const data = {...latePolicyData, lateSubmissionDeductionEnabled: false}
    this.wrapper = mountComponent({data})
    lateDeductionCheckbox(this.wrapper).simulate('change', {target: {checked: true}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes,
      {lateSubmissionDeductionEnabled: true},
      'sends the changes'
    )
  })

  test('does not send any changes to the changeLatePolicy function on the second action if the late submission deduction checkbox is unchecked and then checked', function () {
    this.wrapper = mountComponent()
    const checkbox = lateDeductionCheckbox(this.wrapper)
    checkbox.simulate('change', {target: {checked: false}})
    checkbox.simulate('change', {target: {checked: true}})
    strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy')
    deepEqual(changeLatePolicySpy.getCall(1).args[0].changes, {}, 'does not send any changes')
  })

  test('sets lateSubmissionMinimumPercentEnabled to true when the late submission deduction checkbox is checked and the late submission minimum percent is greater than zero', function () {
    const data = {
      ...latePolicyData,
      lateSubmissionMinimumPercent: 1,
      lateSubmissionDeductionEnabled: false,
    }
    this.wrapper = mountComponent({data})
    lateDeductionCheckbox(this.wrapper).simulate('change', {target: {checked: true}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes,
      {lateSubmissionDeductionEnabled: true, lateSubmissionMinimumPercentEnabled: true},
      'sends the changes'
    )
  })

  test('does not set lateSubmissionMinimumPercentEnabled to true when the late submission deduction checkbox is checked and the late submission minimum percent is zero', function () {
    const data = {...latePolicyData, lateSubmissionDeductionEnabled: false}
    this.wrapper = mountComponent({data})
    lateDeductionCheckbox(this.wrapper).simulate('change', {target: {checked: true}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes,
      {lateSubmissionDeductionEnabled: true},
      'sends the changes'
    )
  })

  QUnit.module('LatePoliciesTabPanel: late submission deduction input', {
    teardown() {
      this.wrapper.unmount()
    },
  })

  test('disables the late deduction input if the late deduction checkbox is unchecked', function () {
    const data = {...latePolicyData, lateSubmissionDeductionEnabled: false}
    this.wrapper = mountComponent({data})
    ok(lateDeductionInput(this.wrapper).prop('disabled'))
  })

  test('enables the late deduction input if the late deduction checkbox is checked', function () {
    this.wrapper = mountComponent()
    notOk(lateDeductionInput(this.wrapper).prop('disabled'))
  })

  test('calls the changeLatePolicy function with a new deduction when the late submission deduction input is changed and is valid', function () {
    this.wrapper = mountComponent()
    lateDeductionInput(this.wrapper).simulate('change', {target: {value: '22'}})
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.firstCall.args[0].changes,
      {lateSubmissionDeduction: 22},
      'sends the changes'
    )
  })

  test('does not send any changes to the changeLatePolicy function when the late submission deduction input is changed back to its initial value', function () {
    this.wrapper = mountComponent()
    const input = lateDeductionInput(this.wrapper)
    input.simulate('change', {target: {value: '22'}})
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].changes,
      {lateSubmissionDeduction: 22},
      'sends changed values'
    )

    input.simulate('change', {target: {value: '0'}})
    strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].changes,
      {lateSubmissionDeduction: 0},
      'sends changed values'
    )

    input.simulate('blur')
    strictEqual(
      changeLatePolicySpy.callCount,
      2,
      'does not call changeLatePolicy on blur with no changes'
    )
  })

  test('calls the changeLatePolicy function with a validationError if the late submission deduction input is changed and is not numeric', function () {
    this.wrapper = mountComponent()
    lateDeductionInput(this.wrapper).simulate('change', {target: {value: 'abc'}})

    const newProps = {...this.wrapper.props()}
    newProps.latePolicy.changes = {lateSubmissionDeduction: NaN}
    this.wrapper.setProps(newProps)

    lateDeductionInput(this.wrapper).simulate('blur')
    strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].changes,
      {lateSubmissionDeduction: NaN},
      'includes the changed value'
    )
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].validationErrors,
      {lateSubmissionDeduction: 'Late submission deduction must be numeric'},
      'sends validation errors'
    )
  })

  test('calls the changeLatePolicy function without a validationError for late submission deduction if a valid input is entered after an invalid input is entered', function () {
    this.wrapper = mountComponent({
      changes: {
        lateSubmissionDeduction: 100,
      },
      validationErrors: {
        lateSubmissionDeduction: 'Late submission deduction must be between 0 and 100',
      },
    })
    lateDeductionInput(this.wrapper).simulate('blur')
    strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
    deepEqual(
      changeLatePolicySpy.lastCall.args[0].validationErrors,
      {},
      'does not send validation errors for lateSubmissionDeduction'
    )
  })

  QUnit.module('LatePoliciesTabPanel: late submission deduction interval select', hooks => {
    let wrapper

    hooks.afterEach(() => {
      wrapper.unmount()
    })

    test('disables the late deduction interval select if the late deduction checkbox is unchecked', () => {
      const data = {...latePolicyData, lateSubmissionDeductionEnabled: false}
      wrapper = mountComponent({data})
      ok(lateDeductionIntervalSelectInput(wrapper).prop('disabled'))
    })

    test('enables the late deduction interval select if the late deduction checkbox is checked', () => {
      wrapper = mountComponent()
      notOk(lateDeductionIntervalSelectInput(wrapper).prop('disabled'))
    })

    test('calls the changeLatePolicy function when the late submission deduction interval select is changed', () => {
      wrapper = mountComponent()
      changeLateDeductionIntervalSelect(wrapper, 'hour')
      strictEqual(changeLatePolicySpy.callCount, 1)
    })

    test('calls the changeLatePolicy function with a new deduction interval when the late submission deduction interval select is changed', () => {
      wrapper = mountComponent()
      changeLateDeductionIntervalSelect(wrapper, 'hour')
      const {
        firstCall: {
          args: [{changes}],
        },
      } = changeLatePolicySpy
      deepEqual(changes, {lateSubmissionInterval: 'hour'})
    })

    test('does not send any changes to the changeLatePolicy function when the late submission deduction interval is changed back to its initial value', () => {
      wrapper = mountComponent({})
      changeLateDeductionIntervalSelect(wrapper, 'hour')
      changeLateDeductionIntervalSelect(wrapper, 'day')
      const {
        secondCall: {
          args: [{changes}],
        },
      } = changeLatePolicySpy
      deepEqual(changes, {})
    })
  })

  QUnit.module('LatePoliciesTabPanel: late submission minimum percent input', hooks => {
    let wrapper

    hooks.afterEach(() => {
      wrapper.unmount()
    })

    test('calls the changeLatePolicy function with a new percent when the late submission minimum percent input is changed and is valid', () => {
      const data = {
        ...latePolicyData,
        lateSubmissionMinimumPercent: 60,
        lateSubmissionMinimumPercentEnabled: true,
      }
      wrapper = mountComponent({data})
      lateSubmissionMinimumPercentInput(wrapper).simulate('change', {target: {value: '22'}})
      strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
      deepEqual(
        changeLatePolicySpy.firstCall.args[0].changes,
        {lateSubmissionMinimumPercent: 22},
        'sends the changes'
      )
    })

    test('does not send any changes to the changeLatePolicy function when the late submission minimum percent input is changed back to its initial value', () => {
      const data = {
        ...latePolicyData,
        lateSubmissionMinimumPercent: 60,
        lateSubmissionMinimumPercentEnabled: true,
      }
      wrapper = mountComponent({data})
      const input = lateSubmissionMinimumPercentInput(wrapper)
      input.simulate('change', {target: {value: '22'}})

      const newProps = {
        ...wrapper.props(),
      }
      newProps.latePolicy.changes = {lateSubmissionMinimumPercent: 22}
      wrapper.setProps(newProps)

      input.simulate('blur')
      deepEqual(
        changeLatePolicySpy.lastCall.args[0].changes,
        {lateSubmissionMinimumPercent: 22},
        'sends changes when value changed'
      )

      input.simulate('change', {target: {value: '60'}})

      const evenNewerProps = {
        ...wrapper.props(),
      }
      evenNewerProps.latePolicy.changes = {lateSubmissionMinimumPercent: 60}
      wrapper.setProps(evenNewerProps)

      input.simulate('blur')
      strictEqual(changeLatePolicySpy.callCount, 4, 'calls changeLatePolicy')
      deepEqual(changeLatePolicySpy.lastCall.args[0].changes, {}, 'does not send any changes')
    })

    test('sets lateSubmissionMinimumPercentEnabled to true if the minimum percent is changed from zero to non-zero', () => {
      wrapper = mountComponent()
      const input = lateSubmissionMinimumPercentInput(wrapper)
      input.simulate('change', {target: {value: '22'}})
      strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy once')

      const {changes} = changeLatePolicySpy.firstCall.args[0]
      const newProps = {
        ...wrapper.props(),
      }
      newProps.latePolicy.changes = {...newProps.latePolicy.changes, ...changes}
      wrapper.setProps(newProps)
      input.simulate('blur')
      strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy twice')
      deepEqual(
        changeLatePolicySpy.lastCall.args[0].changes,
        {lateSubmissionMinimumPercent: 22, lateSubmissionMinimumPercentEnabled: true},
        'sends the changes'
      )
    })

    test('sets lateSubmissionMinimumPercentEnabled to false if the minimum percent is changed from non-zero to zero', () => {
      const data = {
        ...latePolicyData,
        lateSubmissionMinimumPercent: 60,
        lateSubmissionMinimumPercentEnabled: true,
      }
      wrapper = mountComponent({data})
      const input = lateSubmissionMinimumPercentInput(wrapper)
      input.simulate('change', {target: {value: '0'}})
      const {changes} = changeLatePolicySpy.firstCall.args[0]
      const newProps = {
        ...wrapper.props(),
      }
      newProps.latePolicy.changes = {...newProps.latePolicy.changes, ...changes}
      wrapper.setProps(newProps)
      input.simulate('blur')
      strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy')
      deepEqual(
        changeLatePolicySpy.secondCall.args[0].changes,
        {lateSubmissionMinimumPercent: 0, lateSubmissionMinimumPercentEnabled: false},
        'sends the changes'
      )
    })

    test('calls the changeLatePolicy function with a validationError if the late submission minimum percent input is changed and is not numeric', () => {
      wrapper = mountComponent()
      lateSubmissionMinimumPercentInput(wrapper).simulate('change', {target: {value: 'abc'}})
      strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
      deepEqual(
        changeLatePolicySpy.firstCall.args[0].changes,
        {lateSubmissionMinimumPercent: NaN},
        'sends NaN'
      )
      deepEqual(changeLatePolicySpy.firstCall.args[0].validationErrors, {}, 'no validation errors')

      const newProps = {
        ...wrapper.props(),
      }
      newProps.latePolicy.changes = {lateSubmissionMinimumPercent: NaN}
      wrapper.setProps(newProps)

      lateSubmissionMinimumPercentInput(wrapper).simulate('blur')
      strictEqual(changeLatePolicySpy.callCount, 2, 'calls changeLatePolicy')
      deepEqual(
        changeLatePolicySpy.lastCall.args[0].changes,
        {lateSubmissionMinimumPercent: NaN},
        'sends changes'
      )
      deepEqual(
        changeLatePolicySpy.lastCall.args[0].validationErrors,
        {lateSubmissionMinimumPercent: 'Lowest possible grade must be numeric'},
        'sends validation errors'
      )
    })

    test('does not allow entering negative numbers for late submission minimum percent', () => {
      wrapper = mountComponent({
        changes: {lateSubmissionMinimumPercentInput: -0.1},
      })
      const input = lateSubmissionMinimumPercentInput(wrapper)
      input.simulate('blur')
      strictEqual(input.instance().value, '0')
    })

    test('calls the changeLatePolicy function without a validationError for late submission minimum percent if a valid input is entered after an invalid input is entered', () => {
      wrapper = mountComponent({
        changes: {
          lateSubmissionMinimumPercent: 100,
        },
        validationErrors: {
          lateSubmissionMinimumPercent: 'Lowest possible grade must be between 0 and 100',
        },
      })
      lateSubmissionMinimumPercentInput(wrapper).simulate('blur')
      strictEqual(changeLatePolicySpy.callCount, 1, 'calls changeLatePolicy')
      deepEqual(
        changeLatePolicySpy.lastCall.args[0].validationErrors,
        {},
        'does not send validation errors for lateSubmissionMinimumPercent'
      )
    })
  })
})
