define [
  'compiled/behaviors/SyllabusBehaviors',
  'jsx/shared/rce/Sidebar',
  'helpers/editorUtils',
  'helpers/fixtures',
  'jsx/shared/rce/RichContentEditor',
  'jquery'
], (SyllabusBehaviors, Sidebar, editorUtils, fixtures, RichContentEditor, $) ->

  module 'SyllabusBehaviors.bindToEditSyllabus',
    setup: ->
      editorUtils.resetRCE()
      fixtures.setup()
      @stub(Sidebar, 'init')

    teardown: ->
      # on successful bindToEditSyllabus, it will have added keyboard
      # shortcut bindings that we don't actually want to keep. unfortunately
      # we don't have a handle on the KeyboardShortcut view object to just
      # call `.remove()` :(
      if $('.ui-dialog').length > 0
        $(document).off('keyup.tinymce_keyboard_shortcuts')
        $(document).off('editorKeyUp')
        $('.ui-dialog').remove()

      editorUtils.resetRCE()
      fixtures.teardown()

  test "initializes sidebar when edit link present", ->
    fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
    SyllabusBehaviors.bindToEditSyllabus()
    ok Sidebar.init.called, 'foo'

  test "skips initializing sidebar when edit link absent", ->
    equal fixtures.find('.edit_syllabus_link').length, 0
    SyllabusBehaviors.bindToEditSyllabus()
    ok Sidebar.init.notCalled, 'bar'

  test "sets syllabus_body data value on fresh node when showing edit form", ->
    fresh = val: sinon.spy()
    @stub(RichContentEditor, 'freshNode').returns(fresh)
    @stub(RichContentEditor, 'loadNewEditor')
    fixtures.create('<div id="course_syllabus"></div>')
    fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
    fixtures.create('<form id="edit_course_syllabus_form"></form>')
    fixtures.create('<textarea id="course_syllabus_body"></textarea>')
    text = 'foo'
    $('#course_syllabus').data('syllabus_body', text)
    $form = SyllabusBehaviors.bindToEditSyllabus()
    $form.triggerHandler('edit')
    ok RichContentEditor.freshNode.called
    body = document.getElementById('course_syllabus_body')
    equal RichContentEditor.freshNode.firstCall.args[0][0], body
    ok fresh.val.calledWith(text)
