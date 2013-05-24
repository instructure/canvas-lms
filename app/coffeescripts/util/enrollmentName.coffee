define ['i18n!enrollmentNames'], (I18n) ->

  types =
    StudentEnrollment:  I18n.t "student", "Student"
    TeacherEnrollment:  I18n.t "teacher", "Teacher"
    TaEnrollment:       I18n.t "teacher_assistant", "TA"
    ObserverEnrollment: I18n.t "observer", "Observer"
    DesignerEnrollment: I18n.t "course_designer", "Course Designer"

  enrollmentName = (type) ->
    types[type] or type

