define ['jsx/shared/helpers/createStore'], (createStore) ->

  test 'sets initial state', ->
    store = createStore({foo: 'bar'})
    deepEqual store.getState(), {foo: 'bar'}

  test 'merges data on setState', ->
    store = createStore({foo: 'bar', baz: null})
    deepEqual store.getState(), {foo: 'bar', baz: null}
    store.setState({baz: 'qux'})
    deepEqual store.getState(), {foo: 'bar', baz: 'qux'}

  test 'emits change on setState', ->
    expect 1
    store = createStore({foo: null})
    store.addChangeListener ->
      ok true
    store.setState foo: 'bar'

  test 'removes change listeners', ->
    callCount = 0
    fn = -> callCount++
    store = createStore({foo: null})
    store.addChangeListener fn
    store.setState foo: 'bar'
    equal callCount, 1
    store.removeChangeListener fn
    store.setState foo: 'baz'
    equal callCount, 1

