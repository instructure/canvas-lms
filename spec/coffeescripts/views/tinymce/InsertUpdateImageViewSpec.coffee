define [
  'jquery'
  'compiled/views/tinymce/InsertUpdateImageView'
  'jsx/shared/rce/RceCommandShim'
], ($, InsertUpdateImageView, RceCommandShim) ->
  fakeEditor = undefined
  moveToBookmarkSpy = undefined

  QUnit.module "InsertUpdateImageView#update",
    setup: ->
      moveToBookmarkSpy = sinon.spy()
      fakeEditor = {
        id: "someId"
        focus: ()->
        dom: {
          createHTML: (()=> return "<a href='#'>stub link html</a>")
        }
        selection: {
          getBookmark: ()->
          moveToBookmark: moveToBookmarkSpy
        }
      }

      sinon.stub(RceCommandShim, 'send')

    teardown: ->
      $("#fixtures").html("")
      RceCommandShim.send.restore()

  test "it uses RceCommandShim to call insert_code", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.update()
    ok RceCommandShim.send.calledWith('$fakeEditor', 'insert_code', view.generateImageHtml())

  test "it restores caret on update", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.update()
    ok moveToBookmarkSpy.called

  test "it restores caret on close", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.close()
    ok moveToBookmarkSpy.called
