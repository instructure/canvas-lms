define [
  'react',
  'react-dom',
  'jsx/assignments/ModeratedStudentList'
  'jsx/assignments/constants'
  'underscore'
], (React, ReactDOM, ModeratedStudentList, Constants, _) ->
  TestUtils = React.addons.TestUtils
  fakeStudentList = {students:
    [
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
    ]
  }
  fakeUngradedStudentList = {students:
    [
      {
        'id': 3
        'display_name': 'a@example.edu'
        'avatar_image_url': 'https://canvas.instructure.com/images/messages/avatar-50.png'
        'html_url': 'http://localhost:3000/courses/1/users/3'
        'in_moderation_set': false
        'selected_provisional_grade_id': null
      }
    ]
  }

  module 'ModeratedStudentList'

  test 'only shows the next speedgrader link when in moderation set', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    newFakeStudentList.students[0].in_moderation_set = true
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: true},
        handleCheckbox: () => 'stub',
        onSelectProvisionalGrade: () => 'stub'
      )
    )
    moderatedColumns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'ModeratedAssignmentList__Mark')
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList__Mark')
    equal moderatedColumns[0].getDOMNode().querySelectorAll('span')[1].textContent, '4', 'displays the grade in the first column'
    equal moderatedColumns[1].getDOMNode().querySelectorAll('span')[1].textContent, 'SpeedGrader™', 'displays speedgrader link in the second'
    equal columns[0].getDOMNode().querySelectorAll('span')[1].textContent, '-', 'third column is a dash'
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'show a dash in in the first column when not in the moderation set', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub',
        onSelectProvisionalGrade: () => 'stub'
      )
    )
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList__Mark')
    equal columns[0].getDOMNode().querySelectorAll('span')[1].textContent, '-', 'shows a dash for non moderation set students'
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'only shows one column when includeModerationSetHeaders is false', ->
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: false,
        studentList: fakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub',
        onSelectProvisionalGrade: () => 'stub'
      )
    )
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList__Mark')
    moderatedColumns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'ModeratedAssignmentList__Mark')
    equal columns.length, 1, 'only show one column'
    equal moderatedColumns.length, 0, 'no moderated columns shown'
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'shows the grade column when there is a selected_provisional_grade_id', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    newFakeStudentList.students[0].selected_provisional_grade_id = 10
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub'
        onSelectProvisionalGrade: () => 'stub'
      )
    )

    gradeColumns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList_Grade')
    equal gradeColumns[0].props.children[1].props.children, 4
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'properly renders final grade if there are no provisional grades', ->
    newFakeStudentList = _.extend({}, fakeUngradedStudentList)
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub'
        onSelectProvisionalGrade: () => 'stub'
      )
    )

    gradeColumns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList_Grade')
    equal gradeColumns[0].getDOMNode().querySelectorAll('span')[1].textContent, '-', 'grade column is a dash'
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'does not show radio button if there is only one provisional grade', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub'
        onSelectProvisionalGrade: () => 'stub'
      )
    )

    inputs = TestUtils.scryRenderedDOMComponentsWithTag(studentList, 'input')
    radioInputs = inputs.filter((input) -> input.getDOMNode().type == 'radio')
    equal radioInputs.length, 0, 'does not render any radio buttons'
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(studentList).parentNode)

  test 'shows radio button if there is more than 1 provisional grade', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    newFakeStudentList.students[0].provisional_grades.push({
      'grade': '4'
      'score': 4
      'graded_at': '2015-09-11T15:42:28Z'
      'scorer_id': 1
      'final': false
      'provisional_grade_id': 11
      'grade_matches_current_submission': true
      'speedgrader_url': 'http://example.com'
    })
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList,
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub'
        onSelectProvisionalGrade: () => 'stub'
      )
    )

    inputs = TestUtils.scryRenderedDOMComponentsWithTag(studentList, 'input')
    radioInputs = inputs.filter((input) -> input.getDOMNode().type == 'radio')
    equal radioInputs.length, 2, 'renders two radio buttons'
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  module 'Persist provisional grades'

  test 'selecting provisional grade triggers handleSelectProvisionalGrade handler', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    newFakeStudentList.students[0].provisional_grades.push({
      'grade': '4'
      'score': 4
      'graded_at': '2015-09-11T15:42:28Z'
      'scorer_id': 1
      'final': false
      'provisional_grade_id': 11
      'grade_matches_current_submission': true
      'speedgrader_url': 'http://example.com'
    })
    newFakeStudentList.students[0].in_moderation_set = true
    callback = sinon.spy()
    studentList = TestUtils.renderIntoDocument(React.createElement(ModeratedStudentList, {
      onSelectProvisionalGrade: callback,
      urls: {provisional_grades_base_url: 'blah'},
      includeModerationSetColumns: true,
      studentList: newFakeStudentList,
      assignment: {published: false},
      handleCheckbox: () => 'stub'
    }))
    radio = TestUtils.scryRenderedDOMComponentsWithTag(studentList, 'input').filter((domComponent) -> domComponent.type == 'radio')
    TestUtils.Simulate.change(radio[0])
    ok callback.called, 'called selectProvisionalGrade'
    ReactDOM.unmountComponentAtNode(studentList.getDOMNode().parentNode)
