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

import FormContent from '@canvas/post-assignment-grades-tray/react/FormContent'
import {EVERYONE} from '@canvas/post-assignment-grades-tray/react/PostTypes'

QUnit.module('PostAssignmentGradesTray FormContent', suiteHooks => {
  let $container

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

  function getSpinner() {
    return [...$container.querySelectorAll('svg')].find(
      $spinner => $spinner.textContent === 'Posting grades'
    )
  }

  function getPostType(type) {
    return document.getElementById(getLabel(type).htmlFor)
  }

  function formContentProps({assignment, ...props} = {}) {
    return {
      assignment: {
        anonymousGrading: false,
        gradesPublished: true,
        ...assignment,
      },
      dismiss() {},
      postBySections: true,
      postBySectionsChanged() {},
      postingGrades: false,
      postType: EVERYONE,
      postTypeChanged() {},
      onPostClick() {},
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
      sectionSelectionChanged() {},
      selectedSectionIds: [],
      unpostedCount: 0,
      ...props,
    }
  }

  function mountComponent(props = {}) {
    ReactDOM.render(<FormContent {...formContentProps(props)} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('clicking "Close" button calls the dismiss prop', () => {
    const dismiss = sinon.spy()
    mountComponent({dismiss})
    getCloseButton().click()
    const {callCount} = dismiss
    strictEqual(callCount, 1)
  })

  test('clicking "Post" button calls the onPostClick prop', () => {
    const onPostClick = sinon.spy()
    mountComponent({onPostClick})
    getPostButton().click()
    const {callCount} = onPostClick
    strictEqual(callCount, 1)
  })

  QUnit.module('default behavior', mountComponentHooks => {
    mountComponentHooks.beforeEach(() => mountComponent())

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

    test('"Post types" inputs are enabled', () => {
      strictEqual(
        getPostTypeInputs().every($input => !$input.disabled),
        true
      )
    })

    test('a summary of unposted submissions is not displayed', () => {
      notOk(getUnpostedSummary())
    })
  })

  QUnit.module('given "postingGrades" prop is true', postingGradesHooks => {
    postingGradesHooks.beforeEach(() => {
      mountComponent({postingGrades: true})
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

    test('"Post types" inputs are hidden', () => {
      notOk(getPostTypeInputs())
    })
  })

  QUnit.module('given grades are not published', gradesPublishedHooks => {
    gradesPublishedHooks.beforeEach(() => {
      mountComponent({assignment: {gradesPublished: false}})
    })

    test('"Post types" inputs are disabled', () => {
      strictEqual(
        getPostTypeInputs().every($input => $input.disabled),
        true
      )
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
  })

  QUnit.module('when some submissions are unposted', () => {
    test('a summary of unposted submissions is displayed', () => {
      mountComponent({unpostedCount: 1})
      ok(getUnpostedSummary())
    })

    test('the number of unposted submissions is displayed', () => {
      mountComponent({unpostedCount: 2})
      strictEqual(getUnpostedCount().textContent, '2')
    })

    test('text describing the number of unposted submissions is displayed', () => {
      mountComponent({unpostedCount: 1})
      ok(getUnpostedHiddenText())
    })

    test('the accessible message is present', () => {
      mountComponent({unpostedCount: 2})
      strictEqual(getUnpostedSummary().textContent.includes('2 hidden'), true)
    })

    test('the displayed context has aria-hidden set to true', () => {
      mountComponent({unpostedCount: 2})
      const {textContent} = getUnpostedSummary().querySelectorAll('[aria-hidden="true"]')[0]
      strictEqual(textContent, 'Hidden2')
    })
  })

  QUnit.module('when sections are absent', () => {
    test('section toggle is not shown', () => {
      mountComponent({sections: []})
      notOk(getLabel('Specific Sections'))
    })

    test('sections are not shown when postBySections is false', () => {
      mountComponent({sections: [], postBySections: false})
      notOk(getLabel('Sophomores'))
    })
  })

  QUnit.module('Anonymous assignments', anonymousAssignmentsHooks => {
    anonymousAssignmentsHooks.beforeEach(() => {
      mountComponent({assignment: {anonymousGrading: true}})
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
      const postTypeChanged = sinon.spy()
      mountComponent({postTypeChanged})
      getPostType('Graded').click()
      const {callCount} = postTypeChanged
      strictEqual(callCount, 1)
    })
  })

  QUnit.module('SpecificSections', () => {
    test('enabling "Specific Sections" calls the postBySectionsChanged prop', () => {
      const postBySectionsChanged = sinon.spy()
      mountComponent({postBySectionsChanged})
      getSpecificSectionToggleInput().click()
      const {callCount} = postBySectionsChanged
      strictEqual(callCount, 1)
    })

    test('selecting "Graded" calls the sectionSelectionChanged prop', () => {
      const sectionSelectionChanged = sinon.spy()
      mountComponent({sectionSelectionChanged})
      getSpecificSectionToggleInput().click()
      getInputByLabel('Freshmen').click()
      const {callCount} = sectionSelectionChanged
      strictEqual(callCount, 1)
    })
  })
})
