define [
  'tinymce_plugins/instructure_record/mediaEditorLoader',
  'jsx/shared/rce/RceCommandShim',
  'jquery'
], (mediaEditorLoader, RceCommandShim, $)->

  QUnit.module "mediaEditorLoader",
    setup: ->
      sinon.stub(RceCommandShim, 'send')
      @mel = mediaEditorLoader

      @collapseSpy = sinon.spy()
      @selectSpy = sinon.spy()
      @fakeED =
        getBody: ()->
        selection:
          select: @selectSpy
          collapse: @collapseSpy

    teardown: ->
      RceCommandShim.send.restore()
      window.$.mediaComment.restore  && window.$.mediaComment.restore()

  test 'properly makes link html', ->
    linkHTML = @mel.makeLinkHtml("FOO", "BAR")
    expectedResult =  "<a href='/media_objects/FOO' class='instructure_inline_media_comment BAR" +
      "_comment' id='media_comment_FOO'>this is a media comment</a><br>";

    equal linkHTML, expectedResult

  test 'creates a callback that will run callONRCE', ->
    @mel.commentCreatedCallback(@fakeED, "ID", "TYPE")
    ok RceCommandShim.send.called

  test 'creates a callback that try to collapse a selection', ->
    @mel.commentCreatedCallback(@fakeED, "ID", "TYPE")
    ok @selectSpy.called
    ok @collapseSpy.called

  test 'calls mediaComment with a function', ->
    window.$.mediaComment
    sinon.spy(window.$, "mediaComment")
    @mel.insertEditor("foo")
    ok window.$.mediaComment.calledWith('create', 'any')
    spyCall = window.$.mediaComment.getCall(0)
    lastArgType = typeof spyCall.args[2]
    equal "function", lastArgType
