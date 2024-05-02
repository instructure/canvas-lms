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

import GradeInput from '../GradeInput'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import {fireEvent, render, waitFor} from '@testing-library/react'

describe('GradebookGrid GradeInput', () => {
  let ref
  let instance
  let props
  let wrapper

  beforeEach(() => {
    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: {
        data: [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0],
        ],
      },
    })

    props = {
      disabled: false,
      gradeEntry,
      gradeInfo: gradeEntry.gradeInfoFromGrade(null),
      pendingGradeInfo: null,
    }
  })

  function mountComponent() {
    ref = React.createRef()
    wrapper = render(<GradeInput {...props} ref={ref} />)
    instance = ref.current
  }

  function updateProps(nextProps) {
    ref = React.createRef()
    wrapper.rerender(<GradeInput {...{...props, ...nextProps}} ref={ref} />)
  }

  function getTextInput() {
    return wrapper.container.querySelector('input[type="text"]')
  }

  function getTextInputValue() {
    return getTextInput().value
  }

  function setTextInputValue(value) {
    fireEvent.change(wrapper.container.querySelector('input[type="text"]'), {target: {value}})
  }

  describe('when using a grading scheme', () => {
    test('adds the PercentInput suffix class to the container', () => {
      // TODO: GRADE-1926, Use GradingSchemeInput suffix instead
      mountComponent()
      expect(wrapper.container.querySelector('.Grid__GradeCell__PercentInput')).toBeInTheDocument()
    })

    test('renders a text input', () => {
      mountComponent()
      expect(getTextInput()).toBeInTheDocument()
    })

    test('optionally disables the input', () => {
      props.disabled = true
      mountComponent()
      expect(getTextInput().disabled).toBeTruthy()
    })
  })

  describe('when not using a grading scheme', () => {
    beforeEach(() => {
      props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
    })

    test('adds the PercentInput suffix class to the container', () => {
      mountComponent()
      expect(wrapper.container.querySelector('.Grid__GradeCell__PercentInput')).toBeInTheDocument()
    })

    test('renders a text input', () => {
      mountComponent()
      expect(getTextInput()).toBeInTheDocument()
    })

    test('optionally disables the input', () => {
      props.disabled = true
      mountComponent()
      expect(getTextInput()).toBeDisabled()
    })
  })

  describe('when no grade is assigned', () => {
    beforeEach(() => {
      props.gradeInfo = props.gradeEntry.gradeInfoFromGrade(null)
      mountComponent()
    })

    test('keeps the input blank', () => {
      expect(getTextInputValue()).toBe('')
    })

    test('#gradeInfo is set to a null grade', () => {
      const grade = props.gradeEntry.parseValue('')
      expect(instance.gradeInfo).toEqual(grade)
    })

    test('#hasGradeChanged() returns false when the input value has not changed', () => {
      expect(instance.hasGradeChanged()).toBeFalsy()
    })

    test('#hasGradeChanged() returns true when the input value has changed', () => {
      setTextInputValue('A')
      expect(instance.hasGradeChanged()).toBeTruthy()
    })
  })

  describe('when a grade is assigned', () => {
    describe('when using a grading scheme', () => {
      beforeEach(() => {
        props.gradeInfo = props.gradeEntry.parseValue('91.1%')
        mountComponent()
      })

      test('sets the input value with the scheme grade', () => {
        expect(getTextInputValue()).toBe('A')
      })

      test('#gradeInfo is set to equivalent grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1%')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the assigned scheme grade', () => {
        setTextInputValue(' A ')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns false when the input value matches as a percentage', () => {
        setTextInputValue('91.1')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input value differs from the assigned grade', () => {
        setTextInputValue('B')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })

    describe('when not using a grading scheme', () => {
      beforeEach(() => {
        props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
        props.gradeInfo = props.gradeEntry.parseValue('91.1%')
      })

      test('sets the input value with the percentage grade', () => {
        mountComponent()
        expect(getTextInputValue()).toBe('91.1%')
      })

      test('rounds the input value to two decimal places', () => {
        props.gradeInfo = props.gradeEntry.parseValue('91.1234%')
        mountComponent()
        expect(getTextInputValue()).toBe('91.12%')
      })

      test('strips insignificant zeros', () => {
        props.gradeInfo = props.gradeEntry.parseValue('91.0000%')
        mountComponent()
        expect(getTextInputValue()).toBe('91%')
      })

      test('#gradeInfo is set to equivalent grade info', () => {
        mountComponent()
        const gradeInfo = props.gradeEntry.parseValue('91.1%')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the assigned grade', () => {
        mountComponent()
        setTextInputValue(' 91.1 ')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input value differs from the assigned grade', () => {
        mountComponent()
        setTextInputValue('91.2')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })
  })

  describe('when no grade is assigned and a valid grade is pending', () => {
    beforeEach(() => {
      props.gradeInfo = props.gradeEntry.gradeInfoFromGrade(null)
    })

    describe('when using a grading scheme', () => {
      beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
        mountComponent()
      })

      test('sets the input value with the scheme grade', () => {
        expect(getTextInputValue()).toBe('A')
      })

      test('#gradeInfo is set to the pending grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending scheme grade', () => {
        setTextInputValue(' A ')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns false when the input value matches as a percentage', () => {
        setTextInputValue('91.1')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        setTextInputValue('B')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })

    describe('when not using a grading scheme', () => {
      beforeEach(() => {
        props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
      })

      test('sets the input value with the percentage grade', () => {
        mountComponent()
        expect(getTextInputValue()).toBe('91.1%')
      })

      test('#gradeInfo is set to the pending grade info', () => {
        mountComponent()
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending grade', () => {
        mountComponent()
        setTextInputValue(' 91.1 ')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        mountComponent()
        setTextInputValue('91.2')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })
  })

  describe('when a grade is assigned and an updated, valid grade is pending', () => {
    beforeEach(() => {
      props.gradeInfo = props.gradeEntry.parseValue('89.9')
    })

    describe('when using a grading scheme', () => {
      beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
        mountComponent()
      })

      test('sets the input value with the scheme grade of the pending grade', () => {
        expect(getTextInputValue()).toBe('A')
      })

      test('#gradeInfo is set to pending grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending scheme grade', () => {
        setTextInputValue(' A ')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns false when the input value matches as a percentage', () => {
        setTextInputValue('91.1')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        setTextInputValue('C')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })

      test('#hasGradeChanged() returns true when the input value matches the assigned grade', () => {
        setTextInputValue('B')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })

    describe('when not using a grading scheme', () => {
      beforeEach(() => {
        props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
        mountComponent()
      })

      test('sets the input value with the percentage grade', () => {
        expect(getTextInputValue()).toBe('91.1%')
      })

      test('#gradeInfo is set to the pending grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending grade', () => {
        setTextInputValue(' 91.1 ')
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        setTextInputValue('91.2')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })

      test('#hasGradeChanged() returns true when the input value matches the assigned grade', () => {
        setTextInputValue('89.9')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })

    describe('when the pending grade cleared the assigned grade', () => {
      beforeEach(() => {
        props.gradeInfo = props.gradeEntry.parseValue('A')
        props.pendingGradeInfo = props.gradeEntry.parseValue('')
        mountComponent()
      })

      test('keeps the input blank', () => {
        expect(getTextInputValue()).toBe('')
      })

      test('#gradeInfo is set to the pending blank grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('')
        expect(instance.gradeInfo).toEqual(gradeInfo)
      })

      test('#hasGradeChanged() returns false while the input remains blank', () => {
        expect(instance.hasGradeChanged()).toBeFalsy()
      })

      test('#hasGradeChanged() returns true when the input is not blank', () => {
        setTextInputValue('A')
        expect(instance.hasGradeChanged()).toBeTruthy()
      })
    })
  })

  describe('when a new grade changes from pending to applied', () => {
    beforeEach(() => {
      props.gradeInfo = props.gradeEntry.gradeInfoFromGrade(null)
      props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
      mountComponent()
    })

    function updateGrade() {
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      updateProps({gradeInfo, pendingGradeInfo: null})
    }

    test('sets the input value with the updated grade', () => {
      updateGrade()
      expect(getTextInputValue()).toBe('A')
    })

    test('#gradeInfo is set to the updated grade info', () => {
      updateGrade()
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      expect(instance.gradeInfo).toEqual(gradeInfo)
    })

    test('does not update the input value when the input has focus', () => {
      getTextInput().focus()
      setTextInputValue('91.2%')
      updateGrade()
      expect(getTextInputValue()).toBe('91.2%')
    })
  })

  describe('when an updated grade changes from pending to applied', () => {
    beforeEach(() => {
      props.gradeInfo = props.gradeEntry.parseValue('89.9')
      props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
      mountComponent()
    })

    function updateGrade() {
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      updateProps({gradeInfo, pendingGradeInfo: null})
    }

    test('sets the input value with the updated grade', () => {
      updateGrade()
      expect(getTextInputValue()).toBe('A')
    })

    test('#gradeInfo is set to the updated grade info', () => {
      updateGrade()
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      expect(instance.gradeInfo).toEqual(gradeInfo)
    })

    test('does not update the input value when the input has focus', () => {
      getTextInput().focus()
      setTextInputValue('91.2%')
      updateGrade()
      expect(getTextInputValue()).toBe('91.2%')
    })
  })

  describe('#gradeInfo', () => {
    test('is set to the parsed grade from the given GradeEntry', () => {
      mountComponent()
      setTextInputValue('91.1')
      waitFor(() => {
        expect(instance.gradeInfo).toBe(props.gradeEntry.parseValue('91.1'))
      })
    })

    test('trims whitespace from the input value', () => {
      mountComponent()
      setTextInputValue('  90.0  ')
      waitFor(() => {
        expect(instance.gradeInfo).toBe(props.gradeEntry.parseValue('90.0'))
      })
    })

    test('sets .grade to null when the input was cleared', () => {
      mountComponent()
      setTextInputValue('90.0')
      setTextInputValue('')
      expect(instance.gradeInfo.grade).toBeNull()
    })
  })

  describe('#focus()', () => {
    test('sets focus on the input', () => {
      mountComponent()
      ref.current.focus()
      expect(document.activeElement).toBe(getTextInput())
    })

    test('selects the content of the input', () => {
      props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
      props.gradeInfo = props.gradeEntry.parseValue('78.9')
      mountComponent()
      ref.current.focus()
      waitFor(() => {
        expect(document.getSelection().toString()).toBe('78.9%')
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
})
