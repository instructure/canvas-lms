define ['compiled/util/enrollmentName'], (enrollmentName) ->

  QUnit.module 'enrollmentName'

  test 'it converts a role name to the name', ->
    equal enrollmentName('StudentEnrollment'), 'Student'
    equal enrollmentName('TeacherEnrollment'), 'Teacher'
    equal enrollmentName('TaEnrollment'), 'TA'
    equal enrollmentName('ObserverEnrollment'), 'Observer'
    equal enrollmentName('DesignerEnrollment'), 'Course Designer'
    equal enrollmentName('no match'), 'no match'

