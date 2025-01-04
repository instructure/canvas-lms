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
import ReactDOM from 'react-dom'
import TotalGradeOverrideCellPropFactory from '../../editors/TotalGradeOverrideCellEditor/TotalGradeOverrideCellPropFactory'
import TotalGradeOverrideCellEditor from '../../editors/TotalGradeOverrideCellEditor/index'
import GridEvent from '../../GridSupport/GridEvent'
import {createGradebook} from '../../../__tests__/GradebookSpecHelper'

describe('GradebookGrid TotalGradeOverrideCellEditor', () => {
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    gradebook = createGradebook({final_grade_override_enabled: true})
    jest.spyOn(gradebook, 'isStudentGradeable').mockReturnValue(true)
    jest.spyOn(gradebook, 'studentHasGradedSubmission').mockReturnValue(true)
    jest.spyOn(gradebook, 'student').mockReturnValue({
      enrollments: [
        {
          grades: {
            html_url: 'https://canvas.instructure.com/courses/1101/grades',
          },
        },
      ],
    })

    editorOptions = {
      column: {
        getGridSupport() {
          return gridSupport
        },

        propFactory: new TotalGradeOverrideCellPropFactory(gradebook),
      },

      container: $container,
      item: {
        id: '1101',
        name: 'Some Student',
        avatar_url: 'https://canvas.instructure.com/images/messages/avatar-55.png',
        enrollments: [
          {
            id: '222',
            grades: {
              html_url: 'https://canvas.instructure.com/courses/1101/grades',
            },
          },
        ],
      },
    }
  })

  afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
  })

  function createEditor() {
    editor = new TotalGradeOverrideCellEditor(editorOptions)
  }

  describe('initialization', () => {
    test('renders an editable cell when the student is gradeable', () => {
      createEditor()
      expect($container.querySelector('.Grid__ReadOnlyCell')).toBeFalsy()
    })

    test('renders a read-only cell when the student is not gradeable', () => {
      gradebook.isStudentGradeable.mockReturnValue(false)
      createEditor()
      expect($container.querySelector('.Grid__ReadOnlyCell')).toBeTruthy()
    })

    test('renders a read-only cell when the student has no graded submissions', () => {
      gradebook.studentHasGradedSubmission.mockReturnValue(false)
      createEditor()
      expect($container.querySelector('.Grid__ReadOnlyCell')).toBeTruthy()
    })

    test('stores a reference to the rendered component', () => {
      createEditor()
      expect(editor.component instanceof React.Component).toBeTruthy()
    })
  })

  describe('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the component when triggered', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })

    test('passes the event when calling handleKeyDown', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledWith(keyboardEvent)
    })

    test('returns the return value from the component', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown').mockReturnValue(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when the student is not gradeable', () => {
      gradebook.isStudentGradeable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    test('removes the reference to the component', () => {
      createEditor()
      editor.destroy()
      expect(editor.component).toBeNull()
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(
        true,
        '"true" is the default return value when the event has no subscribers',
      )
    })

    test('unmounts the component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      expect(unmounted).toBe(false, 'component was already unmounted')
    })
  })

  describe('#focus()', () => {
    test('calls .focus on the component', () => {
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })

    test('calls .focus on the ReadOnlyCell component when the student is not gradeable', () => {
      gradebook.isStudentGradeable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the component', () => {
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the student is not gradeable', () => {
      gradebook.isStudentGradeable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('returns false when the component has not yet rendered', () => {
      createEditor()
      editor.component = null
      expect(editor.isValueChanged()).toBe(false)
    })
  })

  describe('#serializeValue()', () => {
    test('returns null', () => {
      createEditor()
      expect(editor.serializeValue()).toBeNull()
    })
  })

  describe('#loadValue()', () => {
    test('re-renders the component', () => {
      createEditor()
      ReactDOM.unmountComponentAtNode($container)
      editor.loadValue(/* SlickGrid API parameters are not used */)
      expect($container.querySelector('.Grid__GradeCell')).toBeTruthy()
    })
  })

  describe('#applyValue()', () => {
    test('calls .applyValue on the component', () => {
      createEditor()
      jest.spyOn(editor.component, 'applyValue')
      editor.applyValue(/* SlickGrid API parameters are not used */)
      expect(editor.component.applyValue).toHaveBeenCalledTimes(1)
    })
  })

  describe('#validate()', () => {
    test('returns an empty validation success', () => {
      // SlickGrid validation is not used.
      // Validation is performed within Gradebook.
      createEditor()
      expect(editor.validate()).toEqual({msg: null, valid: true})
    })
  })
})
