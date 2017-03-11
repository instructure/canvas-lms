define [
  'underscore'
  "jsx/assignments/reducers/rootReducer"
  "jsx/assignments/constants"
  "jsx/assignments/actions/ModerationActions"
], (_, rootReducer, Constants, ModerationActions) ->
  fakeStudents =
      [
        {
          'id': 2
          'display_name': 'Test Student'
          'avatar_image_url': 'https://canvas.instructure.com/images/messages/avatar-50.png'
          'html_url': 'http://localhost:3000/courses/1/users/2'
          'in_moderation_set': false
          'selected_provisional_grade_id': null
          'provisional_grades': []
        }
        {
          'id': 3
          'display_name': 'a@example.edu'
          'avatar_image_url': 'https://canvas.instructure.com/images/messages/avatar-50.png'
          'html_url': 'http://localhost:3000/courses/1/users/3'
          'in_moderation_set': false
          'selected_provisional_grade_id': null
          'provisional_grades': [ {
            'grade': '4'
            'score': 4
            'graded_at': '2015-09-11T15:42:28Z'
            'scorer_id': 1
            'final': false
            'provisional_grade_id': 10
            'grade_matches_current_submission': true
            'speedgrader_url': 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#%7B%22student_id%22:3,%22provisional_grade_id%22:10%7D'
          }
          {
            'grade': '10'
            'score': '10'
            'graded_at': '2015-09-11T15:42:28Z'
            'scorer_id': 1
            'final': false
            'provisional_grade_id': 10
            'grade_matches_current_submission': true
            'speedgrader_url': 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#%7B%22student_id%22:3,%22provisional_grade_id%22:10%7D'
          }
          {
            'grade': '1'
            'score': '1'
            'graded_at': '2015-09-11T15:42:28Z'
            'scorer_id': 1
            'final': false
            'provisional_grade_id': 10
            'grade_matches_current_submission': true
            'speedgrader_url': 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#%7B%22student_id%22:3,%22provisional_grade_id%22:10%7D'
          }
          ]
        }
        {
          'id': 4
          'display_name': 'b@example.edu'
          'avatar_image_url': 'https://canvas.instructure.com/images/messages/avatar-50.png'
          'html_url': 'http://localhost:3000/courses/1/users/4'
          'in_moderation_set': true
          'selected_provisional_grade_id': 13
          'provisional_grades': [
            {
              'grade': '6'
              'score': 6
              'graded_at': '2015-09-11T16:44:09Z'
              'scorer_id': 1
              'final': false
              'provisional_grade_id': 11
              'grade_matches_current_submission': true
              'speedgrader_url': 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#%7B%22student_id%22:4,%22provisional_grade_id%22:11%7D'
            }
            {
              'grade': '6'
              'score': 6
              'graded_at': '2015-09-21T17:23:43Z'
              'scorer_id': 1
              'final': true
              'provisional_grade_id': 13
              'grade_matches_current_submission': true
              'speedgrader_url': 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#%7B%22student_id%22:4,%22provisional_grade_id%22:13%7D'
            }
            {
              'grade': '6'
              'score': 6
              'graded_at': '2015-09-21T17:23:43Z'
              'scorer_id': 1
              'final': true
              'provisional_grade_id': 13
              'grade_matches_current_submission': true
              'speedgrader_url': 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=1#%7B%22student_id%22:4,%22provisional_grade_id%22:13%7D'
            }
          ]
        }
      ]


  QUnit.module "students reducer"

  test "concatenates students on GOT_STUDENTS", ->
    initialState =
      studentList: {
        students: [{'one': 1}, {'two': 2}]
      }
    gotStudentsAction =
      type: 'GOT_STUDENTS'
      payload:
        students: [{'three': 3}, {'four': 4}]
    newState = rootReducer(initialState, gotStudentsAction)
    expected = [{'one': 1}, {'two': 2}, {'three': 3}, {'four': 4}]
    deepEqual newState.studentList.students, expected, 'successfully concatenates'

  test "updates the moderation set handling UPDATED_MODERATION_SET", ->
    initialState =
      studentList: {
        students: [{id: 1},{id: 2}]
      }
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        students: [{id: 1},{id: 2}]
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected = [{id: 1, in_moderation_set: true, on_moderation_stage: false},{id: 2, in_moderation_set: true, on_moderation_stage: false}]

    deepEqual newState.studentList.students, expected, 'successfully updates moderation set'

  test "sets all the students on_moderation_stage property to true on SELECT_ALL_STUDENTS", ->
    initialState =
      studentList: {
        students: [{id: 1},{id: 2}]
      }
    selectAllStudentsAction =
      type: 'SELECT_ALL_STUDENTS'
      payload:
        students: [{id: 1},{id: 2}]
    newState = rootReducer(initialState, selectAllStudentsAction)
    expected = [{id: 1, on_moderation_stage: true},{id: 2, on_moderation_stage: true}]

    deepEqual newState.studentList.students, expected, 'successfully updates all students on_moderation_stage property'

  test "sets all the students on_moderation_stage property to false on UNSELECT_ALL_STUDENTS", ->
    initialState =
      studentList:
        students: [{id: 1, on_moderation_stage: true},{id: 2, on_moderation_stage: true}]
    unselectAllStudentsAction =
      type: 'UNSELECT_ALL_STUDENTS'
    newState = rootReducer(initialState, unselectAllStudentsAction)
    expected = [{id: 1, on_moderation_stage: false},{id: 2, on_moderation_stage: false}]

    deepEqual newState.studentList.students, expected, 'successfully updates all students on_moderation_stage property'

  test "sets on_moderation_stage property to true on SELECT_STUDENT", ->
    initialState =
      studentList:
        students: [{id: 1},{id: 2}]
    selectStudentAction =
      type: 'SELECT_STUDENT'
      payload:
        studentId: 2
    newState = rootReducer(initialState, selectStudentAction)
    expected = [{id: 1},{id: 2, on_moderation_stage: true}]

    deepEqual newState.studentList.students, expected, 'successfully updates student on_moderation_stage property'


  test "sets on_moderation_stage property to false on UNSELECT_STUDENT", ->
    initialState =
      studentList:
        students: [{id: 1, on_moderation_stage: true},{id: 2}]
    unselectStudentAction =
      type: 'UNSELECT_STUDENT'
      payload:
        studentId: 1
    newState = rootReducer(initialState, unselectStudentAction)
    expected = [{id: 1, on_moderation_stage: false},{id: 2}]

    deepEqual newState.studentList.students, expected, 'successfully updates student on_moderation_stage property'

  test "set the on_moderation_stage to false from all students on UPDATED_MODERATION_SET", ->
    initialState =
      studentList:
        students: [{id: 1, on_moderation_stage: true},{id: 2, on_moderation_stage: true}]
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        students: [{id: 1}, {id: 2}, {id: 3}]
    newState = rootReducer(initialState, updatedModerationSetAction)

    studentsInSet = _.find(newState.studentList.students, (student) => student.on_moderation_stage)

    ok !studentsInSet, 'updates state'

  test "sets the selected_provisional_grade_id for a student on SELECT_MARK", ->
    initialState =
      studentList:
        students: [
          id: 1
          selected_provisional_grade_id: null
          provisional_grades: [
            provisional_grade_id: 10
          ]
        ]
    selectMarkAction =
      type: 'SELECT_MARK'
      payload:
        studentId: 1
        selectedProvisionalId: 10

    newState = rootReducer(initialState, selectMarkAction)
    expected = [
          id: 1
          selected_provisional_grade_id: 10
          provisional_grades: [
            provisional_grade_id: 10
          ]
        ]

    deepEqual newState.studentList.students, expected, 'student received updated selected_provisional_grade_id property'

  QUnit.module "urls reducer"

  test "passes through whatever the current state is", ->
    initialState =
      urls:
        test_url: 'test'
    someRandomAction =
      type: 'Random'
    newState = rootReducer(initialState, someRandomAction)
    deepEqual newState.urls, initialState.urls, 'passes through unchanged'

  QUnit.module "assignments reducer"

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


  QUnit.module "flashMessage reducer"

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

  test "sets success message on UPDATED_MODERATION_SET", ->
    initialState =
      flashMessage: {}
      studentList:
        students: []
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        time: 10
        message: 'test success'
        students: [{id: 1},{id: 2}]
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected =
      time: 10
      message: 'test success'
      error: false
    deepEqual newState.flashMessage, expected, 'updates state'

  test "sets failure message on UPDATE_MODERATION_SET_FAILED", ->
    initialState =
      flashMessage: {}
    updatedModerationSetAction =
      type: 'UPDATE_MODERATION_SET_FAILED'
      payload:
        time: 10
        message: 'test failure'
        students: [{id: 1},{id: 2}]
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected =
      time: 10
      message: 'test failure'
      error: true
    deepEqual newState.flashMessage, expected, 'updates state'


  test "sets message and error on SELECTING_PROVISIONAL_GRADES_FAILED", ->
    message = 'some error message'
    error = new Error(message)
    error.time = Date.now()

    initialState =
      flashMessage: {}
    updatedModerationSetAction =
      type: 'SELECTING_PROVISIONAL_GRADES_FAILED'
      payload: error
      error: true
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected =
      time: error.time
      message: message
      error: true
    deepEqual newState.flashMessage, expected, 'updates state'

  QUnit.module 'inflightAction reducer',
    setup: ->
      @initialState =
        inflightAction:
          review: false
          publish: false

      @inflightInitialState =
        students: {}
        inflightAction:
          review: true
          publish: true

  test 'marks the review action as in-flight on ACTION_DISPATCHED with a payload of review', ->
    reviewActionDispatchedAction =
      type: 'ACTION_DISPATCHED'
      payload:
        name: 'review'

    stateWithReviewDispatched = rootReducer(@initialState, reviewActionDispatchedAction)
    equal stateWithReviewDispatched.inflightAction.review, true
    equal stateWithReviewDispatched.inflightAction.publish, false

  test 'marks the publish action as in-flight on ACTION_DISPATCHED with a payload of publish', ->
    publishActionDispatchedAction =
      type: 'ACTION_DISPATCHED'
      payload:
        name: 'publish'

    stateWithPublishDispatched = rootReducer(@initialState, publishActionDispatchedAction)
    equal stateWithPublishDispatched.inflightAction.publish, true
    equal stateWithPublishDispatched.inflightAction.review, false

  test 'lands the review action on UPDATED_MODERATION_SET', ->
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        students: []

    stateWithReviewLanded = rootReducer(@inflightInitialState, updatedModerationSetAction)
    equal stateWithReviewLanded.inflightAction.review, false

  test 'lands the review action on UPDATE_MODERATION_SET_FAILED', ->
    updateModerationSetFailedAction =
      type: 'UPDATE_MODERATION_SET_FAILED'
      payload:
        time: Date.now()

    stateWithReviewLanded = rootReducer(@inflightInitialState, updateModerationSetFailedAction)
    equal stateWithReviewLanded.inflightAction.review, false

  test 'lands the publish action on PUBLISHED_GRADES', ->
    publishedGradesAction =
      type: 'PUBLISHED_GRADES'
      payload:
        time: Date.now()

    stateWithPublishLanded = rootReducer(@inflightInitialState, publishedGradesAction)
    equal stateWithPublishLanded.inflightAction.publish, false

  test 'lands the publish action on PUBLISHED_GRADES_FAILED', ->
    publishedGradesFailedAction =
      type: 'PUBLISHED_GRADES_FAILED'
      payload:
        time: Date.now()

    stateWithPublishLanded = rootReducer(@inflightInitialState, publishedGradesFailedAction)
    equal stateWithPublishLanded.inflightAction.publish, false

  QUnit.module "sorting mark1 column on SORT_MARK1_COLUMN"

  test 'default to descending order when clicking on a new column', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: undefined
          direction: undefined

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK1_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    deepEqual newState.studentList.students[0].id, 4, 'sorts the right student to the top'

  test 'sorts students to descending order when previously ascending', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: Constants.markColumnNames.MARK_ONE
          direction: Constants.sortDirections.ASCENDING

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK1_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    deepEqual newState.studentList.students[0].id, 4, 'sorts the right student to the top'

  test 'sorts students to ascending order when previously descending', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: Constants.markColumnNames.MARK_ONE
          direction: Constants.sortDirections.DESCENDING

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK1_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    equal newState.studentList.sort.direction, Constants.sortDirections.ASCENDING, 'sets the right direction'
    deepEqual newState.studentList.students[0].id, 2, 'sorts the right student to the top'

  QUnit.module "sorting mark2 column on SORT_MARK2_COLUMN"

  test 'default to descending order when clicking on a new column', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: undefined
          direction: undefined

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK2_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    deepEqual newState.studentList.students[0].id, 3, 'sorts the right student to the top'

  test 'sorts students to descending order when previously ascending', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: Constants.markColumnNames.MARK_TWO
          direction: Constants.sortDirections.ASCENDING

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK2_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    deepEqual newState.studentList.students[0].id, 3, 'sorts the right student to the top'

  test 'sorts students to ascending order when previously descending', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: Constants.markColumnNames.MARK_TWO
          direction: Constants.sortDirections.DESCENDING

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK2_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    equal newState.studentList.sort.direction, Constants.sortDirections.ASCENDING, 'sets the right direction'
    deepEqual newState.studentList.students[0].id, 2, 'sorts the right student to the top'

  QUnit.module "sorting mark3 column on SORT_MARK3_COLUMN"

  test 'default to descending order when clicking on a new column', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: undefined
          direction: undefined

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK3_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    deepEqual newState.studentList.students[0].id, 4, 'sorts the right student to the top'

  test 'sorts students to descending order when previously ascending', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: Constants.markColumnNames.MARK_THREE
          direction: Constants.sortDirections.ASCENDING

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK3_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    deepEqual newState.studentList.students[0].id, 4, 'sorts the right student to the top'

  test 'sorts students to ascending order when previously descending', ->
    initialState =
      studentList:
        students: fakeStudents
        sort:
          column: Constants.markColumnNames.MARK_THREE
          direction: Constants.sortDirections.DESCENDING

    updatedModerationSetAction =
      type: ModerationActions.SORT_MARK3_COLUMN
    newState = rootReducer(initialState, updatedModerationSetAction)

    equal newState.studentList.sort.direction, Constants.sortDirections.ASCENDING, 'sets the right direction'
    deepEqual newState.studentList.students[0].id, 2, 'sorts the right student to the top'
