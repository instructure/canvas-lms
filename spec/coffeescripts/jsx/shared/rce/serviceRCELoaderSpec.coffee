define [
  'jquery'
  'jsx/shared/rce/serviceRCELoader'
  'helpers/editorUtils'
  'helpers/fakeENV'
  'helpers/fixtures'
], ($, RCELoader, editorUtils, fakeENV, fixtures) ->
  module 'loadRCE',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_APP_HOST = 'app-host'
      # make sure we don't get a cached thing from other tests
      RCELoader.cachedModule = null
      @getScriptSpy = sinon.stub $, "getScript", (__host__, callback)=>
        window.RceModule = 'fakeModule'
        callback()

    teardown: ->
      fakeENV.teardown()
      $.getScript.restore()
      editorUtils.resetRCE()

  # loading RCE

  test 'calls getScript with ENV.RICH_CONTENT_APP_HOST and /get_module if no CDN host', ->
    RCELoader.loadRCE(()->)
    ok @getScriptSpy.calledWith("//app-host/get_module")

  test 'prefers ENV.RICH_CONTENT_APP_HOST with /latest over app host for getScript call', ->
    ENV.RICH_CONTENT_CDN_HOST = 'cdn-host'
    RCELoader.loadRCE(()->)
    ok @getScriptSpy.calledWith("//cdn-host/latest")

  test 'caches the response of get_module when called', ->
    RCELoader.cachedModule = null
    RCELoader.loadRCE(()->)
    equal RCELoader.cachedModule, 'fakeModule'

  test 'does not call get_module once a response has been cached', ->
    RCELoader.cachedModule = "foo"
    RCELoader.loadRCE(()->)
    ok @getScriptSpy.notCalled

  test 'executes a callback when RCE is loaded', ->
    cb = sinon.spy()
    RCELoader.loadRCE(cb)
    ok cb.called

  test 'only tries to load the module once', ->
    RCELoader.preload()
    RCELoader.preload()
    RCELoader.preload()
    ok(@getScriptSpy.calledOnce)

  asyncTest 'handles callbacks once module is loaded', ->
    expect(1)
    resolveGetScript = null
    $.getScript.restore()
    sinon.stub $, "getScript", (__host__, callback)=>
      resolveGetScript = ()->
        window.RceModule = 'fakeModule'
        callback()
    # first make sure all the state is fixed so test call isn't
    # making it's own getScript call
    RCELoader.preload()
    RCELoader.loadRCE(()->)

    # now setup while-in-flight load request to check
    RCELoader.loadRCE (module) =>
      start()
      equal(module, "fakeModule")
    resolveGetScript()

  module 'loadOnTarget',
    setup: ->
      fixtures.setup()
      @$div = fixtures.create('<div><textarea id="theTarget" name="elementName" /></div>')
      @$textarea = fixtures.find('#theTarget')
      @editor = {}
      @rce = { renderIntoDiv: sinon.stub().callsArgWith(2, @editor) }
      sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, @rce)

    teardown: ->
      fixtures.teardown()
      RCELoader.loadRCE.restore()

  # target finding

  test 'finds a target textarea if a textarea is passed in', ->
    equal RCELoader.getTargetTextarea(@$textarea), @$textarea.get(0)

  test 'finds a target textarea if a normal div is passed in', ->
    equal RCELoader.getTargetTextarea(@$div), @$textarea.get(0)

  test 'returns the textareas parent as the renderingTarget when no custom function given', ->
    equal RCELoader.getRenderingTarget(@$textarea.get(0)), @$div.get(0)

  test 'returned parent has class `ic-RichContentEditor`', ->
    target = RCELoader.getRenderingTarget(@$textarea.get(0))
    ok $(target).hasClass('ic-RichContentEditor')

  test 'uses a custom get target function if given', ->
    customFn = -> "someCustomTarget"
    RCELoader.loadOnTarget(@$textarea, {getRenderingTarget: customFn}, ()->)
    ok @rce.renderIntoDiv.calledWith("someCustomTarget")

  # propsForRCE construction

  test 'extracts content from the target', ->
    @$textarea.val('some text here')
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.defaultContent, "some text here"

  test 'falls back to defaultContent if target has no content', ->
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.defaultContent, "default text"

  test 'passes the textarea height into tinyOptions', ->
    taHeight = "123"
    textarea = { offsetHeight: taHeight }
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(textarea, opts)
    equal opts.tinyOptions.height, taHeight

  test 'adds the elements name attribute to mirroredAttrs', ->
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.mirroredAttrs.name, "elementName"

  test 'adds onFocus to props', ->
    opts = {onFocus: ->}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.onFocus, opts.onFocus

  test 'renders with rce', ->
    RCELoader.loadOnTarget(@$div, {}, ()->)
    ok @rce.renderIntoDiv.calledWith(@$div.get(0))

  test 'yields editor to callback', ->
    cb = sinon.spy()
    RCELoader.loadOnTarget(@$div, {}, cb)
    ok cb.calledWith(@$textarea.get(0), @editor)

  test 'ensures yielded editor has call and focus methods', ->
    cb = sinon.spy()
    RCELoader.loadOnTarget(@$div, {}, cb)
    equal typeof @editor.call, 'function'
    equal typeof @editor.focus, 'function'

  module 'loadSidebarOnTarget',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_APP_HOST = 'http://rce.host'
      ENV.RICH_CONTENT_CAN_UPLOAD_FILES = true
      ENV.context_asset_string = 'courses_1'
      fixtures.setup()
      @$div = fixtures.create('<div />')
      @sidebar = {}
      @rce = { renderSidebarIntoDiv: sinon.stub().callsArgWith(2, @sidebar) }
      sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, @rce)

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      RCELoader.loadRCE.restore()

  test 'passes host and context from ENV as props to sidebar', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    ok @rce.renderSidebarIntoDiv.called
    props = @rce.renderSidebarIntoDiv.args[0][1]
    equal props.host, 'http://rce.host'
    equal props.contextType, 'courses'
    equal props.contextId, '1'

  test 'yields sidebar to callback', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    ok cb.calledWith(@sidebar)

  test 'ensures yielded sidebar has show and hide methods', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    equal typeof @sidebar.show, 'function'
    equal typeof @sidebar.hide, 'function'

  test 'provides a callback for loading a new jwt', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    ok @rce.renderSidebarIntoDiv.called
    props = @rce.renderSidebarIntoDiv.args[0][1]
    equal(typeof props.refreshToken, 'function')

  test 'passes brand config json url', ->
    ENV.active_brand_config_json_url = {}
    RCELoader.loadSidebarOnTarget(@$div, ->)
    props = @rce.renderSidebarIntoDiv.args[0][1]
    equal props.themeUrl, ENV.active_brand_config_json_url
