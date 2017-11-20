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

import SyllabusBehaviors from 'compiled/behaviors/SyllabusBehaviors';
import Sidebar from 'jsx/shared/rce/Sidebar';
import editorUtils from 'helpers/editorUtils';
import fixtures from 'helpers/fixtures';
import $ from 'jquery';
import RichContentEditor from 'jsx/shared/rce/RichContentEditor';

QUnit.module('SyllabusBehaviors.bindToEditSyllabus', {
  setup () {
    editorUtils.resetRCE();
    fixtures.setup();
    this.stub(Sidebar, 'init');
  },
  teardown () {
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
    $(".ui-dialog").remove()
  }
});

test('sets focus to the edit button when hide_edit occurs', function () {
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>');
  fixtures.create('<form id="edit_course_syllabus_form"></form>');
  SyllabusBehaviors.bindToEditSyllabus();
  $('#edit_course_syllabus_form').trigger('hide_edit');
  equal(document.activeElement, $('.edit_syllabus_link')[0]);
});

test('initializes sidebar when edit link present', function () {
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>');
  SyllabusBehaviors.bindToEditSyllabus();
  ok(Sidebar.init.called, 'foo');
});

test('skips initializing sidebar when edit link absent', function () {
  equal(fixtures.find('.edit_syllabus_link').length, 0);
  SyllabusBehaviors.bindToEditSyllabus();
  ok(Sidebar.init.notCalled, 'bar');
});

test('sets syllabus_body data value on fresh node when showing edit form', function () {
  const fresh = { val: sinon.spy() };
  this.stub(RichContentEditor, 'freshNode').returns(fresh);
  this.stub(RichContentEditor, 'loadNewEditor');
  fixtures.create('<div id="course_syllabus"></div>');
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>');
  fixtures.create('<form id="edit_course_syllabus_form"></form>');
  fixtures.create('<textarea id="course_syllabus_body"></textarea>');
  const text = 'foo';
  $('#course_syllabus').data('syllabus_body', text);
  const $form = SyllabusBehaviors.bindToEditSyllabus();
  $form.triggerHandler('edit');
  ok(RichContentEditor.freshNode.called);
  const body = document.getElementById('course_syllabus_body');
  equal(RichContentEditor.freshNode.firstCall.args[0][0], body);
  ok(fresh.val.calledWith(text));
});

test('sets course_syllabus_body after mce destruction', function () {
  this.stub(RichContentEditor, 'destroyRCE').callsFake( ()=> {
     let elem = document.getElementById('course_syllabus_body');
     elem.parentNode.removeChild(elem);
  });
  fixtures.create('<div id="course_syllabus"></div>');
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>');
  fixtures.create('<form id="edit_course_syllabus_form"></form>');
  fixtures.create('<div id="tinymce-parent-of-course_syllabus_body"><textarea id="course_syllabus_body"></textarea></div>');
  const $form = SyllabusBehaviors.bindToEditSyllabus();
  $form.triggerHandler('hide_edit');
  ok(RichContentEditor.destroyRCE.called)
  const body = document.getElementById('course_syllabus_body');
  ok(body !== null);
});
