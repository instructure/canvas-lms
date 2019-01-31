/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import CustomColumnCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/CustomColumnCellFormatter'

QUnit.module('GradebookGrid CustomColumnCellFormatter', hooks => {
  let $fixture
  let columnContent
  let formatter

  hooks.beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))

    formatter = new CustomColumnCellFormatter()
  })

  hooks.afterEach(() => {
    $fixture.remove()
  })

  function renderCell() {
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      columnContent, // value
      null, // column definition
      null // dataContext
    )
    return $fixture
  }

  test('renders no content when given null content', () => {
    columnContent = null
    const $cell = renderCell()
    strictEqual($cell.innerHTML, '')
  })

  test('renders the content when defined', () => {
    columnContent = 'Example Content'
    const $cell = renderCell()
    equal($cell.innerHTML, 'Example Content')
  })

  test('escapes html in the content', () => {
    columnContent = '<span>Example Content</span>'
    const $cell = renderCell()
    equal($cell.innerHTML, '&lt;span&gt;Example Content&lt;/span&gt;')
  })
})
