define [
  'jsx/gradebook/grid/helpers/enrollmentsHelper'
], (EnrollmentsHelper) ->

  defaultEnrollments = ->
    [
      { id: 1, user_id: 7, type: 'StudentEnrollment', user: { id: 7, name: 'Dora' } },
      { id: 2, user_id: 8, type: 'ObserverEnrollment', user: { id: 8, name: 'Parent' } },
      { id: 3, user_id: 9, type: 'StudentViewEnrollment', user: { id: 9, name: 'Fake Student' } },
      { id: 4, user_id: 10, type: 'StudentEnrollment', user: { id: 10, name: 'Swiper' } },
    ]

  module 'EnrollmentsHelper#studentEnrollments'

  test 'filters out non-student enrollments', ->
    returnedEnrollments = EnrollmentsHelper.studentEnrollments(defaultEnrollments())
    expectedEnrollments = defaultEnrollments()
    expectedEnrollments.splice(1,2)

    propEqual returnedEnrollments, expectedEnrollments

  module 'EnrollmentsHelper#students'

  test 'returns students indexed by their IDs given an array of enrollments', ->
    enrollments = defaultEnrollments()
    student = enrollments[0].user
    returnedStudents = EnrollmentsHelper.students(enrollments)

    propEqual returnedStudents[student.id], student

  test 'excludes non-students (observers, fake students)', ->
    enrollments = defaultEnrollments()
    parent = enrollments[1].user
    returnedStudents = EnrollmentsHelper.students(enrollments)

    notOk returnedStudents[parent.id]

  module 'EnrollmentsHelper#studentsThatCanSeeAssignment'

  test 'returns students that are included in the assignment visibility, indexed by their ids', ->
    assignment = { id: 54, assignment_visibility: ['7'] }
    enrollments = defaultEnrollments()
    studentThatCanSeeAssignment = enrollments[0].user
    returnedStudents = EnrollmentsHelper.studentsThatCanSeeAssignment(enrollments, assignment)

    ok returnedStudents[studentThatCanSeeAssignment.id]

  test 'excludes students that are not included in the assignment visibility', ->
    assignment = { id: 54, assignment_visibility: ['7'] }
    enrollments = defaultEnrollments()
    studentThatCannotSeeAssignment = enrollments[3].user
    returnedStudents = EnrollmentsHelper.studentsThatCanSeeAssignment(enrollments, assignment)

    notOk returnedStudents[studentThatCannotSeeAssignment.id]

  test 'excludes observers, even if their ids are included in the assignment visibility', ->
    assignment = { id: 54, assignment_visibility: ['7', '8'] }
    enrollments = defaultEnrollments()
    observer = enrollments[1].user
    returnedStudents = EnrollmentsHelper.studentsThatCanSeeAssignment(enrollments, assignment)

    notOk returnedStudents[observer.id]

  test 'excludes fake students, even if their ids are included in the assignment visibility', ->
    assignment = { id: 54, assignment_visibility: ['7', '9'] }
    enrollments = defaultEnrollments()
    fakeStudent = enrollments[2].user
    returnedStudents = EnrollmentsHelper.studentsThatCanSeeAssignment(enrollments, assignment)

    notOk returnedStudents[fakeStudent.id]
