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
  teardown: () => {
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

const rubricHtml =
  '<div class="edit_rubric_test">' +
  ' <div class="rubric">' +
  '  <form id="edit_rubric_form">' +
  '   <input type="checkbox" id="hide_points" class="hide_points_checkbox" />' +
  '   <div class="rubric_grading">' +
  '    <input type="checkbox" id="grading_rubric" class="grading_rubric_checkbox" />' +
  '   </div>' +
  '   <div class="totalling_rubric">' +
  '    <input type="checkbox" id="totalling_rubric" class="totalling_rubric_checkbox" />' +
  '   </div>' +
  '  </form>' +
  ' </div>' +
  '</div>';

test('clicking hide_points checkbox hides grading_rubric checkbox', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  $('.hide_points_checkbox').prop('checked', true)
  $('.hide_points_checkbox').triggerHandler('change')
  ok($('.rubric_grading').attr('style').includes('display: none;'))
})

test('clicking hide_points checkbox unchecks grading_rubric checkbox if checked', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  $('.hide_points_checkbox').prop('checked', true)
  $('.grading_rubric_checkbox').prop('checked', true)
  $('.hide_points_checkbox').triggerHandler('change')
  notOk($('.grading_rubric_checkbox').prop('checked'))
})

test('clicking hide_points checkbox hides totalling_rubric checkbox', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  $('.hide_points_checkbox').prop('checked', true)
  $('.hide_points_checkbox').triggerHandler('change')
  ok($('.totalling_rubric').attr('style').includes('display: none'))
})

test('clicking hide_points checkbox unchecks totalling_rubric checkbox if checked', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  $('.hide_points_checkbox').prop('checked', true)
  $('.totalling_rubric_checkbox').prop('checked', true)
  $('.hide_points_checkbox').triggerHandler('change')
  notOk($('.totalling_rubric_checkbox').prop('checked'))
})
