define ['Backbone'], ({Model}) ->

  QUnit.module 'Backbone.Model',
    setup: -> @model = new Model

  test '@mixin', ->
    initSpy = @spy()
    mixable =
      defaults:
        cash: 'money'
      initialize: initSpy
    class Mixed extends Model
      @mixin mixable
      initialize: ->
        initSpy.apply this, arguments
        super

    model = new Mixed
    equal model.get('cash'), 'money',
      'mixes in defaults'
    ok initSpy.calledTwice, 'inherits initialize'

  test 'increment', ->
    model = new Model count: 1
    model.increment 'count', 2
    equal model.get('count'), 3

  test 'decrement', ->
    model = new Model count: 10
    model.decrement 'count', 7
    equal model.get('count'), 3

  test '#deepGet returns nested attributes', ->
    @model.attributes = {foo: {bar: {zing: 'cats'}}}

    value = @model.deepGet 'foo.bar.zing'
    equal value, 'cats', 'gets a nested attribute'
