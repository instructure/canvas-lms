define [
  'jsx/shared/rce/RichContentEditor',
  'jsx/shared/rce/serviceRCELoader',
  'jquery',
  'helpers/fakeENV',
  'helpers/editorUtils'
], (RichContentEditor, RCELoader, $, fakeENV, editorUtils) ->

  wikiSidebar = undefined

  module 'Rce Abstraction - integration',
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
      sinon.stub($, "getScript", ((url, callback)=>
        window.tinyrce = {
          editorsListing: []
        }
        window.RceModule = @fakeRceModule
        callback()
      ));

    teardown: ->
      fakeENV.teardown()
      $('#fixtures').empty()
      $.getScript.restore()
      editorUtils.resetRCE()

  test "instatiating a remote editor", ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_SIDEBAR_ENABLED = true
    ENV.RICH_CONTENT_HIGH_RISK_ENABLED = true
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = true
    richContentEditor = new RichContentEditor({riskLevel: "highrisk"})
    richContentEditor.preloadRemoteModule()
    target = $("#big_rce_text")
    richContentEditor.loadNewEditor(target, { manageParent: true })
    equal(window.RceModule, @fakeRceModule)
    equal(target.parent().attr("id"), "tinymce-parent-of-big_rce_text")
    equal(target.parent().find("#fake-editor").length, 1)

  test "instatiating a local editor", ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    ENV.RICH_CONTENT_SIDEBAR_ENABLED = false
    ENV.RICH_CONTENT_HIGH_RISK_ENABLED = false
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = false
    richContentEditor = new RichContentEditor({riskLevel: "highrisk"})
    richContentEditor.preloadRemoteModule()
    target = $("#big_rce_text")
    richContentEditor.loadNewEditor(target, { manageParent: true })
    equal($("#fake-editor").length, 0)
