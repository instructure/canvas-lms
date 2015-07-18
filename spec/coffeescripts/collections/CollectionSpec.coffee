define [
  'jquery'
  'Backbone'
], ($, Backbone) ->

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
      @xhr = sinon.useFakeXMLHttpRequest()
      @ajaxSpy = @spy $, 'ajax'
    teardown: ->
      @xhr.restore

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
    spy = @spy()
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
    spy = @spy()
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
      meta: {}
      posts: [
        {id: 1, links: { author: 1 }},
        {id: 2, links: { author: 1 }}
      ]
    equal collection.parse(document), document.posts,
      'extracts primary collection'

    john = id: 1, name: "John Doe"
    document =
      posts: [
        {id: 1, links: { author: 1 }},
        {id: 2, links: { author: 1 }}
      ]
      linked:
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
      posts: [
        {id: 1, links: { author: 1 }},
        {id: 2, links: { author: 1 }}
      ]
      linked:
        users: [john]
    deepEqual collection.parse(document), expected,
      'recognizes string side load as collection name'

    # complex
    SideLoader::sideLoad = author:
        collection: 'users'
        foreignKey: 'user_id'

    document =
      posts: [
        {id: 1, links: { user_id: 1 }},
        {id: 2, links: { user_id: 1 }}
      ]
      linked:
        users: [john]
    deepEqual collection.parse(document), expected,
      'recognizes complex side load declaration'

    # multiple
    SideLoader::sideLoad =
      author: 'users'
      editor: 'users'

    jane = id: 2, name: "Jane Doe"
    document =
      posts: [
        {id: 1, links: { author: 1, editor: 2 }},
        {id: 2, links: { author: 2, editor: 1 }}
      ]
      linked:
        users: [john, jane]
    expected = [
      {id: 1, author: john, editor: jane},
      {id: 2, author: jane, editor: john}
    ]
    deepEqual collection.parse(document), expected,
      'recognizes multiple side load declarations'

    # keeps links attributes that are not found or not defined
    SideLoader::sideLoad = author: 'users'

    jane = id: 2, name: "Jane Doe"
    document =
      posts: [
        {id: 1, links: { author: 1, editor: 2 }},
        {id: 2, links: { author: 2, editor: 1 }},
        {id: 3, links: { author: 5, editor: 1 }}
      ]
      linked:
        users: [john, jane]
    expected = [
      {id: 1, author: john, links: { editor: 2 }},
      {id: 2, author: jane, links: { editor: 1 }},
      {id: 3, links: { author: 5, editor: 1 }}
    ]
    deepEqual collection.parse(document), expected,
      'retains links when sideload relation is not found'

    # to_many simple
    SideLoader::sideLoad = authors: true

    document =
      posts: [
        { id: 1, links: { authors: [ '1', '2' ] }},
        { id: 2, links: { authors: [ '1' ] }}
      ]
      linked:
        authors: [ john, jane ]

    expected = [
      { id: 1, authors: [ john, jane ] },
      { id: 2, authors: [ john ] }
    ]

    deepEqual collection.parse(document), expected,
      'extracts links with simple to_many relationships'

    # to_many string
    SideLoader::sideLoad = authors: "users"

    document =
      posts: [
        { id: 1, links: { authors: [ '1', '2' ] }},
        { id: 2, links: { authors: [ '1' ] }}
      ]
      linked:
        users: [ john, jane ]

    expected = [
      { id: 1, authors: [ john, jane ] },
      { id: 2, authors: [ john ] }
    ]

    deepEqual collection.parse(document), expected,
      'extracts links with string to_many relationships'

    # to_many complex
    SideLoader::sideLoad = authors:
      collection: 'users'
      foreignKey: 'author_ids'

    document =
      posts: [
        { id: 1, links: { author_ids: [ '1', '2' ] }},
        { id: 2, links: { author_ids: [ '1' ] }}
      ]
      linked:
        users: [ john, jane ]

    expected = [
      { id: 1, authors: [ john, jane ] },
      { id: 2, authors: [ john ] }
    ]

    deepEqual collection.parse(document), expected,
      'extracts links with complex to_many relationships'

    # to_many complex
    SideLoader::sideLoad = authors:
      collection: 'authors'
      foreignKey: 'author_ids'

    document =
      posts: [
        { id: 1, links: { author_ids: [ '1', '2' ] }},
        { id: 2, links: { author_ids: [ '1' ] }}
      ]
      linked:
        users: [ john, jane ]

    expected = "Could not find linked collection for 'authors' using 'author_ids'."

    throws (-> collection.parse(document)), expected,
      'should throw error when a to_many relationship is not found'

    SideLoader::sideLoad = authors: true

    # Links attribute
    document =
      links:
        "posts.author": "http://example.com/authors/{posts.author}"
      posts: [
        { id: 1, links: { authors: [ '1', '2' ] }},
        { id: 2, links: { authors: [ '1' ] }}
      ]
      linked:
        authors: [ john, jane ]

    expected = [
      { id: 1, authors: [ john, jane ] },
      { id: 2, authors: [ john ] }
    ]

    deepEqual collection.parse(document), expected,
      'extracts links with links root'
