define ['jsx/assignments/stores/ModerationStore'], (ModerationStore) ->

  module 'ModerationStore',

  test 'constructor', ->
    store = new ModerationStore()
    ok store, "constructs properly"
    equal store.submissions.length, 0, 'student list is initally empty'

  test 'adds multiple submissions to the store', ->
    store = new ModerationStore()
    store.addSubmissions([{id: 1}, {id: 2}])
    equal store.submissions.length, 2, 'store length is two'

  test 'doesn\'t add duplicates to the store', ->
    store = new ModerationStore()
    store.addSubmissions([{id: 1}])
    store.addSubmissions([{id: 1}])
    equal store.submissions.length, 1, 'store length is one'

  test 'triggers change when adding submissions', ->
    store = new ModerationStore()
    called = false
    store.addChangeListener () ->
      called = true
    store.addSubmissions([{id: 1}])
    ok called, 'change listener handler was called'
