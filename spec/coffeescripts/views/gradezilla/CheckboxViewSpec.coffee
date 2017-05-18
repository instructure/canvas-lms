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

define ['jquery', 'underscore', 'compiled/views/gradezilla/CheckboxView'], ($, _, CheckboxView) ->

  QUnit.module 'gradezilla/CheckboxView',
    setup: ->
      @view = new CheckboxView(color: 'red', label: 'test label')
      @view.render()
      @view.$el.appendTo('#fixtures')
      @checkbox = @view.$el.find('.checkbox')

    teardown: ->
      $('#fixtures').empty()

  test 'displays checkbox and label', ->
    ok @view.$el.html().match(/test label/), 'should display label'
    ok @view.$el.find('.checkbox').length, 'should display checkbox'

  test 'toggles active state', ->
    ok @view.checked, 'should default to checked'
    @view.$el.click()
    ok !@view.checked, 'should uncheck when clicked'
    @view.$el.click()
    ok @view.checked, 'should check when clicked'

  test 'visually indicates state', ->
    checkedColor = @view.$el.find('.checkbox').css('background-color')
    ok _.include(['rgb(255, 0, 0)', 'red'], checkedColor), 'displays checked state'
    @view.$el.click()
    uncheckedColor = @view.$el.find('.checkbox').css('background-color')
    ok _.include(['rgba(0, 0, 0, 0)', 'transparent'], uncheckedColor), 'displays unchecked state'
