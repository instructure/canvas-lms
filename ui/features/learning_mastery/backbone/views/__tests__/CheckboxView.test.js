/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import CheckboxView from '../CheckboxView'

describe('gradebook/CheckboxView', () => {
  let view
  let checkbox

  beforeEach(() => {
    const node = document.createElement('div')
    view = new CheckboxView({
      color: 'red',
      label: 'test label',
    })
    view.render()
    view.$el.appendTo(node)
    checkbox = view.$el.find('.checkbox')
  })

  afterEach(() => {
    $('#fixtures').empty()
  })

  it('displays checkbox and label', () => {
    expect(view.$el.html()).toMatch(/test label/)
    expect(checkbox.length).toBeTruthy()
  })

  it('toggles active state', () => {
    expect(view.checked).toBeTruthy()
    view.$el.click()
    expect(view.checked).toBeFalsy()
    view.$el.click()
    expect(view.checked).toBeTruthy()
  })

  // passes in QUnit, fails in Jest
  it.skip('visually indicates state', () => {
    const checkedColor = checkbox.css('background-color')
    expect(['rgb(255, 0, 0)', 'red']).toContain(checkedColor)
    view.$el.click()
    const uncheckedColor = checkbox.css('background-color')
    expect(['rgba(0, 0, 0, 0)', 'transparent']).toContain(uncheckedColor)
  })
})
