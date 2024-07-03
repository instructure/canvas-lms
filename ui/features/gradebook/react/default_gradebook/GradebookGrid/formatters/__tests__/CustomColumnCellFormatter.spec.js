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

import 'jquery-migrate'
import CustomColumnCellFormatter from '../CustomColumnCellFormatter'

describe('GradebookGrid CustomColumnCellFormatter', () => {
  let $fixture
  let columnContent
  let formatter

  beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))
    formatter = new CustomColumnCellFormatter()
  })

  afterEach(() => {
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
    expect($cell.innerHTML).toBe('')
  })

  test('renders the content when defined', () => {
    columnContent = 'Example Content'
    const $cell = renderCell()
    expect($cell.innerHTML).toBe('Example Content')
  })

  test('escapes html in the content', () => {
    columnContent = '<span>Example Content</span>'
    const $cell = renderCell()
    expect($cell.innerHTML).toBe('&lt;span&gt;Example Content&lt;/span&gt;')
  })
})
