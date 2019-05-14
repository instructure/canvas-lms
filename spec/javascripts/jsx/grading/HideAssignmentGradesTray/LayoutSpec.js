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

  function getHeading() {
    return [...$container.querySelectorAll('h3')].find($heading =>
      $heading.textContent.includes('Hide Grades')
    )
  }

  function getAnonymousText() {
    const hideText = 'Anonymous assignments cannot be hidden by section.'
    return [...$container.querySelectorAll('p')].find($p => $p.textContent === hideText)
  }

  function getDescription() {
    const description =
      'While the grades for this assignment are hidden, students will not receive new notifications about or be able to see:'
    return [...$container.querySelectorAll('p')].find($p => $p.textContent === description)
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

  function getSpinner() {
    return [...$container.querySelectorAll('svg')].find(
      $spinner => $spinner.textContent === 'Hiding grades'
    )
  }

  function getLabel(text) {
    return [...$container.querySelectorAll('label')].find($label => $label.textContent === text)
  }

  function getInputByLabel(label) {
    const $label = getLabel(label)
    if ($label === undefined) return undefined
    return document.getElementById($label.htmlFor)
  }

  function getSpecificSectionToggleInput() {
    return getInputByLabel('Specific Sections')
  }

  function mountComponent() {
    ReactDOM.render(<Layout {...context} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    context = {
      assignment: {
        anonymizeStudents: false,
        gradesPublished: true
      },
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
    sinon.spy(context, 'dismiss')
    mountComponent()
    getCloseButton().click()
    const {
      dismiss: {callCount}
    } = context
    strictEqual(callCount, 1)
  })

  test('clicking "Hide" button calls the onHideClick prop', () => {
    sinon.spy(context, 'onHideClick')
    mountComponent()
    getHideButton().click()
    const {
      onHideClick: {callCount}
    } = context
    strictEqual(callCount, 1)
  })

  QUnit.module('default behavior', mountComponentHooks => {
    mountComponentHooks.beforeEach(() => mountComponent())

    test('heading is present', () => {
      ok(getHeading())
    })

    test('spinner is hidden', () => {
      notOk(getSpinner())
    })

    test('section toggle is present', () => {
      ok(getSpecificSectionToggleInput())
    })

    test('description is present', () => {
      ok(getDescription())
    })

    test('"hide" button is present', () => {
      ok(getHideButton())
    })

    test('close button is present', () => {
      ok(getCloseButton())
    })

    test('anonymous descriptive text is hidden', () => {
      mountComponent()
      notOk(getAnonymousText())
    })
  })

  QUnit.module('given "hidingGrades" prop is true', hidingGradesHooks => {
    hidingGradesHooks.beforeEach(() => {
      context.hidingGrades = true
      mountComponent()
    })

    test('heading is present', () => {
      ok(getHeading())
    })

    test('spinner is present', () => {
      ok(getSpinner())
    })

    test('section toggle hidden', () => {
      notOk(getSpecificSectionToggleInput())
    })

    test('"hide" button is hidden', () => {
      notOk(getHideButton())
    })

    test('close button is hidden', () => {
      notOk(getCloseButton())
    })

    test('anonymous descriptive text is hidden', () => {
      notOk(getAnonymousText())
    })
  })

  QUnit.module('given grades are not published', gradesPublishedHooks => {
    gradesPublishedHooks.beforeEach(() => {
      context.assignment.gradesPublished = false
      mountComponent()
    })

    test('"Specific Section" toggle is disabled', () => {
      strictEqual(getSpecificSectionToggleInput().disabled, true)
    })

    test('"Close" button is disabled', () => {
      strictEqual(getCloseButton().disabled, true)
    })

    test('"Hide" button is disabled', () => {
      strictEqual(getHideButton().disabled, true)
    })

    test('description is present', () => {
      ok(getDescription())
    })
  })

  QUnit.module('when sections are absent', contextHooks => {
    contextHooks.beforeEach(() => {
      context.sections = []
    })

    test('section toggle is not shown', () => {
      mountComponent()
      notOk(getLabel('Specific Sections'))
    })

    test('anonymous descriptive text is shown', () => {
      mountComponent()
      notOk(getAnonymousText())
    })

    test('anonymous descriptive text is not shown', () => {
      context.assignment.anonymizeStudents = true
      mountComponent()
      notOk(getAnonymousText())
    })

    test('sections are not shown', () => {
      context.hideBySections = false
      mountComponent()
      notOk(getLabel('Sophomores'))
    })
  })

  QUnit.module('Anonymous assignments', anonymousAssignmentsHooks => {
    anonymousAssignmentsHooks.beforeEach(() => {
      context.assignment.anonymizeStudents = true
      mountComponent()
    })

    test('anonymous descriptive text is present', () => {
      ok(getAnonymousText())
    })

    test('"Specific Sections" is disabled', () => {
      strictEqual(getSpecificSectionToggleInput().disabled, true)
    })
  })

  QUnit.module('SpecificSections', () => {
    test('enabling "Specific Sections" calls the hideBySectionsChanged prop', () => {
      const spy = sinon.spy(context, 'hideBySectionsChanged')
      mountComponent()
      getSpecificSectionToggleInput().click()
      const {callCount} = spy
      strictEqual(callCount, 1)
    })

    test('selecting "Graded" calls the sectionSelectionChanged prop', () => {
      const spy = sinon.spy(context, 'sectionSelectionChanged')
      mountComponent()
      getSpecificSectionToggleInput().click()
      getInputByLabel('Freshmen').click()
      const {callCount} = spy
      strictEqual(callCount, 1)
    })
  })
})
