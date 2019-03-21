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

import HideBySections from 'jsx/grading/HideAssignmentGradesTray/HideBySections'

QUnit.module('HideAssignmentGradesTray HideBySections', suiteHooks => {
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

  function getLabel(text) {
    return [...$container.querySelectorAll('label')].find($label => $label.textContent === text)
  }

  function getSectionToggleInput() {
    return document.getElementById(getLabel('Specific Sections').htmlFor)
  }

  function mountComponent() {
    ReactDOM.render(<HideBySections {...context} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    context = {
      assignment: assignmentFixture(),
      hideBySections: false,
      hideBySectionsChanged: () => {},
      sections: [{id: '2001', name: 'Freshmen'}, {id: '2002', name: 'Sophomores'}],
      sectionSelectionChanged: () => {},
      selectedSectionIds: []
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('descriptive text is not shown', () => {
    mountComponent()
    notOk(getAnonymousText())
  })

  test('section toggle is enabled', () => {
    mountComponent()
    strictEqual(getSectionToggleInput().disabled, false)
  })

  test('section toggle is checked when hideBySections is true', () => {
    context.hideBySections = true
    mountComponent()
    ok(
      getSectionToggleInput()
        .getAttributeNames()
        .includes('checked')
    )
  })

  test('sections are shown when hideBySections is true', () => {
    context.hideBySections = true
    mountComponent()
    ok(getLabel('Sophomores'))
  })

  test('clicking the section toggle calls hideBySectionsChanged', () => {
    const hideBySectionsChangedSpy = sinon.spy()
    context.hideBySectionsChanged = hideBySectionsChangedSpy
    mountComponent()
    getSectionToggleInput().click()
    strictEqual(hideBySectionsChangedSpy.callCount, 1)
  })

  test('selecting a section calls sectionSelectionChanged', () => {
    const sectionSelectionChangedSpy = sinon.spy()
    context.hideBySections = true
    context.sectionSelectionChanged = sectionSelectionChangedSpy
    mountComponent()
    document.getElementById(getLabel('Sophomores').htmlFor).click()
    strictEqual(sectionSelectionChangedSpy.callCount, 1)
  })

  QUnit.module('when assignment is anonymized', contextHooks => {
    contextHooks.beforeEach(() => {
      context.assignment.anonymizeStudents = true
    })

    test('anonymous descriptive text is shown', () => {
      mountComponent()
      ok(getAnonymousText())
    })

    test('section toggle is disabled', () => {
      mountComponent()
      strictEqual(getSectionToggleInput().disabled, true)
    })

    test('sections are not shown', () => {
      context.hideBySections = true
      mountComponent()
      notOk(getLabel('Sophomores'))
    })
  })
})
