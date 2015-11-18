define [
  'jquery'
  'compiled/views/tinymce/InsertUpdateImageView'
  'helpers/fakeENV'
], ($, InsertUpdateImageView, fakeENV) ->
  fakeEditor = undefined
  $fakeEditor = undefined

  module "InsertUpdateImageView#update",
    setup: ->
      fakeENV.setup()

      fakeEditor = {
        id: "someId",
        bookmarkMoved: false,
        focus: (()=>),
        dom: {
          createHTML: (()=> return "<a href='#'>stub link html</a>")
        },
        selection: {
          getBookmark: (()=> {})
          moveToBookmark: (prevSelect)=>
            fakeEditor.bookmarkMoved = true
        }
      }

      $fakeEditor = {
        editorBoxCalled: false,
        editorBox: ()=>
          $fakeEditor.editorBoxCalled = true
      }

    teardown: ->
      fakeENV.teardown()
      $("#fixtures").html("")

  test "it uses editorBox when feature flag disabled", ->
    window.ENV.RICH_CONTENT_SERVICE_ENABLED = false
    view = new InsertUpdateImageView(fakeEditor, "<div></div>")
    view.$editor = $fakeEditor
    view.update()
    equal($fakeEditor.editorBoxCalled, true)
