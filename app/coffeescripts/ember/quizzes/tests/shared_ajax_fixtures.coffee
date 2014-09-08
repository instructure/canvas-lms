define [
  'ic-ajax',
  'ember'
  'underscore'
], (ajax, Ember, _) ->

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
            "quizStatistics": "/api/v1/courses/1/quizzes/1/statistics"
            "quizReports": "/api/v1/courses/1/quizzes/1/reports"
            "submitted_students": "/api/v1/courses/1/quizzes/1/submission_users?submitted=true"
            "unsubmitted_students": "/api/v1/courses/1/quizzes/1/submission_users?submitted=false"
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":1,
          "quiz_submission_html_url": "/courses/1/quizzes/1/submission_html"
          "ip_filter":null,
          "due_at":"2013-11-01T06:59:59Z",
          "all_dates": [
            {
              base: true,
              title: "Everyone"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            },
            {
              id: "1"
              title: "My Section"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            }
          ]
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
          "message_students_url": "http://localhost:3000/courses/1/quizzes/1/submission_users/message",
          "question_count":0,
          "published":true,
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
          "links":
            "assignment_group": "/api/v1/courses/1/assignment_groups/1"
          "all_dates": [
            {
              base: true,
              title: "Everyone"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            }
          ]
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
          "quiz_submission_html_url": "/courses/1/quizzes/2/submission_html"
          "html_url":"http://localhost:3000/courses/1/quizzes/2",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/2?force_user=1&persist_headless=1",
          "message_students_url": "http://localhost:3000/courses/1/quizzes/2/submission_users/message",
          "question_count":0,
          "published":false,
          "unpublishable":true,
          "locked_for_user":false
        }
      ]

  quizShowStudentResponse =
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
            "quizStatistics": "/api/v1/courses/1/quizzes/2/statistics"
            "quizReports": "/api/v1/courses/1/quizzes/2/reports"
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":2,
          "quiz_submission_html_url": "/courses/1/quizzes/2/submission_html"
          "ip_filter":null,
          "due_at":"2013-11-01T06:59:59Z",
          "all_dates": [
            {
              base: true,
              title: "Everyone"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            },
            {
              id: "1"
              title: "My Section"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            }
          ]
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
          "html_url":"http://localhost:3000/courses/1/quizzes/2",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/2?force_user=1&persist_headless=1",
          "question_count":0,
          "published":false,
          "unpublishable":true,
          "locked_for_user":false
          "permissions":
            read: true
            delete: false
            manage: false
            update: false
        }
      ]

  quizEmptyStatisticsResponse =
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
            "quizStatistics": "/api/v1/courses/1/quizzes/3/statistics"
            "quizReports": "/api/v1/courses/1/quizzes/3/reports"
            "submitted_students": "/api/v1/courses/1/quizzes/3/submission_users?submitted=true"
            "unsubmitted_students": "/api/v1/courses/1/quizzes/3/submission_users?submitted=false"
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":3,
          "quiz_submission_html_url": "/courses/1/quizzes/3/submission_html"
          "ip_filter":null,
          "due_at":"2013-11-01T06:59:59Z",
          "all_dates": [
            {
              base: true,
              title: "Everyone"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            },
            {
              id: "1"
              title: "My Section"
              due_at: new Date()
              lock_at: null
              unlock_at: null
            }
          ]
          "lock_at":"2013-11-01T06:59:59Z",
          "unlock_at":"2013-10-27T07:00:00Z",
          "one_question_at_a_time":false,
          "points_possible": 1,
          "quiz_type":"assignment",
          "scoring_policy":"keep_highest",
          "show_correct_answers":true,
          "show_correct_answers_at":null,
          "shuffle_answers":false,
          "time_limit":null,
          "title":"Quiz taken by nobody",
          "html_url":"http://localhost:3000/courses/1/quizzes/3",
          "mobile_url":"http://localhost:3000/courses/1/quizzes/3?force_user=1&persist_headless=1",
          "message_students_url": "http://localhost:3000/courses/1/quizzes/3/submission_users/message",
          "question_count":0,
          "published":true,
          "unpublishable":true,
          "locked_for_user":false
          "permissions":
            delete: true
            manage: true
            update: true
        }
      ]

  submissionUsers =
    users: [
      {
        "id":"1",
        "links":{"quiz_submission":3},
        "name":"James Brown",
        "sortable_name":"Brown, James",
        "short_name":"James Brown"
      },
      {
        "id":"2",
        "links":{"quiz_submission":4},
        "name":"Maceo Parker",
        "sortable_name":"Parker, Maceo",
        "short_name":"Maceo Parker"
      }
    ]
    submissions: [
      {
        "attempt":1,
        "end_at":null,
        "extra_attempts":null,
        "extra_time":null,
        "finished_at":"2014-05-07T22:41:40Z",
        "fudge_points":null,
        "id":"3",
        "kept_score":0,
        "quiz_id":1,
        "quiz_points_possible":1,
        "quiz_version":1,
        "score":0,
        "score_before_regrade":null,
        "started_at":"2014-05-07T22:41:34Z",
        "submission_id":3,
        "user_id":1,
        "validation_token":"b1d62b22f0b6bf69e2b67437560f1555fd7ae925f3269e8b63f16c9e1fa8a956",
        "workflow_state":"complete",
        "time_spent":6,
        "html_url":"http://localhost:3000/courses/1/quizzes/1/submissions/3"
      },
      {
        "attempt":2,
        "end_at":null,
        "extra_attempts":null,
        "extra_time":null,
        "finished_at":"2014-05-07T22:41:40Z",
        "fudge_points":null,
        "id":"4",
        "kept_score":0,
        "quiz_id":1,
        "quiz_points_possible":1,
        "quiz_version":1,
        "score":0,
        "score_before_regrade":null,
        "started_at":"2014-05-07T22:41:34Z",
        "submission_id":4,
        "user_id":2,
        "validation_token":"b1d62b22f0b6bf69e2b67437560f1555fd7ae925f3269e8b63f16c9e1fa8a956",
        "workflow_state":"complete",
        "time_spent":6,
        "html_url":"http://localhost:3000/courses/1/quizzes/1/submissions/4"
      }
    ]
    meta: {}

  assignmentGroup =
    id: "1"
    name: "Assignments"

  quizStatisticsResponse = {"quiz_statistics":[{"id":"14","url":"http://localhost:3000/api/v1/courses/1/quizzes/1/statistics","html_url":"http://localhost:3000/courses/1/quizzes/1/statistics","multiple_attempts_exist":true,"generated_at":"2014-06-17T16:38:25Z","includes_all_versions":false,"question_statistics":[{"id":"11","question_type":"multiple_choice_question","question_text":"<p>Which?</p>","position":1,"responses":6,"answers":[{"id":"3866","text":"I am a very long description of an answer that should span multiple lines.","correct":true,"responses":4},{"id":"2040","text":"b","correct":false,"responses":1},{"id":"7387","text":"c","correct":false,"responses":1},{"id":"4082","text":"d","correct":false,"responses":0}],"answered_student_count":6,"top_student_count":2,"middle_student_count":2,"bottom_student_count":2,"correct_student_count":4,"incorrect_student_count":2,"correct_student_ratio":0.6666666666666666,"incorrect_student_ratio":0.3333333333333333,"correct_top_student_count":1,"correct_middle_student_count":2,"correct_bottom_student_count":1,"variance":0.22222222222222224,"stdev":0.4714045207910317,"difficulty_index":0.6666666666666666,"alpha":null,"point_biserials":[{"answer_id":3866,"point_biserial":-0.0473037765270769,"correct":true,"distractor":false},{"answer_id":2040,"point_biserial":0.3889279569582486,"correct":false,"distractor":true},{"answer_id":7387,"point_biserial":-0.32909288665697956,"correct":false,"distractor":true},{"answer_id":4082,"point_biserial":null,"correct":false,"distractor":true}]},{"id":"12","question_type":"multiple_choice_question","question_text":"<p>A, B, C, or D?</p>","position":2,"responses":5,"answers":[{"id":"3023","text":"A","correct":true,"responses":4},{"id":"8899","text":"B","correct":false,"responses":1},{"id":"7907","text":"C","correct":false,"responses":0},{"id":"5646","text":"D","correct":false,"responses":0},{"id":"none","text":"No Answer","correct":false,"responses":1}],"answered_student_count":4,"top_student_count":2,"middle_student_count":2,"bottom_student_count":0,"correct_student_count":3,"incorrect_student_count":1,"correct_student_ratio":0.75,"incorrect_student_ratio":0.25,"correct_top_student_count":2,"correct_middle_student_count":1,"correct_bottom_student_count":0,"variance":0.1875,"stdev":0.4330127018922193,"difficulty_index":0.75,"alpha":null,"point_biserials":[{"answer_id":3023,"point_biserial":0.42308109549488865,"correct":true,"distractor":false},{"answer_id":8899,"point_biserial":-0.42308109549488865,"correct":false,"distractor":true},{"answer_id":7907,"point_biserial":null,"correct":false,"distractor":true},{"answer_id":5646,"point_biserial":null,"correct":false,"distractor":true}]},{"id":"13","question_type":"multiple_choice_question","question_text":"<p>D, A, B, or C?</p>\n<p><img src=\"http://kodoware.com/hadooken.gif\" alt=\"Impressive!\" width=\"400\" height=\"180\">This is a longer description. I'ma embed an image too.</p>","position":3,"responses":6,"answers":[{"id":"3964","text":"A","correct":false,"responses":2},{"id":"6628","text":"B","correct":false,"responses":0},{"id":"2839","text":"C, or...\n \n","correct":false,"responses":1},{"id":"6102","text":"D","correct":true,"responses":3}],"answered_student_count":5,"top_student_count":2,"middle_student_count":2,"bottom_student_count":1,"correct_student_count":3,"incorrect_student_count":2,"correct_student_ratio":0.6,"incorrect_student_ratio":0.4,"correct_top_student_count":2,"correct_middle_student_count":1,"correct_bottom_student_count":0,"variance":0.24000000000000005,"stdev":0.48989794855663565,"difficulty_index":0.6,"alpha":null,"point_biserials":[{"answer_id":6102,"point_biserial":0.606710935709257,"correct":true,"distractor":false},{"answer_id":3964,"point_biserial":-0.606710935709257,"correct":false,"distractor":true},{"answer_id":6628,"point_biserial":null,"correct":false,"distractor":true},{"answer_id":2839,"point_biserial":null,"correct":false,"distractor":true}]},{"id":"14","question_type":"true_false_question","question_text":"<p>Is is true?</p>","position":4,"responses":6,"answers":[{"id":"1496","text":"True","correct":true,"responses":5},{"id":"5354","text":"False","correct":false,"responses":1}],"answered_student_count":5,"top_student_count":2,"middle_student_count":2,"bottom_student_count":1,"correct_student_count":4,"incorrect_student_count":1,"correct_student_ratio":0.8,"incorrect_student_ratio":0.2,"correct_top_student_count":2,"correct_middle_student_count":1,"correct_bottom_student_count":1,"variance":0.16000000000000006,"stdev":0.4000000000000001,"difficulty_index":0.8,"alpha":null,"point_biserials":[{"answer_id":1496,"point_biserial":0.4024941412521818,"correct":true,"distractor":false},{"answer_id":5354,"point_biserial":-0.40249414125218186,"correct":false,"distractor":true}]},{"id":"15","question_type":"short_answer_question","question_text":"<p>Type something</p>","position":5,"responses":6,"answers":[{"id":"4684","text":"Something","correct":true,"responses":4},{"id":"1797","text":"False","correct":true,"responses":1},{"id":"other","text":"Other","correct":false,"responses":1}],"correct":5},{"id":"16","question_type":"fill_in_multiple_blanks_question","question_text":"<p>Roses are [color1], violets are [color2]</p>","position":6,"responses":5,"answered":5,"correct":1,"partially_correct":4,"incorrect":1,"answer_sets":[{"id":"dddce03739867ad935a78cda255ec4dd","text":"color1","answers":[{"id":"9711","text":"Red","correct":true,"responses":5},{"id":"2700","text":"Blue","correct":true,"responses":0},{"id":"none","text":"No Answer","correct":false,"responses":1}]},{"id":"2c442e61b76cc00acf08a1118eae7852","text":"color2","answers":[{"id":"9702","text":"bonkers","correct":true,"responses":1},{"id":"7150","text":"mumbojumbo","correct":true,"responses":0},{"id":"other","text":"Other","correct":false,"responses":4},{"id":"none","text":"No Answer","correct":false,"responses":1}]}]},{"id":"17","question_type":"multiple_answers_question","question_text":"<p>A and B, or B and C?</p>","position":7,"responses":6,"correct":2,"partially_correct":2,"answers":[{"id":"5514","text":"A","correct":true,"responses":5},{"id":"4261","text":"B","correct":true,"responses":3},{"id":"3322","text":"C","correct":false,"responses":2}]},{"id":"18","question_type":"essay_question","question_text":"<p>Summarize your feelings towards life, the universe, and everything in decimal numbers.</p>","position":8,"responses":3,"graded":1,"full_credit":1,"point_distribution":[{"score":0,"count":5},{"score":1,"count":1}]},{"id":"19","question_type":"multiple_dropdowns_question","question_text":"<p>Alligators are [color], zombies eat [organ].</p>","position":9,"responses":6,"answered":5,"correct":5,"partially_correct":0,"incorrect":1,"answer_sets":[{"id":"6892cf3e76966a4d15b8b50bbe335858","text":"organ","answers":[{"id":"3208","text":"brainz","correct":true,"responses":5},{"id":"8331","text":"","correct":false,"responses":0},{"id":"none","text":"No Answer","correct":false,"responses":1}]},{"id":"70dda5dfb8053dc6d1c492574bce9bfd","text":"color","answers":[{"id":"1381","text":"green","correct":true,"responses":5},{"id":"1638","text":"cool","correct":false,"responses":1}]}]},{"id":"20","question_type":"matching_question","question_text":"","position":10,"correct":2,"partially_correct":1,"incorrect":3,"responses":3,"answered":3,"answer_sets":[{"id":"8796","text":"What's for a drink?","correct":false,"responses":0,"answers":[{"id":"1525","text":"A coke, please.","correct":true,"responses":3},{"id":"4756","text":"Home.","correct":false,"responses":0},{"id":"7160","text":"January 1st, 1960.","correct":false,"responses":0},{"id":"4393","text":"Right over there.","correct":false,"responses":0},{"id":"4573","text":"What do you think?","correct":false,"responses":0},{"id":"none","text":"No Answer","correct":false,"responses":3}]},{"id":"6666","text":"Where were we?","correct":false,"responses":0,"answers":[{"id":"1525","text":"A coke, please.","correct":false,"responses":0},{"id":"4756","text":"Home.","correct":false,"responses":1},{"id":"7160","text":"January 1st, 1960.","correct":false,"responses":0},{"id":"4393","text":"Right over there.","correct":true,"responses":2},{"id":"4573","text":"What do you think?","correct":false,"responses":0},{"id":"none","text":"No Answer","correct":false,"responses":3}]},{"id":"6430","text":"What time is it?","correct":false,"responses":0,"answers":[{"id":"1525","text":"A coke, please.","correct":false,"responses":0},{"id":"4756","text":"Home.","correct":false,"responses":0},{"id":"7160","text":"January 1st, 1960.","correct":false,"responses":1},{"id":"4393","text":"Right over there.","correct":false,"responses":0},{"id":"4573","text":"What do you think?","correct":true,"responses":2},{"id":"none","text":"No Answer","correct":false,"responses":3}]}]},{"id":"21","question_type":"numerical_question","question_text":"<p>[Numerical:Exact] What's 9 plus 3, 2.5 minus 1, or 4 minus zero?</p>","position":11,"responses":5,"full_credit":1,"correct":2,"incorrect":4,"answers":[{"id":"4343","text":"12.00","correct":true,"responses":1,"value":[12,12],"margin":0,"is_range":false},{"id":"6959","text":"[3.00..6.00]","correct":true,"responses":0,"value":[3,6],"margin":0,"is_range":true},{"id":"8617","text":"4.00","correct":true,"responses":0,"value":[4,4],"margin":0,"is_range":false},{"id":"6704","text":"1.50","correct":true,"responses":0,"value":[0.5,2.5],"margin":1,"is_range":false},{"id":"none","text":"No Answer","correct":false,"responses":1},{"id":"other","text":"Other","correct":false,"responses":4}]},{"id":"53","question_type":"calculated_question","question_text":"<p>Formula: what is 5 plus [x]?</p>","position":12,"responses":1,"graded":0,"full_credit":0,"point_distribution":[{"score":0,"count":2}]},{"id":"54","question_type":"file_upload_question","question_text":"<p>File Upload: what's that you look like?</p>","position":13,"responses":1,"graded":0,"full_credit":0,"point_distribution":[{"score":0,"count":2}]}],"submission_statistics":{"user_ids":[1,2,14,12,6,4],"logged_out_users":[],"scores":{"15":1,"25":1,"44":1,"50":1,"59":2},"score_average":6.722222222222221,"score_high":9.5,"score_low":2.3333333333333335,"score_stdev":2.7023081126700714,"correct_count_average":5.5,"incorrect_count_average":3.6666666666666665,"duration_average":69.33333333333333,"unique_count":6},"links":{"quiz":"http://localhost:3000/api/v1/courses/1/quizzes/1"}}]}
  quizReportsResponse = {"quiz_reports":[{"id":"14","report_type":"student_analysis","readable_type":"Student Analysis","includes_all_versions":false,"generatable":true,"anonymous":false,"url":"http://localhost:3000/api/v1/courses/1/quizzes/1/reports/14","created_at":"2014-04-29T08:57:36Z","updated_at":"2014-04-29T09:08:55Z","links":{"quiz":"http://localhost:3000/api/v1/courses/1/quizzes/1"},"file":{"id":154,"content-type":"text/csv","display_name":"CNVS-4338 Quiz Student Analysis Report.csv","filename":"quiz_student_analysis_report.csv","url":"http://localhost:3000/files/154/download?download_frd=1&verifier=XDl5emZ8E5KHjrmkcMUArhyLCHEJsi6DxNoLqsd4","size":1093,"created_at":"2014-04-29T09:08:55Z","updated_at":"2014-04-29T09:08:55Z","unlock_at":null,"locked":false,"hidden":false,"lock_at":null,"hidden_for_user":false,"thumbnail_url":null,"locked_for_user":false},"progress":{"completion":100,"context_id":13,"context_type":"Quizzes::QuizStatistics","created_at":"2014-04-02T06:41:47Z","id":143,"message":null,"tag":"Quizzes::QuizStatistics","updated_at":"2014-04-02T06:41:47Z","user_id":null,"workflow_state":"completed","url":"http://localhost:3000/api/v1/progress/143"}},{"id":"13","report_type":"item_analysis","readable_type":"Item Analysis","includes_all_versions":true,"generatable":true,"anonymous":false,"url":"http://localhost:3000/api/v1/courses/1/quizzes/1/reports/13","created_at":"2014-04-29T08:57:36Z","updated_at":"2014-04-29T09:08:25Z","links":{"quiz":"http://localhost:3000/api/v1/courses/1/quizzes/1"}}]}
  emptyQuizStatisticsResponse = {
    "quiz_statistics": [
      {
        "id": "104",
        "url": "http://localhost:3000/api/v1/courses/1/quizzes/3/statistics",
        "html_url": "http://localhost:3000/courses/1/quizzes/3/statistics",
        "multiple_attempts_exist": false,
        "generated_at": "2014-06-05T07:19:35Z",
        "includes_all_versions": false,
        "question_statistics": [],
        "submission_statistics": {
          "user_ids": [],
          "logged_out_users": [],
          "scores": {},
          "score_average": null,
          "score_high": null,
          "score_low": null,
          "score_stdev": null,
          "duration_average": 0,
          "incorrect_count_average": 0,
          "correct_count_average": 0,
          "unique_count": 0
        },
        "links": {
          "quiz": "http://localhost:3000/api/v1/courses/1/quizzes/3"
        }
      }
    ]
  }
  emptyQuizReportsResponse = {
    "quiz_reports": [
      {
        "id": "104",
        "report_type": "student_analysis",
        "readable_type": "Student Analysis",
        "includes_all_versions": false,
        "generatable": true,
        "anonymous": false,
        "url": "http://localhost:3000/api/v1/courses/1/quizzes/3/reports/104",
        "created_at": "2014-06-05T07:19:35Z",
        "updated_at": "2014-06-05T07:19:35Z",
        "links": {
          "quiz": "http://localhost:3000/api/v1/courses/1/quizzes/3"
        }
      },
      {
        "id": "105",
        "report_type": "item_analysis",
        "readable_type": "Item Analysis",
        "includes_all_versions": true,
        "generatable": true,
        "anonymous": false,
        "url": "http://localhost:3000/api/v1/courses/1/quizzes/3/reports/105",
        "created_at": "2014-06-05T07:19:35Z",
        "updated_at": "2014-06-05T07:19:35Z",
        "links": {
          "quiz": "http://localhost:3000/api/v1/courses/1/quizzes/3"
        }
      }
    ]
  }

  {
    QUIZ_INDEX_RESPONSE: _.cloneDeep quizIndexResponse
    QUIZ_SHOW_STUDENT_RESPONSE: _.cloneDeep quizShowStudentResponse
    QUIZZES: quizIndexResponse.quizzes
    ASSIGNMENT_GROUP: assignmentGroup
    QUIZ_STATISTICS: quizStatisticsResponse.quiz_statistics
    QUIZ_REPORTS: quizReportsResponse.quiz_reports

    create: ->
      # TODO: This slows the tests down. We need to figure out a good way of
      # making this immutable
      ajax.defineFixture '/api/v1/courses/1/quizzes',
        response: JSON.parse(JSON.stringify quizIndexResponse),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/assignment_groups/1',
        response: JSON.parse(JSON.stringify assignmentGroup),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1',
        response: JSON.parse(JSON.stringify quizIndexResponse),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/2',
        response: JSON.parse(JSON.stringify quizShowStudentResponse),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/3',
        response: JSON.parse(JSON.stringify quizEmptyStatisticsResponse),
        jqXHR: {}
        testStatus: '200'

      ajax.defineFixture '/courses/1/quizzes/1/submission_html',
        response: 'submission html!'
        textStatus: '200'
        textStatus: 'success'

      ajax.defineFixture '/courses/1/quizzes/2/submission_html',
        response: 'submission html!'
        textStatus: '200'
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/statistics',
        response: JSON.parse(JSON.stringify quizStatisticsResponse),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/reports',
        response: JSON.parse(JSON.stringify quizReportsResponse),

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/statistics?include=quiz_questions',
        response: JSON.parse(JSON.stringify(quizStatisticsResponse)),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/reports?includes_all_versions=true',
        response: JSON.parse(JSON.stringify(quizReportsResponse)),
        jqXHR: {}
        testStatus: '200'

      ajax.defineFixture '/api/v1/courses/1/quizzes/3/statistics',
        response: JSON.parse(JSON.stringify(emptyQuizStatisticsResponse)),
        jqXHR: {}
        testStatus: '200'

      ajax.defineFixture '/api/v1/courses/1/quizzes/3/reports',
        response: JSON.parse(JSON.stringify(emptyQuizReportsResponse)),
        jqXHR: {}
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/assignment_overrides/1',
        response:
          id: "1"
          title: "My Section"
          due_at: new Date()
          lock_at: new Date()
        textStatus: 'success'
        jqXHR: {}

      ajax.defineFixture '/api/v1/courses/1/quizzez/1/submission_users?include[]=quiz_submissions',
        response: submissionUsers
        textStatus: 'success'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/submission_users?submitted=true',

        response:
          users: [
            {
              id: '1'
              name: 'roxette'
              short_name: 'roxette'
              sortable_name: 'roxette'
            }
          ]
        textStatus: 'success'
        jqXHR: {}
  }

