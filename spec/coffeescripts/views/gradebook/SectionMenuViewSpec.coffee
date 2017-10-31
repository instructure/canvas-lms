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
  'jquery'
  'underscore',
  'compiled/views/gradebook/SectionMenuView',
  'vendor/jquery.ba-tinypubsub'
], ($, _, SectionMenuView) ->

  sections = [{id: 1, name: 'Section One', checked: true},
              {id: 2, name: 'Section Two', checked: false}]
  course = {id: 1, name: 'Course One', checked: false}
  currentSection = 1

  QUnit.module 'gradebook/SectionMenuView',
    setup: ->
      @view = new SectionMenuView(sections: sections, currentSection: currentSection, course: course)
      @view.render()
      @view.$el.appendTo('#fixtures')

    teardown: ->
      $('#fixtures').empty()

  test 'it renders a button', ->
    ok @view.$el.find('button').length, 'button displays'
    ok @view.$el.find('button').text().match(/Section One/), 'button label includes current section'

  test 'it displays given sections', ->
    clock = sinon.useFakeTimers()
    @view.$el.find('button').click()
    clock.tick(101)
    html = $('.section-select-menu:visible').html()
    ok html.match(/All Sections/), 'displays default "all sections"'
    ok html.match(/Section One/), 'displays first section'
    ok html.match(/Section Two/), 'displays section section'
    clock.restore()

  test 'it changes sections', ->
    @view.$el.find('button').click()
    $('input[value=2]').parent().click()
    ok @view.currentSection == '2', 'updates its section'

  asyncTest 'it publishes changes', ->
    expect(1)
    $.subscribe 'currentSection/change', (section) ->
      ok section == '2', 'publish fires'
      start()
    @view.$el.find('button').click()
    $('input[value=2]').parent().click()
    $.unsubscribe 'currentSection/change'
