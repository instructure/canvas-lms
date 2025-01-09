/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import rubricEditing from '../edit_rubric'

describe('edit_rubric', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
  })

  afterEach(() => {
    $('.edit_rubric_test').remove()
  })

  it('hidePoints hides elements marked with class toggle_for_hide_points', () => {
    $(document.body).append(
      $(
        '<div class="edit_rubric_test">' +
          ' <div class="rubric">' +
          '   <span class="toggle_for_hide_points">Hello</span>' +
          ' </div>' +
          '</div>',
      ),
    )
    rubricEditing.hidePoints($('.rubric'))
    expect($('.toggle_for_hide_points').hasClass('hidden')).toBe(true)
  })

  it('showPoints shows elements marked with class toggle_for_hide_points', () => {
    $(document.body).append(
      $(
        '<div class="edit_rubric_test">' +
          ' <div class="rubric">' +
          '   <span class="toggle_for_hide_points hidden">Hello</span>' +
          ' </div>' +
          '</div>',
      ),
    )
    rubricEditing.showPoints($('.rubric'))
    expect($('.toggle_for_hide_points').hasClass('hidden')).toBe(false)
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

  it('opening new rubric from assignment page displays "use this rubric for assignment editing" right away', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    expect($('.rubric_grading').hasClass('hidden')).toBe(false)
  })

  it('clicking hide_points checkbox hides grading_rubric checkbox', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    $('#hide_points').prop('checked', true).trigger('change')
    expect($('.rubric_grading').is(':hidden')).toBe(true)
  })

  it('clicking hide_points checkbox hides the grading_rubric section', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    $('#grading_rubric').prop('checked', true)
    $('#hide_points').prop('checked', true).trigger('change')
    expect($('.rubric_grading').is(':hidden')).toBe(true)
  })

  it('clicking hide_points checkbox hides totalling_rubric checkbox', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    $('#hide_points').prop('checked', true).trigger('change')
    expect($('.totalling_rubric').is(':hidden')).toBe(true)
  })

  it('clicking hide_points checkbox hides the totalling_rubric section', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    $('#totalling_rubric').prop('checked', true)
    $('#hide_points').prop('checked', true).trigger('change')
    expect($('.totalling_rubric').is(':hidden')).toBe(true)
  })

  it('clicking hidden hide_points checkbox does not hide grading_rubric and totalling_rubric checkboxes', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    $('#hide_points').hide()
    $('#hide_points').prop('checked', true).trigger('change')
    expect($('.rubric_grading').hasClass('hidden')).toBe(false)
    expect($('.totalling_rubric').hasClass('hidden')).toBe(false)
  })

  it('clicking hidden grading_rubric checkbox does not hide totalling_rubric checkbox', () => {
    $(document.body).append($(rubricHtml))
    rubricEditing.init()
    $('#grading_rubric').hide()
    $('#grading_rubric').prop('checked', true).trigger('change')
    expect($('.totalling_rubric').hasClass('hidden')).toBe(false)
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

  it('sets the first rating value to the points input initially when a criterion id is "blank"', () => {
    $(document.body).append($(rubricHtml))
    $(document.body).append($(criterionHtml))
    rubricEditing.init()
    expect($('.criterion_points').val()).toBe('4')
  })
})
