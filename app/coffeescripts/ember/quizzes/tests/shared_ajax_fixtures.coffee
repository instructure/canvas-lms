define [
  'ic-ajax',
  'ember'
], (ajax, Ember) ->

  quiz_index_response = {
    "meta": {
      "pagination": {},
      "primaryCollection": "quizzes"
    },
    "quizzes":
      [
        {
          "access_code":null,
          "allowed_attempts":1,
          "assignment_group_id":1,
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":29,
          "ip_filter":null,
          "due_at":"2013-11-01T06:59:59Z",
          "lock_at":"2013-11-01T06:59:59Z",
          "unlock_at":"2013-10-27T07:00:00Z",
          "one_question_at_a_time":false,
          "points_possible":null,
          "quiz_type":"practice_quiz",
          "scoring_policy":"keep_highest",
          "show_correct_answers":true,
          "show_correct_answers_at":null,
          "shuffle_answers":false,
          "time_limit":null,
          "title":"Alt practice test",
          "html_url":"http://localhost:3000/courses/1/quizzes/29",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/29?force_user=1&persist_headless=1",
          "question_count":0,
          "published":false,
          "unpublishable":true,
          "locked_for_user":false
        },
        {
          "access_code":null,
          "allowed_attempts":1,
          "assignment_group_id":1,
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":30,
          "ip_filter":null,
          "due_at":"2013-12-01T06:59:59Z",
          "lock_at":"2013-12-01T06:59:59Z",
          "unlock_at":"2013-11-27T07:00:00Z",
          "one_question_at_a_time":false,
          "points_possible":null,
          "quiz_type":"practice_quiz",
          "scoring_policy":"keep_highest",
          "show_correct_answers":true,
          "show_correct_answers_at":null,
          "shuffle_answers":false,
          "time_limit":null,
          "title":"Another test",
          "html_url":"http://localhost:3000/courses/1/quizzes/29",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/29?force_user=1&persist_headless=1",
          "question_count":0,
          "published":false,
          "unpublishable":true,
          "locked_for_user":false
        }
      ]
    }

  create: ->
    ajax.defineFixture '/api/v1/courses/1/quizzes',
      response: quiz_index_response,
      jqXHR: {}
      testStatus: '200'

