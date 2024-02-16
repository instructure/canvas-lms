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
import CheckboxView from 'ui/features/learning_mastery/backbone/views/CheckboxView'

QUnit.module('gradebook/CheckboxView', {
  setup() {
    this.view = new CheckboxView({
      color: 'red',
      label: 'test label',
    })
    this.view.render()
    this.view.$el.appendTo('#fixtures')
    this.checkbox = this.view.$el.find('.checkbox')
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('displays checkbox and label', function () {
  ok(this.view.$el.html().match(/test label/), 'should display label')
  ok(this.view.$el.find('.checkbox').length, 'should display checkbox')
})

test('toggles active state', function () {
  ok(this.view.checked, 'should default to checked')
  this.view.$el.click()
  ok(!this.view.checked, 'should uncheck when clicked')
  this.view.$el.click()
  ok(this.view.checked, 'should check when clicked')
})

test('visually indicates state', function () {
  const checkedColor = this.view.$el.find('.checkbox').css('background-color')
  ok(['rgb(255, 0, 0)', 'red'].includes(checkedColor), 'displays checked state')
  this.view.$el.click()
  const uncheckedColor = this.view.$el.find('.checkbox').css('background-color')
  ok(['rgba(0, 0, 0, 0)', 'transparent'].includes(uncheckedColor), 'displays unchecked state')
})
