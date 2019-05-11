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
import ReactDOM from 'react-dom'

import Layout from 'jsx/grading/HideAssignmentGradesTray/Layout'

QUnit.module('HideAssignmentGradesTray Layout', suiteHooks => {
  let $container
  let context

  function assignmentFixture() {
    return {
      anonymizeStudents: false,
      gradesPublished: true,
      id: '2301',
      name: 'Math 1.1'
    }
  }

  function getAnonymousText() {
    const hideText = 'Anonymous assignments cannot be hidden by section.'
    return [...$container.querySelectorAll('p')].find($p => $p.textContent === hideText)
  }

  function getCloseButton() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Close'
    )
  }

  function getHideButton() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Hide'
    )
  }

  function getHideText() {
    const hideText =
      'Hiding grades is not allowed because grades have not been released for this assignment.'
    return [...$container.querySelectorAll('p')].find($p => $p.textContent === hideText)
  }

  function getLabel(text) {
    return [...$container.querySelectorAll('label')].find($label => $label.textContent === text)
  }

  function mountComponent() {
    ReactDOM.render(<Layout {...context} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    context = {
      assignment: assignmentFixture(),
      dismiss: () => {},
      hideBySections: true,
      hideBySectionsChanged: () => {},
      hidingGrades: false,
      onHideClick: () => {},
      sections: [{id: '2001', name: 'Freshmen'}, {id: '2002', name: 'Sophomores'}],
      sectionSelectionChanged: () => {},
      selectedSectionIds: []
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('clicking "Close" button calls the dismiss prop', () => {
    const dismissSpy = sinon.spy()
    context.dismiss = dismissSpy
    mountComponent()
    getCloseButton().click()
    strictEqual(dismissSpy.callCount, 1)
  })

  test('"Hide" button is disabled when grades have yet to be published', () => {
    const unpublishedAssignment = {...assignmentFixture(), gradesPublished: false}
    context.assignment = unpublishedAssignment
    mountComponent()
    strictEqual(getHideButton().disabled, true)
  })

  test('descriptive text exists when grades have yet to be published', () => {
    const unpublishedAssignment = {...assignmentFixture(), gradesPublished: false}
    context.assignment = unpublishedAssignment
    mountComponent()
    ok(getHideText())
  })

  test('"Hide" button is disabled when hidingGrades is true', () => {
    context.hidingGrades = true
    mountComponent()
    strictEqual(getHideButton().disabled, true)
  })

  test('descriptive text does not exist when grades have been published', () => {
    mountComponent()
    notOk(getHideText())
  })

  test('clicking "Hide" button calls the onHideClick prop', () => {
    const onHideClickSpy = sinon.spy()
    context.onHideClick = onHideClickSpy
    mountComponent()
    getHideButton().click()
    strictEqual(onHideClickSpy.callCount, 1)
  })

  QUnit.module('when no sections exist', contextHooks => {
    contextHooks.beforeEach(() => {
      context.sections = []
    })

    test('anonymous descriptive text is not shown', () => {
      context.assignment = {...assignmentFixture(), anonymizeStudents: true}
      mountComponent()
      notOk(getAnonymousText())
    })

    test('section toggle is not shown', () => {
      mountComponent()
      notOk(getLabel('Specific Sections'))
    })

    test('sections are not shown', () => {
      context.hideBySections = false
      mountComponent()
      notOk(getLabel('Sophomores'))
    })
  })
})
