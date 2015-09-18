define [
  "when"
  "jsx/assignments/actions/ModerationActions",
], (whenJS, ModerationActions) ->

  module "ModerationActions - Action Creators",

  test 'creates the SORT_MARK_COLUMN action', ->
    markColumnData =
               markColumn: 2,
               currentSortDirection: 'highest'
    action = ModerationActions.sortMarkColumn(markColumnData)
    expected =
      type: ModerationActions.SORT_MARK_COLUMN
      payload: markColumnData

    deepEqual action, expected, "creates the action successfully"

  test "creates the SELECT_STUDENT action", ->
    action = ModerationActions.selectStudent(1)
    expected =
      type: ModerationActions.SELECT_STUDENT
      payload:
        studentId: 1

    deepEqual action, expected, "creates the action successfully"

  test "creates the UNSELECT_STUDENT action", ->
    action = ModerationActions.unselectStudent(1)
    expected =
      type: ModerationActions.UNSELECT_STUDENT
      payload:
        studentId: 1

    deepEqual action, expected, "creates the action successfully"

  test "creates the UPDATED_MODERATION_SET action", ->
    action = ModerationActions.moderationSetUpdated([{a: 1}, {a: 2}])
    expected =
      type: ModerationActions.UPDATED_MODERATION_SET
      payload:
        message: 'Reviewers successfully added'
        students: [{a: 1}, {a: 2}]
        time: Date.now()

    equal action.type, expected.type, "type matches"
    equal action.payload.message, expected.payload.message, "message matches"
    ok expected.payload.time - action.payload.time < 5, "time within 5 seconds"

  test "creates the UPDATE_MODERATION_SET_FAILED action", ->
    action = ModerationActions.moderationSetUpdateFailed()
    expected =
      type: ModerationActions.UPDATE_MODERATION_SET_FAILED
      payload:
        message: 'A problem occurred adding reviewers.'
        time: Date.now()

    equal action.type, expected.type, "type matches"
    equal action.payload.message, expected.payload.message, "message matches"
    ok expected.payload.time - action.payload.time < 5, "time within 5 seconds"

  test "creates the GOT_STUDENTS action", ->
    action = ModerationActions.gotStudents([1, 2, 3])
    expected =
      type: ModerationActions.GOT_STUDENTS
      payload:
        students: [1, 2, 3]

    deepEqual action, expected, "creates the action successfully"

  test "creates the PUBLISHED_GRADES action", ->
    action = ModerationActions.publishedGrades('test')
    expected =
      type: ModerationActions.PUBLISHED_GRADES
      payload:
        message: 'test'
        time: Date.now()

    equal action.type, expected.type, "type matches"
    equal action.payload.message, expected.payload.message, "message matches"
    ok expected.payload.time - action.payload.time < 5, "time within 5 seconds"

  test "creates the PUBLISHED_GRADES_FAILED action", ->
    action = ModerationActions.publishGradesFailed('test')
    expected =
      type: ModerationActions.PUBLISHED_GRADES_FAILED
      payload:
        message: 'test'
        time: Date.now()
      error: true

    equal action.type, expected.type, "type matches"
    equal action.payload.message, expected.payload.message, "message matches"
    ok action.error, "error flag is set"
    ok expected.payload.time - action.payload.time < 5, "time within 5 seconds"


  module "ModerationActions#apiGetStudents",

    setup: ->
      @client = {
        get: ->
          dfd = whenJS.defer()
          setTimeout ->
            dfd.resolve('test')
          , 100
          dfd.promise()
      }

  test "returns a function", ->
    ok typeof ModerationActions.apiGetStudents() == 'function'

  asyncTest "dispatches gotStudents action", ->

    getState = ->
      urls:
        list_gradeable_students: 'some_url'
      students: []

    fakeResponse = {data: ['test']}

    gotStudentsAction =
      type: ModerationActions.GOT_STUDENTS
      payload:
        students: ['test']

    sinon.stub(@client, 'get').returns(whenJS(fakeResponse))
    ModerationActions.apiGetStudents(@client)((action) ->
      deepEqual action, gotStudentsAction
      start()
    , getState)

  module "ModerationActions#publishGrades",
    setup: ->
      @client = {
        post: ->
          dfd = whenJS.defer()
          setTimeout ->
            dfd.resolve('test')
          , 100
          dfd.promise()
      }

  test "returns a function", ->
    ok typeof ModerationActions.publishGrades() == 'function'

  asyncTest "dispatches publishGrades action on success", ->
    getState = ->
      urls:
        publish_grades_url: 'some_url'
    fakeResponse = {status: 200}

    publishGradesAction =
      type: ModerationActions.PUBLISHED_GRADES
      payload:
        message: 'Success! Grades were published to the grade book.'

    sinon.stub(@client, 'post').returns(whenJS(fakeResponse))
    ModerationActions.publishGrades(@client)((action) ->
      equal action.type, publishGradesAction.type, 'type matches'
      equal action.payload.message, publishGradesAction.payload.message, 'has proper message'
      start()
    , getState)

  asyncTest "dispatches publishGradesFailed action with already published message on 400 failure", ->
    getState = ->
      urls:
        publish_grades_url: 'some_url'
    fakeResponse =
      status: 400

    publishGradesAction =
      type: ModerationActions.PUBLISHED_GRADES_FAILED
      payload:
        message: 'Assignment grades have already been published.'

    sinon.stub(@client, 'post').returns(whenJS.reject(fakeResponse))
    ModerationActions.publishGrades(@client)((action) ->
      equal action.type, publishGradesAction.type, 'type matches'
      equal action.payload.message, publishGradesAction.payload.message, 'has proper message'
      start()
    , getState)

  asyncTest "dispatches publishGradesFailed action with generic error message on non-400 error", ->
    getState = ->
      urls:
        publish_grades_url: 'some_url'
    fakeResponse =
      status: 500

    publishGradesAction =
      type: ModerationActions.PUBLISHED_GRADES_FAILED
      payload:
        message: 'An error occurred publishing grades.'

    sinon.stub(@client, 'post').returns(whenJS.reject(fakeResponse))
    ModerationActions.publishGrades(@client)((action) ->
      equal action.type, publishGradesAction.type, 'type matches'
      equal action.payload.message, publishGradesAction.payload.message, 'has proper message'
      start()
    , getState)

  module "ModerationActions#addStudentToModerationSet",
    setup: ->
      @client = {
        post: ->
          dfd = whenJS.defer()
          setTimeout ->
            dfd.resolve('test')
          , 100
          dfd.promise()
      }

  test "returns a function", ->
    ok typeof ModerationActions.addStudentToModerationSet() == 'function'

  asyncTest "dispatches moderationSetUpdated on success", ->
    getState = ->
      urls:
        add_moderated_students: 'some_url'
      moderationStage: [1, 2]
    fakeResponse =
      status: 200
      students: [{id: 1}, {id: 2}]

    moderationSetUpdatedAction =
      type: ModerationActions.UPDATED_MODERATION_SET
      payload:
        message: 'Reviewers successfully added'

    sinon.stub(@client, 'post').returns(whenJS(fakeResponse))
    ModerationActions.addStudentToModerationSet(@client)((action) ->
      equal action.type, moderationSetUpdatedAction.type, 'type matches'
      equal action.payload.message, moderationSetUpdatedAction.payload.message, 'has proper message'
      start()
    , getState)

  asyncTest "dispatches moderationSetUpdateFailed on failure", ->
    getState = ->
      urls:
        add_moderated_students: 'some_url'
      moderationStage: [1, 2]
    fakeResponse =
      status: 500

    moderationSetUpdateFailedAction =
      type: ModerationActions.UPDATE_MODERATION_SET_FAILED
      payload:
        message: 'A problem occurred adding reviewers.'

    sinon.stub(@client, 'post').returns(whenJS.reject(fakeResponse))
    ModerationActions.addStudentToModerationSet(@client)((action) ->
      equal action.type, moderationSetUpdateFailedAction.type, 'type matches'
      equal action.payload.message, moderationSetUpdateFailedAction.payload.message, 'has proper message'
      start()
    , getState)