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
import { render, cleanup, fireEvent } from '@testing-library/react'
import GradeInput from '../../components/GradeInput'
import '@testing-library/jest-dom/extend-expect'
import sinon from 'sinon'

describe('Gradebook > Default Gradebook > Components > GradeInput', () => {
  let props

  beforeEach(() => {
    ENV.GRADEBOOK_OPTIONS = { assignment_missing_shortcut: true }

    const assignment = {
      anonymizeStudents: false,
      gradingType: 'letter_grade',
      pointsPossible: 10,
    }

    const submission = {
      enteredGrade: 'C',
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
      enterGradesAs: 'gradingScheme',
      gradingScheme,
      onSubmissionUpdate: sinon.stub(),
      pendingGradeInfo: null,
      submission,
    }
  })

  afterEach(() => {
    cleanup()
  })

  const renderComponent = () => render(<GradeInput {...props} />)

  it('displays a label of "Letter Grade"', () => {
    const { getByLabelText } = renderComponent()
    expect(getByLabelText('Letter Grade')).toBeInTheDocument()
  })

  it('sets the scheme key grade of the submission as the input value', () => {
    const { getByDisplayValue } = renderComponent()
    expect(getByDisplayValue('C')).toBeInTheDocument()
  })

  it('is blank when the submission is not graded', () => {
    props.submission.enteredGrade = null
    props.submission.enteredScore = null
    const { queryByDisplayValue } = renderComponent()
    expect(queryByDisplayValue('')).toBeInTheDocument()
  })

  describe('when the submission is excused', () => {
    beforeEach(() => {
      props.submission.excused = true
    })

    it('sets the input value to "Excused"', () => {
      const { getByDisplayValue } = renderComponent()
      expect(getByDisplayValue('Excused')).toBeInTheDocument()
    })

    it('disables the input', () => {
      const { getByDisplayValue } = renderComponent()
      const input = getByDisplayValue('Excused')
      expect(input).toBeDisabled()
    })
  })

  it('is blank when the assignment has anonymized students', () => {
    props.assignment.anonymizeStudents = true
    const { queryByDisplayValue } = renderComponent()
    expect(queryByDisplayValue('')).toBeInTheDocument()
  })

  it('disables the input when disabled is true', () => {
    props.disabled = true
    const { getByDisplayValue } = renderComponent()
    const input = getByDisplayValue('C')
    expect(input).toBeDisabled()
  })

  describe('when the input receives a new value', () => {
    beforeEach(() => {
      renderComponent()
      const input = document.querySelector('input')
      fireEvent.change(input, { target: { value: 'A' } })
    })

    it('updates the input to the given value', () => {
      const input = document.querySelector('input')
      expect(input.value).toBe('A')
    })

    it('does not call the onSubmissionUpdate prop', () => {
      expect(props.onSubmissionUpdate.callCount).toBe(0)
    })
  })

  describe('when the input blurs after receiving a new value', () => {
    beforeEach(() => {
      renderComponent()
      const input = document.querySelector('input')
      fireEvent.change(input, { target: { value: 'A' } })
      fireEvent.blur(input)
    })

    it('calls the onSubmissionUpdate prop', () => {
      expect(props.onSubmissionUpdate.callCount).toBe(1)
    })

    it('calls the onSubmissionUpdate prop with the submission', () => {
      const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
      expect(updatedSubmission).toBe(props.submission)
    })

    it('calls the onSubmissionUpdate prop with the current grade info', () => {
      const [, gradeInfo] = props.onSubmissionUpdate.lastCall.args
      expect(gradeInfo.grade).toBe('A')
    })

    describe('when a point value is entered', () => {
      let gradeInfo

      beforeEach(() => {
        renderComponent()
        const input = document.querySelector('input')
        fireEvent.change(input, { target: { value: '8.9' } })
        fireEvent.blur(input)
        gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
      })

      it('calls the onSubmissionUpdate prop with the scheme key form of the entered grade', () => {
        expect(gradeInfo.grade).toBe('B')
      })

      it('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        expect(gradeInfo.score).toBe(8.9)
      })

      it('calls the onSubmissionUpdate prop with the enteredAs set to "points"', () => {
        expect(gradeInfo.enteredAs).toBe('points')
      })
    })

    describe('when a percent value is entered', () => {
      let gradeInfo

      beforeEach(() => {
        renderComponent()
        const input = document.querySelector('input')
        fireEvent.change(input, { target: { value: '89.1%' } })
        fireEvent.blur(input)
        gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
      })

      it('calls the onSubmissionUpdate prop with the scheme key form of the entered grade', () => {
        expect(gradeInfo.grade).toBe('B')
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

      beforeEach(() => {
        renderComponent()
        const input = document.querySelector('input')
        fireEvent.change(input, { target: { value: 'B' } })
        fireEvent.blur(input)
        gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
      })

      it('calls the onSubmissionUpdate prop with the scheme key form of the entered grade', () => {
        expect(gradeInfo.grade).toBe('B')
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

      beforeEach(() => {
        renderComponent()
        const input = document.querySelector('input')
        fireEvent.change(input, { target: { value: 'EX' } })
        fireEvent.blur(input)
        gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
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

      beforeEach(() => {
        renderComponent()
        const input = document.querySelector('input')
        fireEvent.change(input, { target: { value: 'unknown' } })
        fireEvent.blur(input)
        gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
      })

      it('calls the onSubmissionUpdate prop with the grade set to the given value', () => {
        expect(gradeInfo.grade).toBe('unknown')
      })
      it('calls the onSubmissionUpdate prop with a null score form', () => {
        expect(gradeInfo.score).toBe(null)
      })
    })
  })

  describe('when the input blurs without having received a new value', () => {
    beforeEach(() => {
      renderComponent()
      const input = document.querySelector('input')
      fireEvent.change(input, { target: { value: 'A' } })
      fireEvent.change(input, { target: { value: 'C' } })
      fireEvent.blur(input)
    })
    it('does not call the onSubmissionUpdate prop', () => {
      expect(props.onSubmissionUpdate.callCount).toBe(0)
    })
  })

  describe('when the submission grade is updating', () => {
    beforeEach(() => {
      props.submission = { ...props.submission, enteredGrade: null, enteredScore: null }
      props.submissionUpdating = true
      props.pendingGradeInfo = { grade: 'A', score: 9.8, valid: true, excused: false }
    })

    it('updates the text input with the value of the pending grade', () => {
      const { getAllByDisplayValue } = renderComponent()
      const inputs = getAllByDisplayValue('A')
      expect(inputs.length).toBeGreaterThan(0)
    })

    it('sets the text input to "Excused" when the submission is being excused', () => {
      props.pendingGradeInfo = { grade: null, valid: false, excused: true }
      const { getByDisplayValue } = renderComponent()
      expect(getByDisplayValue('Excused')).toBeInTheDocument()
    })

    it('sets the input to "read only"', () => {
      const { getAllByDisplayValue } = renderComponent()
      const inputs = getAllByDisplayValue('A')
      inputs.forEach(input => {
        expect(input).toHaveAttribute('readOnly')
      })
    })

    describe('when the submission grade finishes updating', () => {
      beforeEach(() => {
        renderComponent()
        props.submission = { ...props.submission, enteredGrade: 'A', enteredScore: 9.8 }
        props.submissionUpdating = false
        renderComponent()
      })

      it('updates the input value with the updated grade', () => {
        const { getAllByDisplayValue } = renderComponent()
        const inputs = getAllByDisplayValue('A')
        expect(inputs.length).toBeGreaterThan(0)
      })

      it('enables the input', () => {
        const { getAllByDisplayValue } = renderComponent()
        const inputs = getAllByDisplayValue('A')
        inputs.forEach(input => {
          expect(input).not.toBeDisabled()
        })
      })
    })
  })

  describe('when the submission is otherwise being updated', () => {
    it('does not update the input value when the submission begins updating', () => {
      renderComponent()
      props.submission = { ...props.submission, enteredGrade: 'A', enteredScore: 9.8 }
      props.submissionUpdating = true
      const { queryByDisplayValue } = renderComponent()
      expect(queryByDisplayValue('C')).toBeInTheDocument()
    })
    it('updates the input value when the submission finishes updating', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = { ...props.submission, enteredGrade: 'A', enteredScore: 9.8 }
      props.submissionUpdating = false
      const { queryByDisplayValue } = renderComponent()
      expect(queryByDisplayValue('A')).toBeInTheDocument()
    })
  })
})
