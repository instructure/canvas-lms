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

import React from 'react'
import {userEvent} from '@testing-library/user-event'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import LatePoliciesTabPanel from '../LatePoliciesTabPanel'
import {
  getAutomaticallyApplyGradeForMissingSubmissionsCheckbox,
  getAutomaticallyApplyDeductionToLateSubmissionsCheckbox,
  getGradePercentageForMissingSubmissionsInput,
  getLateSubmissionDeductionPercentInput,
  getLateSubmissionDeductionIntervalInput,
  getLowestPossibleGradePercentInput,
  getLatePoliciesTabPanelProps,
  getDefaultLatePolicyData,
  getLatePolicyData,
  findOption,
} from './helpers'

describe('LatePoliciesTabPanel', () => {
  describe('Missing Submissions', () => {
    /*
     * typically all props would be passed in on initial render, however
     * with this component the way it's been architected is to first render
     * and then fetch the data for the latePolicy and render again to update
     * those props. In order to accomplish this in test first we render the
     * component without `props.latePolicy.data` and then render it again
     * immediately to fake out the loading of this data but stil preserve
     * the double render behavior.
     */
    function subject(cb: (props: any) => void = () => {}) {
      const props: any = {...getLatePoliciesTabPanelProps(), ...{}}
      const container = render(<LatePoliciesTabPanel {...props} />)
      props.latePolicy.data = {...getDefaultLatePolicyData(), ...{}}
      cb(props)
      container.rerender(<LatePoliciesTabPanel {...props} />)
      return {container, props}
    }

    test("the 'Automatically apply grade for missing submissions' checkbox displays what's passed in via props", () => {
      subject(props => {
        props.latePolicy.data.missingSubmissionDeductionEnabled = true
      })
      expect(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen)).toBeChecked()
    })

    test("the 'Grade percentage for missing submissions' displays what's passed in via props, adjusted for display", () => {
      subject(props => {
        props.latePolicy.data.missingSubmissionDeduction = 42
      })
      expect(getGradePercentageForMissingSubmissionsInput(screen).value).toBe('58')
    })

    test('input and checkbox are disabled if gradebook is not editable by user', () => {
      subject(props => {
        props.gradebookIsEditable = false
      })
      expect(getGradePercentageForMissingSubmissionsInput(screen)).toBeDisabled()
      expect(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen)).toBeDisabled()
    })

    test("the 'Grade percentage for missing submissions' input is disabled by default", () => {
      subject()
      expect(getGradePercentageForMissingSubmissionsInput(screen)).toBeDisabled()
    })

    test("clicking the 'Automatically apply grade for missing submissions' checkbox enables the 'Grade percentage for missing submissions' input", async () => {
      const {container, props} = subject(_props => {
        _props.changeLatePolicy = () =>
          (_props.latePolicy.data.missingSubmissionDeductionEnabled = true)
      })
      expect(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen)).not.toBeChecked()
      await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
      container.rerender(<LatePoliciesTabPanel {...props} />)
      await waitFor(() => {
        expect(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen)).toBeChecked()
      })
      expect(getGradePercentageForMissingSubmissionsInput(screen)).not.toBeDisabled()
    })

    test("the 'Grade percentage for missing submissions' defaults to 0", async () => {
      subject()
      await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
      expect(getGradePercentageForMissingSubmissionsInput(screen).value).toBe('0')
    })

    test('when a single character is entered in the input, changeLatePolicy is called once', async () => {
      let mock
      subject(props => {
        mock = props.changeLatePolicy = jest.fn()
      })
      await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
      const input = getGradePercentageForMissingSubmissionsInput(screen)
      expect(mock).toHaveBeenCalledTimes(1)
      fireEvent.change(input, {target: {value: '1'}})
      expect(mock).toHaveBeenCalledTimes(2)
    })

    test('when clearing the input and then typing one character followed by blurring the input, changeLatePolicy is calle three times', async () => {
      let mock
      subject(props => {
        mock = props.changeLatePolicy = jest.fn()
      })
      await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
      const input = getGradePercentageForMissingSubmissionsInput(screen)
      expect(mock).toHaveBeenCalledTimes(1)
      fireEvent.change(input, {target: {value: '1'}})
      expect(mock).toHaveBeenCalledTimes(2)
      fireEvent.change(input, {target: {value: ''}})
      fireEvent.change(input, {target: {value: '9'}})
      expect(mock).toHaveBeenCalledTimes(4)
      fireEvent.blur(input)
      expect(mock).toHaveBeenCalledTimes(4) // blur is smart enough now not to trigger it by itself with no changes
    })

    test('changeLatePolicy passes the difference of 100 - missingSubmissionDeduction', async () => {
      let mock
      subject(props => {
        mock = props.changeLatePolicy = jest.fn()
      })
      await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
      const input = getGradePercentageForMissingSubmissionsInput(screen)
      fireEvent.change(input, {target: {value: '1.23'}})
      fireEvent.blur(input)
      expect(mock).toHaveBeenCalledWith({
        changes: {missingSubmissionDeduction: 98.77},
        data: expect.anything(),
        validationErrors: expect.anything(),
      })
    })
  })

  describe('Late Submissions', () => {
    /*
     * typically all props would be passed in on initial render, however
     * with this component the way it's been architected is to first render
     * and then fetch the data for the latePolicy and render again to update
     * those props. In order to accomplish this in test first we render the
     * component without `props.latePolicy.data` and then render it again
     * immediately to fake out the loading of this data but stil preserve
     * the double render behavior.
     */
    function subject(cb: (props: any) => void = () => {}) {
      const props: any = {...getLatePoliciesTabPanelProps(), ...{}}
      const {rerender} = render(<LatePoliciesTabPanel {...props} />)
      props.latePolicy.data = {...getDefaultLatePolicyData, ...{}}
      cb(props)
      rerender(<LatePoliciesTabPanel {...props} />)
    }

    test("the 'Automatically apply grade for missing submissions' checkbox displays what's passed in via props", () => {
      subject(props => {
        props.latePolicy.data.lateSubmissionDeductionEnabled = true
      })
      expect(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen)).toBeChecked()
    })

    test("the 'Late submission deduction percent' input displays what's passed in via props", () => {
      subject(props => {
        props.latePolicy.data.lateSubmissionDeduction = 43
      })
      expect(getLateSubmissionDeductionPercentInput(screen).value).toEqual('43')
    })

    test("the 'Lowest Possible Grade Percent' input displays what's passed in via props", () => {
      subject(props => {
        props.latePolicy.data.lateSubmissionMinimumPercent = 44
      })
      expect(getLowestPossibleGradePercentInput(screen).value).toEqual('44')
    })

    test('the correct inputs are disabled and have the correct default values', () => {
      subject(props => {
        props.latePolicy.data = getDefaultLatePolicyData()
      })
      expect(getLateSubmissionDeductionPercentInput(screen)).toBeDisabled()
      expect(getLateSubmissionDeductionIntervalInput(screen)).toBeDisabled()
      expect(getLowestPossibleGradePercentInput(screen)).toBeDisabled()
      expect(getLateSubmissionDeductionPercentInput(screen).value).toEqual('0')
      expect(getLateSubmissionDeductionIntervalInput(screen).value).toEqual('Day')
      expect(getLowestPossibleGradePercentInput(screen).value).toEqual('0')
      expect(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen)).not.toBeChecked()
    })

    describe('when the "Automatically apply deduction to late submissions" checkbox is toggled on', () => {
      test('inputs and checkbox are disabled if gradebook is not editable by user', async () => {
        subject(props => {
          props.gradebookIsEditable = false
          props.latePolicy.data.lateSubmissionDeductionEnabled = true
        })
        expect(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen)).toBeDisabled()
        expect(getLowestPossibleGradePercentInput(screen)).toBeDisabled()
        expect(getLateSubmissionDeductionPercentInput(screen)).toBeDisabled()
        expect(getLateSubmissionDeductionIntervalInput(screen)).toBeDisabled()
      })

      test('passes "lateSubmissionDeductionEnabled" to parent', async () => {
        let mock
        subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledWith({
          changes: {lateSubmissionDeductionEnabled: true},
          data: expect.anything(),
          validationErrors: expect.anything(),
        })
      })

      test('inputs and checkbox are not disabled', () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = true
        })
        expect(getLateSubmissionDeductionIntervalInput(screen)).not.toBeDisabled()
        expect(getLateSubmissionDeductionPercentInput(screen)).not.toBeDisabled()
        expect(getLowestPossibleGradePercentInput(screen)).not.toBeDisabled()
      })
    })

    describe('when the "Automatically apply deduction to late submissions" checkbox is toggled on and the "Late submission deduction interval" is changed', () => {
      let mock: any

      beforeEach(async () => {
        subject(props => {
          props.latePolicy.data = getLatePolicyData()
          mock = props.changeLatePolicy = jest.fn()
        })
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        await userEvent.click(getLateSubmissionDeductionIntervalInput(screen))
      })

      test('last call to changeLatePolicy is called with lateSubmissionInterval set to "hour"', async () => {
        await userEvent.click(findOption(document, 'Hour')!)

        expect(mock).toHaveBeenCalledWith({
          changes: {lateSubmissionInterval: 'hour'},
          data: expect.anything(),
          validationErrors: expect.anything(),
        })
      })

      test('last call to changeLatePolicy is not called when the same value as default is selected', async () => {
        await userEvent.click(findOption(document, 'Day')!)

        expect(mock).toHaveBeenCalledWith({
          changes: {lateSubmissionDeductionEnabled: false},
          data: expect.anything(),
          validationErrors: expect.anything(),
        })
      })

      test('sets Day and Hour when toggled several times', async () => {
        await userEvent.click(findOption(document, 'Day')!)
        expect(getLateSubmissionDeductionIntervalInput(screen).value).toEqual('Day')
        await userEvent.click(getLateSubmissionDeductionIntervalInput(screen))
        await userEvent.click(findOption(document, 'Hour')!)
        expect(getLateSubmissionDeductionIntervalInput(screen).value).toEqual('Hour')
        await userEvent.click(getLateSubmissionDeductionIntervalInput(screen))
        await userEvent.click(findOption(document, 'Day')!)
        expect(getLateSubmissionDeductionIntervalInput(screen).value).toEqual('Day')
      })
    })
  })

  describe('Alert', () => {
    const ref: any = React.createRef()

    function subject(specific_props: any, specific_data = {}) {
      let props: any = getLatePoliciesTabPanelProps()
      props = {...props, ...specific_props}
      props.latePolicy.data = {...getLatePolicyData(), ...specific_data}
      return render(<LatePoliciesTabPanel {...props} ref={ref} />)
    }

    test('initializes with an alert showing if passed showAlert: true', () => {
      subject({showAlert: true})
      expect(
        screen.getByText('Changing the late policy will affect previously graded submissions.')
      ).toBeInTheDocument()
    })

    test('does not initialize with an alert showing if passed showAlert: false', () => {
      subject({showAlert: false})
      expect(
        screen.queryByText('Changing the late policy will affect previously graded submissions.')
      ).not.toBeInTheDocument()
    })

    test('focuses on the missing submission input when the alert closes', () => {
      subject({showAlert: true})
      const spy = jest.spyOn(getGradePercentageForMissingSubmissionsInput(screen), 'focus')
      ref.current.closeAlert()
      expect(spy).toHaveBeenCalledTimes(1)
    })

    test('does not focus on the missing submission checkbox when the alert closes', () => {
      subject({showAlert: true})
      const spy = jest.spyOn(
        getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen),
        'focus'
      )
      ref.current.closeAlert()
      expect(spy).toHaveBeenCalledTimes(0)
    })

    test(
      'focuses on the missing submission checkbox when the alert closes if the' +
        'missing submission input is disabled',
      () => {
        subject({showAlert: true}, {missingSubmissionDeductionEnabled: false})
        const spy = jest.spyOn(
          getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen),
          'focus'
        )
        ref.current.closeAlert()
        expect(spy).toHaveBeenCalledTimes(1)
      }
    )

    test(
      'does not focus on the missing submission input when the alert closes if the' +
        'missing submission input is disabled',
      () => {
        subject({showAlert: true}, {missingSubmissionDeductionEnabled: false})
        const spy = jest.spyOn(getGradePercentageForMissingSubmissionsInput(screen), 'focus')
        ref.current.closeAlert()
        expect(spy).toHaveBeenCalledTimes(0)
      }
    )
  })

  describe('spinner', () => {
    test('shows a spinner if no data is present', function () {
      render(<LatePoliciesTabPanel {...getLatePoliciesTabPanelProps()} />)
      expect(screen.getByText('Loading')).toBeInTheDocument()
    })

    test('does not show a spinner if data is present', function () {
      const props: any = getLatePoliciesTabPanelProps()
      props.latePolicy.data = getLatePolicyData()
      render(<LatePoliciesTabPanel {...props} />)
      expect(screen.queryByText('Loading')).not.toBeInTheDocument()
    })
  })

  describe('validations', () => {
    let mock: any

    function subject(cb: (props: any) => void = () => {}) {
      const props: any = getLatePoliciesTabPanelProps()
      props.latePolicy.data = getDefaultLatePolicyData()
      cb(props)
      const container = render(<LatePoliciesTabPanel {...props} />)
      return {container, props}
    }

    test('shows a message if missing deduction validation errors are passed', async () => {
      subject(props => {
        props.latePolicy.validationErrors = {missingSubmissionDeduction: 'An Error'}
      })
      expect(screen.getAllByText('An Error')[0]).toBeInTheDocument()
    })

    test('shows a message if late deduction validation errors are passed', async () => {
      subject(props => {
        props.latePolicy.validationErrors = {lateSubmissionDeduction: 'An Error'}
      })
      expect(screen.getAllByText('An Error')[0]).toBeInTheDocument()
    })

    describe('missing submission deduction checkbox', () => {
      test('calls the changeLatePolicy function when the missing submission deduction checkbox is changed', async () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: expect.objectContaining({missingSubmissionDeductionEnabled: true}),
          })
        )
      })

      test('does not send any changes to the changeLatePolicy function on the second action if the missing submission deduction checkbox is unchecked and then checked', async () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn(
            () => (props.latePolicy.data.missingSubmissionDeductionEnabled = true)
          )
        })
        await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
        await userEvent.click(getAutomaticallyApplyGradeForMissingSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledTimes(2)
        expect(mock.mock.calls[1][0].changes).toEqual({})
      })
    })

    describe('missing submission deduction input', () => {
      test('missing submission input has label describing it', async () => {
        subject()
        expect(screen.getByText('Grade for missing submissions')).toBeInTheDocument()
      })

      test('enables the missing deduction input if the missing deduction checkbox is checked', async () => {
        subject(props => {
          props.latePolicy.data.missingSubmissionDeductionEnabled = true
        })
        expect(getGradePercentageForMissingSubmissionsInput(screen)).not.toBeDisabled()
      })

      test('disables the missing deduction input if the missing deduction checkbox is unchecked', () => {
        subject(props => {
          props.latePolicy.data.missingSubmissionDeductionEnabled = false
        })
        expect(getGradePercentageForMissingSubmissionsInput(screen)).toBeDisabled()
      })

      test('calls the changeLatePolicy function with a new deduction when the missing submission deduction input is changed and is valid', () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        fireEvent.change(getGradePercentageForMissingSubmissionsInput(screen), {
          target: {value: '22'},
        })
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {missingSubmissionDeduction: 78},
          })
        )
      })

      test('calls the changeLatePolicy function with a validationError if the missing submission deduction input is changed and is not numeric', () => {
        const {container} = subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        fireEvent.change(getGradePercentageForMissingSubmissionsInput(screen), {
          target: {value: 'abc'},
        })
        expect(mock).toHaveBeenCalledTimes(1)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {missingSubmissionDeduction: NaN},
          })
        )
        const props: any = getLatePoliciesTabPanelProps()
        props.latePolicy.data = getDefaultLatePolicyData()
        const rerender_mock = (props.changeLatePolicy = jest.fn())
        props.latePolicy.changes = {missingSubmissionDeduction: NaN}
        container.rerender(<LatePoliciesTabPanel {...props} />)
        fireEvent.blur(getGradePercentageForMissingSubmissionsInput(screen))
        expect(rerender_mock).toHaveBeenCalledWith(
          expect.objectContaining({
            validationErrors: {
              missingSubmissionDeduction: 'Missing submission grade must be numeric',
            },
          })
        )
      })

      test('calls the changeLatePolicy function without a validationError for missing submission deduction if a valid input is entered after an invalid input is entered', () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn()
          props.latePolicy.changes = {
            missingSubmissionDeduction: 0,
          }
          props.validationErrors = {
            missingSubmissionDeduction: 'Missing submission grade must be between 0 and 100',
          }
        })
        fireEvent.blur(getGradePercentageForMissingSubmissionsInput(screen))
        expect(mock).toHaveBeenCalledTimes(1)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            validationErrors: {},
          })
        )
      })
    })

    describe('late submission deduction checkbox', () => {
      test('calls the changeLatePolicy function when the late submission deduction checkbox is changed', async () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = false
          mock = props.changeLatePolicy = jest.fn()
        })
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {lateSubmissionDeductionEnabled: true},
          })
        )
      })

      test('does not send any changes to the changeLatePolicy function on the second action if the late submission deduction checkbox is unchecked and then checked', async () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn(
            () => (props.latePolicy.data.lateSubmissionDeductionEnabled = false)
          )
        })
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledTimes(2)
        expect(mock.mock.calls[1][0].changes).toEqual({})
      })

      test('sets lateSubmissionMinimumPercentEnabled to true when the late submission deduction checkbox is checked and the late submission minimum percent is greater than zero', async () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionMinimumPercent = 1
          props.latePolicy.data.lateSubmissionDeductionEnabled = false
          mock = props.changeLatePolicy = jest.fn()
        })
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {
              lateSubmissionDeductionEnabled: true,
              lateSubmissionMinimumPercentEnabled: true,
            },
          })
        )
      })

      test('does not set lateSubmissionMinimumPercentEnabled to true when the late submission deduction checkbox is checked and the late submission minimum percent is zero', async () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = false
          mock = props.changeLatePolicy = jest.fn()
        })
        await userEvent.click(getAutomaticallyApplyDeductionToLateSubmissionsCheckbox(screen))
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {
              lateSubmissionDeductionEnabled: true,
            },
          })
        )
      })
    })

    describe('late submission deduction input', () => {
      test('disables the late deduction input if the late deduction checkbox is unchecked', () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = false
        })
        expect(getLateSubmissionDeductionPercentInput(screen)).toBeDisabled()
      })

      test('enables the late deduction input if the late deduction checkbox is checked', () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = true
        })
        expect(getLateSubmissionDeductionPercentInput(screen)).not.toBeDisabled()
      })

      test('calls the changeLatePolicy function with a new deduction when the late submission deduction input is changed and is valid', async () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        fireEvent.change(getLateSubmissionDeductionPercentInput(screen), {
          target: {value: '22'},
        })
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {lateSubmissionDeduction: 22},
          })
        )
        fireEvent.change(getLateSubmissionDeductionPercentInput(screen), {
          target: {value: '0'},
        })
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {lateSubmissionDeduction: 0},
          })
        )
        fireEvent.blur(getLateSubmissionDeductionPercentInput(screen))
        // does not call changeLatePolicy on blur with no changes
        expect(mock).toHaveBeenCalledTimes(2)
      })

      test('calls the changeLatePolicy function with a validationError if the late submission deduction input is changed and is not numeric', () => {
        const {container} = subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        fireEvent.change(getLateSubmissionDeductionPercentInput(screen), {
          target: {value: 'abc'},
        })
        expect(mock).toHaveBeenCalledTimes(1)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {lateSubmissionDeduction: NaN},
          })
        )
        const props: any = getLatePoliciesTabPanelProps()
        props.latePolicy.data = getDefaultLatePolicyData()
        const rerender_mock = (props.changeLatePolicy = jest.fn())
        props.latePolicy.changes = {lateSubmissionDeduction: NaN}
        container.rerender(<LatePoliciesTabPanel {...props} />)
        fireEvent.blur(getLateSubmissionDeductionPercentInput(screen))
        expect(rerender_mock).toHaveBeenCalledWith(
          expect.objectContaining({
            validationErrors: {
              lateSubmissionDeduction: 'Late submission deduction must be numeric',
            },
          })
        )
      })
    })

    describe('late submission deduction interval select', () => {
      test('disables the late deduction interval select if the late deduction checkbox is unchecked', () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = false
        })
        expect(getLateSubmissionDeductionIntervalInput(screen)).toBeDisabled()
      })

      test('enables the late deduction interval select if the late deduction checkbox is checked', () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionDeductionEnabled = true
        })
        expect(getLateSubmissionDeductionIntervalInput(screen)).not.toBeDisabled()
      })

      test('calls the changeLatePolicy function when the late submission deduction interval select is changed', async () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn(() => {
            props.latePolicy.data.lateSubmissionDeductionEnabled = true
          })
          props.latePolicy.data.lateSubmissionDeductionEnabled = true
        })

        await userEvent.click(screen.getByLabelText(/deduction interval/i))
        await userEvent.click(await screen.findByText(/hour/i))
        expect(mock).toHaveBeenCalledTimes(1)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {
              lateSubmissionInterval: 'hour',
            },
          })
        )
      })
    })

    describe('late submission minimum percent input', () => {
      test('calls the changeLatePolicy function with a new percent when the late submission minimum percent input is changed and is valid', () => {
        subject(props => {
          mock = props.changeLatePolicy = jest.fn()
          props.latePolicy.data.lateSubmissionMinimumPercent = 60
          props.latePolicy.data.lateSubmissionMinimumPercentEnabled = true
        })
        fireEvent.change(getLowestPossibleGradePercentInput(screen), {
          target: {value: '22'},
        })
        expect(mock).toHaveBeenCalledTimes(1)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {
              lateSubmissionMinimumPercent: 22,
            },
          })
        )
      })

      test('sets lateSubmissionMinimumPercentEnabled to true if the minimum percent is changed from zero to non-zero', async () => {
        const {container, props} = subject(_props => {
          _props.lateSubmissionMinimumPercent = 0
          mock = _props.changeLatePolicy = jest.fn()
        })
        fireEvent.change(getLowestPossibleGradePercentInput(screen), {
          target: {value: '22'},
        })
        const changes = mock.mock.calls[0][0].changes
        props.latePolicy.changes = {...props.latePolicy.changes, ...changes}
        container.rerender(<LatePoliciesTabPanel {...props} />)
        fireEvent.blur(getLowestPossibleGradePercentInput(screen))
        expect(mock).toHaveBeenCalledTimes(2)
        expect(mock.mock.calls[1][0].changes).toEqual({
          lateSubmissionMinimumPercent: 22,
          lateSubmissionMinimumPercentEnabled: true,
        })
      })

      test('sets lateSubmissionMinimumPercentEnabled to false if the minimum percent is changed from non-zero to zero', () => {
        const {container, props} = subject(_props => {
          _props.latePolicy.data.lateSubmissionMinimumPercent = 60
          _props.latePolicy.data.lateSubmissionMinimumPercentEnabled = true
          mock = _props.changeLatePolicy = jest.fn()
        })
        const elm = screen.getByTestId('late-submission-minimum-percent')
        fireEvent.change(elm, {
          target: {value: '0'},
        })
        const {changes} = mock.mock.calls[0][0]
        props.latePolicy.changes = {...props.latePolicy.changes, ...changes}
        container.rerender(<LatePoliciesTabPanel {...props} />)
        fireEvent.blur(elm)
        expect(mock).toHaveBeenCalledTimes(2)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {
              lateSubmissionMinimumPercent: 0,
              lateSubmissionMinimumPercentEnabled: false,
            },
          })
        )
      })

      test('calls the changeLatePolicy function with a validationError if the late submission minimum percent input is changed and is not numeric', () => {
        const {container} = subject(props => {
          mock = props.changeLatePolicy = jest.fn()
        })
        fireEvent.change(getLowestPossibleGradePercentInput(screen), {
          target: {value: 'abc'},
        })
        expect(mock).toHaveBeenCalledTimes(1)
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            changes: {lateSubmissionMinimumPercent: NaN},
          })
        )
        const props: any = getLatePoliciesTabPanelProps()
        props.latePolicy.data = getDefaultLatePolicyData()
        const rerender_mock = (props.changeLatePolicy = jest.fn())
        props.latePolicy.changes = {lateSubmissionMinimumPercent: NaN}
        container.rerender(<LatePoliciesTabPanel {...props} />)
        fireEvent.blur(getLowestPossibleGradePercentInput(screen))
        expect(rerender_mock).toHaveBeenCalledWith(
          expect.objectContaining({
            validationErrors: {
              lateSubmissionMinimumPercent: 'Lowest possible grade must be numeric',
            },
          })
        )
      })

      test('does not allow entering negative numbers for late submission minimum percent', async () => {
        subject(props => {
          props.latePolicy.data.lateSubmissionMinimumPercent = -0.1
          props.latePolicy.changes.lateSubmissionMinimumPercent = 0
        })
        const elm = screen.getByTestId('late-submission-minimum-percent')
        fireEvent.focus(elm)
        fireEvent.blur(elm)
        expect(getLowestPossibleGradePercentInput(screen)).toHaveValue('0')
      })

      test('calls the changeLatePolicy function without a validationError for late submission minimum percent if a valid input is entered after an invalid input is entered', () => {
        subject(props => {
          props.latePolicy.changes = {lateSubmissionMinimumPercent: 100}
          props.latePolicy.validationErrors = {
            lateSubmissionMinimumPercent: 'Lowest possible grade must be between 0 and 100',
          }
          mock = props.changeLatePolicy = jest.fn()
        })
        fireEvent.blur(getLowestPossibleGradePercentInput(screen))
        expect(mock).toHaveBeenCalledWith(
          expect.objectContaining({
            validationErrors: {},
          })
        )
      })
    })
  })
})
