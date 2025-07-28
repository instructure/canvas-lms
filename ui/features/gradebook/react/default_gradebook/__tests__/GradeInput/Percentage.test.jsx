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
import {render, cleanup, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradeInput from '../../components/GradeInput'
import '@testing-library/jest-dom/extend-expect'

describe('Gradebook > Default Gradebook > Components > GradeInput', () => {
  let props

  beforeEach(() => {
    ENV.GRADEBOOK_OPTIONS = {assignment_missing_shortcut: true}

    const assignment = {
      anonymizeStudents: false,
      gradingType: 'percent',
      pointsPossible: 10,
    }

    const submission = {
      enteredGrade: '78%',
      enteredScore: 7.8,
      excused: false,
      id: '2501',
    }

    const gradingScheme = [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.7],
      ['D', 0.6],
      ['F', 0],
    ]

    props = {
      assignment,
      disabled: false,
      enterGradesAs: 'percent',
      gradingScheme,
      onSubmissionUpdate: jest.fn(),
      pendingGradeInfo: null,
      submission,
    }
  })

  afterEach(() => {
    cleanup()
  })

  const renderComponent = () => render(<GradeInput {...props} />)

  it('displays a label of "Grade out of 100%"', () => {
    const {getByLabelText} = renderComponent()
    expect(getByLabelText('Grade out of 100%')).toBeInTheDocument()
  })

  it('sets the scheme key grade of the submission as the input value', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue('78%')).toBeInTheDocument()
  })

  it('is blank when the submission is not graded', () => {
    props.submission.enteredGrade = null
    props.submission.enteredScore = null
    const {queryByDisplayValue} = renderComponent()
    expect(queryByDisplayValue('')).toBeInTheDocument()
  })

  describe('when the submission is excused', () => {
    beforeEach(() => {
      props.submission.excused = true
    })

    it('sets the input value to "Excused"', () => {
      const {getByDisplayValue} = renderComponent()
      expect(getByDisplayValue('Excused')).toBeInTheDocument()
    })

    it('disables the input', () => {
      const {getByDisplayValue} = renderComponent()
      const input = getByDisplayValue('Excused')
      expect(input).toBeDisabled()
    })
  })

  it('is blank when the assignment has anonymized students', () => {
    props.assignment.anonymizeStudents = true
    const {queryByDisplayValue} = renderComponent()
    expect(queryByDisplayValue('')).toBeInTheDocument()
  })

  it('disables the input when disabled is true', () => {
    props.disabled = true
    const {getByDisplayValue} = renderComponent()
    const input = getByDisplayValue('78%')
    expect(input).toBeDisabled()
  })

  describe('when the input receives a new value', () => {
    beforeEach(async () => {
      const {getByDisplayValue} = renderComponent()
      const input = getByDisplayValue('78%')
      await userEvent.clear(input)
      await userEvent.type(input, '98%')
    })

    it('updates the input to the given value', async () => {
      const input = document.querySelector('input')
      await waitFor(() => {
        expect(input.value).toBe('98%')
      })
    })

    it('does not call the onSubmissionUpdate prop', () => {
      expect(props.onSubmissionUpdate).not.toHaveBeenCalled()
    })
  })

  describe('when the input blurs after receiving a new value', () => {
    beforeEach(async () => {
      const {getByDisplayValue} = renderComponent()
      const input = getByDisplayValue('78%')
      await userEvent.clear(input)
      await userEvent.type(input, '98%')
      fireEvent.blur(input)
    })

    it('calls the onSubmissionUpdate prop', () => {
      expect(props.onSubmissionUpdate).toHaveBeenCalledTimes(1)
    })

    it('calls the onSubmissionUpdate prop with the submission', () => {
      const [updatedSubmission] =
        props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1]
      expect(updatedSubmission).toBe(props.submission)
    })

    it('calls the onSubmissionUpdate prop with the current grade info', () => {
      const [, gradeInfo] =
        props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1]
      expect(gradeInfo.grade).toBe('98%')
    })

    describe('when a unsigned numeric value is entered', () => {
      let gradeInfo

      beforeEach(async () => {
        const {getByDisplayValue} = renderComponent()
        const input = getByDisplayValue('78%')
        await userEvent.clear(input)
        await userEvent.type(input, '89.1')
        fireEvent.blur(input)
        gradeInfo =
          props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1][1]
      })

      it('calls the onSubmissionUpdate prop with the entered grade', () => {
        expect(gradeInfo.grade).toBe('89.1%')
      })

      it('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        expect(gradeInfo.score).toBe(8.91)
      })

      it('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
        expect(gradeInfo.enteredAs).toBe('percent')
      })
    })

    describe('when a percent value is entered', () => {
      let gradeInfo

      beforeEach(async () => {
        const {getByDisplayValue} = renderComponent()
        const input = getByDisplayValue('78%')
        await userEvent.clear(input)
        await userEvent.type(input, '89.1%')
        fireEvent.blur(input)
        gradeInfo =
          props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1][1]
      })

      it('calls the onSubmissionUpdate prop with the percent form of the entered grade', () => {
        expect(gradeInfo.grade).toBe('89.1%')
      })

      it('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        expect(gradeInfo.score).toBe(8.91)
      })

      it('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
        expect(gradeInfo.enteredAs).toBe('percent')
      })
    })

    describe('when a grading scheme value is entered', () => {
      let gradeInfo

      beforeEach(async () => {
        const {getByDisplayValue} = renderComponent()
        const input = getByDisplayValue('78%')
        await userEvent.clear(input)
        await userEvent.type(input, 'B')
        fireEvent.blur(input)
        gradeInfo =
          props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1][1]
      })

      it('calls the onSubmissionUpdate prop with the percent form of the entered grade', () => {
        expect(gradeInfo.grade).toBe('89%')
      })

      it('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        expect(gradeInfo.score).toBe(8.9)
      })

      it('calls the onSubmissionUpdate prop with the enteredAs set to "gradingScheme"', () => {
        expect(gradeInfo.enteredAs).toBe('gradingScheme')
      })
    })

    describe('when the submission is being excused', () => {
      let gradeInfo

      beforeEach(async () => {
        const {getByDisplayValue} = renderComponent()
        const input = getByDisplayValue('78%')
        await userEvent.clear(input)
        await userEvent.type(input, 'EX')
        fireEvent.blur(input)
        gradeInfo =
          props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1][1]
      })

      it('calls the onSubmissionUpdate prop with a null grade form', () => {
        expect(gradeInfo.grade).toBe(null)
      })

      it('calls the onSubmissionUpdate prop with a null score form', () => {
        expect(gradeInfo.score).toBe(null)
      })

      it('calls the onSubmissionUpdate prop with the enteredAs set to "excused"', () => {
        expect(gradeInfo.enteredAs).toBe('excused')
      })
    })

    describe('when an invalid grade value is entered', () => {
      let gradeInfo

      beforeEach(async () => {
        const {getByDisplayValue} = renderComponent()
        const input = getByDisplayValue('78%')
        await userEvent.clear(input)
        await userEvent.type(input, 'unknown')
        fireEvent.blur(input)
        gradeInfo =
          props.onSubmissionUpdate.mock.calls[props.onSubmissionUpdate.mock.calls.length - 1][1]
      })

      it('calls the onSubmissionUpdate prop with the grade set to the given value', () => {
        expect(gradeInfo.grade).toBe('unknown')
      })

      it('calls the onSubmissionUpdate prop with a null score form', () => {
        expect(gradeInfo.score).toBe(null)
      })

      it('calls the onSubmissionUpdate prop with enteredAs set to null', () => {
        expect(gradeInfo.enteredAs).toBe(null)
      })

      it('calls the onSubmissionUpdate prop with valid set to false', () => {
        expect(gradeInfo.valid).toBe(false)
      })
    })
  })

  describe('when the input blurs without having received a new value', () => {
    beforeEach(async () => {
      const {getByDisplayValue} = renderComponent()
      const input = getByDisplayValue('78%')
      await userEvent.clear(input)
      await userEvent.type(input, '9.8')
      await userEvent.clear(input)
      await userEvent.type(input, '78%')
      fireEvent.blur(input)
    })

    it('does not call the onSubmissionUpdate prop', () => {
      expect(props.onSubmissionUpdate).not.toHaveBeenCalled()
    })
  })

  describe('when the submission grade is updating', () => {
    beforeEach(() => {
      props.submission = {...props.submission, enteredGrade: null, enteredScore: null}
      props.submissionUpdating = true
      props.pendingGradeInfo = {grade: '98%', score: 9.8, valid: true, excused: false}
    })

    it('updates the text input with the value of the pending grade', async () => {
      const {getAllByDisplayValue} = renderComponent()
      await waitFor(() => {
        const inputs = getAllByDisplayValue('98%')
        expect(inputs.length).toBeGreaterThan(0)
      })
    })

    it('sets the text input to "Excused" when the submission is being excused', async () => {
      props.pendingGradeInfo = {grade: null, valid: false, excused: true}
      const {getByDisplayValue} = renderComponent()
      await waitFor(() => {
        expect(getByDisplayValue('Excused')).toBeInTheDocument()
      })
    })

    it('sets the input to "read only"', async () => {
      const {getAllByDisplayValue} = renderComponent()
      await waitFor(() => {
        const inputs = getAllByDisplayValue('98%')
        inputs.forEach(input => {
          expect(input).toHaveAttribute('readOnly')
        })
      })
    })

    describe('when the submission grade finishes updating', () => {
      beforeEach(async () => {
        props.submission = {...props.submission, enteredGrade: '98%', enteredScore: 9.8}
        props.submissionUpdating = false
        renderComponent()
      })

      it('updates the input value with the updated grade', async () => {
        const {getAllByDisplayValue} = renderComponent()
        await waitFor(() => {
          expect(getAllByDisplayValue('98%').length).toBeGreaterThan(0)
        })
      })

      it('enables the input', async () => {
        const {getAllByDisplayValue} = renderComponent()
        await waitFor(() => {
          const inputs = getAllByDisplayValue('98%')
          inputs.forEach(input => {
            expect(input).not.toHaveAttribute('readOnly')
          })
        })
      })
    })
  })

  describe('when the submission is otherwise being updated', () => {
    it('does not update the input value when the submission begins updating', async () => {
      props.submissionUpdating = true
      const {getAllByDisplayValue} = renderComponent()
      await waitFor(() => {
        expect(getAllByDisplayValue('78%').length).toBeGreaterThan(0)
      })
    })

    it('updates the input value when the submission finishes updating', async () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredGrade: '98%', enteredScore: 9.8}
      props.submissionUpdating = false
      const {getByDisplayValue} = renderComponent()
      await waitFor(() => {
        expect(getByDisplayValue('98%')).toBeInTheDocument()
      })
    })
  })
})
