define [
  'jsx/shared/rce/RichContentEditor',
  'jsx/shared/rce/RceCommandShim',
  'jsx/shared/rce/serviceRCELoader',
  'jsx/shared/rce/Sidebar',
  'helpers/fakeENV'
  'helpers/editorUtils'
  'helpers/fixtures'
], (RichContentEditor, RceCommandShim, RCELoader, Sidebar, fakeENV, editorUtils, fixtures) ->

  module 'RichContentEditor - preloading',
    setup: ->
      fakeENV.setup()
      @preloadSpy = sinon.spy(RCELoader, "preload")

    teardown: ->
      fakeENV.teardown()
      RCELoader.preload.restore()
      editorUtils.resetRCE()

  test 'loads via RCELoader.preload when service enabled', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_APP_HOST = 'app-host'
    RichContentEditor.preloadRemoteModule()
    ok @preloadSpy.called

  test 'does nothing when service disabled', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = undefined
    RichContentEditor.preloadRemoteModule()
    ok @preloadSpy.notCalled

  module 'RichContentEditor - loading editor',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = true
      ENV.RICH_CONTENT_APP_HOST = "http://fakehost.com"
      fixtures.setup()
      @$target = fixtures.create('<textarea id="myEditor" />')
      sinon.stub(RCELoader, 'loadOnTarget')

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      RCELoader.loadOnTarget.restore()
      editorUtils.resetRCE()

  test 'calls RCELoader.loadOnTarget with target and options', ->
    sinon.stub(RichContentEditor, 'freshNode').withArgs(@$target).returns(@$target)
    options = {}
    RichContentEditor.loadNewEditor(@$target, options)
    ok RCELoader.loadOnTarget.calledWith(@$target, options)
    RichContentEditor.freshNode.restore()

  test 'calls editorBox and set_code when feature flag off', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    sinon.stub(@$target, 'editorBox')
    @$target.editorBox.onCall(0).returns(@$target)
    RichContentEditor.loadNewEditor(@$target, {defaultContent: "content"})
    ok @$target.editorBox.calledTwice
    ok @$target.editorBox.firstCall.calledWith()
    ok @$target.editorBox.secondCall.calledWith('set_code', "content")

  test 'skips instantiation when called with empty target', ->
    RichContentEditor.loadNewEditor("#fixtures .invalidTarget", {})
    ok RCELoader.loadOnTarget.notCalled

  test 'with focus:true calls focus on RceCommandShim after load', ->
    # false so we don't have to stub out freshNode or RCELoader.loadOnTarget
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    sinon.stub(RceCommandShim, 'focus')
    RichContentEditor.loadNewEditor(@$target, {focus: true})
    ok RceCommandShim.focus.calledWith(@$target)
    RceCommandShim.focus.restore()

  test 'with focus:true tries to show sidebar', ->
    # false so we don't have to stub out RCELoader.loadOnTarget
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    RichContentEditor.initSidebar()
    sinon.spy(Sidebar, 'show')
    RichContentEditor.loadNewEditor(@$target, {focus: true})
    ok Sidebar.show.called
    Sidebar.show.restore()

  test 'hides resize handle when called', ->
    $resize = fixtures.create('<div class="mce-resizehandle"></div>')
    RichContentEditor.loadNewEditor(@$target, {})
    equal $resize.attr('aria-hidden'), "true"

  module 'RichContentEditor - callOnRCE',
    setup: ->
      fakeENV.setup()
      fixtures.setup()
      @$target = fixtures.create('<textarea id="myEditor" />')
      sinon.stub(RceCommandShim, 'send').returns('methodResult')

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      RceCommandShim.send.restore()
      editorUtils.resetRCE()

  test 'proxies to RceCommandShim', ->
    equal RichContentEditor.callOnRCE(@$target, 'methodName', 'methodArg'), 'methodResult'
    ok RceCommandShim.send.calledWith(@$target, 'methodName', 'methodArg')

  test 'with flag enabled freshens node before passing to RceCommandShim', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    $freshTarget = $(@$target) # new jquery obj of same node
    sinon.stub(RichContentEditor, 'freshNode').withArgs(@$target).returns($freshTarget)
    equal RichContentEditor.callOnRCE(@$target, 'methodName', 'methodArg'), 'methodResult'
    ok RceCommandShim.send.calledWith($freshTarget, 'methodName', 'methodArg')
    RichContentEditor.freshNode.restore()

  module 'RichContentEditor - destroyRCE',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = false
      fixtures.setup()
      @$target = fixtures.create('<textarea id="myEditor" />')

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      editorUtils.resetRCE()

  test 'proxies destroy to RceCommandShim', ->
    sinon.stub(RceCommandShim, 'destroy')
    RichContentEditor.destroyRCE(@$target)
    ok RceCommandShim.destroy.calledWith(@$target)
    RceCommandShim.destroy.restore()

  test 'tries to hide the sidebar', ->
    RichContentEditor.initSidebar()
    sinon.spy(Sidebar, 'hide')
    RichContentEditor.destroyRCE(@$target)
    ok Sidebar.hide.called
    Sidebar.hide.restore()

  module 'RichContentEditor - clicking into editor (editor_box_focus)',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = false
      fixtures.setup()
      @$target = fixtures.create('<textarea id="myEditor" />')
      RichContentEditor.loadNewEditor(@$target)
      sinon.stub(RceCommandShim, 'focus')

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      editorUtils.resetRCE()
      RceCommandShim.focus.restore()

  test 'on target causes target to focus', ->
    # would be nicer to test based on actual click causing this trigger, but
    # not sure how to do that. for now this will do
    @$target.triggerHandler('editor_box_focus')
    ok RceCommandShim.focus.calledWith(@$target)

  test 'with multiple targets only focuses triggered target', ->
    # would be nicer to test based on actual click causing this trigger, but
    # not sure how to do that. for now this will do
    $otherTarget = fixtures.create('<textarea id="otherEditor" />')
    RichContentEditor.loadNewEditor($otherTarget)
    $otherTarget.triggerHandler('editor_box_focus')
    ok RceCommandShim.focus.calledOnce
    ok RceCommandShim.focus.calledWith($otherTarget)
    ok RceCommandShim.focus.neverCalledWith(@$target)
