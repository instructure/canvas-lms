define [
  'jquery'
  'compiled/views/tinymce/InsertUpdateImageView'
  'jsx/shared/rce/RceCommandShim'
], ($, InsertUpdateImageView, RceCommandShim) ->
  fakeEditor = undefined

  module "InsertUpdateImageView#update",
    setup: ->
      fakeEditor = {
        id: "someId"
        focus: ()->
        dom: {
          createHTML: (()=> return "<a href='#'>stub link html</a>")
        }
        selection: {
          getBookmark: ()->
          moveToBookmark: ()->
        }
      }

      sinon.stub(RceCommandShim.prototype, 'send')

    teardown: ->
      $("#fixtures").html("")
      RceCommandShim.prototype.send.restore()

  test "it uses RceCommandShim to call insert_code", ->
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = '$fakeEditor'
    view.update()
    ok RceCommandShim.prototype.send.calledWith('$fakeEditor', 'insert_code', view.generateImageHtml())
