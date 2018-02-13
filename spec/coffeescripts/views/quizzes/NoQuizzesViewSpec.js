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

import Backbone from 'Backbone'
import NoQuizzesView from 'compiled/views/quizzes/NoQuizzesView'
import $ from 'jquery'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

QUnit.module('NoQuizzesView', {
  setup() {
    this.view = new NoQuizzesView()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.view, done, {a11yReport: true})
})

test('it renders', function() {
  ok(this.view.$el.hasClass('item-group-condensed'))
})
