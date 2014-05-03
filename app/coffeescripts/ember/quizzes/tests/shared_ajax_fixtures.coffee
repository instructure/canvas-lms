define [
  'ic-ajax',
  'ember'
], (ajax, Ember) ->

  quizIndexResponse =
    "meta":
      "pagination":
          page: 1,
          page_count: 1
      "primaryCollection": "quizzes"
      "permissions":
        "quizzes":
          create: true
    "quizzes":
      [
        {
          "access_code":null,
          "allowed_attempts":1,
          "links":
            "assignment_group": "/api/v1/courses/1/assignment_groups/1"
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":1,
          "ip_filter":null,
          "due_at":"2013-11-01T06:59:59Z",
          "lock_at":"2013-11-01T06:59:59Z",
          "unlock_at":"2013-10-27T07:00:00Z",
          "one_question_at_a_time":false,
          "points_possible": 1,
          "quiz_type":"practice_quiz",
          "scoring_policy":"keep_highest",
          "show_correct_answers":true,
          "show_correct_answers_at":null,
          "shuffle_answers":false,
          "time_limit":null,
          "title":"Alt practice test",
          "html_url":"http://localhost:3000/courses/1/quizzes/1",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/1?force_user=1&persist_headless=1",
          "question_count":0,
          "published":false,
          "unpublishable":true,
          "locked_for_user":false
          "permissions":
            delete: true
            manage: true
            update: true
        },
        {
          "access_code":null,
          "allowed_attempts":1,
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":2,
          "ip_filter":null,
          "due_at":"2013-12-01T06:59:59Z",
          "lock_at":"2013-12-01T06:59:59Z",
          "unlock_at":"2013-11-27T07:00:00Z",
          "one_question_at_a_time":false,
          "points_possible": 2,
          "quiz_type":"practice_quiz",
          "scoring_policy":"keep_highest",
          "show_correct_answers":true,
          "show_correct_answers_at":null,
          "shuffle_answers":false,
          "time_limit":null,
          "title":"Another test",
          "html_url":"http://localhost:3000/courses/1/quizzes/2",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/2?force_user=1&persist_headless=1",
          "question_count":0,
          "published":false,
          "unpublishable":true,
          "locked_for_user":false
        }
      ]

  assignmentGroup =
    id: "1"
    name: "Assignments"

  {
    QUIZZES: quizIndexResponse.quizzes
    ASSIGNMENT_GROUP: assignmentGroup
    create: ->
      ajax.defineFixture '/api/v1/courses/1/quizzes',
        response: JSON.parse(JSON.stringify quizIndexResponse),
        jqXHR: {}
        testStatus: '200'

      ajax.defineFixture '/api/v1/courses/1/assignment_groups/1',
        response: JSON.parse(JSON.stringify assignmentGroup),
        jqXHR: {}
        testStatus: '200'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1',
        response: JSON.parse(JSON.stringify quizIndexResponse),
        jqXHR: {}
        testStatus: '200'
  }

