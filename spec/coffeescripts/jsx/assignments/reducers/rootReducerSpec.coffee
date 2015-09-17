define [
  "jsx/assignments/reducers/rootReducer"
], (rootReducer) ->

  module "students reducer",

  test "concatenates students handling GOT_STUDENTS", ->
    initialState =
      students: ['one', 'two']
    gotStudentsAction =
      type: 'GOT_STUDENTS'
      payload:
        students: ['three', 'four']
    newState = rootReducer(initialState, gotStudentsAction)
    expected = ['one', 'two', 'three', 'four']
    deepEqual newState.students, expected, 'successfully concatenates'

  module "urls reducer",

  test "passes through whatever the current state is", ->
    initialState =
      urls:
        test_url: 'test'
    someRandomAction =
      type: 'Random'
    newState = rootReducer(initialState, someRandomAction)
    deepEqual newState.urls, initialState.urls, 'passes through unchanged'

  module "assignments reducer",

  test "sets to published on PUBLISHED_GRADES", ->
    initialState =
      assignments:
        published: false
    publishedGradesAction =
      type: 'PUBLISHED_GRADES'
      payload:
        time: Date.now()
        message: 'test'
    newState = rootReducer(initialState, publishedGradesAction)
    ok newState.assignment.published, 'successfully sets to publish'

  module "flashMessage reducer",

  test "sets success message on PUBLISHED_GRADES", ->
    initialState =
      flashMessage: {}
    publishedGradesAction =
      type: 'PUBLISHED_GRADES'
      payload:
        time: 123
        message: 'test success'
    newState = rootReducer(initialState, publishedGradesAction)
    expected =
      time: 123
      message: 'test success'
      error: false
    deepEqual newState.flashMessage, expected, 'updates state'

  test "sets failure message on PUBLISHED_GRADES_FAILED", ->
    initialState =
      flashMessage: {}
    publishedGradesAction =
      type: 'PUBLISHED_GRADES_FAILED'
      payload:
        time: 123
        message: 'failed to publish'
        error: true
    newState = rootReducer(initialState, publishedGradesAction)
    expected =
      time: 123
      message: 'failed to publish'
      error: true
    deepEqual newState.flashMessage, expected, 'updates state'

