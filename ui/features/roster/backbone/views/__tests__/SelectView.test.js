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
import Backbone from '@canvas/backbone'
import SelectView from '../SelectView'
import '@canvas/jquery/jquery.simulate'

let view = null

describe('SelectView', () => {
  beforeEach(() => {
    view = new SelectView({
      template: () => `
        <select>
          <option value="foo">foo</option>
          <option value="bar">bar</option>
        </select>
      `,
    })
    view.render()
    $('body').append(view.el)
  })

  afterEach(() => {
    view.remove()
    $('body').empty()
  })

  it('onChange it updates the model', () => {
    view.model = new Backbone.Model()
    expect(view.el.value).toBe('foo')
    $(view.el).val('bar').trigger('change')
    expect(view.el.value).toBe('bar')
    expect(view.model.get('unnamed')).toBe('bar')
  })
})
