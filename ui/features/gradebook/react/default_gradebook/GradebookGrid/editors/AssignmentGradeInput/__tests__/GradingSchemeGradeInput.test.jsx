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
import {findDOMNode} from 'react-dom'
import AssignmentGradeInput from '../index'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {fireEvent, render, waitFor} from '@testing-library/react'

describe('GradebookGrid AssignmentGradeInput using GradingSchemeGradeInput', () => {
  let props
  let ref
  let resolveClose
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
      ['A+', 0.97],
      ['A', 0.93],
      ['A-', 0.9],
      ['B+', 0.87],
      ['B', 0.83],
      ['B-', 0.8],
      ['C+', 0.77],
      ['C', 0.73],
      ['C-', 0.7],
      ['D+', 0.67],
      ['D', 0.63],
      ['D-', 0.6],
      ['F', 0],
    ]

    props = {
      assignment,
      enterGradesAs: 'gradingScheme',
      disabled: false,
      gradingScheme,
      submission,
    }
  })

  function mountComponent() {
    ref = React.createRef()
    wrapper = render(<AssignmentGradeInput {...props} ref={ref} />)
  }

  async function openAndClick(optionText) {
    await wrapper.getByRole('button').click()
    resolveClose = () => {}
    waitFor(() => {
      wrapper.getByText(optionText).click()
    })
    // await wrapper.getByText(optionText).click()
  }

  function getTextInputValue() {
    return wrapper.container.querySelector('input').value
  }

  test('adds the GradingSchemeInput-suffix class to the container', () => {
    mountComponent()
    expect(
      wrapper.container.querySelector('.Grid__GradeCell__GradingSchemeInput')
    ).toBeInTheDocument()
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

  test('optionally disables the menu button', () => {
    props.disabled = true
    mountComponent()
    expect(wrapper.container.querySelector('button')).toBeDisabled()
  })

  test('sets as the input value the grade corresponding to the entered score', () => {
    props.submission = {...props.submission, enteredScore: 7.8, enteredGrade: 'C+'}
    mountComponent()
    expect(getTextInputValue()).toBe('C+')
  })

  test('sets the input to the pending grade when present and valid', () => {
    props.pendingGradeInfo = {excused: false, grade: 'A+', valid: true}
    mountComponent()
    expect(getTextInputValue()).toBe('A+')
  })

  test('sets the input to the pending grade when present and invalid', () => {
    props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
    mountComponent()
    expect(getTextInputValue()).toBe('invalid')
  })

  describe('#componentWillReceiveProps()', () => {
    test('sets the input value to the entered score of the updated submission, with minus replacing en-dash', async () => {
      mountComponent()
      props.submission = {...props.submission, enteredScore: 8.0, enteredGrade: 'B-'}
      ref = React.createRef()
      wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
      await waitFor(() => {
        expect(getTextInputValue()).toBe('B−')
      })
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
      wrapper.container.querySelector('input').focus()
      props.submission = {...props.submission, enteredScore: 8.0, enteredGrade: 'B-'}
      wrapper.rerender(<AssignmentGradeInput {...props} />)
      expect(getTextInputValue()).toBe('')
    })
  })

  describe('#gradeInfo', () => {
    function getGradeInfo() {
      if (!ref.current) return {}
      return ref.current.gradeInfo
    }

    describe('when the submission is ungraded', () => {
      beforeEach(() => {
        mountComponent()
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to null', () => {
        expect(getGradeInfo().enteredAs).toBeNull()
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the submission becomes ungraded', () => {
      beforeEach(async () => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
        props.submission = {...props.submission, enteredGrade: null, enteredScore: null}
        ref = React.createRef()
        wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to null', () => {
        expect(getGradeInfo().enteredAs).toBeNull()
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the submission is graded', () => {
      beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
      })

      test('sets grade to the letter grade form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('C')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(7.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        expect(getGradeInfo().enteredAs).toBe('gradingScheme')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the submission becomes graded', () => {
      beforeEach(() => {
        mountComponent()
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        ref = React.createRef()
        wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
      })

      test('sets grade to the letter grade form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('C')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(7.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        expect(getGradeInfo().enteredAs).toBe('gradingScheme')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the submission is excused', () => {
      beforeEach(() => {
        props.submission = {...props.submission, excused: true}
        mountComponent()
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to "excused"', () => {
        expect(getGradeInfo().enteredAs).toBe('excused')
      })

      test('sets excused to true', () => {
        expect(getGradeInfo().excused).toBeTruthy()
      })
    })

    describe('when the submission becomes excused', () => {
      beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
        props.submission = {
          ...props.submission,
          enteredGrade: null,
          enteredScore: null,
          excused: true,
        }
        ref = React.createRef()
        wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to "excused"', () => {
        expect(getGradeInfo().enteredAs).toBe('excused')
      })

      test('sets excused to true', () => {
        expect(getGradeInfo().excused).toBeTruthy()
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
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the submission receives a pending grade', () => {
      beforeEach(() => {
        mountComponent()
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true,
        }
        ref = React.createRef()
        wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
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
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the pending grade updates', () => {
      beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true,
        }
        mountComponent()
        props.pendingGradeInfo = {
          enteredAs: 'percent',
          excused: false,
          grade: 'A',
          score: 9.3,
          valid: true,
        }
        ref = React.createRef()
        wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
      })

      test('sets grade to the grade of the pending grade', () => {
        expect(getGradeInfo().grade).toBe('A')
      })

      test('sets score to the score of the pending grade', () => {
        expect(getGradeInfo().score).toBe(9.3)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        expect(getGradeInfo().enteredAs).toBe('percent')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the pending grade resolves with a graded submission', () => {
      beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true,
        }
        mountComponent()
        props.pendingGradeInfo = null
        props.submission = {...props.submission, enteredGrade: 'B', enteredScore: 8.6}
        ref = React.createRef()
        wrapper.rerender(<AssignmentGradeInput {...props} ref={ref} />)
      })

      test('sets grade to the letter grade form of the entered grade on the submission', () => {
        expect(getGradeInfo().grade).toBe('B')
      })

      test('sets score to the score form of the entered grade on the submission', () => {
        expect(getGradeInfo().score).toBe(8.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        expect(getGradeInfo().enteredAs).toBe('gradingScheme')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    test('trims whitespace from changed input values', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ' B '}})
      expect(getGradeInfo().grade).toBe('B')
    })

    describe('when a point value is entered', () => {
      beforeEach(() => {
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '8.9'}})
      })

      test('sets grade to the percent form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('B+')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(8.9)
      })

      test('sets enteredAs to "points"', () => {
        expect(getGradeInfo().enteredAs).toBe('points')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when a percent value is entered', () => {
      beforeEach(() => {
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '89%'}})
      })

      test('sets grade to the entered grade', () => {
        expect(getGradeInfo().grade).toBe('B+')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(8.9)
      })

      test('sets enteredAs to "percent"', () => {
        expect(getGradeInfo().enteredAs).toBe('percent')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when a grading scheme value is entered', () => {
      beforeEach(() => {
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
      })

      test('sets grade to the percent form of the entered grade', () => {
        expect(getGradeInfo().grade).toBe('B')
      })

      test('sets score to the score form of the entered grade', () => {
        expect(getGradeInfo().score).toBe(8.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        expect(getGradeInfo().enteredAs).toBe('gradingScheme')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when "EX" is entered', () => {
      beforeEach(() => {
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'EX'}})
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to "excused"', () => {
        expect(getGradeInfo().enteredAs).toBe('excused')
      })

      test('sets excused to true', () => {
        expect(getGradeInfo().excused).toBeTruthy()
      })
    })

    describe('when the input is cleared', () => {
      beforeEach(() => {
        mountComponent()
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
        fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ''}})
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to null', () => {
        expect(getGradeInfo().enteredAs).toBeNull()
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    test('ignores case for "ex"', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'ex'}})
      expect(getGradeInfo().excused).toBeTruthy()
    })

    describe('when a grading scheme option is clicked', () => {
      beforeEach(() => {
        mountComponent()
        return openAndClick('B+')
      })

      test('sets grade to the clicked scheme key', () => {
        expect(getGradeInfo().grade).toBe('B+')
      })

      test('sets score to the score form of the clicked scheme key', () => {
        expect(getGradeInfo().score).toBe(8.9)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        expect(getGradeInfo().enteredAs).toBe('gradingScheme')
      })

      test('sets excused to false', () => {
        expect(getGradeInfo().excused).toBeFalsy()
      })
    })

    describe('when the "Excused" option is clicked', () => {
      beforeEach(async () => {
        mountComponent()
        await openAndClick('Excused')
      })

      test('sets grade to null', () => {
        expect(getGradeInfo().grade).toBeNull()
      })

      test('sets score to null', () => {
        expect(getGradeInfo().score).toBeNull()
      })

      test('sets enteredAs to "excused"', () => {
        expect(getGradeInfo().enteredAs).toBe('excused')
      })

      test('sets excused to true', () => {
        expect(getGradeInfo().excused).toBeTruthy()
      })
    })
  })

  describe('#focus()', () => {
    test('sets focus on the input', () => {
      mountComponent()
      ref.current.focus()
      expect(wrapper.container.querySelector('input:focus')).toBeInTheDocument()
    })

    test('selects the content of the input', async () => {
      props.submission = {...props.submission, enteredScore: 8.13, enteredGrade: 'B-'}
      mountComponent()
      ref.current.focus()
      await waitFor(() => {
        expect(wrapper.container.querySelector('input').value).toBe('B−')
      })
    })

    test('does not take focus from the grading scheme menu button', () => {
      mountComponent()
      wrapper.container.querySelector('button').focus()
      ref.current.focus()
      expect(wrapper.container.querySelector('button:focus')).toBeInTheDocument()
    })
  })

  describe('#handleKeyDown()', () => {
    const TAB = {shiftKey: false, which: 9}
    const SHIFT_TAB = {shiftKey: true, which: 9}
    const ENTER = {shiftKey: false, which: 13}

    beforeEach(() => {
      mountComponent()
    })

    function focusOn(element) {
      const node = wrapper.container.querySelector(element)
      node.focus()
    }

    function handleKeyDown(action) {
      return ref.current.handleKeyDown({...action})
    }

    test('returns false when tabbing from the input to the menu button', () => {
      // return false so that focus moves from the input to the menu button
      focusOn('input')
      expect(handleKeyDown(TAB)).toBeFalsy()
    })

    test('returns undefined when tabbing forward from the menu button', () => {
      // return undefined to delegate event handling to the parent
      focusOn('button')
      expect(handleKeyDown(TAB)).toBeUndefined()
    })

    test('returns false when shift+tabbing from the menu button to the input', () => {
      // return false so that focus moves from the menu button to the input
      focusOn('button')
      expect(handleKeyDown(SHIFT_TAB)).toBeFalsy()
    })

    test('returns undefined when shift+tabbing back from the input', () => {
      // return undefined to delegate event handling to the parent
      focusOn('input')
      expect(handleKeyDown(SHIFT_TAB)).toBeUndefined()
    })

    test('returns false when pressing enter on the menu button', () => {
      // return false to allow the popover menu to open
      focusOn('button')
      expect(handleKeyDown(ENTER)).toBeFalsy()
    })

    test('returns undefined when pressing enter on the input', () => {
      // return undefined to delegate event handling to the parent
      focusOn('input')
      expect(handleKeyDown(ENTER)).toBeUndefined()
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
      props.pendingGradeInfo = {excused: false, grade: 'B', valid: true}
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

    test('returns true when a different grade is entered', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns true when a different grade is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      return openAndClick('B').then(() => {
        expect(hasGradeChanged()).toBeTruthy()
      })
    })

    test('returns true when the submission becomes excused', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'EX'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns true when "Excused" is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      return openAndClick('Excused').then(() => {
        expect(hasGradeChanged()).toBeTruthy()
      })
    })

    test('returns false when the grade has not changed', () => {
      mountComponent()
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns false when the same grade is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      return openAndClick('C').then(() => {
        expect(hasGradeChanged()).toBeFalsy()
      })
    })

    test('returns false when the grade has not changed to a different grading scheme key', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns false when the grade has changed to the same value in "points"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.6'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns false when the grade has changed to the same value in "percent"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '76%'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns true when the grade has changed to a different value in "points"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.8'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns true when the grade has changed to a different value in "percent"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '78%'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns false when the grade is stored as the same value in "points"', () => {
      props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns false when the grade is stored as the same value in "percent"', () => {
      props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'C'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('returns true when an invalid grade is corrected', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
      expect(hasGradeChanged()).toBeTruthy()
    })

    test('returns false when the grade has changed back to the original value', () => {
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'B'}})
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: ''}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('ignores whitespace in the entered grade', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '  C  '}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('ignores case for "ex"', () => {
      props.submission = {...props.submission, excused: true}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: 'ex'}})
      expect(hasGradeChanged()).toBeFalsy()
    })

    test('ignores unnecessary zeros in the entered grade', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      fireEvent.change(wrapper.container.querySelector('input'), {target: {value: '7.600'}})
      expect(hasGradeChanged()).toBeFalsy()
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
  })

  describe('Grading Scheme Menu Items', () => {
    test('includes an option for each grading scheme key', async () => {
      mountComponent()
      await wrapper.getByRole('button', {name: 'Open Grading Scheme menu'}).click()
      await waitFor(() => {
        expect(wrapper.getAllByRole('menuitem').length).toBe(14)
      })
    })

    test('uses the grading scheme key (with trailing dashes replaced with minus) for each grading scheme option', async () => {
      const expectedLabels = props.gradingScheme.map(([key]) =>
        GradeFormatHelper.replaceDashWithMinus(key)
      ) // ['A+', 'A', …, 'F']
      mountComponent()
      wrapper.getByRole('button').click()
      expectedLabels.map(async expectedLabel => {
        await waitFor(() => {
          expect(wrapper.getByText(expectedLabel)).toBeInTheDocument()
        })
      })
    })

    test('includes "Excused" as the last option', async () => {
      mountComponent()
      await wrapper.getByRole('button').click()
      await waitFor(() => {
        expect(wrapper.getByText('Excused')).toBeInTheDocument()
      })
    })

    test('set the input to the selected scheme key when clicked', async () => {
      mountComponent()
      await openAndClick('B')
      await waitFor(() => {
        expect(getTextInputValue()).toBe('B')
      })
    })

    test('set the input to "Excused" when clicked', async () => {
      mountComponent()
      await openAndClick('Excused')
      await waitFor(() => {
        expect(getTextInputValue()).toBe('Excused')
      })
    })
  })
})
