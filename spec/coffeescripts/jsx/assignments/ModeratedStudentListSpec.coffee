define [
  'react'
  'jsx/assignments/ModeratedStudentList'
  'jsx/assignments/constants'
], (React, ModeratedStudentList, Constants) ->
  TestUtils = React.addons.TestUtils
  fakeStudent = [
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

  module 'ModeratedColumnHeader',
  test 'only shows one column when includeModerationSetHeaders is false', ->
    studentList = TestUtils.renderIntoDocument(ModeratedStudentList(urls: {assignment_speedgrader_url: 'blah'}, includeModerationSetColumns: false, students: fakeStudent, assignment: {published: false},handleCheckbox: () => 'stub' ))
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList__Mark')
    equal columns.length, 1, 'only show one column'
    React.unmountComponentAtNode(studentList.getDOMNode().parentNode)
  test 'show all columns when includeModerationSetHeaders is true', ->
    studentList = TestUtils.renderIntoDocument(ModeratedStudentList(urls: {assignment_speedgrader_url: 'blah'}, includeModerationSetColumns: true, students: fakeStudent, assignment: {published: false},handleCheckbox: () => 'stub' ))
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'ModeratedAssignmentList__Mark')
    equal columns.length, 3, 'show all columns'
    React.unmountComponentAtNode(studentList.getDOMNode().parentNode)
