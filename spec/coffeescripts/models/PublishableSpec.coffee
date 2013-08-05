define ['compiled/models/Publishable'], (Publishable) ->

  buildModule = (published)->
    new Publishable {published: published}, {url: '/api/1/2/3'}

  module 'Publishable:',
    setup: ->
    teardown: ->

  test 'initialize stores the url for use in url generation', ->
    cModule = buildModule true
    equal cModule.url(), '/api/1/2/3'

  test 'publish updates the state of the model', ->
    cModule = buildModule false
    cModule.save = ()->
    cModule.publish()
    equal cModule.get('published'), true

  test 'publish saves to the server', ->
    cModule = buildModule true
    saveStub = sinon.stub cModule, 'save'
    cModule.publish()
    ok saveStub.calledOnce

  test 'unpublish updates the state of the model', ->
    cModule = buildModule true
    cModule.save = ()->
    cModule.unpublish()
    equal cModule.get('published'), false

  test 'unpublish saves to the server', ->
    cModule = buildModule true
    saveStub = sinon.stub cModule, 'save'
    cModule.unpublish()
    ok saveStub.calledOnce

  test 'toJSON wraps attributes', ->
    publishable = new Publishable {published: true}, {root: 'module'}
    equal publishable.toJSON()['module']['published'], true
