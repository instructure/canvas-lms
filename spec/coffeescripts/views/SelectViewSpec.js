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
import 'jquery-migrate'
import Backbone from '@canvas/backbone'
import SelectView from 'ui/features/roster/backbone/views/SelectView'
import '@canvas/jquery/jquery.simulate'

let view = null

QUnit.module('SelectView', {
  setup() {
    view = new SelectView({
      template: () => `
        <option>foo</option>
        <option>bar</option>
      `,
    })
    view.render()
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    view.remove()
    $('#fixtures').empty()
  },
})

test('onChange it updates the model', () => {
  view.model = new Backbone.Model()
  equal(view.el.value, 'foo')
  view.el.value = 'bar'
  equal(view.el.value, 'bar')
  view.$el.change()
  equal(view.model.get('unnamed'), 'bar')
})
