define [
  'INST'
  'jquery'
  'jquery.ajaxJSON'
], (INST, $) ->

  storedInstEnv = null

  module '$.fn.defaultAjaxError',
    setup: ->
      storedInstEnv = INST.environment

    teardown: ->
      INST.environment = storedInstEnv

  test 'should call the function if not production', ->
    notEqual INST.environment, 'production'
    deepEqual $.ajaxJSON.unhandledXHRs, []

    spy = @spy()
    $("#fixtures").defaultAjaxError(spy)
    xhr = {status: 200, responseText: '{"status": "ok"}'}
    $.fn.defaultAjaxError.func({}, xhr)
    ok spy.called

  test 'should call the function if unhandled', ->
    INST.environment = 'production'
    xhr = {status: 400, responseText: '{"status": "ok"}'}
    $.ajaxJSON.unhandledXHRs.push(xhr)

    spy = @spy()
    $("#fixtures").defaultAjaxError(spy)
    $.fn.defaultAjaxError.func({}, xhr)
    ok spy.called

  test 'should call the function if unauthenticated', ->
    INST.environment = 'production'
    deepEqual $.ajaxJSON.unhandledXHRs, []

    spy = @spy()
    $("#fixtures").defaultAjaxError(spy)
    xhr = {status: 401, responseText: '{"status": "unauthenticated"}'}
    $.fn.defaultAjaxError.func({}, xhr)
    ok spy.called


  module '$.ajaxJSON.isUnauthenticated'

  test 'returns false if status is not 401', ->
    equal $.ajaxJSON.isUnauthenticated({status: 200}), false

  test 'returns false if status is 401 but the message is not unauthenticated', ->
    xhr = {status: 401, responseText: ''}
    equal $.ajaxJSON.isUnauthenticated(xhr), false

  test 'returns false if status is 401 but the message is not unauthenticated', ->
    xhr = {status: 401, responseText: '{"status": "unauthorized"}'}
    equal $.ajaxJSON.isUnauthenticated(xhr), false

  test 'returns true if status is 401 and message is unauthenticated', ->
    xhr = {status: 401, responseText: '{"status": "unauthenticated"}'}
    equal $.ajaxJSON.isUnauthenticated(xhr), true
