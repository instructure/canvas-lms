/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import SpeedgraderSelectMenu from 'speed_grader_select_menu'

QUnit.module('SpeedGraderSelectMenu', {
  setup() {
    this.fixtureNode = document.getElementById('fixtures')
    this.testArea = document.createElement('div')
    this.testArea.id = 'test_area'
    this.fixtureNode.appendChild(this.testArea)
    this.selectMenu = new SpeedgraderSelectMenu(null)
  },
  teardown() {
    this.fixtureNode.innerHTML = ''
    return $('.ui-selectmenu-menu').remove()
  }
})

test('Properly changes the a and select tags', function() {
  this.testArea.innerHTML =
    '<select id="students_selectmenu" style="foo" aria-disabled="true"></select><a class="ui-selectmenu" role="presentation" aria-haspopup="true" aria-owns="true"></a>'
  this.selectMenu.selectMenuAccessibilityFixes(this.testArea)
  equal(
    this.testArea.innerHTML,
    '<select id="students_selectmenu" class="screenreader-only" tabindex="0"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"></a>'
  )
})

test('The span tag decorates properly with focus event', function() {
  this.testArea.innerHTML =
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></a>'
  this.selectMenu.focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('focus', true, true)
  document.getElementById('hit_me').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  )
})

test('The span tag decorates properly with focusout event', function() {
  this.testArea.innerHTML =
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  this.selectMenu.focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('blur', true, true)
  document.getElementById('hit_me').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
  )
})

test('The span tag decorates properly with select tag focus event', function() {
  this.testArea.innerHTML =
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
  this.selectMenu.focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('focus', true, true)
  document.getElementById('students_selectmenu').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  )
})

test('The span tag decorates properly with select tag focusout event', function() {
  this.testArea.innerHTML =
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  this.selectMenu.focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('blur', true, true)
  document.getElementById('students_selectmenu').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
  )
})

test('A key press event on the select menu causes the change function to call', () => {
  const optionsArray = [
    {
      id: '1',
      name: 'Student 1',
      className: {
        raw: 'not_graded',
        formatted: 'not graded'
      },
      anonymizableId: 'id'
    }
  ]
  let fired = false
  const selectMenu = new SpeedgraderSelectMenu(optionsArray)
  selectMenu.appendTo('#test_area', e => (fired = true))
  const event = new Event('keyup')
  event.keyCode = 37
  document.getElementById('students_selectmenu').dispatchEvent(event)
  equal(fired, true)
})

test('Properly replaces the default ui selectmenu icon with the min-arrow-down icon', function() {
  this.testArea.innerHTML = '<span class="ui-selectmenu-icon ui-icon"></span>'
  this.selectMenu.replaceDropdownIcon(this.testArea)
  equal(
    this.testArea.innerHTML,
    '<span class="ui-selectmenu-icon"><i class="icon-mini-arrow-down"></i></span>'
  )
})

QUnit.module('SpeedGraderSelectMenu - rendered select control', {
  setup() {
    this.fixtureNode = document.getElementById('fixtures')
    this.testArea = document.createElement('div')
    this.testArea.id = 'test_area'
    this.fixtureNode.appendChild(this.testArea)
    this.optionsArray = [
      {
        name: 'Showing all sections',
        options: [
          {
            id: 'section_all',
            data: {'section-id': 'all'},
            name: 'Show all sections',
            className: {raw: 'section_all'},
            anonymizableId: 'id'
          },
          {
            id: 'section_1',
            data: {'section-id': '1'},
            name: 'Change section to Section 1',
            className: {raw: 'section_1'},
            anonymizableId: 'id'
          }
        ],
        anonymizableId: 'id'
      },
      {id: '3', name: 'Student 2', className: {raw: 'graded', formatted: 'graded'}, anonymizableId: 'id'},
      {id: '1', name: 'Student 1', className: {raw: 'not_graded', formatted: 'not graded'}, anonymizableId: 'id'}
    ]
    this.selectMenu = new SpeedgraderSelectMenu(this.optionsArray)
    this.selectMenu.appendTo('#test_area')
  },
  teardown() {
    this.fixtureNode.innerHTML = ''
    $('.ui-selectmenu-menu').remove()
  }
})

test('renders a select control', function() {
  strictEqual(this.selectMenu.$el.prop('tagName'), 'SELECT')
})

test('renders the select control with an id of students_selectmenu', function() {
  strictEqual(this.selectMenu.$el.prop('id'), 'students_selectmenu')
})

test('renders one optgroup inside the select control to allow changing sections', function() {
  strictEqual(this.selectMenu.$el.find('optgroup[label="Showing all sections"]').length, 1)
})

test('renders two options inside the section optgroup - one for all sections and one for the specific section', function() {
  strictEqual(this.selectMenu.$el.find('optgroup[label="Showing all sections"] option').length, 2)
})

test('renders an option for showing all sections', function() {
  const optgroup = this.selectMenu.$el.find('optgroup[label="Showing all sections"]')
  strictEqual(optgroup.find('option:contains("Show all sections")').length, 1)
})

test('renders an option for switching to section 1', function() {
  const optgroup = this.selectMenu.$el.find('optgroup[label="Showing all sections"]')
  strictEqual(optgroup.find('option:contains("Change section to Section 1")').length, 1)
})

test('renders two options outside the section optgroup - one for each student', function() {
  strictEqual(this.selectMenu.$el.find('> option').length, 2)
})

test('renders an option for Student 1', function() {
  strictEqual(
    this.selectMenu.$el.find(
      '> option[value="1"]:contains("Student 1"):contains("not graded").not_graded.ui-selectmenu-hasIcon'
    ).length,
    1
  )
})

test('renders an option for Student 2', function() {
  strictEqual(
    this.selectMenu.$el.find(
      '> option[value="3"]:contains("Student 2"):contains("graded").graded.ui-selectmenu-hasIcon'
    ).length,
    1
  )
})

test('option for Student 2 comes first as in the order of the options passed in', function() {
  const options = this.selectMenu.$el.find('> option.ui-selectmenu-hasIcon').toArray()
  deepEqual(options.map(opt => $(opt).attr('value')), ['3', '1'])
})
