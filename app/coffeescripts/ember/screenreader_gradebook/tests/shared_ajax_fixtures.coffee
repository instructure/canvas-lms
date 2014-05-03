define [
  'ic-ajax'
  'ember'
], (ajax, Ember) ->

  clone = (obj) ->
    Em.copy obj, true

  default_grade_response = [{
    "submission": {
        "assignment_id": "1",
        "attachment_id": null,
        "attachment_ids": null,
        "attempt": null,
        "body": null,
        "cached_due_date": "2013-12-19T06:59:59Z",
        "context_code": "course_2",
        "created_at": "2013-12-12T22:57:34Z",
        "grade": "100",
        "grade_matches_current_submission": true,
        "graded_at": "2013-12-16T21:25:44Z",
        "grader_id": "1",
        "group_id": null,
        "has_admin_comment": false,
        "has_rubric_assessment": null,
        "id": "34291",
        "media_comment_id": null,
        "media_comment_type": null,
        "media_object_id": null,
        "process_attempts": 0,
        "processed": null,
        "published_grade": "150",
        "published_score": 100.0,
        "quiz_submission_id": null,
        "score": 100.0,
        "student_entered_score": null,
        "submission_comments_count": null,
        "submission_type": null,
        "submitted_at": null,
        "turnitin_data": null,
        "updated_at": "2013-12-16T21:25:45Z",
        "url": null,
        "user_id": "1",
        "workflow_state": "graded",
        "submission_history": [{
            "submission": {
                "assignment_id": 1,
                "attachment_id": null,
                "attachment_ids": null,
                "attempt": null,
                "body": null,
                "cached_due_date": "2013-12-19T06:59:59Z",
                "context_code": "course_2",
                "created_at": "2013-12-12T22:57:34Z",
                "grade": "100",
                "grade_matches_current_submission": true,
                "graded_at": "2013-12-16T21:25:44Z",
                "grader_id": 1,
                "group_id": null,
                "has_admin_comment": false,
                "has_rubric_assessment": null,
                "id": 34291,
                "media_comment_id": null,
                "media_comment_type": null,
                "media_object_id": null,
                "process_attempts": 0,
                "processed": null,
                "published_grade": "150",
                "published_score": 100.0,
                "quiz_submission_id": null,
                "score": 100.0,
                "student_entered_score": null,
                "submission_comments_count": null,
                "submission_type": null,
                "submitted_at": null,
                "turnitin_data": null,
                "updated_at": "2013-12-16T21:25:45Z",
                "url": null,
                "user_id": 1,
                "workflow_state": "graded",
                "versioned_attachments": []
            }
        }],
        "submission_comments": [],
        "attachments": []
    }
  },
  {
    "submission": {
        "assignment_id": "1",
        "attachment_id": null,
        "attachment_ids": null,
        "attempt": null,
        "body": null,
        "cached_due_date": "2013-12-19T06:59:59Z",
        "context_code": "course_1",
        "created_at": "2013-12-12T22:57:35Z",
        "grade": "100",
        "grade_matches_current_submission": true,
        "graded_at": "2013-12-16T21:25:47Z",
        "grader_id": "1",
        "group_id": null,
        "has_admin_comment": false,
        "has_rubric_assessment": null,
        "id": "34292",
        "media_comment_id": null,
        "media_comment_type": null,
        "media_object_id": null,
        "process_attempts": 0,
        "processed": null,
        "published_grade": "100",
        "published_score": 100.0,
        "quiz_submission_id": null,
        "score": 100.0,
        "student_entered_score": null,
        "submission_comments_count": null,
        "submission_type": null,
        "submitted_at": null,
        "turnitin_data": null,
        "updated_at": "2013-12-16T21:25:47Z",
        "url": null,
        "user_id": "2",
        "workflow_state": "graded",
        "submission_history": [{
            "submission": {
                "assignment_id": 1,
                "attachment_id": null,
                "attachment_ids": null,
                "attempt": null,
                "body": null,
                "cached_due_date": "2013-12-19T06:59:59Z",
                "context_code": "course_2",
                "created_at": "2013-12-12T22:57:35Z",
                "grade": "100",
                "grade_matches_current_submission": true,
                "graded_at": "2013-12-16T21:25:47Z",
                "grader_id": 1,
                "group_id": null,
                "has_admin_comment": false,
                "has_rubric_assessment": null,
                "id": 34292,
                "media_comment_id": null,
                "media_comment_type": null,
                "media_object_id": null,
                "process_attempts": 0,
                "processed": null,
                "published_grade": "100",
                "published_score": 100.0,
                "quiz_submission_id": null,
                "score": 100.0,
                "student_entered_score": null,
                "submission_comments_count": null,
                "submission_type": null,
                "submitted_at": null,
                "turnitin_data": null,
                "updated_at": "2013-12-16T21:25:47Z",
                "url": null,
                "user_id": 2,
                "workflow_state": "graded",
                "versioned_attachments": []
            }
        }],
        "submission_comments": [],
        "attachments": []
      }
  },
  {
    "submission": {
        "assignment_id": "1",
        "attachment_id": null,
        "attachment_ids": null,
        "attempt": null,
        "body": null,
        "cached_due_date": "2013-12-19T06:59:59Z",
        "context_code": "course_2",
        "created_at": "2013-12-12T22:57:34Z",
        "grade": "100",
        "grade_matches_current_submission": true,
        "graded_at": "2013-12-16T21:25:44Z",
        "grader_id": "1",
        "group_id": null,
        "has_admin_comment": false,
        "has_rubric_assessment": null,
        "id": "34291",
        "media_comment_id": null,
        "media_comment_type": null,
        "media_object_id": null,
        "process_attempts": 0,
        "processed": null,
        "published_grade": "150",
        "published_score": 100.0,
        "quiz_submission_id": null,
        "score": 100.0,
        "student_entered_score": null,
        "submission_comments_count": null,
        "submission_type": null,
        "submitted_at": null,
        "turnitin_data": null,
        "updated_at": "2013-12-16T21:25:45Z",
        "url": null,
        "user_id": "3",
        "workflow_state": "graded",
        "submission_history": [{
            "submission": {
                "assignment_id": 1,
                "attachment_id": null,
                "attachment_ids": null,
                "attempt": null,
                "body": null,
                "cached_due_date": "2013-12-19T06:59:59Z",
                "context_code": "course_2",
                "created_at": "2013-12-12T22:57:34Z",
                "grade": "100",
                "grade_matches_current_submission": true,
                "graded_at": "2013-12-16T21:25:44Z",
                "grader_id": 1,
                "group_id": null,
                "has_admin_comment": false,
                "has_rubric_assessment": null,
                "id": 34291,
                "media_comment_id": null,
                "media_comment_type": null,
                "media_object_id": null,
                "process_attempts": 0,
                "processed": null,
                "published_grade": "150",
                "published_score": 100.0,
                "quiz_submission_id": null,
                "score": 100.0,
                "student_entered_score": null,
                "submission_comments_count": null,
                "submission_type": null,
                "submitted_at": null,
                "turnitin_data": null,
                "updated_at": "2013-12-16T21:25:45Z",
                "url": null,
                "user_id": 3,
                "workflow_state": "graded",
                "versioned_attachments": []
            }
        }],
        "submission_comments": [],
        "attachments": []
    }
  }]

  students = [
        {
          user_id: '1'
          user: { id: '1', name: 'Bob' }
          course_section_id: '1'
        }
        {
          user_id: '2'
          user: { id: '2', name: 'Fred' }
          course_section_id: '1'
        }
        {
          user_id: '3'
          user: { id: '3', name: 'Suzy' }
          course_section_id: '1'
        }
        {
          user_id: '4'
          user: { id: '4', name: 'Buffy' }
          course_section_id: '2'
        }
        {
          user_id: '5'
          user: { id: '5', name: 'Willow' }
          course_section_id: '2'
        }
        {
          user_id: '5'
          user: { id: '5', name: 'Willow' }
          course_section_id: '1'
        }
        {
          user_id: '6'
          user: { id: '6', name: 'Giles' }
          course_section_id: '2'
        }
        {
          user_id: '7'
          user: { id: '7', name: 'Xander' }
          course_section_id: '2'
        }
        {
          user_id: '8'
          user: { id: '8', name: 'Cordelia' }
          course_section_id: '2'
        }
        {
          user_id: '9'
          user: { id: '9', name: 'Drusilla' }
          course_section_id: '1'
        }
        {
          user_id: '10'
          user: { id: '10', name: 'Spike' }
          course_section_id: '2'
        }
        {
          user_id: '10'
          user: { id: '10', name: 'Spike' }
          course_section_id: '1'
        }
      ]

  concludedStudents = [
        {
          user: { id: '105', name: 'Lyra' }
          course_section_id: '1'
          user_id: '105'
          workflow_state: 'completed'
          completed_at: "2013-10-01T10:00:00Z"
        }
      ]

  assignmentGroups = [
        {
          id: '1'
          name: 'AG1'
          position: 1
          group_weight: 0
          assignments: [
            {
              id: '1'
              name: 'Z Eats Soup'
              points_possible: 100
              grading_type: "points"
              submission_types: ["none"]
              due_at: "2013-10-01T10:00:00Z"
              position: 1
              assignment_group_id:'1'
              published: true
              muted: false
            }
            {
              id: '2'
              name: 'Drink Water'
              grading_type: "points"
              points_possible: null
              due_at: null
              position: 10
              submission_types: ["online_url", "online_text_entry"]
              assignment_group_id:'1'
              published: true
              muted: true
            }
            {
              id: '3'
              name: 'Apples are good'
              points_possible: 1000
              grading_type: "points"
              submission_types: ["none"]
              due_at: "2013-12-01T10:00:00Z"
              position: 12
              assignment_group_id:'1'
              published: true
              muted: false
            }
          ]
        }
        {
          id: '2'
          name: 'AG2'
          position: 10
          group_weight: 0
          assignments: [
            {
              id: '4'
              name: 'Big Bowl of Nachos'
              points_possible: 20
              grading_type: "percent"
              submission_types: ["none"]
              due_at: null
              position: 5
              assignment_group_id:'2'
              published: true
              muted: false
            }
            {
              id: '5'
              name: 'Can You Eat Just One?'
              points_possible: 40
              grading_type: "percent"
              submission_types: ["none"]
              due_at: "2013-08-01T10:00:00Z"
              position: 6
              assignment_group_id:'2'
              published: true
              muted: true
            }
            {
              id: '6'
              name: 'Da Fish and Chips!'
              points_possible: 40
              grading_type: "pass_fail"
              submission_types: ["none"]
              due_at: "2013-09-01T10:00:00Z"
              position: 9
              assignment_group_id:'2'
            }
          ]
        }
        {
          id: '4'
          name: 'Silent Assignments'
          position: 2
          group_weight: 0
          assignments: [
            {
              id: '20'
              name: 'Published Assignment'
              points_possible: 10
              grading_type: "percent"
              submission_types: ["none"]
              due_at: "2013-09-01T10:00:00Z"
              position: 5
              assignment_group_id:'4'
              published: true
            }
            {
              id: '22'
              name: 'Not Graded'
              points_possible: 10
              grading_type: "percent"
              submission_types: ["not_graded"]
              due_at: "2013-09-01T10:00:00Z"
              position: 1
              assignment_group_id:'4'
              published: true
            }
          ]
        }
        {
          id: '5'
          name: 'Invalid AG'
          position: 3
          group_weight: 0
          assignments: [
            {
              id: '24'
              name: 'No Points Assignment'
              points_possible: 0
              grading_type: "percent"
              submission_types: ["not_graded"]
              due_at: "2013-09-01T10:00:00Z"
              position: 1
              assignment_group_id:'4'
              published: true
            }
          ]
        }
      ]

  submissions = [
        {
          user_id: '1'
          submissions: [
            { id: '1', user_id: '1', assignment_id: '1', grade: '3', score: '3' }
            { id: '2', user_id: '1', assignment_id: '2', grade: null, score: null  }
            { id: '5', user_id: '1', assignment_id: '6', grade: 'incomplete', score: 'incomplete' }
          ]
        }
        {
          user_id: '2'
          submissions: [
            { id: '3', user_id: '2', assignment_id: '1', grade: '9', score: '9' }
            { id: '4', user_id: '2', assignment_id: '2', grade: null, score: null }
          ]
        }
        {
          user_id: '3'
          submissions: [
            { id: '5', user_id: '3', assignment_id: '1', grade: '10', score: '10' }
            { id: '6', user_id: '3', assignment_id: '2', grade: null, score: null }
          ]
        }
        {
          user_id: '4'
          submissions: []
        }
        {
          user_id: '5'
          submissions: []
        }
        {
          user_id: '6'
          submissions: []
        }
        {
          user_id: '7'
          submissions: []
        }
        {
          user_id: '8'
          submissions: []
        }
        {
          user_id: '9'
          submissions: []
        }
        {
          user_id: '10'
          submissions: []
        }
      ]

  sections = [
        { id: '1', name: 'Vampires and Demons' }
        { id: '2', name: 'Slayers and Scoobies' }
      ]

  customColumns = [
    hidden: false
    id: "1"
    position: 1
    teacher_notes: true
    title: "Notes"
  ]

  custom_columns: customColumns
  set_default_grade_response: default_grade_response
  students: students
  concluded_enrollments: concludedStudents
  assignment_groups: assignmentGroups
  submissions: submissions
  sections: sections
  create: (overrides) ->

    window.ENV =
      {
        current_user_id: 1
        context_asset_string: 'course_1'
        GRADEBOOK_OPTIONS: {
          students_url: '/api/v1/enrollments'
          students_url_with_concluded_enrollments: '/api/v1/concluded_enrollments'
          assignment_groups_url: '/api/v1/assignment_groups'
          submissions_url: '/api/v1/submissions'
          sections_url: '/api/v1/sections'
          context_url: '/courses/1'
          context_id: 1
          group_weighting_scheme: "equal"
          change_grade_url: '/api/v1/courses/1/assignments/:assignment/submissions/:submission'
          custom_columns_url: 'api/v1/courses/1/custom_gradebook_columns'
          custom_column_data_url: 'api/v1/courses/1/custom_gradebook_columns/:id'
          setting_update_url: 'api/v1/courses/1/settings'
        }
      }

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.students_url,
      response: clone students
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.students_url_with_concluded_enrollments,
      response: clone concludedStudents
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.assignment_groups_url,
      response: clone assignmentGroups
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.submissions_url,
      response: clone submissions
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.sections_url,
      response: clone sections
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.custom_columns_url,
      response: clone customColumns
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

    ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.setting_update_url,
      response: true
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

