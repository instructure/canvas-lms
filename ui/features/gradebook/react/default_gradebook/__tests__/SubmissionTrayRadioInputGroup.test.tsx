/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import SubmissionTrayRadioInputGroup, {
  type SubmissionTrayRadioInputGroupProps,
  type PendingUpdateData,
} from '../components/SubmissionTrayRadioInputGroup'

describe('SubmissionTrayRadioInputGroup Tests', () => {
  const updateSubmission: (arg0: PendingUpdateData) => void = jest.fn()

  const getComponent = (customProps: Partial<SubmissionTrayRadioInputGroupProps>) => {
    const props: SubmissionTrayRadioInputGroupProps = {
      assignment: {anonymizeStudents: false},
      colors: {
        late: '#FEF7E5',
        missing: '#F99',
        excused: '#E5F3FC',
        extended: '#E5F3FC',
      },
      disabled: false,
      latePolicy: {lateSubmissionInterval: 'day'},
      locale: 'en',
      submission: {
        excused: false,
        late: false,
        missing: false,
        secondsLate: 0,
        latePolicyStatus: '',
      },
      submissionUpdating: false,
      updateSubmission,
      customGradeStatusesEnabled: true,
      ...customProps,
    }

    return <SubmissionTrayRadioInputGroup {...props} />
  }

  const renderComponent = (customProps: Partial<SubmissionTrayRadioInputGroupProps>) => {
    return render(getComponent(customProps))
  }

  beforeEach(() => {
    ;(window.ENV as any) = {
      FEATURES: {
        extended_submission_state: true,
      },
    }
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  describe('radio input disabled tests', () => {
    it('renders radio inputs as enabled when disabled is false', () => {
      const {getByLabelText} = renderComponent({disabled: false})
      const lateInput = getByLabelText('Late')
      const missingInput = getByLabelText('Missing')
      const excusedInput = getByLabelText('Excused')
      const extendedInput = getByLabelText('Extended')

      expect(lateInput).not.toBeDisabled()
      expect(missingInput).not.toBeDisabled()
      expect(excusedInput).not.toBeDisabled()
      expect(extendedInput).not.toBeDisabled()
    })

    it('renders radio inputs as disabled when disabled is true', () => {
      const {getByLabelText} = renderComponent({disabled: true})
      const lateInput = getByLabelText('Late')
      const missingInput = getByLabelText('Missing')
      const excusedInput = getByLabelText('Excused')
      const extendedInput = getByLabelText('Extended')

      expect(lateInput).toBeDisabled()
      expect(missingInput).toBeDisabled()
      expect(excusedInput).toBeDisabled()
      expect(extendedInput).toBeDisabled()
    })
  })

  describe('radio input checked tests', () => {
    it('renders "none" radio input as checked when submission is not late, missing, or excused', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const noneInput = getByLabelText('None')
      expect(noneInput).toBeChecked()
    })

    it('renders with "none" selected if the submission is excused and the student is anonymous', () => {
      const {getByLabelText} = renderComponent({
        assignment: {anonymizeStudents: true},
        submission: {
          excused: true,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const noneInput = getByLabelText('None')
      expect(noneInput).toBeChecked()
    })

    it('renders with "none" selected if the submission is late and the student is anonymous', () => {
      const {getByLabelText} = renderComponent({
        assignment: {anonymizeStudents: true},
        submission: {
          excused: false,
          late: true,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const noneInput = getByLabelText('None')
      expect(noneInput).toBeChecked()
    })

    it('renders with "none" selected if the submission is missing and the student is anonymous', () => {
      const {getByLabelText} = renderComponent({
        assignment: {anonymizeStudents: true},
        submission: {
          excused: false,
          late: false,
          missing: true,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const noneInput = getByLabelText('None')
      expect(noneInput).toBeChecked()
    })

    it('renders with "Excused" selected if the submission is excused', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: true,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const excusedInput = getByLabelText('Excused')
      expect(excusedInput).toBeChecked()
    })

    it('renders with "Excused" selected if the submission is excused and also late', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: true,
          late: true,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const excusedInput = getByLabelText('Excused')
      expect(excusedInput).toBeChecked()
    })

    it('renders with "Excused" selected if the submission is excused and also missing', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: true,
          late: false,
          missing: true,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const excusedInput = getByLabelText('Excused')
      expect(excusedInput).toBeChecked()
    })

    it('renders with "Late" selected if the submission is not excused and is late', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: true,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const lateInput = getByLabelText('Late')
      expect(lateInput).toBeChecked()
    })

    it('renders with "Missing" selected if the submission is not excused and is missing', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: true,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const missingInput = getByLabelText('Missing')
      expect(missingInput).toBeChecked()
    })

    it('renders with "Extended" selected if the submission is not excused and is extended', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: 'extended',
        },
      })
      const extendedInput = getByLabelText('Extended')
      expect(extendedInput).toBeChecked()
    })
  })

  describe('radio input onChange tests', () => {
    it('calls updateSubmission with the late policy status for the selected radio input', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const lateInput = getByLabelText('Missing')
      fireEvent.click(lateInput)
      expect(updateSubmission).toHaveBeenCalledWith({latePolicyStatus: 'missing'})
    })

    it('calls updateSubmission with secondsLateOverride set to the submission secondsLate if the "late" option is selected', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 100,
          latePolicyStatus: '',
        },
      })
      const lateInput = getByLabelText('Late')
      fireEvent.click(lateInput)
      expect(updateSubmission).toHaveBeenCalledWith({
        latePolicyStatus: 'late',
        secondsLateOverride: 100,
      })
    })

    it('calls updateSubmission with excuse set to true if the "excused" option is selected', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const excusedInput = getByLabelText('Excused')
      fireEvent.click(excusedInput)
      expect(updateSubmission).toHaveBeenCalledWith({excuse: true})
    })

    it('does not call updateSubmission if the radio input is already selected', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const noneInput = getByLabelText('None')
      fireEvent.click(noneInput)
      expect(updateSubmission).not.toHaveBeenCalled()
    })

    it('does not queue up an update if there is not an update in flight', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
      })
      const missingInput = getByLabelText('Missing')
      fireEvent.click(missingInput)
      expect(updateSubmission).toHaveBeenCalledWith({latePolicyStatus: 'missing'})
      expect(updateSubmission).toHaveBeenCalledTimes(1)
    })
  })

  describe('when submissionUpdating is true', () => {
    it('does not call updateSubmission', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
        submissionUpdating: true,
      })
      const missingInput = getByLabelText('Missing')
      fireEvent.click(missingInput)
      expect(updateSubmission).not.toHaveBeenCalled()
    })

    it('queues up an update to be executed when the in-flight update is finished', () => {
      const {getByLabelText, rerender} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
        submissionUpdating: true,
      })
      const missingInput = getByLabelText('Missing')
      fireEvent.click(missingInput)
      expect(updateSubmission).not.toHaveBeenCalled()
      rerender(
        getComponent({
          submission: {
            excused: false,
            late: false,
            missing: false,
            secondsLate: 0,
            latePolicyStatus: '',
          },
          submissionUpdating: false,
        })
      )
      expect(updateSubmission).toHaveBeenCalledWith({latePolicyStatus: 'missing'})
    })

    it('queues up the update even it if matches the currently selected value', () => {
      const {getByLabelText, rerender} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: true,
          secondsLate: 0,
          latePolicyStatus: '',
        },
        submissionUpdating: true,
      })
      const missingInput = getByLabelText('None')
      fireEvent.click(missingInput)
      expect(updateSubmission).not.toHaveBeenCalled()
      rerender(
        getComponent({
          submission: {
            excused: false,
            late: false,
            missing: true,
            secondsLate: 0,
            latePolicyStatus: '',
          },
          submissionUpdating: false,
        })
      )
      expect(updateSubmission).toHaveBeenCalledWith({latePolicyStatus: 'none'})
    })

    it('only queues up one of multiple updates & only once', () => {
      const {getByLabelText, rerender} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
        submissionUpdating: true,
      })
      const missingInput = getByLabelText('Missing')
      fireEvent.click(missingInput)
      const lateInput = getByLabelText('Late')
      fireEvent.click(lateInput)
      expect(updateSubmission).not.toHaveBeenCalled()
      rerender(
        getComponent({
          submission: {
            excused: false,
            late: false,
            missing: false,
            secondsLate: 0,
            latePolicyStatus: '',
          },
          submissionUpdating: false,
        })
      )
      expect(updateSubmission).toHaveBeenCalledTimes(1)
      expect(updateSubmission).toHaveBeenCalledWith({
        latePolicyStatus: 'late',
        secondsLateOverride: 0,
      })
    })
  })

  describe('custom statuses', () => {
    it('renders with custom status selected if the submission is missing and has a custom status', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: true,
          secondsLate: 0,
          latePolicyStatus: '',
          customGradeStatusId: '1',
        },
        customGradeStatuses: [{id: '1', name: 'Custom Custom', color: 'blue'}],
      })
      const customInput = getByLabelText('Custom Custom')
      expect(customInput).toBeChecked()
    })

    it('renders with custom status selected if the submission is late and has a custom status', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: true,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
          customGradeStatusId: '1',
        },
        customGradeStatuses: [{id: '1', name: 'Custom Custom', color: 'blue'}],
      })
      const customInput = getByLabelText('Custom Custom')
      expect(customInput).toBeChecked()
    })

    it('renders with custom status selected if the submission is excused and has a custom status', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: true,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
          customGradeStatusId: '1',
        },
        customGradeStatuses: [{id: '1', name: 'Custom Custom', color: 'blue'}],
      })
      const customInput = getByLabelText('Custom Custom')
      expect(customInput).toBeChecked()
    })

    it('calls updateSubmission with the custom status id if the custom status is selected', () => {
      const {getByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
        customGradeStatuses: [{id: '1', name: 'Custom Custom', color: 'blue'}],
      })
      const customInput = getByLabelText('Custom Custom')
      fireEvent.click(customInput)
      expect(updateSubmission).toHaveBeenCalledWith({customGradeStatusId: '1'})
    })

    it('does not render custom statuses when customGradeStatusesEnabled is false', () => {
      const {queryByLabelText} = renderComponent({
        submission: {
          excused: false,
          late: false,
          missing: false,
          secondsLate: 0,
          latePolicyStatus: '',
        },
        customGradeStatuses: [{id: '1', name: 'Custom Custom', color: 'blue'}],
        customGradeStatusesEnabled: false,
      })
      const customInput = queryByLabelText('Custom Custom')
      expect(customInput).toBeNull()
    })
  })
})
