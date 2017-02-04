define [
  "jsx/assignments/actions/ModerationActions"
], (ModerationActions) ->

  QUnit.module "ModerationActions - Action Creators"

  test 'creates the SORT_MARK1_COLUMN action', ->
    action = ModerationActions.sortMark1Column()
    expected =
      type: 'SORT_MARK1_COLUMN'

    deepEqual action, expected, "creates the action successfully"

  test 'creates the SORT_MARK2_COLUMN action', ->
    action = ModerationActions.sortMark2Column()
    expected =
      type: 'SORT_MARK2_COLUMN'

    deepEqual action, expected, "creates the action successfully"

  test 'creates the SORT_MARK3_COLUMN action', ->
    action = ModerationActions.sortMark3Column()
    expected =
      type: 'SORT_MARK3_COLUMN'

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
    action = ModerationActions.moderationSetUpdated([{a: 1}, {b: 2}])
    expected =
      type: ModerationActions.UPDATED_MODERATION_SET
      payload:
        message: 'Reviewers successfully added'
        students: [{a: 1}, {b: 2}]
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

  test "creates the SELECT_ALL_STUDENTS action", ->
    action = ModerationActions.selectAllStudents([{id: 1}, {id: 2}])
    expected =
      type: ModerationActions.SELECT_ALL_STUDENTS
      payload:
        students: [{id: 1}, {id: 2}]

    deepEqual action, expected, "creates the action successfully"

  test "creates the UNSELECT_ALL_STUDENTS action", ->
    action = ModerationActions.unselectAllStudents()
    expected =
      type: ModerationActions.UNSELECT_ALL_STUDENTS

    deepEqual action, expected, "creates the action successfully"

  test "creates the SELECT_MARK action", ->
    action = ModerationActions.selectedProvisionalGrade(1, 2)
    expected =
      type: ModerationActions.SELECT_MARK
      payload:
        studentId: 1
        selectedProvisionalId: 2

    deepEqual action, expected, "creates the action successfully"


  QUnit.module "ModerationActions#apiGetStudents",
    setup: ->
      @client =
        get: ->
          new Promise (resolve) ->
            setTimeout ->
              resolve('test')
            , 100

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

    @stub(@client, 'get').returns(Promise.resolve(fakeResponse))
    ModerationActions.apiGetStudents(@client)((action) ->
      deepEqual action, gotStudentsAction
      start()
    , getState)

  asyncTest "calls itself again if headers indicate more pages", ->

    getState = ->
      urls:
        list_gradeable_students: 'some_url'
      students: []

    fakeHeaders =
      link: '<http://some_url/>; rel="current",<http://some_url/?page=2>; rel="next",<http://some_url>; rel="first",<http://some_url>; rel="last"'
    fakeResponse = {data: ['test'], headers: fakeHeaders}

    callCount = 0
    @stub(@client, 'get').returns(Promise.resolve(fakeResponse))
    ModerationActions.apiGetStudents(@client)((action) ->
      callCount++
      if callCount >= 2
        ok callCount == 2
        start()
    , getState)

  QUnit.module "ModerationActions#publishGrades",
    setup: ->
      @client = {
        post: ->
          new Promise (resolve) ->
            setTimeout ->
              resolve('test')
            , 100
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

    @stub(@client, 'post').returns(Promise.resolve(fakeResponse))
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

    @stub(@client, 'post').returns(Promise.reject(fakeResponse))
    ModerationActions.publishGrades(@client)((action) ->
      equal action.type, publishGradesAction.type, 'type matches'
      equal action.payload.message, publishGradesAction.payload.message, 'has proper message'
      start()
    , getState)

  asyncTest "dispatches publishGradesFailed action with selected grades message on 422 failure", ->
    getState = ->
      urls:
        publish_grades_url: 'some_url'
    fakeResponse =
      status: 422

    publishGradesAction =
      type: ModerationActions.PUBLISHED_GRADES_FAILED
      payload:
        message: 'All submissions must have a selected grade.'

    @stub(@client, 'post').returns(Promise.reject(fakeResponse))
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

    @stub(@client, 'post').returns(Promise.reject(fakeResponse))
    ModerationActions.publishGrades(@client)((action) ->
      equal action.type, publishGradesAction.type, 'type matches'
      equal action.payload.message, publishGradesAction.payload.message, 'has proper message'
      start()
    , getState)

  QUnit.module "ModerationActions#addStudentToModerationSet",
    setup: ->
      @client =
        post: ->
          new Promise (resolve) ->
            setTimeout ->
              resolve('test')
            , 100

  test "returns a function", ->
    ok typeof ModerationActions.addStudentToModerationSet() == 'function'

  asyncTest "dispatches moderationSetUpdated on success", ->
    fakeUrl = 'some_url'
    getState = ->
      urls:
        add_moderated_students: fakeUrl
      studentList:
        students: [
          {id: 1, on_moderation_stage: true},
          {id: 2, on_moderation_stage: true}
        ]
    fakeResponse =
      status: 200
      students: [{id: 1}, {id: 2}]

    moderationSetUpdatedAction =
      type: ModerationActions.UPDATED_MODERATION_SET
      payload:
        message: 'Reviewers successfully added'

    fakePost = @stub(@client, 'post').returns(Promise.resolve(fakeResponse))
    ModerationActions.addStudentToModerationSet(@client)((action) ->
      ok fakePost.calledWith(fakeUrl, {student_ids: [1, 2]}), 'called with the correct params'
      equal action.type, moderationSetUpdatedAction.type, 'type matches'
      equal action.payload.message, moderationSetUpdatedAction.payload.message, 'has proper message'
      start()
    , getState)

  asyncTest "dispatches moderationSetUpdateFailed on failure", ->
    getState = ->
      urls:
        add_moderated_students: 'some_url'
      studentList:
        students: [
          {id: 1, on_moderation_stage: true},
          {id: 2, on_moderation_stage: true}
        ]
    fakeResponse =
      status: 500

    moderationSetUpdateFailedAction =
      type: ModerationActions.UPDATE_MODERATION_SET_FAILED
      payload:
        message: 'A problem occurred adding reviewers.'

    @stub(@client, 'post').returns(Promise.reject(fakeResponse))
    ModerationActions.addStudentToModerationSet(@client)((action) ->
      equal action.type, moderationSetUpdateFailedAction.type, 'type matches'
      equal action.payload.message, moderationSetUpdateFailedAction.payload.message, 'has proper message'
      start()
    , getState)

  QUnit.module "ModerationActions#selectProvisionalGrade",
    setup: ->
      @client =
        put: ->
          new Promise (resolve) ->
            setTimeout ->
              resolve('test')
            , 100

  test "returns a function", ->
    ok typeof ModerationActions.selectProvisionalGrade(1) == 'function'

  asyncTest "dispatches selectProvisionalGrade on success", ->
    fakeUrl = 'base_url'
    getState = ->
      urls:
        provisional_grades_base_url: fakeUrl
      studentList:
        students: [
          {id: 1, provisional_grades: [{provisional_grade_id: 42}], selected_provisional_grade_id: undefined},
        ]
    fakeResponse =
      status: 200
      data:
        student_id: 1
        selected_provisional_grade_id: 42

    fakePost = @stub(@client, 'put').returns(Promise.resolve(fakeResponse))
    ModerationActions.selectProvisionalGrade(42, @client)((action) ->
      ok fakePost.calledWith(fakeUrl+"/"+ "42"+"/select"), 'called with the correct params'
      equal action.type, ModerationActions.SELECT_MARK, 'type matches'
      equal action.payload.studentId, 1, 'has correct payload'
      equal action.payload.selectedProvisionalId, 42, 'has correct payload'
      start()
    , getState)

  asyncTest "dispatches displayErrorMessage on failure", ->
    fakeUrl = 'base_url'
    getState = ->
      urls:
        provisional_grades_base_url: fakeUrl
      studentList:
        students: [
          {id: 1, provisional_grades: [{provisional_grade_id: 42}], selected_provisional_grade_id: undefined},
        ]
    fakeResponse =
      status: 404

    fakePost = @stub(@client, 'put').returns(Promise.resolve(fakeResponse))
    ModerationActions.selectProvisionalGrade(42, @client)((action) ->
      ok fakePost.calledWith(fakeUrl+"/"+ "42"+"/select"), 'called with the correct params'
      equal action.type, ModerationActions.SELECTING_PROVISIONAL_GRADES_FAILED, 'type matches'
      equal action.payload.message,'An error occurred selecting provisional grades' , 'has correct payload'
      ok action.payload instanceof Error, "is an error object"
      equal action.error, true, 'has correct payload'
      start()
    , getState)
