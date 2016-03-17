define [
  'jquery'
  'jsx/shared/rce/serviceRCELoader'
  'helpers/editorUtils'
  'helpers/fakeENV'
], ($, RCELoader, editorUtils, fakeENV) ->
  module 'loadRCE',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_APP_HOST = 'app-host'
      # make sure we don't get a cached thing from other tests
      RCELoader.cachedModule = null
      @elementInFixtures = (type) ->
        newElement = document.createElement(type)
        fixtureDiv = document.getElementById("fixtures")
        fixtureDiv.appendChild(newElement)
        newElement
      @getScriptSpy = sinon.stub $, "getScript", (__host__, callback)=>
        window.RceModule = 'fakeModule'
        callback()

    teardown: ->
      fakeENV.teardown()
      $.getScript.restore()
      editorUtils.resetRCE()
      document.getElementById("fixtures").innerHtml = ""

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

  # target finding

  test 'finds a target textarea if a textarea is passed in', ->
    ta = @elementInFixtures('textarea');
    targetTextarea = RCELoader.getTargetTextarea(ta)
    equal targetTextarea, ta

  test 'finds a target textarea if a normal div is passed in', ->
    d = @elementInFixtures('div')
    ta = document.createElement('textarea')
    ta.setAttribute("id", "theTarget")
    d.appendChild(ta)
    targetTextarea = RCELoader.getTargetTextarea(d)
    equal targetTextarea.id, "theTarget"

  test 'returns the textareas parent as the renderingTarget when no custom function given', ->
    d = @elementInFixtures('div')
    ta = document.createElement('textarea')
    ta.setAttribute("id", "theTarget")
    d.appendChild(ta)
    renderingTarget = RCELoader.getRenderingTarget(ta)
    equal renderingTarget, d

  test 'uses a custom get target function if given', ->
    d = @elementInFixtures('div')
    ta = document.createElement('textarea')
    d.appendChild(ta)
    customFn = ()->
      return "someCustomTarget"

    renderIntoDivSpy = sinon.spy()
    fakeRCE = { renderIntoDiv: renderIntoDivSpy }
    sinon.stub(RCELoader, "loadRCE").callsArgWith(0, fakeRCE)

    # execute renderIntoDivSpy
    RCELoader.loadOnTarget(ta, {getRenderingTarget: customFn})
    ok renderIntoDivSpy.calledWith("someCustomTarget")
    RCELoader.loadRCE.restore()

  # propsForRCE construction

  test 'extracts content from the target', ->
    ta = @elementInFixtures('textarea')
    ta.value = "some text here";
    props = RCELoader.createRCEProps(ta, {defaultContent: "default text"})
    equal props.defaultContent, "some text here"

  test 'passes the textarea height into tinyOptions', ->
    taHeight = "123"
    ta = {
      offsetHeight: taHeight
    }

    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(ta, opts)
    equal opts.tinyOptions.height, taHeight

  test 'falls back to defaultContent if target has no content', ->
    ta = @elementInFixtures('textarea')
    props = RCELoader.createRCEProps(ta, {defaultContent: "default text"})
    equal props.defaultContent, "default text"

  test 'adds the elements name attribute to mirroedAttrs', ->
    ta = @elementInFixtures('textarea')
    ta.setAttribute("name", "elementName")
    props = RCELoader.createRCEProps(ta, {defaultContent: "default text"})
    equal props.mirroredAttrs.name, "elementName"

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
