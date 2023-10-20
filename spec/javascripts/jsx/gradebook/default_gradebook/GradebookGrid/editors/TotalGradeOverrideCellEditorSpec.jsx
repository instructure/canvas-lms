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

import TotalGradeOverrideCellPropFactory from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/TotalGradeOverrideCellEditor/TotalGradeOverrideCellPropFactory'
import TotalGradeOverrideCellEditor from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/TotalGradeOverrideCellEditor/index'
import GridEvent from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/GridSupport/GridEvent'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('GradebookGrid TotalGradeOverrideCellEditor', suiteHooks => {
  let $container
  let editor
  let editorOptions
  let gradebook
  let gridSupport

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    gridSupport = {
      events: {
        onKeyDown: new GridEvent(),
      },
    }

    gradebook = createGradebook({final_grade_override_enabled: true})
    sinon.stub(gradebook, 'isStudentGradeable').returns(true)
    sinon.stub(gradebook, 'studentHasGradedSubmission').returns(true)

    editorOptions = {
      column: {
        getGridSupport() {
          return gridSupport
        },

        propFactory: new TotalGradeOverrideCellPropFactory(gradebook),
      },

      container: $container,
      item: {id: '1101'},
    }
  })

  suiteHooks.afterEach(() => {
    if ($container.childNodes.length > 0) {
      editor.destroy()
    }
    $container.remove()
  })

  function createEditor() {
    editor = new TotalGradeOverrideCellEditor(editorOptions)
  }

  QUnit.module('initialization', () => {
    test('renders an editable cell when the student is gradeable', () => {
      createEditor()
      notOk($container.querySelector('.Grid__ReadOnlyCell'))
    })

    test('renders a read-only cell when the student is not gradeable', () => {
      gradebook.isStudentGradeable.withArgs('1101').returns(false)
      createEditor()
      ok($container.querySelector('.Grid__ReadOnlyCell'))
    })

    test('renders a read-only cell when the student has no graded submissions', () => {
      gradebook.studentHasGradedSubmission.withArgs('1101').returns(false)
      createEditor()
      ok($container.querySelector('.Grid__ReadOnlyCell'))
    })

    test('stores a reference to the rendered component', () => {
      createEditor()
      ok(editor.component instanceof React.Component)
    })
  })

  QUnit.module('"onKeyDown" event', () => {
    test('calls .handleKeyDown on the component when triggered', () => {
      createEditor()
      sinon.spy(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      strictEqual(editor.component.handleKeyDown.callCount, 1)
    })

    test('passes the event when calling handleKeyDown', () => {
      createEditor()
      sinon.spy(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      const [event] = editor.component.handleKeyDown.lastCall.args
      strictEqual(event, keyboardEvent)
    })

    test('returns the return value from the component', () => {
      createEditor()
      sinon.stub(editor.component, 'handleKeyDown').returns(false)
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      strictEqual(returnValue, false)
    })

    test('calls .handleKeyDown on the ReadOnlyCell component when the student is not gradeable', () => {
      gradebook.isStudentGradeable.returns(false)
      createEditor()
      sinon.spy(editor.component, 'handleKeyDown')
      const keyboardEvent = new KeyboardEvent('example')
      gridSupport.events.onKeyDown.trigger(keyboardEvent)
      strictEqual(editor.component.handleKeyDown.callCount, 1)
    })
  })

  QUnit.module('#destroy()', () => {
    test('removes the reference to the component', () => {
      createEditor()
      editor.destroy()
      strictEqual(editor.component, null)
    })

    test('unsubscribes from gridSupport.events.onKeyDown', () => {
      createEditor()
      editor.destroy()
      const keyboardEvent = new KeyboardEvent('example')
      const returnValue = gridSupport.events.onKeyDown.trigger(keyboardEvent)
      strictEqual(
        returnValue,
        true,
        '"true" is the default return value when the event has no subscribers'
      )
    })

    test('unmounts the component', () => {
      createEditor()
      editor.destroy()
      const unmounted = ReactDOM.unmountComponentAtNode($container)
      strictEqual(unmounted, false, 'component was already unmounted')
    })
  })

  QUnit.module('#focus()', () => {
    test('calls .focus on the component', () => {
      createEditor()
      sinon.spy(editor.component, 'focus')
      editor.focus()
      strictEqual(editor.component.focus.callCount, 1)
    })

    test('calls .focus on the ReadOnlyCell component when the student is not gradeable', () => {
      gradebook.isStudentGradeable.returns(false)
      createEditor()
      sinon.spy(editor.component, 'focus')
      editor.focus()
      strictEqual(editor.component.focus.callCount, 1)
    })
  })

  QUnit.module('#isValueChanged()', () => {
    test('returns the result of calling .isValueChanged on the component', () => {
      createEditor()
      sinon.stub(editor.component, 'isValueChanged').returns(true)
      strictEqual(editor.isValueChanged(), true)
    })

    test('calls .isValueChanged on the ReadOnlyCell component when the student is not gradeable', () => {
      gradebook.isStudentGradeable.returns(false)
      createEditor()
      sinon.stub(editor.component, 'isValueChanged').returns(true)
      strictEqual(editor.isValueChanged(), true)
    })

    test('returns false when the component has not yet rendered', () => {
      createEditor()
      editor.component = null
      strictEqual(editor.isValueChanged(), false)
    })
  })

  QUnit.module('#serializeValue()', () => {
    test('returns null', () => {
      createEditor()
      strictEqual(editor.serializeValue(), null)
    })
  })

  QUnit.module('#loadValue()', () => {
    test('re-renders the component', () => {
      createEditor()
      ReactDOM.unmountComponentAtNode($container)
      editor.loadValue(/* SlickGrid API parameters are not used */)
      ok($container.querySelector('.Grid__GradeCell'))
    })
  })

  QUnit.module('#applyValue()', () => {
    test('calls .applyValue on the component', () => {
      createEditor()
      sinon.stub(editor.component, 'applyValue')
      editor.applyValue(/* SlickGrid API parameters are not used */)
      strictEqual(editor.component.applyValue.callCount, 1)
    })
  })

  QUnit.module('#validate()', () => {
    test('returns an empty validation success', () => {
      // SlickGrid validation is not used.
      // Validation is performed within Gradebook.
      createEditor()
      deepEqual(editor.validate(), {msg: null, valid: true})
    })
  })
})
