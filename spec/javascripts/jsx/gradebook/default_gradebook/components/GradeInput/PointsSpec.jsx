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
      gradingType: 'points',
      pointsPossible: 10,
    }

    const submission = {
      enteredGrade: '7.8',
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
      enterGradesAs: 'points',
      gradingScheme,
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

  QUnit.module('when entering grades as points', () => {
    test('displays a label of "Grade out of <points possible>"', () => {
      renderComponent()
      equal(gradeInput.labelText, 'Grade out of 10')
    })

    test('sets the formatted entered score of the submission as the input value', () => {
      renderComponent()
      strictEqual(gradeInput.value, '7.8')
    })

    test('rounds the formatted entered score to two decimal places', () => {
      props.submission.enteredScore = 7.816
      renderComponent()
      strictEqual(gradeInput.value, '7.82')
    })

    test('strips insignificant zeros', () => {
      props.submission.enteredScore = 8.0
      renderComponent()
      strictEqual(gradeInput.value, '8')
    })

    test('is blank when the submission is not graded', () => {
      props.submission.enteredGrade = null
      props.submission.enteredScore = null
      renderComponent()
      strictEqual(gradeInput.value, '')
    })

    QUnit.module('when the submission is excused', () => {
      test('sets the input value to "Excused"', () => {
        props.submission.excused = true
        renderComponent()
        deepEqual(gradeInput.value, 'Excused')
      })

      test('disables the input', () => {
        props.submission.excused = true
        renderComponent()
        strictEqual(gradeInput.inputIsDisabled, true)
      })
    })

    test('is blank when the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      strictEqual(gradeInput.value, '')
    })

    test('disables the input when disabled is true', () => {
      props.disabled = true
      renderComponent()
      strictEqual(gradeInput.inputIsDisabled, true)
    })

    QUnit.module('when the input receives a new value', hooks => {
      hooks.beforeEach(() => {
        renderComponent()
        gradeInput.inputValue('9.8')
      })

      test('updates the input to the given value', () => {
        strictEqual(gradeInput.value, '9.8')
      })

      test('does not call the onSubmissionUpdate prop', () => {
        strictEqual(props.onSubmissionUpdate.callCount, 0)
      })
    })

    QUnit.module('when the input blurs after receiving a new value', () => {
      test('calls the onSubmissionUpdate prop', () => {
        renderComponent()
        gradeInput.inputValue('9.8')
        gradeInput.blurInput()
        strictEqual(props.onSubmissionUpdate.callCount, 1)
      })

      test('calls the onSubmissionUpdate prop with the submission', () => {
        renderComponent()
        gradeInput.inputValue('9.8')
        gradeInput.blurInput()
        const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
        strictEqual(updatedSubmission, props.submission)
      })

      test('calls the onSubmissionUpdate prop with the current grade info', () => {
        renderComponent()
        gradeInput.inputValue('9.8')
        gradeInput.blurInput()
        const [, gradeInfo] = props.onSubmissionUpdate.lastCall.args
        strictEqual(gradeInfo.score, 9.8)
      })

      QUnit.module('when a point value is entered', contextHooks => {
        let gradeInfo

        contextHooks.beforeEach(() => {
          renderComponent()
          gradeInput.inputValue('8.9')
          gradeInput.blurInput()
          gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
        })

        test('calls the onSubmissionUpdate prop with the entered grade', () => {
          strictEqual(gradeInfo.grade, '8.9')
        })

        test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
          strictEqual(gradeInfo.score, 8.9)
        })

        test('calls the onSubmissionUpdate prop with the enteredAs set to "points"', () => {
          strictEqual(gradeInfo.enteredAs, 'points')
        })
      })

      QUnit.module('when a percent value is entered', contextHooks => {
        let gradeInfo

        contextHooks.beforeEach(() => {
          renderComponent()
          gradeInput.inputValue('89%')
          gradeInput.blurInput()
          gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
        })

        test('calls the onSubmissionUpdate prop with the points form of the entered grade', () => {
          strictEqual(gradeInfo.grade, '8.9')
        })

        test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
          strictEqual(gradeInfo.score, 8.9)
        })

        test('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
          strictEqual(gradeInfo.enteredAs, 'percent')
        })
      })

      QUnit.module('when a grading scheme value is entered', contextHooks => {
        let gradeInfo

        contextHooks.beforeEach(() => {
          renderComponent()
          gradeInput.inputValue('B')
          gradeInput.blurInput()
          gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
        })

        test('calls the onSubmissionUpdate prop with the points form of the entered grade', () => {
          strictEqual(gradeInfo.grade, '8.9')
        })

        test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
          strictEqual(gradeInfo.score, 8.9)
        })

        test('calls the onSubmissionUpdate prop with the enteredAs set to "gradingScheme"', () => {
          strictEqual(gradeInfo.enteredAs, 'gradingScheme')
        })
      })

      QUnit.module('when an invalid grade value is entered', contextHooks => {
        let gradeInfo

        contextHooks.beforeEach(() => {
          renderComponent()
          gradeInput.inputValue('unknown')
          gradeInput.blurInput()
          gradeInfo = props.onSubmissionUpdate.lastCall.args[1]
        })

        test('calls the onSubmissionUpdate prop with the points form set to the given value', () => {
          strictEqual(gradeInfo.grade, 'unknown')
        })

        test('calls the onSubmissionUpdate prop with a null score form', () => {
          strictEqual(gradeInfo.score, null)
        })

        test('calls the onSubmissionUpdate prop with enteredAs set to null', () => {
          strictEqual(gradeInfo.enteredAs, null)
        })

        test('calls the onSubmissionUpdate prop with valid set to false', () => {
          strictEqual(gradeInfo.valid, false)
        })
      })
    })

    QUnit.module('when the input blurs without having received a new value', hooks => {
      hooks.beforeEach(() => {
        renderComponent()
        gradeInput.inputValue('9.8') // change the input value
        gradeInput.inputValue('7.8') // revert to the initial value
        gradeInput.blurInput()
      })

      test('does not call the onSubmissionUpdate prop', () => {
        strictEqual(props.onSubmissionUpdate.callCount, 0)
      })
    })

    QUnit.module('when the submission grade is updating', hooks => {
      hooks.beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: null, enteredScore: null}
        props.submissionUpdating = true
        props.pendingGradeInfo = {grade: '9.8', valid: true, excused: false}
      })

      test('updates the text input with the value of the pending grade', () => {
        renderComponent()
        strictEqual(gradeInput.value, '9.8')
      })

      test('sets the text input to "Excused" when the submission is being excused', () => {
        props.pendingGradeInfo = {grade: null, valid: false, excused: true}
        renderComponent()
        equal(gradeInput.value, 'Excused')
      })

      test('sets the input to "read only"', () => {
        renderComponent()
        strictEqual(gradeInput.isReadOnly, true)
      })

      QUnit.module('when the submission grade finishes updating', moreHooks => {
        moreHooks.beforeEach(() => {
          renderComponent()
          props.submission = {...props.submission, enteredGrade: '9.8'}
          props.submissionUpdating = false
          renderComponent()
        })

        test('updates the input value with the updated grade', () => {
          strictEqual(gradeInput.value, '9.8')
        })

        test('enables the input', () => {
          strictEqual(gradeInput.isReadOnly, false)
        })
      })
    })

    QUnit.module('when the submission is otherwise being updated', () => {
      test('does not update the input value when the submission begins updating', () => {
        renderComponent()
        props.submission = {...props.submission, enteredGrade: '9.8'}
        props.submissionUpdating = true
        renderComponent()
        strictEqual(gradeInput.value, '7.8')
      })

      test('updates the input value when the submission finishes updating', () => {
        props.submissionUpdating = true
        renderComponent()
        props.submission = {...props.submission, enteredGrade: '9.8', enteredScore: 9.8}
        props.submissionUpdating = false
        renderComponent()
        strictEqual(gradeInput.value, '9.8')
      })
    })
  })
})
