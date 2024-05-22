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
import sinon from 'sinon'

import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import EditableCell from '../EditableCell'
import {fireEvent, render} from '@testing-library/react'

describe('GradebookGrid TotalGradeOverrideCellEditor EditableCell', () => {
  let ref
  let props
  let wrapper

  beforeEach(() => {
    const gradeEntry = new GradeOverrideEntry()

    props = {
      gradeEntry,
      gradeInfo: gradeEntry.parseValue('91%'),
      gradeIsUpdating: false,
      onGradeUpdate: sinon.stub(),
      pendingGradeInfo: null,
    }
  })

  function mountComponent() {
    ref = React.createRef()
    wrapper = render(<EditableCell {...props} ref={ref} />)
  }

  function getInstance() {
    return ref.current
  }

  function getTextInput() {
    return wrapper.container.querySelector('input[type="text"]')
  }

  function getInvalidGradeIndicator() {
    return wrapper.container.querySelector('.Grid__GradeCell__InvalidGrade button')
  }

  function setTextInputValue(value) {
    fireEvent.change(wrapper.container.querySelector('input[type="text"]'), {target: {value}})
  }

  function simulateKeyDown(keyCode, shiftKey = false) {
    const event = new Event('keydown')
    event.which = keyCode
    event.shiftKey = shiftKey
    return getInstance().handleKeyDown(event)
  }

  function updateProps(nextProps) {
    wrapper.rerender(<EditableCell {...{...props, ...nextProps}} />)
  }

  describe('#render()', () => {
    test('renders a text input', () => {
      mountComponent()
      expect(getTextInput()).toBeInTheDocument()
    })

    test('sets focus on the grade input', () => {
      mountComponent()
      expect(document.activeElement).toBe(getTextInput())
    })

    test('disables the input when the grade is updating', () => {
      props.gradeIsUpdating = true
      mountComponent()
      expect(getTextInput()).toBeDisabled()
    })

    test('does not disable the input when the grade is not updating', () => {
      mountComponent()
      expect(getTextInput()).not.toBeDisabled()
    })

    test('displays the given grade info in the input', () => {
      mountComponent()
      expect(getTextInput().value).toBe('91%')
    })

    test('displays the given pending grade info in the input', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
      mountComponent()
      expect(getTextInput().value).toBe('92%')
    })

    test('displays the invalid grade indicator when the pending grade info is invalid', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('invalid')
      mountComponent()
      expect(getInvalidGradeIndicator()).toBeInTheDocument()
    })

    test('does not display the invalid grade indicator when the pending grade info is valid', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
      mountComponent()
      expect(getInvalidGradeIndicator()).toBeNull()
    })
  })

  describe('#applyValue()', () => {
    test('calls the .onGradeUpdate prop', () => {
      mountComponent()
      getInstance().applyValue()
      expect(props.onGradeUpdate.callCount).toBe(1)
    })

    test('includes the current grade info when calling the .onGradeUpdate prop', () => {
      mountComponent()
      setTextInputValue('93%')
      getInstance().applyValue()
      const [gradeInfo] = props.onGradeUpdate.lastCall.args
      const expected = props.gradeEntry.parseValue('93%')
      expect(gradeInfo).toEqual(expected)
    })
  })

  describe('#focus()', () => {
    test('sets focus on the grade input', () => {
      mountComponent()
      document.body.focus()
      getInstance().focus()
      expect(document.activeElement).toBe(getTextInput())
    })
  })

  describe('#handleKeyDown()', () => {
    describe('when the grade is valid', () => {
      beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
        mountComponent()
      })

      test('does not skip SlickGrid default behavior when tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, false) // tab to next cell
        expect(continueHandling).toBeUndefined()
      })

      test('does not skip SlickGrid default behavior when shift-tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to previous cell
        expect(continueHandling).toBeUndefined()
      })

      // TODO: GRADE-1926 Ensure SlickGrid behavior is skipped when using the
    })

    describe('when the grade is invalid', () => {
      beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('invalid')
        mountComponent()
      })

      test('skips SlickGrid default behavior when tabbing from the invalid grade indicator', () => {
        getInvalidGradeIndicator().focus()
        const continueHandling = simulateKeyDown(9, false) // tab to grade input
        expect(continueHandling).toBeFalsy()
      })

      test('does not skip SlickGrid default behavior when tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, false) // tab to next cell
        expect(continueHandling).toBeUndefined()
      })

      test('does not skip SlickGrid default behavior when shift-tabbing from the invalid grade indicator', () => {
        getInvalidGradeIndicator().focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to previous cell
        expect(continueHandling).toBeUndefined()
      })

      test('skips SlickGrid default behavior when shift-tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to invalid grade indicator
        expect(continueHandling).toBeFalsy()
      })
    })
  })

  describe('#isValueChanged()', () => {
    test('returns false when the grade input value has not changed', () => {
      mountComponent()
      expect(getInstance().isValueChanged()).toBeFalsy()
    })

    test('returns true when the grade input value has changed', () => {
      mountComponent()
      setTextInputValue('93%')
      expect(getInstance().isValueChanged()).toBeTruthy()
    })
  })

  describe('when re-rendering', () => {
    test('sets focus on the grade input when the grade finishes updating', () => {
      props.gradeIsUpdating = true
      mountComponent()
      updateProps({gradeIsUpdating: false})
      expect(document.activeElement).toBe(getTextInput())
    })

    test('does not set focus on the grade input when the grade has not finished updating', () => {
      props.gradeIsUpdating = true
      mountComponent()
      updateProps({gradeIsUpdating: true})
      expect(document.activeElement).not.toBe(getTextInput())
    })
  })
})
