/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import AssignmentGradeInput from '../index'
import {fireEvent, render, waitFor} from '@testing-library/react'

describe('GradebookGrid AssignmentGradeInput', () => {
  let ref
  let props
  let wrapper

  beforeEach(() => {
    ENV.GRADEBOOK_OPTIONS = {assignment_missing_shortcut: true}
    const assignment = {
      pointsPossible: 10,
    }
    const submission = {
      enteredGrade: null,
      enteredScore: null,
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
      enterGradesAs: 'points',
      disabled: false,
      gradingScheme,
      submission,
    }
  })

  function mountComponent() {
    ref = React.createRef()
    wrapper = render(<AssignmentGradeInput {...props} ref={ref} />)
  }

  function getTextInputValue() {
    return wrapper.container.querySelector('input').value
  }

  test('displays a screenreader-only label of "Grade"', () => {
    mountComponent()
    expect(wrapper.getByText('Grade')).toBeInTheDocument()
  })

  test('sets the input value to the grade of the pending grade info, when present', () => {
    props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
    mountComponent()
    waitFor(() => {
      expect(getTextInputValue()).toBe('invalid')
    })
  })

  test('clears the grade input when the pending grade is cleared', () => {
    props.pendingGradeInfo = {excused: false, grade: null, valid: true}
    mountComponent()
    expect(getTextInputValue()).toBe('')
  })

  test('displays "Excused" when the pending grade is "Excused"', () => {
    props.pendingGradeInfo = {excused: true, grade: null, valid: true}
    mountComponent()
    waitFor(() => {
      expect(getTextInputValue()).toBe('Excused')
    })
  })

  describe('when the "enter grades as" setting is "passFail"', () => {
    // const getInputValue = () => wrapper.container.querySelector('.Grid__GradeCell__CompleteIncompleteValue').value
    //   wrapper.find('.Grid__GradeCell__CompleteIncompleteValue').at(0).getDOMNode().textContent

    beforeEach(() => {
      props.enterGradesAs = 'passFail'
      props.submission.enteredGrade = 'complete'
      props.submission.enteredScore = 10
    })

    test('renders a button trigger for the menu', () => {
      mountComponent()
      const button = wrapper.container.querySelectorAll(
        '.Grid__GradeCell__CompleteIncompleteMenu button'
      )
      expect(button.length).toBe(1)
    })

    test('sets the input value to "–" when the submission is not graded and not excused', () => {
      props.submission.enteredGrade = null
      props.submission.enteredScore = null
      mountComponent()
      expect(wrapper.getByText('–')).toBeInTheDocument()
    })

    test('sets the input value to "Excused" when the submission is excused', () => {
      props.submission.enteredGrade = null
      props.submission.enteredScore = null
      props.submission.excused = true
      mountComponent()
      expect(wrapper.getByText('Excused')).toBeInTheDocument()
    })

    test('sets the value to "Complete" when the submission is complete', () => {
      mountComponent()
      expect(wrapper.getByText('Complete')).toBeInTheDocument()
    })

    test('sets the value to "Incomplete" when the submission is incomplete', () => {
      props.submission.enteredGrade = 'incomplete'
      props.submission.enteredScore = 0
      mountComponent()
      expect(wrapper.getByText('Incomplete')).toBeInTheDocument()
    })
  })

  describe('when the "enter grades as" setting is "points"', () => {
    beforeEach(() => {
      props.enterGradesAs = 'points'
      props.submission.enteredGrade = '78%'
      props.submission.enteredScore = 7.8
    })

    test('adds the PointsInput-suffix class to the container', () => {
      mountComponent()
      expect(wrapper.container.querySelector('.Grid__GradeCell__PointsInput')).toBeInTheDocument()
    })

    test('renders a text input', () => {
      mountComponent()
      expect(wrapper.container.querySelectorAll('input[type="text"]').length).toBe(1)
    })

    test('optionally disables the input', () => {
      props.disabled = true
      mountComponent()
      expect(wrapper.container.querySelector('input[type="text"]')).toBeDisabled()
    })

    test('sets the input value to the entered score of the submission', () => {
      props.submission.enteredGrade = '78%'
      mountComponent()
      expect(getTextInputValue()).toBe('7.8')
    })

    test('rounds the input value to two decimal places', () => {
      props.submission.enteredScore = 7.816
      mountComponent()
      expect(getTextInputValue()).toBe('7.82')
    })

    test('strips insignificant zeros', () => {
      props.submission.enteredScore = 8.0
      mountComponent()
      expect(getTextInputValue()).toBe('8')
    })

    test('keeps the input blank when the submission is not graded', () => {
      props.submission.enteredScore = null
      mountComponent()
      expect(getTextInputValue()).toBe('')
    })

    test('displays "Excused" as the input value when the submission is excused', () => {
      props.submission.excused = true
      mountComponent()
      expect(getTextInputValue()).toBe('Excused')
    })
  })

  describe('when the "enter grades as" setting is "percent"', () => {
    beforeEach(() => {
      props.submission.enteredGrade = '7.8'
      props.submission.enteredScore = 7.8
      props.enterGradesAs = 'percent'
    })

    test('adds the PercentInput-suffix class to the container', () => {
      mountComponent()
      expect(wrapper.container.querySelector('.Grid__GradeCell__PercentInput')).toBeInTheDocument()
    })

    test('renders a text input', () => {
      mountComponent()
      expect(wrapper.container.querySelectorAll('input[type="text"]').length).toBe(1)
    })

    test('optionally disables the input', () => {
      props.disabled = true
      mountComponent()
      expect(wrapper.container.querySelector('input[type="text"]')).toBeDisabled()
    })

    test('sets the input value to the percentage value of the entered score of the submission', () => {
      mountComponent()
      expect(getTextInputValue()).toBe('7.8')
    })

    test('rounds the input value to two decimal places', () => {
      props.submission.enteredScore = 7.8916
      mountComponent()
      expect(getTextInputValue()).toBe('7.89')
    })

    test('strips insignificant zeros', () => {
      props.submission.enteredScore = 8.0
      mountComponent()
      expect(getTextInputValue()).toBe('8')
    })

    test('keeps the input blank when the submission is not graded', () => {
      props.submission.enteredScore = null
      mountComponent()
      expect(getTextInputValue()).toBe('')
    })

    test('displays "Excused" as the input value when the submission is excused', () => {
      props.submission.excused = true
      mountComponent()
      expect(getTextInputValue()).toBe('Excused')
    })
  })

  describe('#componentWillReceiveProps()', () => {
    test('sets the input value to the entered score of the updated submission', () => {
      mountComponent()
      props.submission = {...props.submission, enteredScore: 8.0, enteredGrade: '8.00'}
      wrapper.rerender(<AssignmentGradeInput {...props} />)
      expect(getTextInputValue()).toBe('8')
    })

    test('displays "Excused" as the input value when the updated submission is excused', () => {
      mountComponent()
      props.submission = {
        ...props.submission,
        excused: true,
        enteredScore: null,
        enteredGrade: null,
      }
      wrapper.rerender(<AssignmentGradeInput {...props} />)
      expect(getTextInputValue()).toBe('Excused')
    })

    test('does not update the input value when the input has focus', () => {
      mountComponent()
      wrapper.container.querySelector('input[type="text"]').focus()
      props.submission = {...props.submission, enteredScore: 8.0, enteredGrade: '8.00'}
      wrapper.rerender(<AssignmentGradeInput {...props} />)
      expect(getTextInputValue()).toBe('')
    })
  })

  describe('#gradeInfo', () => {
    const getGradeInfo = () => ref.current.gradeInfo

    describe('when the submission is ungraded', () => {
      beforeEach(() => {
        mountComponent()
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBe(null)
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBe(null)
      })

      test('sets enteredAs to null', () => {
        expect(getGradeInfo().enteredAs).toBe(null)
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    describe('when "enterGradesAs" is "points" and the submission is graded', () => {
      beforeEach(() => {
        props.enterGradesAs = 'points'
        props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
        mountComponent()
      })

      test('sets grade to the points form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('7.6')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(7.6)
      })

      test('sets enteredAs to "points"', () => {
        expect(getGradeInfo().enteredAs).toBe('points')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    describe('when "enterGradesAs" is "percent" and the submission is graded', () => {
      beforeEach(() => {
        props.enterGradesAs = 'percent'
        props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
        mountComponent()
      })

      test('sets grade to the percent form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('76%')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(7.6)
      })

      test('sets enteredAs to "percent"', () => {
        expect(getGradeInfo().enteredAs).toBe('percent')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    describe('when the submission is excused', () => {
      beforeEach(() => {
        props.submission = {...props.submission, excused: true}
        mountComponent()
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBe(null)
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBe(null)
      })

      test('sets enteredAs to "excused"', () => {
        expect(getGradeInfo().enteredAs).toBe('excused')
      })

      test('sets excused to true', () => {
        expect(getGradeInfo().excused).toBe(true)
      })
    })

    describe('when the submission has a pending grade', () => {
      beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true,
        }
        mountComponent()
      })

      test('sets grade to the grade of the pending grade', () => {
        expect(getGradeInfo().grade).toBe('B')
      })

      test('sets score to the score of the pending grade', () => {
        expect(getGradeInfo().score).toBe(8.6)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        expect(getGradeInfo().enteredAs).toBe('points')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBe(false)
      })
    })

    test('trims whitespace from changed input values', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ' 8.9 '}})
      expect(getGradeInfo().grade).toBe('8.9')
    })

    test('is excused when the input changes to "EX"', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'EX'}})
      expect(getGradeInfo().excused).toBe(true)
    })

    test('clears the grade when the input is cleared', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ''}})
      expect(getGradeInfo().grade).toBeNull()
    })

    test('clears the score when the input is cleared', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ''}})
      expect(getGradeInfo().score).toBeNull()
    })

    describe('when "enterGradesAs" is "points"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'points'
        mountComponent()
      })

      describe('when a point value is entered', () => {
        beforeEach(() => {
          fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
        })

        test('sets grade to the entered grade', () => {
          expect(getGradeInfo().grade).toBe('8.9')
        })

        test('sets score to the score form of the entered grade', () => {
          expect(getGradeInfo().score).toBe(8.9)
        })

        test('sets enteredAs to "points"', () => {
          expect(getGradeInfo().enteredAs).toBe('points')
        })
      })

      describe('when a percent value is entered', () => {
        beforeEach(() => {
          fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '89%'}})
        })

        test('sets grade to the points form of the entered grade', () => {
          expect(getGradeInfo().grade).toBe('8.9')
        })

        test('sets score to the score form of the entered grade', () => {
          expect(getGradeInfo().score).toBe(8.9)
        })

        test('sets enteredAs to "percent"', () => {
          expect(getGradeInfo().enteredAs).toBe('percent')
        })
      })

      describe('when a grading scheme value is entered', () => {
        beforeEach(() => {
          fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
        })

        test('sets grade to the points form of the entered grade', () => {
          expect(getGradeInfo().grade).toBe('8.9')
        })

        test('sets score to the score form of the entered grade', () => {
          expect(getGradeInfo().score).toBe(8.9)
        })

        test('sets enteredAs to "gradingScheme"', () => {
          expect(getGradeInfo().enteredAs).toBe('gradingScheme')
        })
      })
    })

    describe('when "enterGradesAs" is "percent"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'percent'
        mountComponent()
      })

      describe('when a point value is entered', () => {
        beforeEach(() => {
          fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
        })

        test('sets grade to the percent form of the entered grade', () => {
          expect(getGradeInfo().grade).toBe('8.9%')
        })

        test('sets score to the score form of the entered grade', () => {
          expect(getGradeInfo().score).toBe(0.89)
        })

        test('sets enteredAs to "percent"', () => {
          expect(getGradeInfo().enteredAs).toBe('percent')
        })
      })

      describe('when a percent value is entered', () => {
        beforeEach(() => {
          fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '89%'}})
        })

        test('sets grade to the entered grade', () => {
          expect(getGradeInfo().grade).toBe('89%')
        })

        test('sets score to the score form of the entered grade', () => {
          expect(getGradeInfo().score).toBe(8.9)
        })

        test('sets enteredAs to "percent"', () => {
          expect(getGradeInfo().enteredAs).toBe('percent')
        })
      })

      describe('when a grading scheme value is entered', () => {
        beforeEach(() => {
          fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
        })

        test('sets grade to the percent form of the entered grade', () => {
          expect(getGradeInfo().grade).toBe('89%')
        })

        test('sets score to the score form of the entered grade', () => {
          expect(getGradeInfo().score).toBe(8.9)
        })

        test('sets enteredAs to "gradingScheme"', () => {
          expect(getGradeInfo().enteredAs).toBe('gradingScheme')
        })
      })
    })
  })

  describe('#focus()', () => {
    test('sets focus on the input', () => {
      mountComponent()
      ref.current.focus()
      expect(wrapper.container.querySelector('input[type="text"]:focus')).toBeInTheDocument()
    })

    test('selects the content of the input', () => {
      props.submission = {...props.submission, enteredScore: 8.13, enteredGrade: '8.13'}
      mountComponent()
      ref.current.focus()
      waitFor(() => {
        expect(document.getSelection().toString()).toBe('8.13')
      })
    })
  })

  describe('#handleKeyDown()', () => {
    test('always returns undefined', () => {
      mountComponent()
      const result = ref.current.handleKeyDown({shiftKey: false, which: 9})
      expect(result).toBeUndefined()
    })
  })

  describe('#hasGradeChanged()', () => {
    function hasGradeChanged() {
      return ref.current.hasGradeChanged()
    }

    test('returns true when an invalid grade is entered', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'invalid'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns false when an invalid grade is entered without change', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'invalid'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('ignores whitespace when comparing an invalid grade', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '  invalid  '}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns true when an invalid grade is changed to a different invalid grade', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'also invalid'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns true when an invalid grade is cleared', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ''}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns false when a valid grade is pending', () => {
      props.pendingGradeInfo = {excused: false, grade: '8.9', valid: true}
      mountComponent()
      // with valid pending grades, the input is disabled
      // changing grades is not allowed at this time
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'invalid'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns false when a null grade is unchanged', () => {
      mountComponent()
      expect(hasGradeChanged()).toBeFalsy()
    })

    describe('when the "enter grades as" setting is "points"', () => {
      test('returns true when the grade has changed', () => {
        props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
        expect(hasGradeChanged()).toBeTruthy()
      })

      test('returns true when the submission becomes excused', () => {
        props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'EX'}})
        expect(hasGradeChanged()).toBeTruthy()
      })

      test('returns false when the grade has not changed', () => {
        mountComponent()
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade has not changed to a different value', () => {
        props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.6'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade has changed to the same value in "percent"', () => {
        props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '76%'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade has changed to the same value in the grading scheme', () => {
        props.submission = {...props.submission, enteredGrade: '7.9', enteredScore: 7.9}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns true when the grade has changed to a different value for the same grading scheme key', () => {
        props.submission = {...props.submission, enteredGrade: '7.8', enteredScore: 7.8}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
        expect(hasGradeChanged()).toBeTruthy()
      })

      test('returns false when the grade is stored as the same value in "percent"', () => {
        props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.6'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade is stored as the same value in "gradingScheme"', () => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.6'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns true when an invalid grade is corrected', () => {
        props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
        expect(hasGradeChanged()).toBeTruthy()
      })
    })

    describe('when the "enter grades as" setting is "percent"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'percent'
      })

      test('returns true when the grade has changed', () => {
        props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '89%'}})
        expect(hasGradeChanged()).toBeTruthy()
      })

      test('returns true when the submission becomes excused', () => {
        props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'EX'}})
        expect(hasGradeChanged()).toBeTruthy()
      })

      test('returns false when the grade has not changed', () => {
        mountComponent()
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade has not changed to a different value', () => {
        props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '76%'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade has changed to the same value in "points"', () => {
        props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '76'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade has changed to the same value in the grading scheme', () => {
        props.submission = {...props.submission, enteredGrade: '79%', enteredScore: 7.9}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns true when the grade has changed to a different value for the same grading scheme key', () => {
        props.submission = {...props.submission, enteredGrade: '78%', enteredScore: 7.8}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
        expect(hasGradeChanged()).toBeTruthy()
      })

      test('returns false when the grade is stored as the same value in "points"', () => {
        props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '76%'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the grade is stored as the same value in "gradingScheme"', () => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '76%'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns true when an invalid grade is corrected', () => {
        props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '89%'}})
        expect(hasGradeChanged()).toBeTruthy()
      })
    })

    describe('when the submission is excused', () => {
      beforeEach(() => {
        props.submission = {...props.submission, excused: true}
        mountComponent()
      })

      test('returns false when the input is unchanged', () => {
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when "EX" is entered', () => {
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'EX'}})
        expect(hasGradeChanged()).toBeFalsy()
      })

      test('returns false when the input adds only whitespace', () => {
        fireEvent.change(wrapper.container.querySelector('input'), {
          target: {value: '   Excused   '},
        })
        expect(hasGradeChanged()).toBeFalsy()
      })
    })

    test('returns false when the grade has changed back to the original value', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ''}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('ignores whitespace in the entered grade', () => {
      props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '  7.6  '}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('ignores unnecessary zeros in the entered grade', () => {
      props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.600'}})
      expect(hasGradeChanged()).toBeFalsy()
    })
  })
})
