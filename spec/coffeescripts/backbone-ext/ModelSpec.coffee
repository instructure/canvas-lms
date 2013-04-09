define ['Backbone'], ({Model}) ->

  module 'Backbone.Model'

  test '@mixin', ->
    initSpy = sinon.spy()
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

