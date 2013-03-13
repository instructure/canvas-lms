define [
  'Backbone'
], (Backbone) ->

  class TestCollection extends Backbone.Collection

    defaults:
      foo: 'bar'
      params:
        multi: ['foos', 'bars']
        single: 1

    @optionProperty 'foo'

    url: '/fake'

    model: Backbone.Model.extend()

  module 'Backbone.Collection',
    setup: ->
      @ajaxSpy = sinon.spy $, 'ajax'
    teardown: ->
      $.ajax.restore()

  test 'default options', ->
    collection = new TestCollection()
    equal typeof collection.options, 'object',
      'sets options property'
    equal collection.options.foo, 'bar',
      'sets default options'

    collection2 = new TestCollection null, foo: 'baz'
    equal collection2.options.foo, 'baz',
      'overrides default options with instance options'

  test 'optionProperty', ->
    collection = new TestCollection foo: 'bar'
    equal collection.foo, 'bar'

  test 'sends @params in request', ->
    collection = new TestCollection()
    collection.fetch()
    deepEqual $.ajax.getCall(0).args[0].data, collection.options.params,
      'sends default parameters with request'

    collection.options.params = a: 'b', c: ['d']
    collection.fetch()
    deepEqual $.ajax.getCall(1).args[0].data, collection.options.params,
      'sends dynamic parameters with request'

  test 'uses conventional default url', ->

    FakeModel = Backbone.Model.extend
      resourceName: 'discussion_topics'
      assetString = 'course_1'

    FakeCollection = Backbone.Collection.extend
      model: FakeModel

    collection = new FakeCollection()
    collection.contextAssetString = assetString

    equal collection.url(), '/api/v1/courses/1/discussion_topics',
      'used conventional URL with specific contextAssetString'

  test 'triggers setParam event', ->
    collection = new Backbone.Collection
    spy = sinon.spy()
    collection.on 'setParam', spy
    collection.setParam 'foo', 'bar'
    ok spy.calledOnce, 'event triggered'
    equal spy.args[0][0], 'foo'
    equal spy.args[0][1], 'bar'

