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
            "quizStatistics": "/api/v1/courses/1/quizzes/1/statistics"
            "quizReports": "/api/v1/courses/1/quizzes/1/reports"
          "cant_go_back":false,
          "description":"",
          "hide_correct_answers_at":null,
          "hide_results":null,
          "id":1,
          "quiz_submission_html_url": "/courses/1/quizzes/1/submission_html"
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
          "quiz_submission_html_url": "/courses/1/quizzes/2/submission_html"
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

  quizStatisticsResponse = {"quiz_statistics":[{"id":"14","url":"http://localhost:3000/api/v1/courses/1/quizzes/1/statistics","html_url":"http://localhost:3000/courses/1/quizzes/1/statistics","multiple_attempts_exist":true,"generated_at":"2014-04-01T11:48:04Z","includes_all_versions":false,"question_statistics":[{"id":11,"regrade_option":"","points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"multiple_choice_question","question_name":"Question","name":"Question","question_text":"<p>Which?</p>","answers":[{"id":3866,"text":"I am a very long description of an answer that should span multiple lines.","html":"","comments":"","weight":100,"responses":1,"user_ids":[6]},{"id":2040,"text":"b","html":"","comments":"","weight":0,"responses":1,"user_ids":[4]},{"id":7387,"text":"c","html":"","comments":"","weight":0,"responses":0,"user_ids":[]},{"id":4082,"text":"d","html":"","comments":"","weight":0,"responses":0,"user_ids":[]},{"responses":1,"id":"none","weight":0,"text":"No Answer","user_ids":[2]}],"text_after_answers":"","assessment_question_id":13,"position":1,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","2040","3866"],"unexpected_response_values":[],"user_ids":[2,4,6],"answered_student_count":3,"top_student_count":1,"middle_student_count":1,"bottom_student_count":1,"correct_student_count":2,"incorrect_student_count":1,"correct_student_ratio":0.666666666666667,"incorrect_student_ratio":0.333333333333333,"correct_top_student_count":0,"correct_middle_student_count":1,"correct_bottom_student_count":1,"variance":0.222222222222222,"stdev":0.471404520791032,"difficulty_index":0.666666666666667,"alpha":null,"point_biserials":[{"answer_id":3866,"point_biserial":-0.802955068546966,"correct":true,"distractor":false},{"answer_id":2040,"point_biserial":0.802955068546966,"correct":false,"distractor":true},{"answer_id":7387,"point_biserial":null,"correct":false,"distractor":true},{"answer_id":4082,"point_biserial":null,"correct":false,"distractor":true}]},{"id":12,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"multiple_choice_question","question_name":"Question","name":"Question","question_text":"<p>A, B, C, or D?</p>","answers":[{"id":3023,"text":"A","html":"","comments":"","weight":100,"responses":1,"user_ids":[4]},{"id":8899,"text":"B","html":"","comments":"","weight":0,"responses":1,"user_ids":[6]},{"id":7907,"text":"C","html":"","comments":"","weight":0,"responses":0,"user_ids":[]},{"id":5646,"text":"D","html":"","comments":"","weight":0,"responses":0,"user_ids":[]},{"responses":1,"id":"none","weight":0,"text":"No Answer","user_ids":[2]}],"text_after_answers":"","assessment_question_id":14,"position":2,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","3023","8899"],"unexpected_response_values":[],"user_ids":[2,4,6],"answered_student_count":2,"top_student_count":1,"middle_student_count":1,"bottom_student_count":0,"correct_student_count":1,"incorrect_student_count":1,"correct_student_ratio":0.5,"incorrect_student_ratio":0.5,"correct_top_student_count":1,"correct_middle_student_count":0,"correct_bottom_student_count":0,"variance":0.25,"stdev":0.5,"difficulty_index":0.5,"alpha":null,"point_biserials":[{"answer_id":3023,"point_biserial":1,"correct":true,"distractor":false},{"answer_id":8899,"point_biserial":-1,"correct":false,"distractor":true},{"answer_id":7907,"point_biserial":null,"correct":false,"distractor":true},{"answer_id":5646,"point_biserial":null,"correct":false,"distractor":true}]},{"id":13,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"multiple_choice_question","question_name":"Question 2","name":"Question 2","question_text":"<p>D, A, B, or C?</p>","answers":[{"id":3964,"text":"A","html":"","comments":"","weight":0,"responses":1,"user_ids":[6]},{"id":6628,"text":"B","html":"","comments":"","weight":0,"responses":0,"user_ids":[]},{"id":2839,"text":"C","html":"","comments":"","weight":0,"responses":0,"user_ids":[]},{"id":6102,"text":"D","html":"","comments":"","weight":100,"responses":1,"user_ids":[4]},{"responses":1,"id":"none","weight":0,"text":"No Answer","user_ids":[2]}],"text_after_answers":"","assessment_question_id":15,"position":3,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","6102","3964"],"unexpected_response_values":[],"user_ids":[2,4,6],"answered_student_count":2,"top_student_count":1,"middle_student_count":1,"bottom_student_count":0,"correct_student_count":1,"incorrect_student_count":1,"correct_student_ratio":0.5,"incorrect_student_ratio":0.5,"correct_top_student_count":1,"correct_middle_student_count":0,"correct_bottom_student_count":0,"variance":0.25,"stdev":0.5,"difficulty_index":0.5,"alpha":null,"point_biserials":[{"answer_id":6102,"point_biserial":1,"correct":true,"distractor":false},{"answer_id":3964,"point_biserial":-1,"correct":false,"distractor":true},{"answer_id":6628,"point_biserial":null,"correct":false,"distractor":true},{"answer_id":2839,"point_biserial":null,"correct":false,"distractor":true}]},{"id":14,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"true_false_question","question_name":"Question","name":"Question","question_text":"<p>Is is true?</p>","answers":[{"comments":"","text":"True","weight":100,"id":1496,"responses":2,"user_ids":[4,6]},{"comments":"","text":"False","weight":0,"id":5354,"responses":0,"user_ids":[]},{"responses":1,"id":"none","weight":0,"text":"No Answer","user_ids":[2]}],"text_after_answers":"","assessment_question_id":16,"position":4,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","1496","1496"],"unexpected_response_values":[],"user_ids":[2,4,6],"answered_student_count":2,"top_student_count":1,"middle_student_count":1,"bottom_student_count":0,"correct_student_count":2,"incorrect_student_count":0,"correct_student_ratio":1,"incorrect_student_ratio":0,"correct_top_student_count":1,"correct_middle_student_count":1,"correct_bottom_student_count":0,"variance":0,"stdev":0,"difficulty_index":1,"alpha":null,"point_biserials":[{"answer_id":1496,"point_biserial":null,"correct":true,"distractor":false},{"answer_id":5354,"point_biserial":null,"correct":false,"distractor":true}]},{"id":15,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"short_answer_question","question_name":"Question","name":"Question","question_text":"<p>Type something</p>","answers":[{"id":4684,"text":"Something","comments":"","weight":100,"responses":1,"user_ids":[4]},{"id":1797,"text":"False","comments":"","weight":100,"responses":0,"user_ids":[]},{"id":"8b1a9953c4611296a827abf8c47804d7","responses":1,"user_ids":[6],"text":"Hello"},{"responses":1,"id":"none","weight":0,"text":"No Answer","user_ids":[2]}],"text_after_answers":"","assessment_question_id":17,"position":5,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","Something","Hello"],"unexpected_response_values":[],"user_ids":[2,4,6]},{"id":16,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"fill_in_multiple_blanks_question","question_name":"Question","name":"Question","question_text":"<p>Roses are [color1], violets are [color2]</p>","answers":[{"id":"9711","text":"Red","comments":"","weight":100,"blank_id":"color1","responses":0,"user_ids":[]},{"id":"2700","text":"Blue","comments":"","weight":100,"blank_id":"color1","responses":0,"user_ids":[]},{"id":9702,"text":"bonkers","comments":"","weight":100,"blank_id":"color2","responses":0,"user_ids":[]},{"id":7150,"text":"mumbojumbo","comments":"","weight":100,"blank_id":"color2","responses":0,"user_ids":[]},{"responses":3,"id":"none","weight":0,"text":"No Answer","user_ids":[2,4,6]}],"text_after_answers":"","assessment_question_id":18,"position":6,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","",""],"unexpected_response_values":[],"user_ids":[2,4,6],"multiple_responses":true,"answer_sets":[{"id":"color1","text":"color1","blank_id":"color1","answer_matches":[{"responses":1,"text":"Red","user_ids":[4],"id":"color1","correct":true},{"responses":0,"text":"Blue","user_ids":[],"id":"color1","correct":true},{"id":"bda9643ac6601722a28f238714274da4","responses":1,"user_ids":[6],"text":"red"}],"responses":2,"user_ids":[]},{"id":"color2","text":"color2","blank_id":"color2","answer_matches":[{"responses":0,"text":"bonkers","user_ids":[],"id":"color2","correct":true},{"responses":0,"text":"mumbojumbo","user_ids":[],"id":"color2","correct":true},{"id":"6e11873b9d9d94a44058bef5747735ce","responses":1,"user_ids":[4],"text":"gay"},{"id":"48d6215903dff56238e52e8891380c8f","responses":1,"user_ids":[6],"text":"blue"}],"responses":2,"user_ids":[]}]},{"id":17,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"multiple_answers_question","question_name":"Question","name":"Question","question_text":"<p>A and B, or B and C?</p>","answers":[{"id":5514,"text":"A","comments":"","weight":100,"responses":1,"user_ids":[6]},{"id":4261,"text":"B","comments":"","weight":100,"responses":1,"user_ids":[4]},{"id":3322,"text":"C","comments":"","weight":0,"responses":0,"user_ids":[]},{"responses":1,"id":"none","weight":0,"text":"No Answer","user_ids":[2]}],"text_after_answers":"","assessment_question_id":19,"position":7,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","",""],"unexpected_response_values":[],"user_ids":[2,4,6]},{"id":18,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"essay_question","question_name":"Question","name":"Question","question_text":"<p>Summarize your feelings towards life, the universe, and everything in decimal numbers.</p>","answers":[{"responses":3,"id":"none","weight":0,"text":"No Answer","user_ids":[2,4,6]}],"text_after_answers":"","comments":"","assessment_question_id":20,"position":8,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","<p>It hurtses</p>",""],"unexpected_response_values":[],"user_ids":[2,4,6],"essay_responses":[{"user_id":2,"text":""},{"user_id":4,"text":"<p>It hurtses</p>"},{"user_id":6,"text":""}]},{"id":19,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"multiple_dropdowns_question","question_name":"Question","name":"Question","question_text":"<p>Alligators are [color], zombies eat [organ].</p>","answers":[{"id":3208,"text":"brainz","comments":"","weight":100,"blank_id":"organ","responses":0,"user_ids":[]},{"id":8331,"text":"","comments":"","weight":0,"blank_id":"organ","responses":0,"user_ids":[]},{"id":1381,"text":"green","comments":"","weight":100,"blank_id":"color","responses":0,"user_ids":[]},{"id":1638,"text":"cool","comments":"","weight":0,"blank_id":"color","responses":0,"user_ids":[]},{"responses":3,"id":"none","weight":0,"text":"No Answer","user_ids":[2,4,6]}],"text_after_answers":"","assessment_question_id":21,"position":9,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","",""],"unexpected_response_values":[],"user_ids":[2,4,6],"multiple_responses":true,"answer_sets":[{"id":"organ","text":"organ","blank_id":"organ","answer_matches":[{"responses":2,"text":"brainz","user_ids":[4,6],"id":3208,"correct":true},{"responses":0,"text":"","user_ids":[],"id":8331,"correct":false}],"responses":2,"user_ids":[]},{"id":"color","text":"color","blank_id":"color","answer_matches":[{"responses":2,"text":"green","user_ids":[4,6],"id":1381,"correct":true},{"responses":0,"text":"cool","user_ids":[],"id":1638,"correct":false}],"responses":2,"user_ids":[]}]},{"id":20,"regrade_option":"false","points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"matching_question","question_name":"Question","name":"Question","question_text":"","answers":[{"id":8796,"text":"What's for a drink?","left":"What's for a drink?","right":"A coke, please.","comments":"","match_id":1525,"responses":0,"user_ids":[]},{"id":6666,"text":"Where were we?","left":"Where were we?","right":"Right over there.","comments":"","match_id":4393,"responses":0,"user_ids":[]},{"id":6430,"text":"What time is it?","left":"What time is it?","right":"What do you think?","comments":"","match_id":4573,"responses":0,"user_ids":[]},{"responses":3,"id":"none","weight":0,"text":"No Answer","user_ids":[2,4,6]}],"text_after_answers":"","matching_answer_incorrect_matches":"Home.\nJanuary 1st, 1960.","matches":[{"text":"A coke, please.","match_id":1525},{"text":"Home.","match_id":4756},{"text":"January 1st, 1960.","match_id":7160},{"text":"Right over there.","match_id":4393},{"text":"What do you think?","match_id":4573}],"assessment_question_id":22,"position":10,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["","",""],"unexpected_response_values":[],"user_ids":[2,4,6],"multiple_answers":true},{"id":21,"regrade_option":false,"points_possible":1,"correct_comments":"","incorrect_comments":"","neutral_comments":"","question_type":"numerical_question","question_name":"Question","name":"Question","question_text":"<p>What's 9 plus 3, or 4 minus zero?</p>","answers":[{"id":9395,"text":"","comments":"","weight":100,"numerical_answer_type":"exact_answer","exact":0,"margin":0,"responses":0,"user_ids":[]},{"id":1939,"text":"","comments":"","weight":100,"numerical_answer_type":"exact_answer","exact":0,"margin":0,"responses":0,"user_ids":[]},{"id":3009,"text":"","comments":"","weight":100,"numerical_answer_type":"exact_answer","exact":0,"margin":0,"responses":0,"user_ids":[]},{"id":"c827b577971795c6f15c1d310fe99a2e","responses":1,"user_ids":[2],"text":"32.0000"},{"id":"bd76a9670901fc8194146b6350f4bc7d","responses":1,"user_ids":[4],"text":"93.0000"},{"id":"0b76115015158411e664e9466bcd0ec0","responses":1,"user_ids":[6],"text":"4.0000"}],"text_after_answers":"","assessment_question_id":23,"position":11,"published_at":"2014-04-01T11:47:17Z","responses":3,"response_values":["32.0000","93.0000","4.0000"],"unexpected_response_values":[],"user_ids":[2,4,6]}],"submission_statistics":{"user_ids":[2,4,6],"logged_out_users":[],"scores":{"4":1,"6":1,"0.67":1},"score_average":3.55555555555556,"score_high":6,"score_low":0.666666666666667,"score_stdev":2.19988776369148,"correct_count_average":2.66666666666667,"incorrect_count_average":5.66666666666667,"duration_average":39,"unique_count":3},"links":{"quiz":"http://localhost:3000/api/v1/courses/1/quizzes/1"}}]}
  quizReportsResponse = {"quiz_reports":[{"id":"14","report_type":"student_analysis","readable_type":"Student Analysis","includes_all_versions":false,"generatable":true,"anonymous":false,"url":"http://localhost:3000/api/v1/courses/1/quizzes/1/reports/14","created_at":"2014-04-29T08:57:36Z","updated_at":"2014-04-29T09:08:55Z","links":{"quiz":"http://localhost:3000/api/v1/courses/1/quizzes/1"},"file":{"id":154,"content-type":"text/csv","display_name":"CNVS-4338 Quiz Student Analysis Report.csv","filename":"quiz_student_analysis_report.csv","url":"http://localhost:3000/files/154/download?download_frd=1&verifier=XDl5emZ8E5KHjrmkcMUArhyLCHEJsi6DxNoLqsd4","size":1093,"created_at":"2014-04-29T09:08:55Z","updated_at":"2014-04-29T09:08:55Z","unlock_at":null,"locked":false,"hidden":false,"lock_at":null,"hidden_for_user":false,"thumbnail_url":null,"locked_for_user":false},"progress":{"completion":100,"context_id":13,"context_type":"Quizzes::QuizStatistics","created_at":"2014-04-02T06:41:47Z","id":143,"message":null,"tag":"Quizzes::QuizStatistics","updated_at":"2014-04-02T06:41:47Z","user_id":null,"workflow_state":"completed","url":"http://localhost:3000/api/v1/progress/143"}},{"id":"13","report_type":"item_analysis","readable_type":"Item Analysis","includes_all_versions":true,"generatable":true,"anonymous":false,"url":"http://localhost:3000/api/v1/courses/1/quizzes/1/reports/13","created_at":"2014-04-29T08:57:36Z","updated_at":"2014-04-29T09:08:25Z","links":{"quiz":"http://localhost:3000/api/v1/courses/1/quizzes/1"}}]}

  {
    QUIZZES: quizIndexResponse.quizzes
    ASSIGNMENT_GROUP: assignmentGroup
    QUIZ_STATISTICS: quizStatisticsResponse.quiz_statistics
    QUIZ_REPORTS: quizReportsResponse.quiz_reports

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

      ajax.defineFixture '/courses/1/quizzes/1/submission_html',
        response: 'submission html!'
        textStatus: '200'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/statistics',
        response: quizStatisticsResponse,
        jqXHR: {}
        testStatus: '200'

      ajax.defineFixture '/api/v1/courses/1/quizzes/1/reports',
        response: quizReportsResponse,
        jqXHR: {}
        testStatus: '200'
  }

