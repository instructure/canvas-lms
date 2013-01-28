define ['Backbone'], ({View}) ->

  module 'View'

  test 'template option', ->
    view = new View
      template: -> "hi"
    view.render()
    equal view.$el.html(), "hi",
      "tempalte rendered with view as option"

  test 'View.mixin', 3, ->

    mixin1 =
      events:
        'click .foo': 'foo'
      foo: ->
        ok true, 'called mixin1.foo'

    mixin2 =
      events:
        'click .bar': 'bar'
      bar: ->
        ok true, 'called mixin2.bar'

    class SomeView extends View
      events:
        'click .baz': 'baz'
      baz: ->
        ok true, 'called prototype method baz'

      # the actual api being tested
      @mixin mixin1, mixin2

    view = new SomeView

    # events are expected to all be merged together
    # rather than getting blown away by the last mixin
    expectedEvents =
      'click .foo': 'foo'
      'click .bar': 'bar'
      'click .baz': 'baz'
    deepEqual view.events, expectedEvents, 'events merged properly'

    # call the handlers manually
    view.foo()
    view.bar()
