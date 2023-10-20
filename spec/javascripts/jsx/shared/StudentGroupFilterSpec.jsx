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

import StudentGroupFilter from '@canvas/student-group-filter'

QUnit.module('StudentGroupFilter', suiteHooks => {
  let $container
  let context

  function mountComponent() {
    ReactDOM.render(<StudentGroupFilter {...context} />, $container)
  }

  function getOptions() {
    return [...getSelect().querySelectorAll('option')]
  }

  function getSelect() {
    return $container.querySelector('select')
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    context = {
      categories: [
        {
          groups: [{id: '2101', name: 'group 1'}],
          id: '1101',
          name: 'group category 1',
        },
      ],
      label: 'Select a student group',
      onChange: sinon.spy(),
      value: '2101',
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('renders a select', () => {
    mountComponent()
    ok(getSelect())
  })

  test('renders the group categories', () => {
    mountComponent()
    const categories = [...getSelect().querySelectorAll('optgroup')].map(category => category.label)
    deepEqual(categories, ['group category 1'])
  })

  test('renders the groups', () => {
    mountComponent()
    const groups = getOptions().map(option => option.innerText)
    deepEqual(groups, ['Select One', 'group 1'])
  })

  test('the "Select One" option is disabled', () => {
    mountComponent()
    const option = getOptions().find(opt => opt.innerText === 'Select One')
    strictEqual(option.disabled, true)
  })

  test('the "Select One" option has a value of "0"', () => {
    mountComponent()
    const option = getOptions().find(opt => opt.innerText === 'Select One')
    strictEqual(option.value, '0')
  })

  test('select is set to value that is passed in', () => {
    mountComponent()
    strictEqual(getSelect().value, '2101')
  })

  test('select is set to value "0" when no value is passed in', () => {
    context.value = null
    mountComponent()
    strictEqual(getSelect().value, '0')
  })
})
