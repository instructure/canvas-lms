define [
  'jsx/shared/rce/RichContentEditor',
  'jsx/shared/rce/serviceRCELoader',
  'jquery',
  'helpers/fakeENV',
  'helpers/editorUtils'
], (RichContentEditor, RCELoader, $, fakeENV, editorUtils) ->

  QUnit.module 'Rce Abstraction - integration',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_CDN_HOST = "fakeCDN.com"
      ENV.RICH_CONTENT_APP_HOST = "app-host"
      $textarea = $("""
        <textarea id="big_rce_text" name="context[big_rce_text]"></textarea>
      """)
      $('#fixtures').empty()
      $('#fixtures').append($textarea)
      @fakeRceModule = {
        props: {}
        renderIntoDiv: (renderingTarget, propsForRCE, renderCallback)=>
           $(renderingTarget).append("<div id='fake-editor'>" + propsForRCE.toString() + "</div>")
           renderCallback()
      }
      sinon.stub($, "getScript").callsFake((url, callback) =>
        window.RceModule = @fakeRceModule
        callback()
      )

    teardown: ->
      fakeENV.teardown()
      $('#fixtures').empty()
      $.getScript.restore()
      editorUtils.resetRCE()

  test "instatiating a remote editor", ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    RichContentEditor.preloadRemoteModule()
    target = $("#big_rce_text")
    RichContentEditor.loadNewEditor(target, { manageParent: true })
    equal(window.RceModule, @fakeRceModule)
    equal(target.parent().attr("id"), "tinymce-parent-of-big_rce_text")
    equal(target.parent().find("#fake-editor").length, 1)

  test "instatiating a local editor", ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    RichContentEditor.preloadRemoteModule()
    target = $("#big_rce_text")
    RichContentEditor.loadNewEditor(target, { manageParent: true })
    equal($("#fake-editor").length, 0)
