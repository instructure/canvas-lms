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

import GradeInput from 'ui/features/gradebook/react/default_gradebook/components/GradeInput'
import GradeInputDriver from './GradeInputDriver'
import fakeENV from 'helpers/fakeENV'

QUnit.module('Gradebook > Default Gradebook > Components > GradeInput', suiteHooks => {
  let $container
  let component
  let gradeInput
  let props

  suiteHooks.beforeEach(() => {
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
      onSubmissionUpdate: sinon.stub(),
      pendingGradeInfo: null,
      submission,
    }

    $container = document.body.appendChild(document.createElement('div'))

    component = null
    gradeInput = null
  })

  suiteHooks.afterEach(() => {
    component.unmount()
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

  QUnit.module('when entering Complete/Incomplete grades', () => {
    test('displays a label of "Grade"', () => {
      renderComponent()
      equal(gradeInput.labelText, 'Grade')
    })

    test('includes "Ungraded," "Complete," and "Incomplete" as options text', () => {
      renderComponent()
      gradeInput.clickToExpand()
      deepEqual(gradeInput.optionLabels, ['Ungraded', 'Complete', 'Incomplete'])
    })

    QUnit.module('when the submission is not graded', () => {
      test('sets the select value to "Ungraded"', () => {
        props.submission.enteredGrade = null
        renderComponent()
        equal(gradeInput.value, 'Ungraded')
      })

      test('sets the active option to "Ungraded"', () => {
        props.submission.enteredGrade = null
        renderComponent()
        gradeInput.clickToExpand()
        equal(gradeInput.activeItemLabel, 'Ungraded')
      })
    })

    QUnit.module('when the submission is complete', () => {
      test('sets the select value to "Complete"', () => {
        props.submission.enteredScore = 10
        props.submission.enteredGrade = 'complete'
        renderComponent()
        equal(gradeInput.value, 'Complete')
      })

      test('sets the active option to "Complete"', () => {
        props.submission.enteredScore = 10
        props.submission.enteredGrade = 'complete'
        renderComponent()
        gradeInput.clickToExpand()
        equal(gradeInput.activeItemLabel, 'Complete')
      })
    })

    QUnit.module('when the submission is incomplete', () => {
      test('sets the select value to "Incomplete"', () => {
        props.submission.enteredGrade = 'incomplete'
        renderComponent()
        equal(gradeInput.value, 'Incomplete')
      })

      test('sets the active option to "Incomplete"', () => {
        props.submission.enteredGrade = 'incomplete'
        renderComponent()
        gradeInput.clickToExpand()
        equal(gradeInput.activeItemLabel, 'Incomplete')
      })
    })

    QUnit.module('when the submission is excused', () => {
      test('sets the input value to "Excused"', () => {
        props.submission.excused = true
        renderComponent()
        equal(gradeInput.value, 'Excused')
      })

      test('sets the input to "read only"', () => {
        props.submission.excused = true
        renderComponent()
        strictEqual(gradeInput.isReadOnly, true)
      })
    })

    test('is blank the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      strictEqual(gradeInput.value, '')
    })

    test('disables the input when disabled is true', () => {
      props.disabled = true
      renderComponent()
      strictEqual(gradeInput.inputIsDisabled, true)
    })

    QUnit.module('when "Complete" is selected', contextHooks => {
      contextHooks.beforeEach(() => {
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.clickToSelectOption('Complete')
      })

      test('collapses the options list', () => {
        strictEqual(gradeInput.isExpanded, false)
      })

      test('sets the input value to "Complete"', () => {
        equal(gradeInput.value, 'Complete')
      })

      test('calls the onSubmissionUpdate prop', () => {
        strictEqual(props.onSubmissionUpdate.callCount, 1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
        strictEqual(updatedSubmission, props.submission)
      })

      test('calls the onSubmissionUpdate prop with the grade form of the selected grade', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        equal(gradingData.grade, 'complete')
      })

      test('calls the onSubmissionUpdate prop with the score form of the selected grade', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        strictEqual(gradingData.score, 10)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "passFail"', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        equal(gradingData.enteredAs, 'passFail')
      })
    })

    QUnit.module('when "Incomplete" is selected', contextHooks => {
      contextHooks.beforeEach(() => {
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.clickToSelectOption('Incomplete')
      })

      test('collapses the options list', () => {
        strictEqual(gradeInput.isExpanded, false)
      })

      test('sets the input value to "Incomplete"', () => {
        equal(gradeInput.value, 'Incomplete')
      })

      test('calls the onSubmissionUpdate prop', () => {
        strictEqual(props.onSubmissionUpdate.callCount, 1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
        strictEqual(updatedSubmission, props.submission)
      })

      test('calls the onSubmissionUpdate prop with the entered grade', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        equal(gradingData.grade, 'incomplete')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        strictEqual(gradingData.score, 0)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "passFail"', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        equal(gradingData.enteredAs, 'passFail')
      })
    })

    QUnit.module('when the current grade is cleared', contextHooks => {
      contextHooks.beforeEach(() => {
        props.submission.enteredGrade = 'incomplete'
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.clickToSelectOption('Ungraded')
      })

      test('collapses the options list', () => {
        strictEqual(gradeInput.isExpanded, false)
      })

      test('sets the input value to "Ungraded"', () => {
        equal(gradeInput.value, 'Ungraded')
      })

      test('calls the onSubmissionUpdate prop', () => {
        strictEqual(props.onSubmissionUpdate.callCount, 1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
        strictEqual(updatedSubmission, props.submission)
      })

      test('calls the onSubmissionUpdate prop with a null grade form', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        strictEqual(gradingData.grade, null)
      })

      test('calls the onSubmissionUpdate prop with a null score form', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        strictEqual(gradingData.score, null)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to null', () => {
        const gradingData = props.onSubmissionUpdate.lastCall.args[1]
        strictEqual(gradingData.enteredAs, null)
      })
    })

    QUnit.module('when the submission grade is updating', contextHooks => {
      contextHooks.beforeEach(() => {
        props.submissionUpdating = true
        props.pendingGradeInfo = {grade: 'complete', valid: true, excused: false}
      })

      test('updates the text input with the value of the pending grade', () => {
        renderComponent()
        equal(gradeInput.value, 'Complete')
      })

      test('sets the text input to "Excused" when the submission is being excused', () => {
        props.pendingGradeInfo = {grade: null, valid: false, excused: true}
        renderComponent()
        equal(gradeInput.value, 'Excused')
      })

      test('disables the other select options', () => {
        renderComponent()
        gradeInput.clickToExpand()
        strictEqual(gradeInput.optionsAreDisabled, true)
      })

      QUnit.module('when the submission grade finishes updating', moreHooks => {
        moreHooks.beforeEach(() => {
          renderComponent()
          props.submission = {...props.submission, enteredGrade: 'complete'}
          props.submissionUpdating = false
          renderComponent()
        })

        test('updates the input value with the updated grade', () => {
          equal(gradeInput.value, 'Complete')
        })

        test('enables the select options', () => {
          gradeInput.clickToExpand()
          strictEqual(gradeInput.optionsAreDisabled, false)
        })
      })
    })

    QUnit.module('when the submission is otherwise being updated', () => {
      test('does not update the input value when the submission begins updating', () => {
        renderComponent()
        props.submission = {...props.submission, enteredGrade: 'complete'}
        props.submissionUpdating = true
        renderComponent()
        equal(gradeInput.value, 'Ungraded')
      })

      test('updates the input value when the submission finishes updating', () => {
        props.submissionUpdating = true
        renderComponent()
        props.submission = {...props.submission, enteredGrade: 'complete'}
        props.submissionUpdating = false
        renderComponent()
        equal(gradeInput.value, 'Complete')
      })
    })

    QUnit.module('when handling down arrow', () => {
      test('activates the option after the current active option', () => {
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.keyDown(40)
        equal(gradeInput.activeItemLabel, 'Complete')
      })
    })

    QUnit.module('when handling up arrow', () => {
      test('activates the option previous to the current active option', () => {
        props.submission = {...props.submission, enteredGrade: 'complete'}
        renderComponent()
        gradeInput.clickToExpand()
        gradeInput.keyDown(38)
        equal(gradeInput.activeItemLabel, 'Ungraded')
      })
    })
  })
})
