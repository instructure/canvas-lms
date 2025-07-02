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

import ReactDOM from 'react-dom'
import AssignmentRowCellPropFactory from '../AssignmentRowCellPropFactory'
import AssignmentCellEditor from '../index'
import GridEvent from '../../../GridSupport/GridEvent'
import {createGradebook} from '../../../../__tests__/GradebookSpecHelper'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('GradebookGrid AssignmentCellEditor', () => {
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport
  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    $container = document.createElement('div')
    document.body.appendChild($container)

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    const assignment = {grading_type: 'points', id: '2301', points_possible: 10}
    gradebook = createGradebook()

    gradebook.students['1101'] = {id: '1101'}
    gradebook.setAssignments({2301: assignment})
    gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: '7.8',
      entered_score: 7.8,
      excused: false,
      id: '2501',
      user_id: '1101',
    })

    jest
      .spyOn(gradebook, 'isGradeEditable')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )
    jest
      .spyOn(gradebook, 'isGradeVisible')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )

    editorOptions = {
      column: {
        assignmentId: '2301',
        field: 'assignment_2301',
        getGridSupport() {
          return gridSupport
        },
        object: assignment,
        propFactory: new AssignmentRowCellPropFactory(gradebook),
      },
      grid: {
        onKeyDown: {
          subscribe() {},
          unsubscribe() {},
        },
      },
      item: {
        // student row object
        id: '1101',
        assignment_2301: {
          // submission
          user_id: '1101',
        },
      },
    }
  })

  afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  const createEditor = () => {
    editor = new AssignmentCellEditor({...editorOptions, container: $container})
  }

  describe('initialization', () => {
    beforeEach(() => {
      jest.spyOn(ReactDOM, 'render')
    })

    afterEach(() => {
      ReactDOM.render.mockRestore()
    })

    test('renders with React', () => {
      createEditor()
      expect(ReactDOM.render).toHaveBeenCalledTimes(1)
    })

    test('renders an AssignmentRowCell', () => {
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('AssignmentRowCell')
    })

    test('renders a ReadOnlyCell when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('ReadOnlyCell')
    })

    test('renders into the given container', () => {
      createEditor()
      const [, container] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(container).toBe($container)
    })

    test('stores a reference to the rendered AssignmentRowCell component', () => {
      createEditor()
      expect(editor.component.constructor.name).toBe('AssignmentRowCell')
    })

    test('includes editor options in AssignmentRowCell props', () => {
      createEditor()
      expect(editor.component.props.editorOptions).toEqual(editor.options)
    })
  })

  describe('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the AssignmentRowCell component when triggered', () => {
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
      const [event] =
        editor.component.handleKeyDown.mock.calls[
          editor.component.handleKeyDown.mock.calls.length - 1
        ]
      expect(event).toBe(keyboardEvent)
    })

    test('returns the return value from the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown').mockReturnValue(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    test('removes the reference to the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      expect(editor.component).toBeNull()
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(true) // "true" is the default return value when the event has no subscribers
    })

    test('unmounts the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      expect(unmounted).toBe(false) // component was already unmounted
    })
  })

  describe('#focus()', () => {
    test('calls .focus on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })

    test('calls .focus on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
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
    test('renders the component', () => {
      createEditor()
      jest.spyOn(editor, 'renderComponent').mockImplementation(() => {})
      editor.loadValue()
      expect(editor.renderComponent).toHaveBeenCalledTimes(1)
    })
  })

  describe('#applyValue()', () => {
    test('calls .gradeSubmission on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('calls .gradeSubmission on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('includes the given item when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [item] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(item).toEqual({id: '1101'})
    })

    test('includes the given value when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [, value] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(value).toBe('9.7')
    })
  })

  describe('#validate()', () => {
    test('returns an empty validation success', () => {
      createEditor()
      expect(editor.validate()).toEqual({msg: null, valid: true})
    })
  })
})

describe('GradebookGrid AssignmentCellEditor', () => {
  // Nested describe blocks for better organization
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport
  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    $container = document.createElement('div')
    document.body.appendChild($container)

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    const assignment = {grading_type: 'points', id: '2301', points_possible: 10}
    gradebook = createGradebook()

    gradebook.students['1101'] = {id: '1101'}
    gradebook.setAssignments({2301: assignment})
    gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: '7.8',
      entered_score: 7.8,
      excused: false,
      id: '2501',
      user_id: '1101',
    })

    jest
      .spyOn(gradebook, 'isGradeEditable')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )
    jest
      .spyOn(gradebook, 'isGradeVisible')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )

    editorOptions = {
      column: {
        assignmentId: '2301',
        field: 'assignment_2301',
        getGridSupport() {
          return gridSupport
        },
        object: assignment,
        propFactory: new AssignmentRowCellPropFactory(gradebook),
      },
      grid: {
        onKeyDown: {
          subscribe() {},
          unsubscribe() {},
        },
      },
      item: {
        // student row object
        id: '1101',
        assignment_2301: {
          // submission
          user_id: '1101',
        },
      },
    }
  })

  afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  const createEditor = () => {
    editor = new AssignmentCellEditor({...editorOptions, container: $container})
  }

  const teacherNotesColumn = () =>
    gradebook.gradebookContent.customColumns
      .filter(column => !column.hidden)
      .find(column => column.id === '9999')

  describe('initialization', () => {
    beforeEach(() => {
      jest.spyOn(ReactDOM, 'render')
    })

    afterEach(() => {
      ReactDOM.render.mockRestore()
    })

    test('renders with React', () => {
      createEditor()
      expect(ReactDOM.render).toHaveBeenCalledTimes(1)
    })

    test('renders an AssignmentRowCell', () => {
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('AssignmentRowCell')
    })

    test('renders a ReadOnlyCell when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('ReadOnlyCell')
    })

    test('renders into the given container', () => {
      createEditor()
      const [, container] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(container).toBe($container)
    })

    test('stores a reference to the rendered AssignmentRowCell component', () => {
      createEditor()
      expect(editor.component.constructor.name).toBe('AssignmentRowCell')
    })

    test('includes editor options in AssignmentRowCell props', () => {
      createEditor()
      expect(editor.component.props.editorOptions).toEqual(editor.options)
    })
  })

  describe('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the AssignmentRowCell component when triggered', () => {
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
      const [event] =
        editor.component.handleKeyDown.mock.calls[
          editor.component.handleKeyDown.mock.calls.length - 1
        ]
      expect(event).toBe(keyboardEvent)
    })

    test('returns the return value from the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown').mockReturnValue(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    test('removes the reference to the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      expect(editor.component).toBeNull()
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(true) // "true" is the default return value when the event has no subscribers
    })

    test('unmounts the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      expect(unmounted).toBe(false) // component was already unmounted
    })
  })

  describe('#focus()', () => {
    test('calls .focus on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })

    test('calls .focus on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
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
    test('renders the component', () => {
      createEditor()
      jest.spyOn(editor, 'renderComponent').mockImplementation(() => {})
      editor.loadValue()
      expect(editor.renderComponent).toHaveBeenCalledTimes(1)
    })
  })

  describe('#applyValue()', () => {
    test('calls .gradeSubmission on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('calls .gradeSubmission on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('includes the given item when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [item] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(item).toEqual({id: '1101'})
    })

    test('includes the given value when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [, value] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(value).toBe('9.7')
    })
  })

  describe('#validate()', () => {
    test('returns an empty validation success', () => {
      createEditor()
      expect(editor.validate()).toEqual({msg: null, valid: true})
    })
  })
})

describe('GradebookGrid AssignmentCellEditor', () => {
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport
  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    $container = document.createElement('div')
    document.body.appendChild($container)

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    const assignment = {grading_type: 'points', id: '2301', points_possible: 10}
    gradebook = createGradebook()

    gradebook.students['1101'] = {id: '1101'}
    gradebook.setAssignments({2301: assignment})
    gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: '7.8',
      entered_score: 7.8,
      excused: false,
      id: '2501',
      user_id: '1101',
    })

    jest
      .spyOn(gradebook, 'isGradeEditable')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )
    jest
      .spyOn(gradebook, 'isGradeVisible')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )

    editorOptions = {
      column: {
        assignmentId: '2301',
        field: 'assignment_2301',
        getGridSupport() {
          return gridSupport
        },
        object: assignment,
        propFactory: new AssignmentRowCellPropFactory(gradebook),
      },
      grid: {
        onKeyDown: {
          subscribe() {},
          unsubscribe() {},
        },
      },
      item: {
        // student row object
        id: '1101',
        assignment_2301: {
          // submission
          user_id: '1101',
        },
      },
    }
  })

  afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  const createEditor = () => {
    editor = new AssignmentCellEditor({...editorOptions, container: $container})
  }

  const teacherNotesColumn = () =>
    gradebook.gradebookContent.customColumns
      .filter(column => !column.hidden)
      .find(column => column.id === '9999')

  describe('initialization', () => {
    beforeEach(() => {
      jest.spyOn(ReactDOM, 'render')
    })

    afterEach(() => {
      ReactDOM.render.mockRestore()
    })

    test('renders with React', () => {
      createEditor()
      expect(ReactDOM.render).toHaveBeenCalledTimes(1)
    })

    test('renders an AssignmentRowCell', () => {
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('AssignmentRowCell')
    })

    test('renders a ReadOnlyCell when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('ReadOnlyCell')
    })

    test('renders into the given container', () => {
      createEditor()
      const [, container] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(container).toBe($container)
    })

    test('stores a reference to the rendered AssignmentRowCell component', () => {
      createEditor()
      expect(editor.component.constructor.name).toBe('AssignmentRowCell')
    })

    test('includes editor options in AssignmentRowCell props', () => {
      createEditor()
      expect(editor.component.props.editorOptions).toEqual(editor.options)
    })
  })

  describe('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the AssignmentRowCell component when triggered', () => {
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
      const [event] =
        editor.component.handleKeyDown.mock.calls[
          editor.component.handleKeyDown.mock.calls.length - 1
        ]
      expect(event).toBe(keyboardEvent)
    })

    test('returns the return value from the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown').mockReturnValue(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    test('removes the reference to the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      expect(editor.component).toBeNull()
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(true) // "true" is the default return value when the event has no subscribers
    })

    test('unmounts the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      expect(unmounted).toBe(false) // component was already unmounted
    })
  })

  describe('#focus()', () => {
    test('calls .focus on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })

    test('calls .focus on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
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
    test('renders the component', () => {
      createEditor()
      jest.spyOn(editor, 'renderComponent').mockImplementation(() => {})
      editor.loadValue()
      expect(editor.renderComponent).toHaveBeenCalledTimes(1)
    })
  })

  describe('#applyValue()', () => {
    test('calls .gradeSubmission on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('calls .gradeSubmission on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('includes the given item when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [item] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(item).toEqual({id: '1101'})
    })

    test('includes the given value when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [, value] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(value).toBe('9.7')
    })
  })

  describe('#validate()', () => {
    test('returns an empty validation success', () => {
      createEditor()
      expect(editor.validate()).toEqual({msg: null, valid: true})
    })
  })
})

describe('GradebookGrid AssignmentCellEditor', () => {
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport
  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    $container = document.createElement('div')
    document.body.appendChild($container)

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    const assignment = {grading_type: 'points', id: '2301', points_possible: 10}
    gradebook = createGradebook()

    gradebook.students['1101'] = {id: '1101'}
    gradebook.setAssignments({2301: assignment})
    gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: '7.8',
      entered_score: 7.8,
      excused: false,
      id: '2501',
      user_id: '1101',
    })

    jest
      .spyOn(gradebook, 'isGradeEditable')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )
    jest
      .spyOn(gradebook, 'isGradeVisible')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )

    editorOptions = {
      column: {
        assignmentId: '2301',
        field: 'assignment_2301',
        getGridSupport() {
          return gridSupport
        },
        object: assignment,
        propFactory: new AssignmentRowCellPropFactory(gradebook),
      },
      grid: {
        onKeyDown: {
          subscribe() {},
          unsubscribe() {},
        },
      },
      item: {
        // student row object
        id: '1101',
        assignment_2301: {
          // submission
          user_id: '1101',
        },
      },
    }
  })

  afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  const createEditor = () => {
    editor = new AssignmentCellEditor({...editorOptions, container: $container})
  }

  const teacherNotesColumn = () =>
    gradebook.gradebookContent.customColumns
      .filter(column => !column.hidden)
      .find(column => column.id === '9999')

  describe('initialization', () => {
    beforeEach(() => {
      jest.spyOn(ReactDOM, 'render')
    })

    afterEach(() => {
      ReactDOM.render.mockRestore()
    })

    test('renders with React', () => {
      createEditor()
      expect(ReactDOM.render).toHaveBeenCalledTimes(1)
    })

    test('renders an AssignmentRowCell', () => {
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('AssignmentRowCell')
    })

    test('renders a ReadOnlyCell when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('ReadOnlyCell')
    })

    test('renders into the given container', () => {
      createEditor()
      const [, container] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(container).toBe($container)
    })

    test('stores a reference to the rendered AssignmentRowCell component', () => {
      createEditor()
      expect(editor.component.constructor.name).toBe('AssignmentRowCell')
    })

    test('includes editor options in AssignmentRowCell props', () => {
      createEditor()
      expect(editor.component.props.editorOptions).toEqual(editor.options)
    })
  })

  describe('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the AssignmentRowCell component when triggered', () => {
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
      const [event] =
        editor.component.handleKeyDown.mock.calls[
          editor.component.handleKeyDown.mock.calls.length - 1
        ]
      expect(event).toBe(keyboardEvent)
    })

    test('returns the return value from the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown').mockReturnValue(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    test('removes the reference to the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      expect(editor.component).toBeNull()
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(true) // "true" is the default return value when the event has no subscribers
    })

    test('unmounts the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      expect(unmounted).toBe(false) // component was already unmounted
    })
  })

  describe('#focus()', () => {
    test('calls .focus on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })

    test('calls .focus on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
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
    test('renders the component', () => {
      createEditor()
      jest.spyOn(editor, 'renderComponent').mockImplementation(() => {})
      editor.loadValue()
      expect(editor.renderComponent).toHaveBeenCalledTimes(1)
    })
  })

  describe('#applyValue()', () => {
    test('calls .gradeSubmission on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('calls .gradeSubmission on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('includes the given item when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [item] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(item).toEqual({id: '1101'})
    })

    test('includes the given value when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [, value] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(value).toBe('9.7')
    })
  })

  describe('#validate()', () => {
    test('returns an empty validation success', () => {
      createEditor()
      expect(editor.validate()).toEqual({msg: null, valid: true})
    })
  })
})

describe('GradebookGrid AssignmentCellEditor', () => {
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport
  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    $container = document.createElement('div')
    document.body.appendChild($container)

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    const assignment = {grading_type: 'points', id: '2301', points_possible: 10}
    gradebook = createGradebook()

    gradebook.students['1101'] = {id: '1101'}
    gradebook.setAssignments({2301: assignment})
    gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: '7.8',
      entered_score: 7.8,
      excused: false,
      id: '2501',
      user_id: '1101',
    })

    jest
      .spyOn(gradebook, 'isGradeEditable')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )
    jest
      .spyOn(gradebook, 'isGradeVisible')
      .mockImplementation(
        (studentId, assignmentId) => studentId === '1101' && assignmentId === '2301',
      )

    editorOptions = {
      column: {
        assignmentId: '2301',
        field: 'assignment_2301',
        getGridSupport() {
          return gridSupport
        },
        object: assignment,
        propFactory: new AssignmentRowCellPropFactory(gradebook),
      },
      grid: {
        onKeyDown: {
          subscribe() {},
          unsubscribe() {},
        },
      },
      item: {
        // student row object
        id: '1101',
        assignment_2301: {
          // submission
          user_id: '1101',
        },
      },
    }
  })

  afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  const createEditor = () => {
    editor = new AssignmentCellEditor({...editorOptions, container: $container})
  }

  const teacherNotesColumn = () =>
    gradebook.gradebookContent.customColumns
      .filter(column => !column.hidden)
      .find(column => column.id === '9999')

  describe('initialization', () => {
    beforeEach(() => {
      jest.spyOn(ReactDOM, 'render')
    })

    afterEach(() => {
      ReactDOM.render.mockRestore()
    })

    test('renders with React', () => {
      createEditor()
      expect(ReactDOM.render).toHaveBeenCalledTimes(1)
    })

    test('renders an AssignmentRowCell', () => {
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('AssignmentRowCell')
    })

    test('renders a ReadOnlyCell when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      const [element] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(element.type.name).toBe('ReadOnlyCell')
    })

    test('renders into the given container', () => {
      createEditor()
      const [, container] = ReactDOM.render.mock.calls[ReactDOM.render.mock.calls.length - 1]
      expect(container).toBe($container)
    })

    test('stores a reference to the rendered AssignmentRowCell component', () => {
      createEditor()
      expect(editor.component.constructor.name).toBe('AssignmentRowCell')
    })

    test('includes editor options in AssignmentRowCell props', () => {
      createEditor()
      expect(editor.component.props.editorOptions).toEqual(editor.options)
    })
  })

  describe('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the AssignmentRowCell component when triggered', () => {
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
      const [event] =
        editor.component.handleKeyDown.mock.calls[
          editor.component.handleKeyDown.mock.calls.length - 1
        ]
      expect(event).toBe(keyboardEvent)
    })

    test('returns the return value from the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown').mockReturnValue(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(editor.component.handleKeyDown).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    test('removes the reference to the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      expect(editor.component).toBeNull()
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      expect(returnValue).toBe(true) // "true" is the default return value when the event has no subscribers
    })

    test('unmounts the AssignmentRowCell component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      expect(unmounted).toBe(false) // component was already unmounted
    })
  })

  describe('#focus()', () => {
    test('calls .focus on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })

    test('calls .focus on the ReadOnlyCell component when grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'focus')
      editor.focus()
      expect(editor.component.focus).toHaveBeenCalledTimes(1)
    })
  })

  describe('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'isValueChanged').mockReturnValue(true)
      expect(editor.isValueChanged()).toBe(true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
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
    test('renders the component', () => {
      createEditor()
      jest.spyOn(editor, 'renderComponent').mockImplementation(() => {})
      editor.loadValue()
      expect(editor.renderComponent).toHaveBeenCalledTimes(1)
    })
  })

  describe('#applyValue()', () => {
    test('calls .gradeSubmission on the AssignmentRowCell component', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('calls .gradeSubmission on the ReadOnlyCell component when the grade is not editable', () => {
      gradebook.isGradeEditable.mockReturnValue(false)
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      expect(editor.component.gradeSubmission).toHaveBeenCalledTimes(1)
    })

    test('includes the given item when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [item] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(item).toEqual({id: '1101'})
    })

    test('includes the given value when applying the value', () => {
      createEditor()
      jest.spyOn(editor.component, 'gradeSubmission').mockImplementation(() => {})
      editor.applyValue({id: '1101'}, '9.7')
      const [, value] =
        editor.component.gradeSubmission.mock.calls[
          editor.component.gradeSubmission.mock.calls.length - 1
        ]
      expect(value).toBe('9.7')
    })
  })

  describe('#validate()', () => {
    test('returns an empty validation success', () => {
      createEditor()
      expect(editor.validate()).toEqual({msg: null, valid: true})
    })
  })
})
