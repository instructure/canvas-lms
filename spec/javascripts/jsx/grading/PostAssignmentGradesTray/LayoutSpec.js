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

import Layout from 'jsx/grading/PostAssignmentGradesTray/Layout'
import {EVERYONE} from 'jsx/grading/PostAssignmentGradesTray/PostTypes'

QUnit.module('PostAssignmentGradesTray Layout', suiteHooks => {
  let $container
  let context

  function getHeading() {
    return [...$container.querySelectorAll('h3')].find($heading =>
      $heading.textContent.includes('Post Grades')
    )
  }

  function getAnonymousText() {
    const postText = 'Anonymous assignments cannot be posted by section.'
    return [...$container.querySelectorAll('p')].find($p => $p.textContent === postText)
  }

  function getCloseButton() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Close'
    )
  }

  function getLabel(text) {
    return [...$container.querySelectorAll('label')].find($label =>
      $label.textContent.includes(text)
    )
  }

  function getInputByLabel(label) {
    const $label = getLabel(label)
    if ($label === undefined) return undefined
    return document.getElementById($label.htmlFor)
  }

  function getSpecificSectionToggleInput() {
    return getInputByLabel('Specific Sections')
  }

  function getPostTypeInputs() {
    const postText = 'Select whether to post for all submissions, or only graded ones.'
    const $postTypeFieldSet = [...$container.querySelectorAll('fieldset')].find(
      $fieldset => $fieldset.querySelector('legend').textContent === postText
    )
    if ($postTypeFieldSet === undefined) return undefined
    return [...$postTypeFieldSet.querySelectorAll('input[type=radio]')]
  }

  function getPostButton() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Post'
    )
  }

  function getUnpostedCount() {
    return getUnpostedSummary().querySelector('[id^="Badge__"]')
  }

  function getUnpostedHiddenText() {
    return [...getUnpostedSummary().querySelectorAll('*')].find($el => $el.textContent === 'Hidden')
  }

  function getUnpostedSummary() {
    return document.getElementById('PostAssignmentGradesTray__Layout__UnpostedSummary')
  }

  function getPostText() {
    const postText =
      'Posting grades is not allowed because grades have not been released for this assignment.'
    return [...$container.querySelectorAll('p')].find($p => $p.textContent === postText)
  }

  function getSpinner() {
    return [...$container.querySelectorAll('svg')].find(
      $spinner => $spinner.textContent === 'Posting grades'
    )
  }

  function getPostType(type) {
    return document.getElementById(getLabel(type).htmlFor)
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
      postBySections: true,
      postBySectionsChanged: () => {},
      postingGrades: false,
      postType: EVERYONE,
      postTypeChanged: () => {},
      onPostClick: () => {},
      sections: [{id: '2001', name: 'Freshmen'}, {id: '2002', name: 'Sophomores'}],
      sectionSelectionChanged: () => {},
      selectedSectionIds: [],
      unpostedCount: 0
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

  test('clicking "Post" button calls the onPostClick prop', () => {
    sinon.spy(context, 'onPostClick')
    mountComponent()
    getPostButton().click()
    const {
      onPostClick: {callCount}
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

    test('"post" button is present', () => {
      ok(getPostButton())
    })

    test('close button is present', () => {
      ok(getCloseButton())
    })

    test('descriptive text is hidden', () => {
      notOk(getPostText())
    })

    test('anonymous descriptive text is hidden', () => {
      notOk(getAnonymousText())
    })

    test('"Post types" inputs are enabled', () => {
      strictEqual(getPostTypeInputs().every($input => !$input.disabled), true)
    })

    test('a summary of unposted submissions is not displayed', () => {
      notOk(getUnpostedSummary())
    })
  })

  QUnit.module('given "postingGrades" prop is true', postingGradesHooks => {
    postingGradesHooks.beforeEach(() => {
      context.postingGrades = true
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

    test('"post" button is hidden', () => {
      notOk(getPostButton())
    })

    test('close button is hidden', () => {
      notOk(getCloseButton())
    })

    test('descriptive text is hidden', () => {
      notOk(getPostText())
    })

    test('anonymous descriptive text is hidden', () => {
      notOk(getAnonymousText())
    })

    test('"Post types" inputs are hidden', () => {
      notOk(getPostTypeInputs())
    })
  })

  QUnit.module('given grades are not published', gradesPublishedHooks => {
    gradesPublishedHooks.beforeEach(() => {
      context.assignment.gradesPublished = false
      mountComponent()
    })

    test('"Post types" inputs are disabled', () => {
      strictEqual(getPostTypeInputs().every($input => $input.disabled), true)
    })

    test('"Specific Section" toggle is disabled', () => {
      strictEqual(getSpecificSectionToggleInput().disabled, true)
    })

    test('"Close" button is disabled', () => {
      strictEqual(getCloseButton().disabled, true)
    })

    test('"Post" button is disabled', () => {
      strictEqual(getPostButton().disabled, true)
    })

    test('descriptive text is present', () => {
      ok(getPostText())
    })
  })

  QUnit.module('when some submissions are unposted', () => {
    test('a summary of unposted submissions is displayed', () => {
      context.unpostedCount = 1
      mountComponent()
      ok(getUnpostedSummary())
    })

    test('the number of unposted submissions is displayed', () => {
      context.unpostedCount = 2
      mountComponent()
      strictEqual(getUnpostedCount().textContent, '2')
    })

    test('text describing the number of unposted submissions is displayed', () => {
      context.unpostedCount = 1
      mountComponent()
      ok(getUnpostedHiddenText())
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

    test('anonymous descriptive text is hidden', () => {
      mountComponent()
      notOk(getAnonymousText())
    })

    test('anonymous descriptive text is hidden when assignment is anonymous', () => {
      context.assignment.anonymizeStudents = true
      mountComponent()
      notOk(getAnonymousText())
    })

    test('sections are not shown when postBySections is false', () => {
      context.postBySections = false
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

  QUnit.module('PostTypes', () => {
    test('"Everyone" is checked by default', () => {
      mountComponent()
      strictEqual(getPostType('Everyone').checked, true)
    })

    test('clicking another post type calls postTypeChanged', () => {
      sinon.spy(context, 'postTypeChanged')
      mountComponent()
      getPostType('Graded').click()
      const {
        postTypeChanged: {callCount}
      } = context
      strictEqual(callCount, 1)
    })
  })

  QUnit.module('SpecificSections', () => {
    test('enabling "Specific Sections" calls the postBySectionsChanged prop', () => {
      const spy = sinon.spy(context, 'postBySectionsChanged')
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
