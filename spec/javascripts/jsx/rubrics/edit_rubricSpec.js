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
import 'jquery-migrate'
import rubricEditing from '@canvas/rubrics/jquery/edit_rubric'

QUnit.module('edit_rubric', {
  teardown: () => {
    $('.edit_rubric_test').remove()
  },
})

test('hidePoints hides elements marked with class toggle_for_hide_points', () => {
  $(document.body).append(
    $(
      '<div class="edit_rubric_test">' +
        ' <div class="rubric">' +
        '   <span class="toggle_for_hide_points">Hello</span>' +
        ' </div>' +
        '</div>'
    )
  )
  rubricEditing.hidePoints($('.rubric'))
  ok($('.toggle_for_hide_points').hasClass('hidden'))
})

test('showPoints shows elements marked with class toggle_for_hide_points', () => {
  $(document.body).append(
    $(
      '<div class="edit_rubric_test">' +
        ' <div class="rubric">' +
        '   <span class="toggle_for_hide_points hidden">Hello</span>' +
        ' </div>' +
        '</div>'
    )
  )
  rubricEditing.showPoints($('.rubric'))
  notOk($('.toggle_for_hide_points').hasClass('hidden'))
})

const rubricHtml =
  '<div class="edit_rubric_test">' +
  ' <div class="rubric">' +
  '  <form id="edit_rubric_form">' +
  '   <input type="checkbox" id="hide_points" class="hide_points_checkbox" />' +
  '   <div class="rubric_grading" style="">' +
  '    <input type="checkbox" id="grading_rubric" class="grading_rubric_checkbox" />' +
  '   </div>' +
  '   <div class="totalling_rubric">' +
  '    <input type="checkbox" id="totalling_rubric" class="totalling_rubric_checkbox" />' +
  '   </div>' +
  '  </form>' +
  ' </div>' +
  '</div>'

test('opening new rubric from assignment page displays "use this rubric for assignment editing" right away', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  notOk($('.rubric_grading').attr('style').includes('display: none;'))
})

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

test('clicking hidden hide_points checkbox does not hide grading_rubric and totalling_rubric checkboxes', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  $('.hide_points_checkbox').hide()
  $('.hide_points_checkbox').prop('checked', true)
  $('.hide_points_checkbox').triggerHandler('change')
  notOk($('.rubric_grading').is(':hidden'))
  notOk($('.totalling_rubric').is(':hidden'))
})

test('clicking hidden grading_rubric checkbox does not hide totalling_rubric checkbox', () => {
  $(document.body).append($(rubricHtml))
  rubricEditing.init()
  $('.grading_rubric_checkbox').hide()
  $('.grading_rubric_checkbox').prop('checked', true)
  $('.grading_rubric_checkbox').triggerHandler('change')
  notStrictEqual($('.totalling_rubric').css('visibility'), 'hidden')
})

const criterionHtml =
  '<tr id="criterion_blank" class="criterion">' +
  '  <td style="padding: 0;">' +
  '    <table class="ratings">' +
  '      <tbody>' +
  '        <tr>' +
  '          <td class="rating">' +
  '            <div class="container">' +
  '              <div class="rating-main">' +
  '                <span class="points">4</span>' +
  '                <div class="description rating_description_value">Full Marks</div>' +
  '                <span class="rating_id" style="display: none;">58_3952</span>' +
  '              </div>' +
  '            </div>' +
  '          </td>' +
  '          <td class="rating">' +
  '            <div class="container">' +
  '              <div class="rating-main">' +
  '                <span class="points">2</span>' +
  '                <div class="description rating_description_value">Partial Marks</div>' +
  '                <span class="rating_id" style="display: none;">58_4365</span>' +
  '              </div>' +
  '            </div>' +
  '          </td>' +
  '          <td class="rating">' +
  '            <div class="container">' +
  '              <div class="rating-main">' +
  '                <span class="points">0</span>' +
  '                <div class="description rating_description_value">No Marks</div>' +
  '                <span class="rating_id" style="display: none;">58_4372</span>' +
  '              </div>' +
  '            </div>' +
  '          </td>' +
  '        </tr>' +
  '      </tbody>' +
  '    </table>' +
  '  </td>' +
  '  <td class="nobr points_form toggle_for_hide_points">' +
  '    <div class="editing" style="white-space: normal">' +
  '      <input type="text" aria-label="Points" value="4" class="criterion_points span1 no-margin-bottom">' +
  '      pts' +
  '      </span><br>' +
  '    </div>' +
  '  </td>' +
  '</tr>'

test('sets the first rating value to the points input initially when a criterion id is "blank"', () => {
  $(document.body).append($(rubricHtml))
  $(document.body).append($(criterionHtml))
  rubricEditing.init()
  equal($('.criterion_points').val(), '4')
})
