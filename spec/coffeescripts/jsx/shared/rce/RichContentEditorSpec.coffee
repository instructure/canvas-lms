define [
  'jsx/shared/rce/RichContentEditor',
  'jsx/shared/rce/RceCommandShim',
  'jsx/shared/rce/serviceRCELoader',
  'helpers/fakeENV'
  'helpers/editorUtils'
  'helpers/fixtures'
], (RichContentEditor, RceCommandShim, RCELoader, fakeENV, editorUtils, fixtures) ->

  wikiSidebar = undefined

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
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    richContentEditor.preloadRemoteModule()
    ok @preloadSpy.called

  test 'does nothing when service disabled', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = undefined
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    richContentEditor.preloadRemoteModule()
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

  test 'calls RCELoader.loadOnTarget with target and options', ->
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    sinon.stub(richContentEditor, 'freshNode').withArgs(@$target).returns(@$target)
    options = {}
    richContentEditor.loadNewEditor(@$target, options)
    ok RCELoader.loadOnTarget.calledWith(@$target, options)

  test 'calls editorBox and set_code when feature flag off', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    sinon.stub(@$target, 'editorBox')
    @$target.editorBox.onCall(0).returns(@$target)
    richContentEditor.loadNewEditor(@$target, {defaultContent: "content"})
    ok @$target.editorBox.calledTwice
    ok @$target.editorBox.firstCall.calledWith()
    ok @$target.editorBox.secondCall.calledWith('set_code', "content")

  test 'skips instantiation when called with empty target', ->
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    richContentEditor.loadNewEditor("#fixtures .invalidTarget", {})
    ok RCELoader.loadOnTarget.notCalled

  module 'RichContentEditor - initSidebar',
    setup: ->
      fakeENV.setup()
      wikiSidebar = {
        inited: false,
        hid: false,
        shown: false,
        editor: undefined,
        hide: ->
          wikiSidebar.hid = true
        show: ->
          wikiSidebar.shown = true
        init: ->
          wikiSidebar.inited = true
        attachToEditor: (ed)->
          wikiSidebar.editor = ed
      }
      sinon.stub(RCELoader, "loadSidebarOnTarget").callsArgWith(1, {is_a: 'remote_sidebar'})

    teardown: ->
      fakeENV.teardown()
      RCELoader.loadSidebarOnTarget.restore()

  test 'uses wikiSidebar when feature flag off', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    richContentEditor = new RichContentEditor({sidebar: wikiSidebar, riskLevel: 'basic'})
    richContentEditor.initSidebar()
    ok(wikiSidebar.inited)
    equal(richContentEditor.remoteSidebar, undefined)

  test 'uses wikiSidebar in a high risk area with only low risk feature flagged', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_SIDEBAR_ENABLED = false
    ENV.RICH_CONTENT_HIGH_RISK_ENABLED = false
    richContentEditor = new RichContentEditor({sidebar: wikiSidebar, riskLevel: 'highrisk'})
    richContentEditor.initSidebar()
    ok(wikiSidebar.inited)

  test 'loads remote sidebar when all flags enabled', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_SIDEBAR_ENABLED = true
    ENV.RICH_CONTENT_HIGH_RISK_ENABLED = true
    richContentEditor = new RichContentEditor({sidebar: wikiSidebar, riskLevel: 'highrisk'})
    richContentEditor.initSidebar()
    ok(!wikiSidebar.inited)
    equal(richContentEditor.remoteSidebar.is_a, 'remote_sidebar')

  test 'hiding local wiki sidebar', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    richContentEditor = new RichContentEditor({sidebar: wikiSidebar, riskLevel: 'basic'})
    richContentEditor.hideSidebar()
    ok(wikiSidebar.hid)

  test 'attaching to an editor', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    richContentEditor = new RichContentEditor({sidebar: wikiSidebar, riskLevel: 'basic'})
    editor = {is_a: "editor_element"}
    richContentEditor.attachSidebarTo(editor,()->{})
    equal(wikiSidebar.editor.is_a, "editor_element")
    ok(wikiSidebar.shown)

  test 'attaching without a callback doesnt explode', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    new RichContentEditor({sidebar: wikiSidebar, riskLevel: 'basic'}).attachSidebarTo({})
    ok(true) # did not throw error

  module 'RichContentEditor - callOnRCE',
    setup: ->
      fakeENV.setup()
      fixtures.setup()
      @$target = fixtures.create('<textarea id="myEditor" />')
      sinon.stub(RceCommandShim.prototype, 'send').returns('methodResult')

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      RceCommandShim.prototype.send.restore()
      editorUtils.resetRCE()

  test 'proxies to RceCommandShim', ->
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    equal richContentEditor.callOnRCE(@$target, 'methodName', 'methodArg'), 'methodResult'
    ok RceCommandShim.prototype.send.calledWith(@$target, 'methodName', 'methodArg')

  test 'with flag enabled freshens node before passing to RceCommandShim', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = true
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    $freshTarget = $(@$target) # new jquery obj of same node
    sinon.stub(richContentEditor, 'freshNode').withArgs(@$target).returns($freshTarget)
    equal richContentEditor.callOnRCE(@$target, 'methodName', 'methodArg'), 'methodResult'
    ok RceCommandShim.prototype.send.calledWith($freshTarget, 'methodName', 'methodArg')
