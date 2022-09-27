/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import StudentFirstNameColumnHeader from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/StudentFirstNameColumnHeader'
import StudentFirstNameColumnHeaderRenderer from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/StudentFirstNameColumnHeaderRenderer'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid StudentFirstNameColumnHeaderRenderer', suiteHooks => {
  let $container
  let gradebook
  let renderer
  let component

  function render() {
    renderer.render(
      {} /* column */,
      $container,
      {} /* gridSupport */,
      {
        ref(ref) {
          component = ref
        },
      }
    )
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    setFixtureHtml($container)

    gradebook = createGradebook({
      login_handle_name: 'a_jones',
      sis_name: 'Example SIS',
    })
    sinon.stub(gradebook, 'saveSettings')
    renderer = new StudentFirstNameColumnHeaderRenderer(gradebook)
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  QUnit.module('#render()', () => {
    test('renders the StudentFirstNameColumnHeader to the given container node', () => {
      render()
      ok(
        $container.innerText.includes('Student First Name'),
        'the "Student First Name" header is rendered'
      )
    })

    test('calls the "ref" callback option with the component reference', () => {
      render()
      equal(component.constructor.name, 'StudentFirstNameColumnHeader')
    })

    test('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement')
      render()
      component.props.addGradebookElement()
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1)
    })

    test('sets the component as disabled when students are not loaded', () => {
      gradebook.setStudentsLoaded(false)
      render()
      strictEqual(component.props.disabled, true)
    })

    test('sets the component as not disabled when students are loaded', () => {
      gradebook.setStudentsLoaded(true)
      render()
      strictEqual(component.props.disabled, false)
    })

    test('includes a callback for keyDown events', () => {
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      strictEqual(gradebook.handleHeaderKeyDown.callCount, 1)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      const exampleEvent = new Event('example')
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown(exampleEvent)
      const event = gradebook.handleHeaderKeyDown.lastCall.args[0]
      equal(event, exampleEvent)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      const columnId = gradebook.handleHeaderKeyDown.lastCall.args[1]
      equal(columnId, 'student_firstname')
    })

    test('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement')
      render()
      component.props.removeGradebookElement()
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1)
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the component', () => {
      render()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      strictEqual(removed, false, 'the component was already unmounted')
    })
  })
})
/* eslint-enable qunit/no-identical-names */
