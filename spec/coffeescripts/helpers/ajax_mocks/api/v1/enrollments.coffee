define ['support/jquery.mockjax'], ($) ->
  $.mockjax
    url: /\/api\/v1\/courses\/\d+\/enrollments(\?.+)?$/
    headers: { 'Link': 'rel="next"' }
    responseText: [
      {
        "course_id": 1,
        "course_section_id": 1,
        "enrollment_state": "active",
        "limit_privileges_to_course_section": true,
        "root_account_id": 1,
        "type": "StudentEnrollment",
        "user_id": 1,
        "user": {
          "id": 1,
          "login_id": "bieberfever@example.com",
          "name": "Justin Bieber",
          "short_name": "Justin B.",
          "sortable_name": "Bieber, Justin"
        }
      },
      {
        "course_id": 1,
        "course_section_id": 2,
        "enrollment_state": "active",
        "limit_privileges_to_course_section": false,
        "root_account_id": 1,
        "type": "TeacherEnrollment",
        "user_id": 2,
        "user": {
          "id": 2,
          "login_id": "changyourmind@example.com",
          "name": "Señor Chang",
          "short_name": "S. Chang",
          "sortable_name": "Chang, Señor"
        }
      }
    ]
