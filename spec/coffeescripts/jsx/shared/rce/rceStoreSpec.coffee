define [
  'jsx/shared/rce/rceStore'
  'helpers/fixtures'
], (RCEStore, fixtures) ->

  module 'rceStore',
    setup: ->
      fixtures.setup()
      @$target = fixtures.create('<textarea id="someID" data-rich_text="true" />')
      @tinyrceWas = window.tinyrce
      window.tinyrce = { editorsListing: {} }

    teardown: ->
      fixtures.teardown()
      window.tinyrce = @tinyrceWas

  test 'adds rce instances to global tinyrce.editorsListing', ->
    RCEStore.addToStore("foo", "bar")
    equal window.tinyrce.editorsListing["foo"], "bar"

  test 'sends the right method and arguments to RCE Instances', ->
    method = sinon.spy()
    RCEStore.addToStore(@$target.id, { method: method })
    RCEStore.callOnTarget(@$target, "method", "argument1", "argument2")
    ok method.calledWith("argument1", "argument2")

  test 'callOnTarget returns the value from the RCE instance method call', ->
    returnValue = "return value"
    method = sinon.stub().returns(returnValue)
    RCEStore.addToStore(@$target.id, { method: method })
    equal RCEStore.callOnTarget(@$target, "method"), returnValue

  test 'callOnTarget falls back to using target value if editor load fails for "get_code"', ->
    @$target.val("current text in textarea")
    @$target.data("rich_text", null)
    get_code = sinon.stub().returns("other text")
    RCEStore.addToStore(@$target.id, { get_code: get_code })
    equal RCEStore.callOnTarget(@$target, "get_code"), @$target.val()
    ok get_code.notCalled
