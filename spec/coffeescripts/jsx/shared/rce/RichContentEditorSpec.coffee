define [
  'jsx/shared/rce/RichContentEditor',
  'jsx/shared/rce/serviceRCELoader',
  'jsx/shared/rce/rceStore',
  'helpers/fakeENV'
], (RichContentEditor, serviceRCELoader, rceStore, fakeENV) ->

  wikiSidebar = undefined

  module 'RichContentEditor - preloading',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = true
      @preloadSpy = sinon.spy(serviceRCELoader, "preload");

    teardown: ->
      fakeENV.teardown()
      serviceRCELoader.preload.restore()

  test 'loads with CDN host if available', ->
    ENV.RICH_CONTENT_CDN_HOST = "cdn-host"
    ENV.RICH_CONTENT_APP_HOST = "app-host"
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    richContentEditor.preloadRemoteModule()
    ok @preloadSpy.calledWith("cdn-host")

  test 'uses app host if no cdn host', ->
    ENV.RICH_CONTENT_CDN_HOST = undefined
    ENV.RICH_CONTENT_APP_HOST = "app-host"
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    richContentEditor.preloadRemoteModule()
    ok @preloadSpy.calledWith("app-host")

  test 'does nothing when service disabled', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = undefined
    ENV.RICH_CONTENT_CDN_HOST = "cdn-host"
    ENV.RICH_CONTENT_APP_HOST = "app-host"
    richContentEditor = new RichContentEditor({riskLevel: 'basic'})
    richContentEditor.preloadRemoteModule()
    ok @preloadSpy.notCalled


  module 'RichContentEditor - loading editor',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = true
      ENV.RICH_CONTENT_APP_HOST = "http://fakehost.com"
      @originalLoadOnTarget = serviceRCELoader.loadOnTarget
      @target = {
        attr: (()-> "fakeTarget")
      }
      @fakeJquery = ()=>
        return @target # length is at least one
      @fakeJquery.extend = $.extend
      serviceRCELoader.loadOnTarget = sinon.stub()
    teardown: ->
      serviceRCELoader.loadOnTarget = @originalLoadOnTarget
      fakeENV.teardown()

  test 'calls serviceRCELoader.loadOnTarget with a target and host', ->
    richContentEditor = new RichContentEditor({riskLevel: 'basic', jQuery: @fakeJquery})
    richContentEditor.loadNewEditor(@target, {})
    ok serviceRCELoader.loadOnTarget.calledWith(@target, {}, "http://fakehost.com")

  test 'CDN host overrides app host', ->
    ENV.RICH_CONTENT_CDN_HOST = "http://fakecdn.net"
    richContentEditor = new RichContentEditor({riskLevel: 'basic', jQuery: @fakeJquery})
    richContentEditor.loadNewEditor(@target, {})
    ok serviceRCELoader.loadOnTarget.calledWith(@target, {}, "http://fakecdn.net")

  test 'calls editorBox and set_code when feature flag off', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    richContentEditor = new RichContentEditor({riskLevel: 'basic', jQuery: @fakeJquery})
    secondStub = sinon.stub()
    ebStub = sinon.stub().returns({editorBox: secondStub})
    fakeTarget =
      attr: (()-> fakeTarget)
      editorBox: ebStub
    opts =
      defaultContent: "content"
    richContentEditor.loadNewEditor(fakeTarget, opts)
    ok ebStub.called
    ok secondStub.calledWith('set_code', "content")

  test 'skips instantiation when called with empty target', ->
    notFoundJquery = ->
      return []# length is 0
    notFoundJquery.extend = $.extend
    richContentEditor = new RichContentEditor({riskLevel: 'basic', jQuery: notFoundJquery})
    richContentEditor.loadNewEditor(".invalidTarget", {})
    ok !serviceRCELoader.loadOnTarget.called

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
      @_loadSidebarOnTarget = serviceRCELoader.loadSidebarOnTarget
      serviceRCELoader.loadSidebarOnTarget = (target, host, callback)->
        callback({is_a: 'remote_sidebar'})
    teardown: ->
      serviceRCELoader.loadSidebarOnTarget = @_loadSidebarOnTarget
      fakeENV.teardown()

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
      @callOnRceSpy = sinon.stub(rceStore, "callOnRCE");
      fakeENV.setup()
      @targetElement = {
        is_a: "dom_element",
        attr: (()-> "fakeId")
        oldSchoolCalled: false,
        editorBox: ()=>
          @targetElement.oldSchoolCalled = true
      }
      @fakeJquery = ()=>
        return @targetElement

    teardown: ->
      fakeENV.teardown()
      rceStore.callOnRCE.restore()

  test 'with flag enabled, ultimately lets RCEStore handle the message', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = true
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = true
    richContentEditor = new RichContentEditor({riskLevel: 'basic', jQuery: @fakeJquery})
    richContentEditor.callOnRCE(@targetElement, "someMethod")
    equal(@targetElement.oldSchoolCalled, false)
    ok @callOnRceSpy.calledWith(@targetElement, "someMethod")

  test 'with flag disabled, lets editorbox work it out', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = false
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = false
    richContentEditor = new RichContentEditor({riskLevel: 'basic', jQuery: @fakeJquery})
    richContentEditor.callOnRCE(@targetElement, "someMethod")
    ok !@callOnRceSpy.called
    ok @targetElement.oldSchoolCalled
