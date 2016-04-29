define [
  'compiled/behaviors/SyllabusBehaviors',
  'jsx/shared/rce/Sidebar',
  'helpers/editorUtils',
  'helpers/fixtures'
], (SyllabusBehaviors, Sidebar, editorUtils, fixtures) ->

  module 'SyllabusBehaviors.bindToEditSyllabus',
    setup: ->
      editorUtils.resetRCE()
      fixtures.setup()
      sinon.spy(Sidebar, 'init')

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
      Sidebar.init.restore()

  test "initializes sidebar when edit link present", ->
    fixtures.create('<a href="#" class="edit_syllabus_link">Edit Link</a>')
    SyllabusBehaviors.bindToEditSyllabus()
    ok Sidebar.init.called, 'foo'

  test "skips initializing sidebar when edit link absent", ->
    equal fixtures.find('.edit_syllabus_link').length, 0
    SyllabusBehaviors.bindToEditSyllabus()
    ok Sidebar.init.notCalled, 'bar'
