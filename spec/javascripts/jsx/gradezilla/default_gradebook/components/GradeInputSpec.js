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
import {fireEvent, render} from '@testing-library/react'

import GradeInput from 'jsx/gradezilla/default_gradebook/components/GradeInput'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradeInput', suiteHooks => {
  let $container
  let component
  let props

  suiteHooks.beforeEach(() => {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points'
    }
    const submission = {
      excused: false,
      id: '2501'
    }
    const gradingScheme = [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0]]

    props = {
      assignment,
      disabled: false,
      onSubmissionUpdate: sinon.stub(),
      submission,
      gradingScheme,
      pendingGradeInfo: null
    }

    $container = document.body.appendChild(document.createElement('div'))
    component = null
  })

  suiteHooks.afterEach(() => {
    component.unmount()
    $container.remove()
  })

  function renderComponent() {
    if (component == null) {
      component = render(<GradeInput {...props} />, {container: $container})
    } else {
      component.rerender(<GradeInput {...props} />)
    }
  }

  function getTextInput() {
    return $container.querySelector('input[type="text"]')
  }

  function getLabelText() {
    return $container.querySelector('label').textContent.trim()
  }

  function getInputValue() {
    return getTextInput().value
  }

  function getSelectInput() {
    return $container.querySelector('select')
  }

  function getSelectValue() {
    return getSelectInput().value
  }

  function getSelectOptions() {
    return [...getSelectInput().querySelectorAll('option')]
  }

  function getSelectOptionTexts() {
    return getSelectOptions().map($option => $option.textContent.trim())
  }

  function getMessages() {
    const describedById = (getTextInput() || getSelectInput()).getAttribute('aria-describedby')
    const $messageContainer = $container.querySelector(`#${describedById}`)
    return $messageContainer ? [...$messageContainer.children] : []
  }

  function getMessageTexts() {
    return getMessages().map($message => $message.textContent.trim())
  }

  function isDisabled() {
    return (getTextInput() || getSelectInput()).disabled
  }

  function isInvalid() {
    return (getTextInput() || getSelectInput()).getAttribute('aria-invalid') === 'true'
  }

  function inputTextValue(value) {
    fireEvent.input(getTextInput(), {target: {value}})
  }

  function changeSelectValue(value) {
    fireEvent.change(getSelectInput(), {target: {value}})
  }

  function blurInput() {
    fireEvent.blur(getTextInput())
  }

  QUnit.module('when .enterGradesAs is "points"', hooks => {
    hooks.beforeEach(() => {
      props.assignment.pointsPossible = 10
      props.enterGradesAs = 'points'
      props.submission.enteredGrade = '7.8'
      props.submission.enteredScore = 7.8
    })

    test('renders a text input', () => {
      renderComponent()
      ok(getTextInput())
    })

    test('displays a label of "Grade out of <points possible>"', () => {
      renderComponent()
      equal(getLabelText(), 'Grade out of 10')
    })

    test('sets the formatted entered score of the submission as the input value', () => {
      renderComponent()
      strictEqual(getInputValue(), '7.8')
    })

    test('rounds the formatted entered score to two decimal places', () => {
      props.submission.enteredScore = 7.816
      renderComponent()
      strictEqual(getInputValue(), '7.82')
    })

    test('strips insignificant zeros', () => {
      props.submission.enteredScore = 8.0
      renderComponent()
      strictEqual(getInputValue(), '8')
    })

    test('is blank when the submission is not graded', () => {
      props.submission.enteredScore = null
      renderComponent()
      strictEqual(getInputValue(), '–')
    })

    test('is blank when the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      strictEqual(getInputValue(), '–')
    })

    test('displays "Excused" as the input value when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(getInputValue(), 'Excused')
    })

    test('disables the input when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('disables the input when submissionUpdating is true', () => {
      props.submissionUpdating = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('enables the input when submissionUpdating is false', () => {
      renderComponent()
      strictEqual(isDisabled(), false)
    })

    test('calls the onSubmissionUpdate prop when the value has changed and the input loses focus', () => {
      renderComponent()
      inputTextValue('8.9')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 1)
    })

    test('calls the onSubmissionUpdate prop with the submission', () => {
      renderComponent()
      inputTextValue('8.9')
      blurInput()
      const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
      strictEqual(updatedSubmission, props.submission)
    })

    QUnit.module('when a point value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('8.9')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the entered grade', () => {
        strictEqual(gradingData.grade, '8.9')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "points"', () => {
        strictEqual(gradingData.enteredAs, 'points')
      })
    })

    QUnit.module('when a percent value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('89%')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the points form of the entered grade', () => {
        strictEqual(gradingData.grade, '8.9')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
        strictEqual(gradingData.enteredAs, 'percent')
      })
    })

    QUnit.module('when a grading scheme value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('B')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the points form of the entered grade', () => {
        strictEqual(gradingData.grade, '8.9')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "gradingScheme"', () => {
        strictEqual(gradingData.enteredAs, 'gradingScheme')
      })
    })

    test('does not call the onSubmissionUpdate prop when the value has changed and input maintains focus', () => {
      renderComponent()
      inputTextValue('8.9')
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('does not call the onSubmissionUpdate prop when the value has not changed from initial value', () => {
      renderComponent()
      inputTextValue('8.9')
      inputTextValue('7.8')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('calls the onSubmissionUpdate prop when an invalid grade is changed back to the saved score', () => {
      props.pendingGradeInfo = {grade: 'invalid', valid: false, excused: false}
      renderComponent()
      inputTextValue('7.8')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 1)
    })

    test('does not call the onSubmissionUpdate prop when a pending grade is present', () => {
      props.pendingGradeInfo = {grade: '10', valid: true, excused: false}
      renderComponent()
      inputTextValue('7.8')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('does not call the onSubmissionUpdate prop when the value has not changed from a null value', () => {
      props.submission.enteredGrade = null
      renderComponent()
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('displays "Excused" as the input value when input blurs with a value of "EX"', () => {
      renderComponent()
      inputTextValue('EX')
      blurInput()
      strictEqual(getInputValue(), 'Excused')
    })

    test('trims whitespace from the input value when blurring', () => {
      renderComponent()
      inputTextValue(' EX ')
      blurInput()
      strictEqual(getInputValue(), 'Excused')
    })

    test('does not update the input value when the submission begins updating', () => {
      renderComponent()
      props.submission.enteredGrade = '8.9'
      props.submissionUpdating = true
      renderComponent()
      strictEqual(getInputValue(), '7.8')
    })

    test('updates the input value when the submission is replaced', () => {
      renderComponent()
      props.submission = {excused: false, enteredScore: 8.9, enteredGrade: '8.9', id: '2502'}
      props.submissionUpdating = true
      renderComponent()
      strictEqual(getInputValue(), '8.9')
    })

    test('updates the input value when the submission has updated', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 8.9, enteredGrade: '8.9'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '8.9')
    })

    test('rounds the formatted entered score of the updated submission to two decimal places', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 7.816, enteredGrade: '7.816'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '7.82')
    })

    test('strips insignificant zeros on the updated grade', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 8.0, enteredGrade: '8.00'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '8')
    })

    test('is blank when the updated submission is not graded', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission.enteredGrade = null
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '')
    })

    test('does not call the onSubmissionUpdate prop a submission update and the input has not changed', () => {
      // this prevents the input from calling onSubmissionUpdate when
      // its value was already updated after a successful change
      props.submissionUpdating = true
      renderComponent()
      inputTextValue('8.9')
      props.submission = {...props.submission, enteredScore: 8.9, enteredGrade: '8.9'}
      props.submissionUpdating = false
      renderComponent()
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('ignores onSubmissionUpdate when not defined', () => {
      delete props.onSubmissionUpdate
      renderComponent()
      inputTextValue('8.9')
      blurInput()
      ok(true, 'missing onSubmissionUpdate prop is ignored')
    })

    test('does not update the input when props update without changing the entered score on the submission', () => {
      renderComponent()
      inputTextValue('8.9')
      props.submission = {...props.submission}
      renderComponent()
      strictEqual(getInputValue(), '8.9')
    })
  })

  QUnit.module('when enterGradesAs is "percent"', hooks => {
    hooks.beforeEach(() => {
      props.assignment.pointsPossible = 10
      props.enterGradesAs = 'percent'
      props.submission.enteredGrade = '78%'
      props.submission.enteredScore = 7.8
    })

    test('renders a text input', () => {
      renderComponent()
      ok(getTextInput())
    })

    test('displays a label of "Grade out of 100%"', () => {
      renderComponent()
      equal(getLabelText(), 'Grade out of 100%')
    })

    test('sets the formatted entered score of the submission as the input value', () => {
      renderComponent()
      strictEqual(getInputValue(), '78%')
    })

    test('rounds the formatted entered score to two decimal places', () => {
      props.submission.enteredScore = 7.8916
      renderComponent()
      strictEqual(getInputValue(), '78.92%')
    })

    test('strips insignificant zeros', () => {
      props.submission.enteredScore = 8
      renderComponent()
      strictEqual(getInputValue(), '80%')
    })

    test('is blank when the submission is not graded', () => {
      props.submission.enteredGrade = null
      renderComponent()
      strictEqual(getInputValue(), '')
    })

    test('displays "Excused" as the input value when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(getInputValue(), 'Excused')
    })

    test('is blank when the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      strictEqual(getInputValue(), '–')
    })

    test('disables the input when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('disables the input when disabled is true', () => {
      props.disabled = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('disables the input when submissionUpdating is true', () => {
      props.submissionUpdating = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('enables the input when submissionUpdating is false', () => {
      renderComponent()
      strictEqual(isDisabled(), false)
    })

    test('calls the onSubmissionUpdate prop when the value has changed and the input loses focus', () => {
      renderComponent()
      inputTextValue('89%')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 1)
    })

    test('calls the onSubmissionUpdate prop with the submission', () => {
      renderComponent()
      inputTextValue('89%')
      blurInput()
      const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
      strictEqual(updatedSubmission, props.submission)
    })

    QUnit.module('when a point value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('8.9')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the percent form of the entered grade', () => {
        strictEqual(gradingData.grade, '8.9%')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 0.89)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
        strictEqual(gradingData.enteredAs, 'percent')
      })
    })

    QUnit.module('when a percent value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('89%')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the entered grade', () => {
        strictEqual(gradingData.grade, '89%')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
        strictEqual(gradingData.enteredAs, 'percent')
      })
    })

    QUnit.module('when a grading scheme value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('B')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the percent form of the entered grade', () => {
        strictEqual(gradingData.grade, '89%')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "gradingScheme"', () => {
        strictEqual(gradingData.enteredAs, 'gradingScheme')
      })
    })

    test('does not call the onSubmissionUpdate prop when the value has changed and input maintains focus', () => {
      renderComponent()
      inputTextValue('89%')
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('does not call the onSubmissionUpdate prop when the value has not changed from initial value', () => {
      renderComponent()
      inputTextValue('89%')
      inputTextValue('78%')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('displays "Excused" as the input value when input blurs with a value of "EX"', () => {
      renderComponent()
      inputTextValue('EX')
      blurInput()
      strictEqual(getInputValue(), 'Excused')
    })

    test('does not update the input value when the submission begins updating', () => {
      renderComponent()
      props.submission.enteredGrade = '89%'
      props.submissionUpdating = true
      renderComponent()
      strictEqual(getInputValue(), '78%')
    })

    test('updates the input value when the submission has updated', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 8.9, enteredGrade: '89%'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '89%')
    })

    test('rounds the formatted entered score of the updated submission to two decimal places', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 7.8916, enteredGrade: '78.916%'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '78.92%')
    })

    test('strips insignificant zeros on the updated grade', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 8.9, enteredGrade: '89.00%'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '89%')
    })

    test('is blank when the updated submission is not graded', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission.enteredGrade = null
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '')
    })

    test('does not call the onSubmissionUpdate prop a submission update and the input has not changed', () => {
      // this prevents the input from calling onSubmissionUpdate when
      // its value was already updated after a successful change
      props.submissionUpdating = true
      renderComponent()
      inputTextValue('89%')
      props.submission = {...props.submission, enteredScore: 8.9, enteredGrade: '89%'}
      props.submissionUpdating = false
      renderComponent()
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('ignores onSubmissionUpdate when not defined', () => {
      delete props.onSubmissionUpdate
      renderComponent()
      inputTextValue('89%')
      blurInput()
      ok(true, 'missing onSubmissionUpdate prop is ignored')
    })

    test('does not update the input when props update without changing the entered score on the submission', () => {
      renderComponent()
      inputTextValue('89%')
      props.submission = {...props.submission}
      renderComponent()
      strictEqual(getInputValue(), '89%')
    })
  })

  QUnit.module('when enterGradesAs is "gradingScheme"', hooks => {
    hooks.beforeEach(() => {
      props.assignment.gradingType = 'letter_grade'
      props.assignment.pointsPossible = 10
      props.enterGradesAs = 'gradingScheme'
      props.submission.enteredGrade = 'C'
      props.submission.enteredScore = 7.8
    })

    test('renders a text input', () => {
      renderComponent()
      ok(getTextInput())
    })

    test('displays a label of "Letter Grade"', () => {
      renderComponent()
      equal(getLabelText(), 'Letter Grade')
    })

    test('sets as the input value the grade corresponding to the entered score', () => {
      renderComponent()
      equal(getInputValue(), 'C')
    })

    test('is blank when the submission is not graded', () => {
      props.submission.enteredGrade = null
      renderComponent()
      strictEqual(getInputValue(), '')
    })

    test('displays "Excused" as the input value when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(getInputValue(), 'Excused')
    })

    test('is blank when the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      strictEqual(getInputValue(), '–')
    })

    test('disables the input when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('disables the input when disabled is true', () => {
      props.disabled = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('disables the input when submissionUpdating is true', () => {
      props.submissionUpdating = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('enables the input when submissionUpdating is false', () => {
      renderComponent()
      strictEqual(isDisabled(), false)
    })

    test('calls the onSubmissionUpdate prop when the value has changed and the input loses focus', () => {
      renderComponent()
      inputTextValue('A')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 1)
    })

    QUnit.module('when a point value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('8.9')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the grading scheme form of the entered grade', () => {
        strictEqual(gradingData.grade, 'B')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "points"', () => {
        strictEqual(gradingData.enteredAs, 'points')
      })
    })

    QUnit.module('when a percent value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('89%')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the grading scheme form of the entered grade', () => {
        strictEqual(gradingData.grade, 'B')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "percent"', () => {
        strictEqual(gradingData.enteredAs, 'percent')
      })
    })

    QUnit.module('when a grading scheme value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        inputTextValue('B')
        blurInput()
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the points form of the entered grade', () => {
        strictEqual(gradingData.grade, 'B')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 8.9)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "gradingScheme"', () => {
        strictEqual(gradingData.enteredAs, 'gradingScheme')
      })
    })

    test('calls the onSubmissionUpdate prop with the submission', () => {
      renderComponent()
      inputTextValue('A')
      blurInput()
      const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
      strictEqual(updatedSubmission, props.submission)
    })

    test('calls the onSubmissionUpdate prop with the entered grade', () => {
      renderComponent()
      inputTextValue('A')
      blurInput()
      const [, gradingData] = props.onSubmissionUpdate.lastCall.args
      strictEqual(gradingData.grade, 'A')
    })

    test('does not call the onSubmissionUpdate prop when the value has changed and input maintains focus', () => {
      renderComponent()
      inputTextValue('A')
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('does not call the onSubmissionUpdate prop when the value has not changed from initial value', () => {
      renderComponent()
      inputTextValue('A')
      inputTextValue('C')
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('displays "Excused" as the input value when input blurs with a value of "EX"', () => {
      renderComponent()
      inputTextValue('EX')
      blurInput()
      strictEqual(getInputValue(), 'Excused')
    })

    test('does not update the input value when the submission begins updating', () => {
      renderComponent()
      props.submission = {...props.submission, enteredScore: 10, enteredGrade: 'A'}
      props.submissionUpdating = true
      renderComponent()
      strictEqual(getInputValue(), 'C')
    })

    test('updates the input value when the submission has updated', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredScore: 10, enteredGrade: 'A'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), 'A')
    })

    test('is blank when the updated submission is not graded', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission.enteredGrade = null
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getInputValue(), '')
    })

    test('does not call the onSubmissionUpdate prop a submission update and the input has not changed', () => {
      // this prevents the input from calling onSubmissionUpdate when
      // its value was already updated after a successful change
      props.submissionUpdating = true
      renderComponent()
      inputTextValue('A')
      props.submission = {...props.submission, enteredGrade: 'A'}
      props.submissionUpdating = false
      renderComponent()
      blurInput()
      strictEqual(props.onSubmissionUpdate.callCount, 0)
    })

    test('ignores onSubmissionUpdate when not defined', () => {
      delete props.onSubmissionUpdate
      renderComponent()
      inputTextValue('A')
      blurInput()
      ok(true, 'missing onSubmissionUpdate prop is ignored')
    })

    test('does not update the input when props update without changing the entered score on the submission', () => {
      renderComponent()
      inputTextValue('A')
      props.submission = {...props.submission}
      renderComponent()
      strictEqual(getInputValue(), 'A')
    })
  })

  QUnit.module('when enterGradesAs is "passFail"', hooks => {
    hooks.beforeEach(() => {
      props.assignment.gradingType = 'pass_fail'
      props.assignment.pointsPossible = 10
      props.enterGradesAs = 'passFail'
      props.submission.enteredGrade = 'incomplete'
      props.submission.enteredScore = 0
    })

    test('renders a select input', () => {
      renderComponent()
      ok(getSelectInput())
    })

    test('displays a label of "Grade"', () => {
      renderComponent()
      const labelText = getLabelText()
      const optionsText = getSelectOptionTexts().join('')
      equal(labelText.replace(optionsText, ''), 'Grade')
    })

    test('includes empty string (""), "complete," and "incomplete" as options values', () => {
      renderComponent()
      const values = getSelectOptions().map($option => $option.value)
      deepEqual(values, ['', 'complete', 'incomplete'])
    })

    test('includes "Ungraded," "Complete," and "Incomplete" as options text', () => {
      renderComponent()
      deepEqual(getSelectOptionTexts(), ['Ungraded', 'Complete', 'Incomplete'])
    })

    test('includes only "Excused" when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      deepEqual(getSelectOptionTexts(), ['Excused'])
    })

    test('disables the input when the submission is excused', () => {
      props.submission.excused = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('shows empty string if the assignment has anonymized students', () => {
      props.assignment.anonymizeStudents = true
      renderComponent()
      strictEqual(getSelectValue(), '')
    })

    test('sets the select value to "Ungraded" when the submission is not graded', () => {
      props.submission.enteredGrade = null
      renderComponent()
      strictEqual(getSelectValue(), '', 'empty string is the value for "Ungraded"')
    })

    test('sets the select value to "Complete" when the submission is complete', () => {
      props.submission.enteredScore = 10
      props.submission.enteredGrade = 'complete'
      renderComponent()
      strictEqual(getSelectValue(), 'complete')
    })

    test('sets the select value to "Incomplete" when the submission is incomplete', () => {
      props.submission.enteredGrade = 'incomplete'
      renderComponent()
      strictEqual(getSelectValue(), 'incomplete')
    })

    test('disables the input when disabled is true', () => {
      props.disabled = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('disables the input when submissionUpdating is true', () => {
      props.submissionUpdating = true
      renderComponent()
      strictEqual(isDisabled(), true)
    })

    test('enables the input when submissionUpdating is false', () => {
      renderComponent()
      strictEqual(isDisabled(), false)
    })

    test('calls the onSubmissionUpdate prop when the value has changed', () => {
      renderComponent()
      changeSelectValue('complete')
      strictEqual(props.onSubmissionUpdate.callCount, 1)
    })

    test('calls the onSubmissionUpdate prop with the submission', () => {
      renderComponent()
      changeSelectValue('complete')
      changeSelectValue('complete')
      const [updatedSubmission] = props.onSubmissionUpdate.lastCall.args
      strictEqual(updatedSubmission, props.submission)
    })

    QUnit.module('when a pass/fail value is entered', contextHooks => {
      let gradingData

      contextHooks.beforeEach(() => {
        renderComponent()
        changeSelectValue('complete')
        gradingData = props.onSubmissionUpdate.lastCall.args[1]
      })

      test('calls the onSubmissionUpdate prop with the entered grade', () => {
        strictEqual(gradingData.grade, 'complete')
      })

      test('calls the onSubmissionUpdate prop with the score form of the entered grade', () => {
        strictEqual(gradingData.score, 10)
      })

      test('calls the onSubmissionUpdate prop with the enteredAs set to "passFail"', () => {
        strictEqual(gradingData.enteredAs, 'passFail')
      })
    })

    test('does not update the input value when the submission begins updating', () => {
      renderComponent()
      props.submission = {...props.submission, enteredGrade: 'complete'}
      props.submissionUpdating = true
      renderComponent()
      strictEqual(getSelectValue(), 'incomplete')
    })

    test('updates the input value when the submission has updated', () => {
      props.submissionUpdating = true
      renderComponent()
      props.submission = {...props.submission, enteredGrade: 'complete'}
      props.submissionUpdating = false
      renderComponent()
      strictEqual(getSelectValue(), 'complete')
    })
  })

  QUnit.module('when pendingGradeInfo is set', hooks => {
    hooks.beforeEach(() => {
      props.enterGradesAs = 'points'
    })

    test('does not set the input as invalid when the pending grade is valid', () => {
      renderComponent()
      props.pendingGradeInfo = {grade: '7', valid: true, excused: false}
      renderComponent()
      strictEqual(isInvalid(), false)
    })

    test('does not display any errors when the pending grade is valid', () => {
      renderComponent()
      props.pendingGradeInfo = {grade: '7', valid: true, excused: false}
      renderComponent()
      strictEqual(getMessageTexts().length, 0)
    })

    test('marks the text input as invalid when the pending grade is not valid', () => {
      renderComponent()
      props.pendingGradeInfo = {grade: 'zzz', valid: false, excused: false}
      renderComponent()
      strictEqual(isInvalid(), true)
    })

    test('marks the text input as invalid when the pending grade is not valid', () => {
      renderComponent()
      props.pendingGradeInfo = {grade: 'zzz', valid: false, excused: false}
      renderComponent()
      deepEqual(getMessageTexts(), ['This is not a valid grade'])
    })

    test('updates the text input with the value of the pending grade when valid', () => {
      props.pendingGradeInfo = {grade: '1234', valid: true, excused: false}
      renderComponent()
      strictEqual(getInputValue(), '1234')
    })

    test('updates the text input with the value of the pending grade when invalid', () => {
      props.pendingGradeInfo = {grade: '1234', valid: false, excused: false}
      renderComponent()
      equal(getInputValue(), '1234')
    })

    test('sets the text input to "Excused" when the pending grade is marked as excused', () => {
      props.pendingGradeInfo = {grade: '111', valid: false, excused: true}
      renderComponent()
      equal(getInputValue(), 'Excused')
    })
  })

  test('displays a warning message when passed a negative score', () => {
    props.enterGradesAs = 'points'
    renderComponent()
    props.submission = {enteredScore: -1, excused: false}
    renderComponent()
    deepEqual(getMessageTexts(), ['This grade has negative points'])
  })

  test('displays a warning message when passed an unusually high score', () => {
    props.enterGradesAs = 'points'
    renderComponent()
    props.submission = {enteredScore: 50, excused: false}
    props.assignment = {anonymizeStudents: false, pointsPossible: 10, gradingType: 'points'}
    renderComponent()
    deepEqual(getMessageTexts(), ['This grade is unusually high'])
  })
})
/* eslint-enable qunit/no-identical-names */
