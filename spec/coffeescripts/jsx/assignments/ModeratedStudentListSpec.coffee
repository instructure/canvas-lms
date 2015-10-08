define [
  'react'
  'jsx/assignments/ModeratedStudentList'
  'jsx/assignments/constants'
  'underscore'
], (React, ModeratedStudentList, Constants, _) ->
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

  module 'ModeratedStudentList',
  test 'show a dash in in the first column when not in the moderation set', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    studentList = TestUtils.renderIntoDocument(ModeratedStudentList(
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub',
        onSelectProvisionalGrade: () => 'stub'
      )
    )
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList__Mark')
    equal columns[0].getDOMNode().textContent, '-', 'shows a dash for non moderation set students'
    React.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'only shows one column when includeModerationSetHeaders is false', ->
    studentList = TestUtils.renderIntoDocument(ModeratedStudentList(
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: false,
        studentList: fakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub',
        onSelectProvisionalGrade: () => 'stub'
      )
    )
    columns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList__Mark')
    equal columns.length, 1, 'only show one column'
    React.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  test 'shows the grade column when there is a selected_provisional_grade_id', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    newFakeStudentList.students[0].selected_provisional_grade_id = 10
    studentList = TestUtils.renderIntoDocument(ModeratedStudentList(
        urls: {assignment_speedgrader_url: 'blah'},
        includeModerationSetColumns: true,
        studentList: newFakeStudentList,
        assignment: {published: false},
        handleCheckbox: () => 'stub'
        onSelectProvisionalGrade: () => 'stub'
      )
    )

    gradeColumns = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'AssignmentList_Grade')

    equal gradeColumns[0].props.children, 4
    React.unmountComponentAtNode(studentList.getDOMNode().parentNode)

  module 'Persist provisional grades',
  test 'selecting provisional grade triggers handleSelectProvisionalGrade handler', ->
    newFakeStudentList = _.extend({}, fakeStudentList)
    newFakeStudentList.students[0].in_moderation_set = true
    callback = sinon.spy()
    studentList = TestUtils.renderIntoDocument(ModeratedStudentList(onSelectProvisionalGrade: callback, urls: {provisional_grades_base_url: 'blah'}, includeModerationSetColumns: true, studentList: newFakeStudentList, assignment: {published: false},handleCheckbox: () => 'stub' ))
    mark1Radio = TestUtils.scryRenderedDOMComponentsWithClass(studentList, 'ModeratedAssignmentList__Mark')
    radio = TestUtils.scryRenderedDOMComponentsWithTag(mark1Radio[0], 'input')
    TestUtils.Simulate.change(radio[0].getDOMNode())
    ok callback.called, 'called selectProvisionalGrade'
    React.unmountComponentAtNode(studentList.getDOMNode().parentNode)
