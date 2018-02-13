#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jquery',
  'speed_grader_select_menu'
], ($, SpeedgraderSelectMenu)->

  QUnit.module "SpeedGraderSelectMenu",
    setup: ->
      @fixtureNode = document.getElementById("fixtures")
      @testArea = document.createElement('div')
      @testArea.id = "test_area"
      @fixtureNode.appendChild(@testArea)
      @selectMenu = new SpeedgraderSelectMenu(null)

    teardown: ->
      @fixtureNode.innerHTML = ""
      $(".ui-selectmenu-menu").remove()

  test "Properly changes the a and select tags", ->
    @testArea.innerHTML = '<select id="students_selectmenu" style="foo" aria-disabled="true"></select><a class="ui-selectmenu" role="presentation" aria-haspopup="true" aria-owns="true"></a>'
    @selectMenu.selectMenuAccessibilityFixes(@testArea)

    equal(@testArea.innerHTML,'<select id="students_selectmenu" class="screenreader-only" tabindex="0"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"></a>')


  test "The span tag decorates properly with focus event", ->
    @testArea.innerHTML = '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("focus", true, true)

    document.getElementById('hit_me').dispatchEvent(event)
    equal(@testArea.innerHTML, '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>')


  test "The span tag decorates properly with focusout event", ->
    @testArea.innerHTML = '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("blur", true, true)

    document.getElementById('hit_me').dispatchEvent(event)
    equal(@testArea.innerHTML, '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>')


  test "The span tag decorates properly with select tag focus event", ->
    @testArea.innerHTML = '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("focus", true, true)

    document.getElementById('students_selectmenu').dispatchEvent(event)
    equal(@testArea.innerHTML, '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>')


  test "The span tag decorates properly with select tag focusout event", ->
    @testArea.innerHTML = '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("blur", true, true)

    document.getElementById('students_selectmenu').dispatchEvent(event)
    equal(@testArea.innerHTML, '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>')


  test "A key press event on the select menu causes the change function to call", ->
    optionsArray = [{ id: '1', name: 'Student 1', className: { raw: 'not_graded', formatted: 'not graded' } }]
    fired = false
    selectMenu = new SpeedgraderSelectMenu(optionsArray);
    selectMenu.appendTo('#test_area', (e)->
      fired = true
    )
    event = new Event('keyup')
    event.keyCode = 37

    document.getElementById('students_selectmenu').dispatchEvent(event)
    equal(fired, true)

  test "Properly replaces the default ui selectmenu icon with the min-arrow-down icon", ->
    @testArea.innerHTML = '<span class="ui-selectmenu-icon ui-icon"></span>'
    @selectMenu.replaceDropdownIcon(@testArea)

    equal(@testArea.innerHTML,'<span class="ui-selectmenu-icon"><i class="icon-mini-arrow-down"></i></span>')

  QUnit.module "SpeedGraderSelectMenu - rendered select control",
    setup: ->
      @fixtureNode = document.getElementById("fixtures")
      @testArea = document.createElement('div')
      @testArea.id = "test_area"
      @fixtureNode.appendChild(@testArea)
      @optionsArray = [
        name: 'Showing all sections'
        options: [
          { id: 'section_all', data: { 'section-id': 'all' }, name: 'Show all sections', className: { raw: 'section_all' } },
          { id: 'section_1', data: { 'section-id': '1' }, name: 'Change section to Section 1', className: { raw: 'section_1' } },
        ]
        { id: '3', name: 'Student 2', className: { raw: 'graded', formatted: 'graded' } }
        { id: '1', name: 'Student 1', className: { raw: 'not_graded', formatted: 'not graded' } },
      ]
      @selectMenu = new SpeedgraderSelectMenu(@optionsArray)
      @selectMenu.appendTo('#test_area')

    teardown: ->
      @fixtureNode.innerHTML = ""
      $(".ui-selectmenu-menu").remove()

  test "renders a select control", ->
    strictEqual(@selectMenu.$el.prop('tagName'), 'SELECT')

  test "renders the select control with an id of students_selectmenu", ->
    strictEqual(@selectMenu.$el.prop('id'), 'students_selectmenu')

  test "renders one optgroup inside the select control to allow changing sections", ->
    strictEqual(@selectMenu.$el.find('optgroup[label="Showing all sections"]').length, 1)

  test "renders two options inside the section optgroup - one for all sections and one for the specific section", ->
    strictEqual(@selectMenu.$el.find('optgroup[label="Showing all sections"] option').length, 2)

  test "renders an option for showing all sections", ->
    optgroup = @selectMenu.$el.find('optgroup[label="Showing all sections"]')
    strictEqual(optgroup.find('option:contains("Show all sections")').length, 1)

  test "renders an option for switching to section 1", ->
    optgroup = @selectMenu.$el.find('optgroup[label="Showing all sections"]')
    strictEqual(optgroup.find('option:contains("Change section to Section 1")').length, 1)

  test "renders two options outside the section optgroup - one for each student", ->
    strictEqual(@selectMenu.$el.find('> option').length, 2)

  test "renders an option for Student 1", ->
    strictEqual(@selectMenu.$el.find('> option[value="1"]:contains("Student 1"):contains("not graded").not_graded.ui-selectmenu-hasIcon').length, 1)

  test "renders an option for Student 2", ->
    strictEqual(@selectMenu.$el.find('> option[value="3"]:contains("Student 2"):contains("graded").graded.ui-selectmenu-hasIcon').length, 1)

  test "option for Student 2 comes first as in the order of the options passed in", ->
    options = @selectMenu.$el.find('> option.ui-selectmenu-hasIcon').toArray()

    deepEqual(options.map((opt) => $(opt).attr('value')), ['3', '1'])
