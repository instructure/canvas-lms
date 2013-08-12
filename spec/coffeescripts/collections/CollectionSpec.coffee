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

  test 'setParams', ->
    collection = new Backbone.Collection
    ok !collection.options.params, 'no params'
    collection.setParams
      foo: 'bar'
      baz: 'qux'
    deepEqual collection.options.params, foo: 'bar', baz: 'qux'

  test 'triggers setParams event', ->
    collection = new Backbone.Collection
    spy = sinon.spy()
    collection.on 'setParams', spy
    params =
      foo: 'bar'
      baz: 'qux'
    collection.setParams params
    ok spy.calledOnce, 'event triggered'
    equal spy.args[0][0], params

  test 'parse', ->
    class SideLoader extends Backbone.Collection
    collection = new SideLoader

    # boolean
    SideLoader::sideLoad = author: true

    document = [1,2,3]
    equal collection.parse(document), document,
      'passes through simple documents'

    document = a: 1, b: 2
    equal collection.parse(document), document,
      'passes through without meta key'

    document = 
      meta: {primaryCollection: 'posts'}
      posts: [
        {id: 1, author_id: 1},
        {id: 2, author_id: 1}
      ]
    equal collection.parse(document), document.posts,
      'extracts primary collection'

    john = id: 1, name: "John Doe"
    document =
      meta: {primaryCollection: 'posts'}
      posts: [
        {id: 1, author_id: 1},
        {id: 2, author_id: 1}
      ]
      authors: [john]
    expected = [
      {id: 1, author: john},
      {id: 2, author: john}
    ]
    deepEqual collection.parse(document), expected,
      'extracts primary collection'

    # string
    SideLoader::sideLoad = author: 'users'

    document =
      meta: {primaryCollection: 'posts'}
      posts: [
        {id: 1, author_id: 1},
        {id: 2, author_id: 1}
      ]
      users: [john]
    deepEqual collection.parse(document), expected,
      'recognizes string side load as collection name'

    # complex
    SideLoader::sideLoad = author:
        collection: 'users'
        foreignKey: 'user_id'

    document =
      meta: {primaryCollection: 'posts'}
      posts: [
        {id: 1, user_id: 1},
        {id: 2, user_id: 1}
      ]
      users: [john]
    deepEqual collection.parse(document), expected,
      'recognizes complex side load declaration'

    # multiple
    SideLoader::sideLoad =
      author: 'users'
      editor: 'users'

    jane = id: 2, name: "Jane Doe"
    document =
      meta: {primaryCollection: 'posts'}
      posts: [
        {id: 1, author_id: 1, editor_id: 2},
        {id: 2, author_id: 2, editor_id: 1}
      ]
      users: [john, jane]
    expected = [
      {id: 1, author: john, editor: jane},
      {id: 2, author: jane, editor: john}
    ]
    deepEqual collection.parse(document), expected,
      'recognizes multiple side load declarations'
