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

import FormContent from '@canvas/hide-assignment-grades-tray/react/FormContent'

QUnit.module('HideAssignmentGradesTray FormContent', suiteHooks => {
  let $container

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

  function formContentProps({assignment, ...props} = {}) {
    return {
      assignment: {
        anonymousGrading: false,
        gradesPublished: true,
        ...assignment,
      },
      dismiss() {},
      hideBySections: true,
      hideBySectionsChanged() {},
      hidingGrades: false,
      onHideClick() {},
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
      sectionSelectionChanged() {},
      selectedSectionIds: [],
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

  test('clicking "Hide" button calls the onHideClick prop', () => {
    const onHideClick = sinon.spy()
    mountComponent({onHideClick})
    getHideButton().click()
    const {callCount} = onHideClick
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

    test('description is present', () => {
      ok(getDescription())
    })

    test('"hide" button is present', () => {
      ok(getHideButton())
    })

    test('close button is present', () => {
      ok(getCloseButton())
    })
  })

  QUnit.module('given "hidingGrades" prop is true', ({beforeEach}) => {
    beforeEach(() => {
      mountComponent({hidingGrades: true})
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
  })

  QUnit.module('given grades are not published', ({beforeEach}) => {
    beforeEach(() => {
      mountComponent({assignment: {gradesPublished: false}})
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

  QUnit.module('when sections are absent', () => {
    test('section toggle is not shown', () => {
      mountComponent({sections: []})
      notOk(getLabel('Specific Sections'))
    })

    test('sections are not shown', () => {
      mountComponent({hideBySections: false})
      notOk(getLabel('Sophomores'))
    })
  })

  QUnit.module('Anonymous assignments', ({beforeEach}) => {
    beforeEach(() => {
      mountComponent({assignment: {anonymousGrading: true}})
    })

    test('"Specific Sections" is disabled', () => {
      strictEqual(getSpecificSectionToggleInput().disabled, true)
    })
  })

  QUnit.module('SpecificSections', () => {
    test('enabling "Specific Sections" calls the hideBySectionsChanged prop', () => {
      const hideBySectionsChanged = sinon.spy()
      mountComponent({hideBySectionsChanged})
      getSpecificSectionToggleInput().click()
      const {callCount} = hideBySectionsChanged
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
