/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import rubricEditing from 'edit_rubric'

QUnit.module('edit_rubric', {
  afterEach: () => {
    $('.edit_rubric_test').remove()
  }
})

test('hidePoints hides elements marked with class toggle_for_hide_points', () => {
  $(document.body).append($(
    '<div class="edit_rubric_test">' +
    ' <div class="rubric">' +
    '   <span class="toggle_for_hide_points">Hello</span>' +
    ' </div>' +
    '</div>'
  ))
  rubricEditing.hidePoints($('.rubric'))
  ok($('.toggle_for_hide_points').hasClass('hidden'))
})


test('showPoints shows elements marked with class toggle_for_hide_points', () => {
  $(document.body).append($(
    '<div class="edit_rubric_test">' +
    ' <div class="rubric">' +
    '   <span class="toggle_for_hide_points hidden">Hello</span>' +
    ' </div>' +
    '</div>'
  ))
  rubricEditing.showPoints($('.rubric'))
  notOk($('.toggle_for_hide_points').hasClass('hidden'))
})
