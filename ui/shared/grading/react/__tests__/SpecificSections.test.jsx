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
import SpecificSections from '../SpecificSections'

const ok = x => expect(x).toBeTruthy()
const notOk = x => expect(x).toBeFalsy()
const strictEqual = (x, y) => expect(x).toBe(y)

let $container
let context

function getLabel(text) {
  return [...$container.querySelectorAll('label')].find($label => $label.textContent === text)
}

function getSectionToggleInput() {
  return document.getElementById(getLabel('Specific Sections').htmlFor)
}

function mountComponent() {
  ReactDOM.render(<SpecificSections {...context} />, $container)
}

describe('SpecificSections', () => {
  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    context = {
      checked: false,
      disabled: false,
      onCheck: () => {},
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
      sectionSelectionChanged: () => {},
      selectedSectionIds: [],
    }
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('section toggle is enabled', () => {
    mountComponent()
    strictEqual(getSectionToggleInput().disabled, false)
  })

  test('section toggle is checked when checked is true', () => {
    context.checked = true
    mountComponent()
    ok(getSectionToggleInput().getAttributeNames().includes('checked'))
  })

  test('sections are shown when checked is true', () => {
    context.checked = true
    mountComponent()
    ok(getLabel('Sophomores'))
  })

  test('clicking the section toggle calls onCheck', () => {
    const onCheckSpy = jest.fn()
    context.onCheck = onCheckSpy
    mountComponent()
    getSectionToggleInput().click()
    expect(onCheckSpy).toHaveBeenCalledTimes(1)
  })

  test('selecting a section calls sectionSelectionChanged', () => {
    const sectionSelectionChangedSpy = jest.fn()
    context.checked = true
    context.sectionSelectionChanged = sectionSelectionChangedSpy
    mountComponent()
    document.getElementById(getLabel('Sophomores').htmlFor).click()
    expect(sectionSelectionChangedSpy).toHaveBeenCalledTimes(1)
  })

  describe('when disabled', () => {
    beforeEach(() => {
      context.disabled = true
    })

    test('section toggle is disabled', () => {
      mountComponent()
      strictEqual(getSectionToggleInput().disabled, true)
    })

    test('sections are not shown', () => {
      context.checked = true
      mountComponent()
      notOk(getLabel('Sophomores'))
    })

    test('clicking the section toggle does not call onCheck', () => {
      const onCheckSpy = jest.fn()
      context.onCheck = onCheckSpy
      mountComponent()
      getSectionToggleInput().click()
      expect(onCheckSpy).not.toHaveBeenCalled()
    })
  })
})
