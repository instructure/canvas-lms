define [
  'jquery'
  'jsx/shared/rce/serviceRCELoader'
], ($, RCELoader) ->
  module 'loadRCE',
    setup: ->
      # make sure we don't get a cached thing from other tests
      RCELoader.setCache(null)
      @elementInFixtures = (type) ->
        newElement = document.createElement(type)
        fixtureDiv = document.getElementById("fixtures")
        fixtureDiv.appendChild(newElement)
        newElement
      @modifiedJquery = $
      @originalGetScript = @modifiedJquery.getScript
      @modifiedJquery.getScript = (__host__, cb) ->
        # spoofing getScript behavior
        $.globalEval( "RceModule = 'fakeModule'" )
        cb()

      @getScriptSpy = sinon.spy(@modifiedJquery, "getScript");

      window.$ = @modifiedJquery
      window.tinyrce = {editorsListing: {}}

    teardown: ->
      RCELoader.setCache(null)
      @modifiedJquery.getScript.restore()
      @modifiedJquery.getScript = @originalGetScript
      window.tinyrce = null
      document.getElementById("fixtures").innerHtml = ""

  # loading RCE

  test 'caches the response of get_module when called', ->
    equal RCELoader.cachedModule, null
    RCELoader.loadRCE("somehost.com", (() ->))
    equal RCELoader.cachedModule, 'fakeModule'
    ok @getScriptSpy.calledOnce

  test 'does not call get_module once a response has been cached', ->
    RCELoader.cachedModule = "something"
    RCELoader.setCache("foo")

    ok @getScriptSpy.notCalled
    RCELoader.loadRCE("somehost.com", () -> "noop")
    ok @getScriptSpy.notCalled

  test 'executes a callback when RCE is loaded', ->
    cb = sinon.spy();
    RCELoader.loadRCE("dontCare", cb)
    ok cb.called

  test 'uses `latest` version when hitting a cloudfront host', ->
    ok @getScriptSpy.notCalled
    RCELoader.loadRCE("xyz.cloudfront.net/some/path", () -> "noop")
    ok @getScriptSpy.calledWith("//xyz.cloudfront.net/some/path/latest")

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

    loadingSpy = sinon.stub(RCELoader, "loadRCE")
    renderIntoDivSpy = sinon.spy()
    fakeRCE = { renderIntoDiv: renderIntoDivSpy}

    # execute renderIntoDivSpy
    RCELoader.loadOnTarget(ta, {getRenderingTarget: customFn}, "www.some-host.com")
    call = loadingSpy.getCall(0)
    call.args[1](fakeRCE)
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
