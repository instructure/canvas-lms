define ['jsx/assignments/stores/ModerationStore'], (ModerationStore) ->

  module 'ModerationStore',

  test 'constructor', ->
    store = new ModerationStore()
    ok store, "constructs properly"
    equal store.students.length, 0, 'student list is initally empty'

  test 'adds multiple students to the store', ->
    store = new ModerationStore()
    store.addStudents([{id: 1}, {id: 2}])
    equal store.students.length, 2, 'store length is two'

  test 'doesn\'t add duplicates to the store', ->
    store = new ModerationStore()
    store.addStudents([{id: 1}])
    store.addStudents([{id: 1}])
    equal store.students.length, 1, 'store length is one'

  test 'triggers change when adding students', ->
    store = new ModerationStore()
    called = false
    store.addChangeListener () ->
      called = true
    store.addStudents([{id: 1}])
    ok called, 'change listener handler was called'
