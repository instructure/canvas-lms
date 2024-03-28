/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import SyllabusBehaviors from '@canvas/syllabus/backbone/behaviors/SyllabusBehaviors'
import Sidebar from '@canvas/rce/Sidebar'
import editorUtils from 'helpers/editorUtils'
import fixtures from 'helpers/fixtures'
import $ from 'jquery'
import 'jquery-migrate'
import RichContentEditor from '@canvas/rce/RichContentEditor'

QUnit.module('SyllabusBehaviors.bindToEditSyllabus', {
  setup() {
    editorUtils.resetRCE()
    fixtures.setup()
    sandbox.stub(Sidebar, 'init')
  },
  teardown() {
    // on successful bindToEditSyllabus, it will have added keyboard
    // shortcut bindings that we don't actually want to keep. unfortunately
    // we don't have a handle on the KeyboardShortcut view object to just
    // call `.remove()` :(
    if ($('.ui-dialog').length > 0) {
      $(document).off('keyup.tinymce_keyboard_shortcuts')
      $(document).off('editorKeyUp')
      $('.ui-dialog').remove()
    }
    editorUtils.resetRCE()
    fixtures.teardown()
    $('.ui-dialog').remove()
  },
})

test('sets focus to the edit button when hide_edit occurs', () => {
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
  fixtures.create('<form id="edit_course_syllabus_form"></form>')
  SyllabusBehaviors.bindToEditSyllabus()
  $('#edit_course_syllabus_form').trigger('hide_edit')
  equal(document.activeElement, $('.edit_syllabus_link')[0])
  equal($('.edit_syllabus_link').attr('aria-expanded'), 'false')
})

test('skips initializing sidebar when edit link absent', () => {
  equal(fixtures.find('.edit_syllabus_link').length, 0)
  SyllabusBehaviors.bindToEditSyllabus()
  ok(Sidebar.init.notCalled, 'bar')
})

test('sets syllabus_body data value on fresh node when showing edit form', () => {
  const fresh = {val: sinon.spy()}
  sandbox.stub(RichContentEditor, 'freshNode').returns(fresh)
  sandbox.stub(RichContentEditor, 'loadNewEditor')
  fixtures.create('<div id="course_syllabus"></div>')
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
  fixtures.create('<form id="edit_course_syllabus_form"></form>')
  fixtures.create('<textarea id="course_syllabus_body"></textarea>')
  const text = 'foo'
  $('#course_syllabus').data('syllabus_body', text)
  const $form = SyllabusBehaviors.bindToEditSyllabus()
  $form.triggerHandler('edit')
  equal($('.edit_syllabus_link').attr('aria-expanded'), 'true')
  ok(RichContentEditor.freshNode.called)
  const body = document.getElementById('course_syllabus_body')
  equal(RichContentEditor.freshNode.firstCall.args[0][0], body)
  ok(fresh.val.calledWith(text))
})

test('sets course_syllabus_body after mce destruction', () => {
  sandbox.stub(RichContentEditor, 'destroyRCE').callsFake(() => {
    const elem = document.getElementById('course_syllabus_body')
    elem.parentNode.removeChild(elem)
  })
  fixtures.create('<div id="course_syllabus"></div>')
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
  fixtures.create('<form id="edit_course_syllabus_form"></form>')
  fixtures.create(
    '<div id="tinymce-parent-of-course_syllabus_body"><textarea id="course_syllabus_body"></textarea></div>'
  )
  const $form = SyllabusBehaviors.bindToEditSyllabus()
  $form.triggerHandler('hide_edit')
  ok(RichContentEditor.destroyRCE.called)
  const body = document.getElementById('course_syllabus_body')
  notStrictEqual(body, null)
})

test('hides student view button when editing syllabus', () => {
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
  fixtures.create('<form id="edit_course_syllabus_form"></form>')
  fixtures.create('<a href="#" id="easy_student_view"></a>')
  SyllabusBehaviors.bindToEditSyllabus()
  $('#edit_course_syllabus_form').trigger('edit')
  equal($('#easy_student_view').is(':hidden'), true)
})

test('shows student view button again after done editing', () => {
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
  fixtures.create('<form id="edit_course_syllabus_form"></form>')
  fixtures.create('<a href="#" id="easy_student_view" style="display: none;"></a>')
  SyllabusBehaviors.bindToEditSyllabus()
  $('#edit_course_syllabus_form').trigger('hide_edit')
  equal($('#easy_student_view').is(':hidden'), false)
})

test('jumps to the events when events have no dates and user clicks "Jump to Today"', () => {
  // Create an event without a due date
  fixtures.create(
    '<tr id="testTr" class="date detail_list  syllabus_assignment  related-assignment_4" data-workflow-state="published"></tr>'
  )
  fixtures.create('<a id="testLink" href="#" class="jump_to_today_link">Jump to Today</a>')
  SyllabusBehaviors.bindToMiniCalendar()
  ok(!$('#testTr').hasClass('selected'))
  $('#testLink').trigger('click')
  ok($('#testTr').hasClass('selected'))
})

test('jumps to the first event when all events are future and user clicks "Jump to Today"', () => {
  fixtures.create(
    '<tr id="test4" class="date detail_list events_4000_07_28 syllabus_assignment related-assignment_4" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="4000_07_28">Thu Jul 28, 4000</td></tr>'
  )
  fixtures.create(
    '<tr id="test9" class="date detail_list events_4000_09_09 syllabus_assignment related-assignment_9" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="4000_09_09">Fri Sep 9, 4000</td></tr>'
  )
  fixtures.create('<a id="testLink" href="#" class="jump_to_today_link">Jump to Today</a>')
  SyllabusBehaviors.bindToMiniCalendar()
  ok(!$('#test4').hasClass('selected'))
  ok(!$('#test9').hasClass('selected'))
  $('#testLink').trigger('click')
  ok($('#test4').hasClass('selected'))
  ok(!$('#test9').hasClass('selected'))
})

test('jumps to most recent past event when there are past, future, and dateless events and user clicks "Jump to Today"', () => {
  fixtures.create(
    '<tr id="test0" class="date detail_list  syllabus_assignment  related-assignment_4" data-workflow-state="published"></tr>'
  )
  fixtures.create(
    '<tr id="test1" class="date detail_list events_2000_07_28 syllabus_assignment related-assignment_4" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="2000_07_28">Thu Jul 28, 2000</td></tr>'
  )
  fixtures.create(
    '<tr id="test2" class="date detail_list events_2000_09_09 syllabus_assignment related-assignment_9" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="2000_09_09">Fri Sep 9, 2000</td></tr>'
  )
  fixtures.create(
    '<tr id="test3" class="date detail_list events_4000_07_28 syllabus_assignment related-assignment_4" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="4000_07_28">Thu Jul 28, 4000</td></tr>'
  )
  fixtures.create(
    '<tr id="test4" class="date detail_list events_4000_09_09 syllabus_assignment related-assignment_9" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="4000_09_09">Fri Sep 9, 4000</td></tr>'
  )
  fixtures.create('<a id="testLink" href="#" class="jump_to_today_link">Jump to Today</a>')
  SyllabusBehaviors.bindToMiniCalendar()
  ok(!$('#test0').hasClass('selected'))
  ok(!$('#test1').hasClass('selected'))
  ok(!$('#test2').hasClass('selected'))
  ok(!$('#test3').hasClass('selected'))
  ok(!$('#test4').hasClass('selected'))
  $('#testLink').trigger('click')
  ok(!$('#test0').hasClass('selected'))
  ok(!$('#test1').hasClass('selected'))
  ok($('#test2').hasClass('selected'))
  ok(!$('#test3').hasClass('selected'))
  ok(!$('#test4').hasClass('selected'))
})

test('jumps to most recent past event when there are only past events and user clicks "Jump to Today"', () => {
  fixtures.create(
    '<tr id="test1" class="date detail_list events_2000_07_28 syllabus_assignment related-assignment_4" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="2000_07_28">Thu Jul 28, 2000</td></tr>'
  )
  fixtures.create(
    '<tr id="test2" class="date detail_list events_2000_09_09 syllabus_assignment related-assignment_9" data-workflow-state="published"><td scope="row" rowspan="1" valign="top" class="day_date" data-date="2000_09_09">Fri Sep 9, 2000</td></tr>'
  )
  fixtures.create('<a id="testLink" href="#" class="jump_to_today_link">Jump to Today</a>')
  SyllabusBehaviors.bindToMiniCalendar()
  ok(!$('#test1').hasClass('selected'))
  ok(!$('#test2').hasClass('selected'))
  $('#testLink').trigger('click')
  ok(!$('#test1').hasClass('selected'))
  ok($('#test2').hasClass('selected'))
})

test('escapes selector when jumping to event', () => {
  const restoreFn = $.fn.ifExists
  const spy = sinon.spy()
  $.fn.ifExists = spy
  fixtures.create(
    // eslint-disable-next-line no-template-curly-in-string
    '<div class="mini_month"><div class="day_wrapper" id="mini_day_2023_10_31_1"><div class="mini_calendar_day" id="mini_day_2023_10_31_1, id=[<img src=x onerror=\'alert(`${document.domain}:${document.cookie}`)\' />]">Click me to trigger XSS</div></div></div>'
  )
  SyllabusBehaviors.bindToMiniCalendar()
  try {
    $('.mini_calendar_day').trigger('click')
  } catch (error) {
    equal(
      error?.message,
      // eslint-disable-next-line no-template-curly-in-string
      "Syntax error, unrecognized expression: #mini_day_2023_10_31_1, id=[<img src=x onerror='alert(`${document.domain}:${document.cookie}`)' />]",
      'Expected syntax error for malformed selector in jQuery >= 1.8'
    )
  }
  $.fn.ifExists = restoreFn
})
