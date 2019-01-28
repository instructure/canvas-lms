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
import AdvancedTabPanel from 'jsx/gradezilla/default_gradebook/components/AdvancedTabPanel'

const fixtures = document.getElementById('fixtures')
const overridesOnChangeStub = sinon.stub()

function renderComponent({overrides, props} = {}) {
  const componentProps = {
    overrides: {
      defaultChecked: true,
      disabled: false,
      onChange: overridesOnChangeStub,
      ...overrides
    },
    ...props
  }
  ReactDOM.render(<AdvancedTabPanel {...componentProps} />, fixtures)
  return fixtures.children[0]
}

function findCheckBox(label, scope = fixtures) {
  const labels = []
  scope.querySelectorAll('label').forEach(node => labels.push(node))
  const labelFor = labels.find(node => node.innerText.trim() === label).getAttribute('for')
  return scope.querySelector(`#${labelFor}`)
}

function overridesCheckbox() {
  return findCheckBox('Allow final grade override')
}

QUnit.module('AdvancedTabPanel', moduleHooks => {
  moduleHooks.beforeEach(() => {})

  moduleHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode(fixtures)
  })

  test('it renders', () => {
    renderComponent()
    const container = fixtures.querySelectorAll('#AdvancedTabPanel__Container')
    equal(container.length, 1)
  })

  QUnit.module('Overrides', () => {
    test('checkbox is checked', () => {
      renderComponent()
      const {checked} = overridesCheckbox()
      strictEqual(checked, true)
    })

    test('checkbox is not checked when `overrides.defaultChecked` is false', () => {
      renderComponent({overrides: {defaultChecked: false}})
      const {checked} = overridesCheckbox()
      strictEqual(checked, false)
    })

    test('checkbox is not disabled', () => {
      renderComponent()
      const {disabled} = overridesCheckbox()
      strictEqual(disabled, false)
    })

    test('checkbox is disabled when `overrides.disabled` is true', () => {
      renderComponent({overrides: {disabled: true}})
      const {disabled} = overridesCheckbox()
      strictEqual(disabled, true)
    })

    test('onChange is called when checkbox is clicked', () => {
      renderComponent()
      overridesCheckbox().click()
      strictEqual(overridesOnChangeStub.callCount, 1)
    })
  })
})
