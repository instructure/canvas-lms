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

import StudentGroupFilter from 'jsx/gradezilla/default_gradebook/components/StudentGroupFilter'

QUnit.module('Student Group Filter - subclass functionality', hooks => {
  let $container
  let props

  hooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    props = {
      items: [
        {
          children: [{id: '1', name: 'First Group Set 1'}, {id: '2', name: 'First Group Set 2'}],
          id: '1',
          name: 'First Group Set'
        },
        {
          children: [{id: '3', name: 'Second Group Set 1'}, {id: '4', name: 'Second Group Set 2'}],
          id: '2',
          name: 'Second Group Set'
        }
      ],
      onSelect: () => {},
      selectedItemId: '0'
    }
  })

  hooks.afterEach(() => {
    $container.remove()
  })

  test('renders a screenreader-friendly label', () => {
    ReactDOM.render(<StudentGroupFilter {...props} />, $container)

    ok($container.querySelector('label').innerText.includes('Student Group Filter'))
  })

  test('the options are displayed in the same order as they were sent in', () => {
    ReactDOM.render(<StudentGroupFilter {...props} />, $container)

    // "0" is the value for "All Student Groups"
    const expectedOptionValues = ['0', '1', '2', '3', '4']
    deepEqual(
      [...$container.querySelectorAll('option')].map(option => option.value),
      expectedOptionValues
    )
  })

  test('options are displayed within their respective groups', () => {
    ReactDOM.render(<StudentGroupFilter {...props} />, $container)

    const firstGroupOptions = [
      ...$container.querySelectorAll('optgroup[label="First Group Set"] option')
    ]
    deepEqual(firstGroupOptions.map(option => option.value), ['1', '2'])
  })
})
