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
