define [
  'jsx/shared/rce/RceCommandShim',
  'helpers/fakeENV'
], (RceCommandShim, fakeENV) ->

  module 'RceCommandShim',
    setup: ->
      fakeENV.setup()
      @fakeStore = {
        called: false,
        callOnRCE: (target, methodName)=>
          @fakeStore.called = true
          @fakeStore.callTarget = target
          @fakeStore.callMethodName = methodName
      }
      @targetElement = {
        is_a: "dom_element",
        oldSchoolCalled: false,
        attr: (()-> "dom_element_id")
        editorBox: ()=>
          @targetElement.oldSchoolCalled = true
      }
      @fakeJquery = ()=>
        return @targetElement
      @shim = new RceCommandShim({
        jQuery: @fakeJquery,
        store: @fakeStore
      })

    teardown: ->
      fakeENV.teardown()

  test 'uses editor box when feature flag contextually off', ->
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = false
    @shim.send(@targetElement, "someMethod")
    ok !@fakeStore.called
    ok @targetElement.oldSchoolCalled

  test 'goes through RCE store when feature flag contextually on', ->
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = true
    @shim.send(@targetElement, "someMethod")
    equal(@targetElement.oldSchoolCalled, false)
    ok @fakeStore.called
    equal(@fakeStore.callTarget, @targetElement)
    equal(@fakeStore.callMethodName, "someMethod")

  test "falls back to using target value if editor load fails for 'get_code'", ->
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = true
    # jquery api for an element with no editor attached
    @targetElement.val = (()=> "current text in textarea")
    @targetElement.data = (()=> false)
    value = @shim.send(@targetElement, "get_code")
    equal(value, "current text in textarea")
