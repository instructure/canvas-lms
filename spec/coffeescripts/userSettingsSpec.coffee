define [
  'compiled/userSettings'
], (userSettings)->

  globalObj = this

  QUnit.module 'UserSettings',
    setup: ->
      @_ENV = globalObj.ENV
      globalObj.ENV =
        current_user_id: 1
        context_asset_string: 'course_1'

      userSettings.globalEnv = globalObj.ENV

    teardown: ->
      globalObj.ENV = @_ENV

  test '`get` should return what was `set`', ->
    userSettings.set('foo', 'bar')
    equal userSettings.get('foo'), 'bar'

  test 'it should strigify/parse JSON', ->
    testObject =
      foo: [1, 2, 3]
      bar: 'true'
      baz: true
    userSettings.set('foo', testObject)
    deepEqual userSettings.get('foo'), testObject

  test 'it should store different things for different users', ->
    userSettings.set('foo', 1)

    globalObj.ENV.current_user_id = 2
    userSettings.set('foo', 2)
    equal userSettings.get('foo'), 2

    globalObj.ENV.current_user_id = 1
    equal userSettings.get('foo'), 1

  test 'it should store different things for different contexts', ->
    userSettings.contextSet('foo', 1)

    globalObj.ENV.context_asset_string = 'course_2'
    userSettings.contextSet('foo', 2)
    equal userSettings.contextGet('foo'), 2

    globalObj.ENV.context_asset_string = 'course_1'
    equal userSettings.contextGet('foo'), 1
