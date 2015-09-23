define [
  "jsx/assignments/reducers/rootReducer"
  "jsx/assignments/constants"
  "jsx/assignments/actions/ModerationActions"
], (rootReducer, Constants, ModerationActions) ->
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
          } ]
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
          ]
        }
        {
          'id': 5
          'display_name': 'c@example.edu'
          'avatar_image_url': 'https://canvas.instructure.com/images/messages/avatar-50.png'
          'html_url': 'http://localhost:3000/courses/1/users/5'
          'in_moderation_set': false
          'selected_provisional_grade_id': null
          'provisional_grades': []
        }
      ]


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

  test "updates the moderation set handling UPDATED_MODERATION_SET", ->
    initialState =
      students: [{id: 1},{id: 2}]
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        students: [{id: 1},{id: 2}]
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected = [{id: 1, in_moderation_set: true},{id: 2, in_moderation_set: true}]

    deepEqual newState.students, expected, 'successfully updates moderation set'

  test "sets all the students on_moderation_stage property to true on SELECT_ALL_STUDENTS", ->
    initialState =
      students: [{id: 1},{id: 2}]
    selectAllStudentsAction =
      type: 'SELECT_ALL_STUDENTS'
      payload:
        students: [{id: 1},{id: 2}]
    newState = rootReducer(initialState, selectAllStudentsAction)
    expected = [{id: 1, on_moderation_stage: true},{id: 2, on_moderation_stage: true}]

    deepEqual newState.students, expected, 'successfully updates all students on_moderation_stage property'

  test "sets all the students on_moderation_stage property to false on UNSELECT_ALL_STUDENTS", ->
    initialState =
      students: [{id: 1, on_moderation_stage: true},{id: 2, on_moderation_stage: true}]
    unselectAllStudentsAction =
      type: 'UNSELECT_ALL_STUDENTS'
    newState = rootReducer(initialState, unselectAllStudentsAction)
    expected = [{id: 1, on_moderation_stage: false},{id: 2, on_moderation_stage: false}]

    deepEqual newState.students, expected, 'successfully updates all students on_moderation_stage property'

  test "sets on_moderation_stage property to true on SELECT_STUDENT", ->
    initialState =
      students: [{id: 1},{id: 2}]
    selectStudentAction =
      type: 'SELECT_STUDENT'
      payload:
        studentId: 2
    newState = rootReducer(initialState, selectStudentAction)
    expected = [{id: 1},{id: 2, on_moderation_stage: true}]

    deepEqual newState.students, expected, 'successfully updates student on_moderation_stage property'


  test "sets on_moderation_stage property to false on UNSELECT_STUDENT", ->
    initialState =
      students: [{id: 1, on_moderation_stage: true},{id: 2}]
    unselectStudentAction =
      type: 'UNSELECT_STUDENT'
      payload:
        studentId: 1
    newState = rootReducer(initialState, unselectStudentAction)
    expected = [{id: 1, on_moderation_stage: false},{id: 2}]

    deepEqual newState.students, expected, 'successfully updates student on_moderation_stage property'

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

  module "moderationStage reducer",

  test "adds student to the moderation stage on SELECT_STUDENT", ->
    initialState =
      students: [{id: 1}, {id: 2}, {id: 3}, {id: 10}]
      moderationStage: [1, 2, 3]
    selectStudentAction =
      type: 'SELECT_STUDENT'
      payload:
        studentId: 10
    newState = rootReducer(initialState, selectStudentAction)
    expected = [1, 2, 3, 10]

    deepEqual newState.moderationStage, expected, 'updates state'

  test "removes student from the moderationStage on UNSELECT_STUDENT", ->
    initialState =
      students: [{id: 1}, {id: 2}, {id: 3}]
      moderationStage: [1, 2, 3]
    unselectStudentAction =
      type: 'UNSELECT_STUDENT'
      payload:
        studentId: 2
    newState = rootReducer(initialState, unselectStudentAction)
    expected = [1, 3]

    deepEqual newState.moderationStage, expected, 'updates state'

  test "adds all students to the moderation stage on SELECT_ALL_STUDENTS", ->
    initialState =
      students: [{id: 1}, {id: 2}, {id: 3}, {id: 10}]
      moderationStage: [1, 2, 3]
    selectAllStudentsAction =
      type: 'SELECT_ALL_STUDENTS'
      payload:
        students: [{id: 1}, {id: 2}, {id: 3}, {id: 10}]
    newState = rootReducer(initialState, selectAllStudentsAction)
    expected = [1, 2, 3, 10]

    deepEqual newState.moderationStage, expected, 'updates state'

  test "clears the moderation stage on UNSELECT_ALL_STUDENTS", ->
    initialState =
      moderationStage: [1, 2, 3]
    unselectAllStudentsAction =
      type: 'UNSELECT_ALL_STUDENTS'
    newState = rootReducer(initialState, unselectAllStudentsAction)
    expected = []

    deepEqual newState.moderationStage, expected, 'updates state'

  test "clears the moderation stage on UPDATED_MODERATION_SET", ->
    initialState =
      moderationStage: [1, 2, 3]
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        students: [{id: 1}, {id: 2}, {id: 3}]
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected = []

    deepEqual newState.moderationStage, expected, 'updates state'

  test "clears only the returned students from the moderation stage on UPDATED_MODERATION_SET", ->
    initialState =
      moderationStage: [1, 2, 3]
    updatedModerationSetAction =
      type: 'UPDATED_MODERATION_SET'
      payload:
        students: [{id: 2}, {id: 3}]
    newState = rootReducer(initialState, updatedModerationSetAction)
    expected = [1]

    deepEqual newState.moderationStage, expected, 'updates state'

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

  test "sets success message on UPDATED_MODERATION_SET", ->
    initialState =
      flashMessage: {}
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

  module "sortMarkColumn reducer",

  test 'toggles currentSortDirection to HIGHEST by default on SORT_MARK_COLUMN ', ->
    initialState =
      markColumnSort:
        markColumn: 0
        currentSortDirection: undefined

    sortColumnAction =
      type: ModerationActions.SORT_MARK_COLUMN
      payload:
        markColumn: 0,
        currentSortDirection: undefined

    newState = rootReducer(initialState, sortColumnAction)
    expected =
      markColumn: 0
      currentSortDirection: Constants.sortDirections.HIGHEST
    deepEqual newState.markColumnSort, expected, 'updates state'

  test 'toggles currentSortDirection from HIGHEST to LOWEST on SORT_MARK_COLUMN ', ->
    initialState =
      markColumnSort:
        markColumn: 0
        currentSortDirection: Constants.sortDirections.HIGHEST

    sortColumnAction =
      type: ModerationActions.SORT_MARK_COLUMN
      payload:
        markColumn: 0,
        currentSortDirection: Constants.sortDirections.HIGHEST

    newState = rootReducer(initialState, sortColumnAction)
    expected =
      markColumn: 0
      currentSortDirection: Constants.sortDirections.LOWEST
    deepEqual newState.markColumnSort, expected, 'updates state'

  test 'sort in descending order if new column selected default on SORT_MARK_COLUMN ', ->
    initialState =
      students: fakeStudents
      markColumnSort:
        previousMarkColumn: undefined
        markColumn: 0
        currentSortDirection: Constants.sortDirections.HIGHEST

    sortColumnAction =
      type: ModerationActions.SORT_MARK_COLUMN
      payload:
        previousMarkColumn: 1
        markColumn: 0
        currentSortDirection: Constants.sortDirections.HIGHEST

    newState = rootReducer(initialState, sortColumnAction)
    expectedStudentId = 4
    firstStudent = newState.students[0]
    equal firstStudent.id, expectedStudentId, 'sorts students it descending order'

  test 'sorting students in descending order by default on SORT_MARK_COLUMN ', ->
    initialState =
      students: fakeStudents
      markColumnSort:
        markColumn: 0
        currentSortDirection: undefined

    sortColumnAction =
      type: ModerationActions.SORT_MARK_COLUMN
      payload:
        markColumn: 0,
        currentSortDirection: undefined

    newState = rootReducer(initialState, sortColumnAction)
    expectedStudentId = 4
    firstStudent = newState.students[0]
    equal firstStudent.id, expectedStudentId, 'sorts students it descending order'

  test 'sorting students in descending order by when currentSortDirection is LOWEST on SORT_MARK_COLUMN ', ->
    initialState =
      students: fakeStudents
      markColumnSort:
        markColumn: 0
        currentSortDirection: Constants.sortDirections.LOWEST

    sortColumnAction =
      type: ModerationActions.SORT_MARK_COLUMN
      payload:
        markColumn: 0,
        currentSortDirection: Constants.sortDirections.LOWEST

    newState = rootReducer(initialState, sortColumnAction)
    expectedStudentId = 4
    firstStudent = newState.students[0]
    equal firstStudent.id, expectedStudentId, 'sorts students it descending order'

  test 'sorting students in ascending order by when currentSortDirection is HIGHEST on SORT_MARK_COLUMN ', ->
    initialState =
      students: fakeStudents
      markColumnSort:
        previousMarkColumn: 0
        markColumn: 0
        currentSortDirection: Constants.sortDirections.HIGHEST

    sortColumnAction =
      type: ModerationActions.SORT_MARK_COLUMN
      payload:
        previousMarkColumn: 0
        markColumn: 0,
        currentSortDirection: Constants.sortDirections.HIGHEST

    newState = rootReducer(initialState, sortColumnAction)
    expectedStudentId = 2
    firstStudent = newState.students[0]
    equal firstStudent.id, expectedStudentId, 'sorts students it ascending order'


