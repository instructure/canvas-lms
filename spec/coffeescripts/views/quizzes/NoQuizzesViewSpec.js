#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'compiled/views/quizzes/NoQuizzesView'
  'jquery'
  'helpers/assertions'
  'helpers/jquery.simulate'
], (Backbone, NoQuizzesView, $, assertions) ->

  QUnit.module 'NoQuizzesView',
    setup: ->
      @view = new NoQuizzesView()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @view, done, {'a11yReport': true}

  test 'it renders', ->
    ok @view.$el.hasClass('item-group-condensed')