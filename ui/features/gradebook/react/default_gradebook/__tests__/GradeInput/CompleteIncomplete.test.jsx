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
import {render} from '@testing-library/react'
import GradeInput from '../../components/GradeInput'
import GradeInputDriver from './GradeInputDriver'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Gradebook > Default Gradebook > Components > GradeInput', () => {
  let $container
  let component
  let gradeInput
  let props

  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'pass_fail',
      pointsPossible: 10,
    }

    const submission = {
      enteredGrade: null,
      enteredScore: 0,
      excused: false,
      id: '2501',
    }

    props = {
      assignment,
      disabled: false,
      enterGradesAs: 'passFail',
      onSubmissionUpdate: jest.fn(),
      pendingGradeInfo: null,
      submission,
    }

    $container = document.body.appendChild(document.createElement('div'))

    component = null
    gradeInput = null
  })

  afterEach(() => {
    if (component) {
      component.unmount()
    }
    $container.remove()
    fakeENV.teardown()
  })

  function renderComponent() {
    if (component == null) {
      component = render(<GradeInput {...props} />, {container: $container})
      gradeInput = GradeInputDriver.find($container)
    } else {
      component.rerender(<GradeInput {...props} />)
    }
  }

  describe('when entering Complete/Incomplete grades', () => {
    test('displays a label of "Grade"', () => {
      renderComponent()
      // checks if the label text is "Grade"
      expect(gradeInput.labelText).toBe('Grade')
    })

    test('includes "Ungraded," "Complete," and "Incomplete" as options text', () => {
      renderComponent()
      gradeInput.clickToExpand()
      // verifies the option labels
      expect(gradeInput.optionLabels).toEqual(['Ungraded', 'Complete', 'Incomplete'])
    })

    describe('when the submission is not graded', () => {
      test('sets the select value to "Ungraded"', () => {
        props.submission.enteredGrade = null
        renderComponent()
        // checks if the value is "Ungraded"
        expect(gradeInput.value).toBe('Ungraded')
      })

      test('sets the active option to "Ungraded"', () => {
        props.submission.enteredGrade = null
        renderComponent()
        gradeInput.clickToExpand()
        // verifies the active item label
        expect(gradeInput.activeItemLabel).toBe('Ungraded')
      })
    })

    describe('when the submission is complete', () => {
      test('sets the select value to "Complete"', () => {
        props.submission.enteredScore = 10
        props.submission.enteredGrade = 'complete'
        renderComponent()
        // checks if the value is "Complete"
        expect(gradeInput.value).toBe('Complete')
      })

      test('sets the active option to "Complete"', () => {
        props.submission.enteredScore = 10
        props.submission.enteredGrade = 'complete'
        renderComponent()
        gradeInput.clickToExpand()
        // verifies the active item label
        expect(gradeInput.activeItemLabel).toBe('Complete')
      })
    })

    describe('when the submission is incomplete', () => {
      test('sets the select value to "Incomplete"', () => {
        props.submission.enteredGrade = 'incomplete'
        renderComponent()
        // checks if the value is "Incomplete"
        expect(gradeInput.value).toBe('Incomplete')
      })

      test('sets the active option to "Incomplete"', () => {
        props.submission.enteredGrade = 'incomplete'
        renderComponent()
        gradeInput.clickToExpand()
        // verifies the active item label
        expect(gradeInput.activeItemLabel).toBe('Incomplete')
      })
    })

    describe('when the submission is excused', () => {
      test('sets the input value to "Excused"', () => {
        props.submission.excused = true
        renderComponent()
        // checks if the value is "Excused"
        expect(gradeInput.value).toBe('Excused')
      })

      test('sets the input to "read only"', () => {
        props.submission.excused = true
        renderComponent()
        // verifies if the input is read-only
        expect(gradeInput.isReadOnly).toBe(true)
      })
    })

    test('is blank the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      // checks if the value is blank
      expect(gradeInput.value).toBe('')
    })

    test('disables the input when disabled is true', () => {
      props.disabled = true
      renderComponent()
      // verifies if the input is disabled
      expect(gradeInput.inputIsDisabled).toBe(true)
    })

    describe('when "Complete" is selected', () => {
      beforeEach(() => {
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.clickToSelectOption('Complete')
      })

      test('collapses the options list', () => {
        // checks if the options list is collapsed
        expect(gradeInput.isExpanded).toBe(false)
      })

      test('sets the input value to "Complete"', () => {
        // verifies the input value
        expect(gradeInput.value).toBe('Complete')
      })

      test('calls the onSubmissionUpdate prop', () => {
        expect(props.onSubmissionUpdate).toHaveBeenCalledTimes(1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        const [updatedSubmission] = props.onSubmissionUpdate.mock.calls[0]
        expect(updatedSubmission).toBe(props.submission)
      })

      test('calls the onSubmissionUpdate prop with the grade form of the selected grade', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.grade).toBe('complete')
      })

      test('calls the onSubmissionUpdate prop with the score form of the selected grade', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.score).toBe(10)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "passFail"', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.enteredAs).toBe('passFail')
      })
    })

    describe('when "Incomplete" is selected', () => {
      beforeEach(() => {
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.clickToSelectOption('Incomplete')
      })

      test('collapses the options list', () => {
        // checks if the options list is collapsed
        expect(gradeInput.isExpanded).toBe(false)
      })

      test('sets the input value to "Incomplete"', () => {
        // verifies the input value
        expect(gradeInput.value).toBe('Incomplete')
      })

      test('calls the onSubmissionUpdate prop', () => {
        expect(props.onSubmissionUpdate).toHaveBeenCalledTimes(1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        const [updatedSubmission] = props.onSubmissionUpdate.mock.calls[0]
        expect(updatedSubmission).toBe(props.submission)
      })

      test('calls the onSubmissionUpdate prop with the entered grade', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.grade).toBe('incomplete')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.score).toBe(0)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "passFail"', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.enteredAs).toBe('passFail')
      })
    })

    describe('when the current grade is cleared', () => {
      beforeEach(() => {
        props.submission.enteredGrade = 'incomplete'
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.clickToSelectOption('Ungraded')
      })

      test('collapses the options list', () => {
        // checks if the options list is collapsed
        expect(gradeInput.isExpanded).toBe(false)
      })

      test('sets the input value to "Ungraded"', () => {
        // verifies the input value
        expect(gradeInput.value).toBe('Ungraded')
      })

      test('calls the onSubmissionUpdate prop', () => {
        expect(props.onSubmissionUpdate).toHaveBeenCalledTimes(1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        const [updatedSubmission] = props.onSubmissionUpdate.mock.calls[0]
        expect(updatedSubmission).toBe(props.submission)
      })

      test('calls the onSubmissionUpdate prop with a null grade form', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.grade).toBeNull()
      })

      test('calls the onSubmissionUpdate prop with a null score form', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.score).toBeNull()
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to null', () => {
        const gradingData = props.onSubmissionUpdate.mock.calls[0][1]
        expect(gradingData.enteredAs).toBeNull()
      })
    })

    describe('when the submission grade is updating', () => {
      beforeEach(() => {
        props.submissionUpdating = true
        props.pendingGradeInfo = {grade: 'complete', valid: true, excused: false}
      })

      test('updates the text input with the value of the pending grade', () => {
        renderComponent()
        // checks if the value matches the pending grade
        expect(gradeInput.value).toBe('Complete')
      })

      test('sets the text input to "Excused" when the submission is being excused', () => {
        props.pendingGradeInfo = {grade: null, valid: false, excused: true}
        renderComponent()
        // verifies the input value is "Excused"
        expect(gradeInput.value).toBe('Excused')
      })

      test('disables the other select options', () => {
        renderComponent()
        gradeInput.clickToExpand()
        // checks if the select options are disabled
        expect(gradeInput.optionsAreDisabled).toBe(true)
      })

      describe('when the submission grade finishes updating', () => {
        beforeEach(() => {
          renderComponent()
          props.submission = {...props.submission, enteredGrade: 'complete'}
          props.submissionUpdating = false
          renderComponent()
        })

        test('updates the input value with the updated grade', () => {
          // verifies the updated grade
          expect(gradeInput.value).toBe('Complete')
        })

        test('enables the select options', () => {
          gradeInput.clickToExpand()
          // checks if the select options are enabled
          expect(gradeInput.optionsAreDisabled).toBe(false)
        })
      })
    })

    describe('when the submission is otherwise being updated', () => {
      test('does not update the input value when the submission begins updating', () => {
        renderComponent()
        props.submission = {...props.submission, enteredGrade: 'complete'}
        props.submissionUpdating = true
        renderComponent()
        // checks if the value remains "Ungraded"
        expect(gradeInput.value).toBe('Ungraded')
      })

      test('updates the input value when the submission finishes updating', () => {
        props.submissionUpdating = true
        renderComponent()
        props.submission = {...props.submission, enteredGrade: 'complete'}
        props.submissionUpdating = false
        renderComponent()
        // verifies the input value is updated to "Complete"
        expect(gradeInput.value).toBe('Complete')
      })
    })

    describe('when handling down arrow', () => {
      test('activates the option after the current active option', () => {
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.keyDown(40) // Arrow Down key code
        // checks if the active item label is "Complete"
        expect(gradeInput.activeItemLabel).toBe('Complete')
      })
    })

    describe('when handling up arrow', () => {
      test('activates the option previous to the current active option', () => {
        props.submission = {...props.submission, enteredGrade: 'complete'}
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.keyDown(38) // Arrow Up key code
        // verifies the active item label is "Ungraded"
        expect(gradeInput.activeItemLabel).toBe('Ungraded')
      })
    })
  })
})
