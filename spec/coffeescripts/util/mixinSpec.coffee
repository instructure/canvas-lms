define ['compiled/util/mixin'], (mixin) ->

  QUnit.module 'mixin'

  test 'merges objects without blowing away events or defaults', 4, ->
    mixin1 =
      events: 'click .foo': 'foo'
      defaults:
        foo: 'bar'
      foo: @spy()
    mixin2 =
      events: 'click .bar': 'bar'
      defaults:
        baz: 'qux'
      bar: @spy()
    obj = mixin {}, mixin1, mixin2
    # events are expected to all be merged together
    # rather than getting blown away by the last mixin
    expectedEvents =
      'click .foo': 'foo'
      'click .bar': 'bar'
    expectedDefaults =
      foo: 'bar'
      baz: 'qux'
    deepEqual obj.events, expectedEvents, 'events merged properly'
    deepEqual obj.defaults, expectedDefaults, 'defaults merged properly'
    obj.foo()
    ok obj.foo.calledOnce
    obj.bar()
    ok obj.bar.calledOnce
