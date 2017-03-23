import SyllabusBehaviors from 'compiled/behaviors/SyllabusBehaviors';
import Sidebar from 'jsx/shared/rce/Sidebar';
import editorUtils from 'helpers/editorUtils';
import fixtures from 'helpers/fixtures';
import $ from 'jquery';

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
  }
});

test('sets focus to the edit button when hide_edit occurs', function () {
  fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>');
  fixtures.create('<form id="edit_course_syllabus_form"></form>');
  SyllabusBehaviors.bindToEditSyllabus();
  $('#edit_course_syllabus_form').trigger('hide_edit');
  equal(document.activeElement, $('.edit_syllabus_link')[0]);
});
