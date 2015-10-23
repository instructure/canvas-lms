define ['jsx/shared/rce/rceStore'], (RCEStore) ->

  module 'rceStore',
    setup: ->
      @elementInFixtures = (type) ->
        newElement = document.createElement(type)
        fixtureDiv = document.getElementById("fixtures")
        fixtureDiv.appendChild(newElement)
        newElement
      @someFunctionSpy = sinon.stub().withArgs("someArgument").returns("called properly")
      @anotherFunctionSpy = sinon.stub().withArgs("anotherArgument").returns("stubbedReturn")

      @stubbedRCEInstance = {
        someFunction: @someFunctionSpy,
        anotherFunction: @anotherFunctionSpy
      }

      window.tinyrce = {editorsListing: {someID: @stubbedRCEInstance}}

      @makeDiv = (opts) ->
        d = @elementInFixtures('div');
        d.setAttribute("class", opts.className)
        d.setAttribute("id", opts.divId)
        d

    teardown: ->
      document.getElementById("fixtures").innerHtml = ""

  test 'adds rce instances to global tinyrce.editorsListing', ->
    RCEStore.addToStore("foo", "bar")
    equal window.tinyrce.editorsListing["foo"], "bar"

  test 'fetches dom nodes based on classKeyword', ->
    RCEStore.classKeyword = "matchThisClass"
    matchingNode = @makeDiv(className: "matchThisClass")
    notMatchingNode = @makeDiv(className: "doNotMatchThisClass")
    nodes = [matchingNode, notMatchingNode]
    deepEqual RCEStore.matchingClass(nodes), [matchingNode]

  test 'sends the right method and arguments to RCE Instances', ->
    someFunctionVal = RCEStore.sendFunctionToCorrespondingEditor(["someFunction", "someArgument"], @makeDiv(divId: "someID") )
    equal someFunctionVal, "called properly"

  test 'callOnRCE returns a value from a matching RCE instance method call', ->
    RCEStore.classKeyword = "matchThisClass"
    matchingNode = @makeDiv(className: "matchThisClass", divId: "someID")

    anotherFunctionsVal = RCEStore.callOnRCE([matchingNode], "anotherFunction", "anotherArgument")
    equal anotherFunctionsVal, "stubbedReturn"
