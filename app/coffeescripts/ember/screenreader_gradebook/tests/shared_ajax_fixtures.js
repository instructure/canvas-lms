//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import ajax from 'ic-ajax'
import Ember from 'ember'

const clone = obj => Ember.copy(obj, true)

const default_grade_response = [
  {
    submission: {
      assignment_id: '1',
      attachment_id: null,
      attachment_ids: null,
      attempt: null,
      body: null,
      cached_due_date: '2013-12-19T06:59:59Z',
      context_code: 'course_2',
      created_at: '2013-12-12T22:57:34Z',
      grade: '100',
      grade_matches_current_submission: true,
      graded_at: '2013-12-16T21:25:44Z',
      grader_id: '1',
      group_id: null,
      has_admin_comment: false,
      has_rubric_assessment: null,
      id: '34291',
      media_comment_id: null,
      media_comment_type: null,
      media_object_id: null,
      process_attempts: 0,
      processed: null,
      published_grade: '150',
      published_score: 100.0,
      quiz_submission_id: null,
      score: 100.0,
      student_entered_score: null,
      submission_comments_count: null,
      submission_type: null,
      submitted_at: null,
      turnitin_data: null,
      updated_at: '2013-12-16T21:25:45Z',
      url: null,
      user_id: '1',
      workflow_state: 'graded',
      submission_history: [
        {
          submission: {
            assignment_id: 1,
            attachment_id: null,
            attachment_ids: null,
            attempt: null,
            body: null,
            cached_due_date: '2013-12-19T06:59:59Z',
            context_code: 'course_2',
            created_at: '2013-12-12T22:57:34Z',
            grade: '100',
            grade_matches_current_submission: true,
            graded_at: '2013-12-16T21:25:44Z',
            grader_id: 1,
            group_id: null,
            has_admin_comment: false,
            has_rubric_assessment: null,
            id: 34291,
            media_comment_id: null,
            media_comment_type: null,
            media_object_id: null,
            process_attempts: 0,
            processed: null,
            published_grade: '150',
            published_score: 100.0,
            quiz_submission_id: null,
            score: 100.0,
            student_entered_score: null,
            submission_comments_count: null,
            submission_type: null,
            submitted_at: null,
            turnitin_data: null,
            updated_at: '2013-12-16T21:25:45Z',
            url: null,
            user_id: 1,
            workflow_state: 'graded',
            versioned_attachments: []
          }
        }
      ],
      submission_comments: [],
      attachments: []
    }
  },
  {
    submission: {
      assignment_id: '1',
      attachment_id: null,
      attachment_ids: null,
      attempt: null,
      body: null,
      cached_due_date: '2013-12-19T06:59:59Z',
      context_code: 'course_1',
      created_at: '2013-12-12T22:57:35Z',
      grade: '100',
      grade_matches_current_submission: true,
      graded_at: '2013-12-16T21:25:47Z',
      grader_id: '1',
      group_id: null,
      has_admin_comment: false,
      has_rubric_assessment: null,
      id: '34292',
      media_comment_id: null,
      media_comment_type: null,
      media_object_id: null,
      process_attempts: 0,
      processed: null,
      published_grade: '100',
      published_score: 100.0,
      quiz_submission_id: null,
      score: 100.0,
      student_entered_score: null,
      submission_comments_count: null,
      submission_type: null,
      submitted_at: null,
      turnitin_data: null,
      updated_at: '2013-12-16T21:25:47Z',
      url: null,
      user_id: '2',
      workflow_state: 'graded',
      submission_history: [
        {
          submission: {
            assignment_id: 1,
            attachment_id: null,
            attachment_ids: null,
            attempt: null,
            body: null,
            cached_due_date: '2013-12-19T06:59:59Z',
            context_code: 'course_2',
            created_at: '2013-12-12T22:57:35Z',
            grade: '100',
            grade_matches_current_submission: true,
            graded_at: '2013-12-16T21:25:47Z',
            grader_id: 1,
            group_id: null,
            has_admin_comment: false,
            has_rubric_assessment: null,
            id: 34292,
            media_comment_id: null,
            media_comment_type: null,
            media_object_id: null,
            process_attempts: 0,
            processed: null,
            published_grade: '100',
            published_score: 100.0,
            quiz_submission_id: null,
            score: 100.0,
            student_entered_score: null,
            submission_comments_count: null,
            submission_type: null,
            submitted_at: null,
            turnitin_data: null,
            updated_at: '2013-12-16T21:25:47Z',
            url: null,
            user_id: 2,
            workflow_state: 'graded',
            versioned_attachments: []
          }
        }
      ],
      submission_comments: [],
      attachments: []
    }
  },
  {
    submission: {
      assignment_id: '1',
      attachment_id: null,
      attachment_ids: null,
      attempt: null,
      body: null,
      cached_due_date: '2013-12-19T06:59:59Z',
      context_code: 'course_2',
      created_at: '2013-12-12T22:57:34Z',
      grade: '100',
      grade_matches_current_submission: true,
      graded_at: '2013-12-16T21:25:44Z',
      grader_id: '1',
      group_id: null,
      has_admin_comment: false,
      has_rubric_assessment: null,
      id: '34291',
      media_comment_id: null,
      media_comment_type: null,
      media_object_id: null,
      process_attempts: 0,
      processed: null,
      published_grade: '150',
      published_score: 100.0,
      quiz_submission_id: null,
      score: 100.0,
      student_entered_score: null,
      submission_comments_count: null,
      submission_type: null,
      submitted_at: null,
      turnitin_data: null,
      updated_at: '2013-12-16T21:25:45Z',
      url: null,
      user_id: '3',
      workflow_state: 'graded',
      submission_history: [
        {
          submission: {
            assignment_id: 1,
            attachment_id: null,
            attachment_ids: null,
            attempt: null,
            body: null,
            cached_due_date: '2013-12-19T06:59:59Z',
            context_code: 'course_2',
            created_at: '2013-12-12T22:57:34Z',
            grade: '100',
            grade_matches_current_submission: true,
            graded_at: '2013-12-16T21:25:44Z',
            grader_id: 1,
            group_id: null,
            has_admin_comment: false,
            has_rubric_assessment: null,
            id: 34291,
            media_comment_id: null,
            media_comment_type: null,
            media_object_id: null,
            process_attempts: 0,
            processed: null,
            published_grade: '150',
            published_score: 100.0,
            quiz_submission_id: null,
            score: 100.0,
            student_entered_score: null,
            submission_comments_count: null,
            submission_type: null,
            submitted_at: null,
            turnitin_data: null,
            updated_at: '2013-12-16T21:25:45Z',
            url: null,
            user_id: 3,
            workflow_state: 'graded',
            versioned_attachments: []
          }
        }
      ],
      submission_comments: [],
      attachments: []
    }
  }
]

const students = [
  {
    user_id: '1',
    user: {id: '1', name: 'Bob', group_ids: [], sections: []},
    course_section_id: '1'
  },
  {
    user_id: '2',
    user: {id: '2', name: 'Fred', group_ids: [], sections: []},
    course_section_id: '1'
  },
  {
    user_id: '3',
    user: {id: '3', name: 'Suzy', group_ids: [], sections: []},
    course_section_id: '1'
  },
  {
    user_id: '4',
    user: {id: '4', name: 'Buffy', group_ids: [], sections: []},
    course_section_id: '2'
  },
  {
    user_id: '5',
    user: {id: '5', name: 'Willow', group_ids: [], sections: []},
    course_section_id: '2'
  },
  {
    user_id: '5',
    user: {id: '5', name: 'Willow', group_ids: [], sections: []},
    course_section_id: '1'
  },
  {
    user_id: '6',
    user: {id: '6', name: 'Giles', group_ids: [], sections: []},
    course_section_id: '2'
  },
  {
    user_id: '7',
    user: {id: '7', name: 'Xander', group_ids: [], sections: []},
    course_section_id: '2'
  },
  {
    user_id: '8',
    user: {id: '8', name: 'Cordelia', group_ids: [], sections: []},
    course_section_id: '2'
  },
  {
    user_id: '9',
    user: {id: '9', name: 'Drusilla', group_ids: [], sections: []},
    course_section_id: '1'
  },
  {
    user_id: '10',
    user: {id: '10', name: 'Spike', group_ids: [], sections: []},
    course_section_id: '2'
  },
  {
    user_id: '10',
    user: {id: '10', name: 'Spike', group_ids: [], sections: []},
    course_section_id: '1'
  }
]

const concludedStudents = [
  {
    user: {id: '105', name: 'Lyra', group_ids: [], sections: []},
    course_section_id: '1',
    user_id: '105',
    workflow_state: 'completed',
    completed_at: '2013-10-01T10:00:00Z'
  }
]

const assignmentGroups = [
  {
    id: '1',
    name: 'AG1',
    position: 1,
    group_weight: 0,
    assignments: [
      {
        id: '1',
        name: 'Z Eats Soup',
        points_possible: 100,
        grading_type: 'points',
        submission_types: ['none'],
        due_at: '2013-10-01T10:00:00Z',
        position: 1,
        assignment_group_id: '1',
        published: true,
        muted: false,
        only_visible_to_overrides: true,
        assignment_visibility: ['1']
      },
      {
        id: '2',
        name: 'Drink Water',
        grading_type: 'points',
        points_possible: null,
        due_at: null,
        position: 10,
        submission_types: ['online_url', 'online_text_entry'],
        assignment_group_id: '1',
        published: true,
        muted: true,
        only_visible_to_overrides: true,
        assignment_visibility: ['2']
      },
      {
        id: '3',
        name: 'Apples are good',
        points_possible: 1000,
        grading_type: 'points',
        submission_types: ['none'],
        due_at: '2013-12-01T10:00:00Z',
        position: 12,
        assignment_group_id: '1',
        published: true,
        muted: false,
        assignment_visibility: ['1', '2', '3']
      }
    ]
  },
  {
    id: '2',
    name: 'AG2',
    position: 10,
    group_weight: 0,
    assignments: [
      {
        id: '4',
        name: 'Big Bowl of Nachos',
        points_possible: 20,
        grading_type: 'percent',
        submission_types: ['none'],
        due_at: null,
        position: 5,
        assignment_group_id: '2',
        published: true,
        muted: false
      },
      {
        id: '5',
        name: 'Can You Eat Just One?',
        points_possible: 40,
        grading_type: 'percent',
        submission_types: ['none'],
        due_at: '2013-08-01T10:00:00Z',
        position: 6,
        assignment_group_id: '2',
        published: true,
        muted: true
      },
      {
        id: '6',
        name: 'Da Fish and Chips!',
        points_possible: 40,
        grading_type: 'pass_fail',
        submission_types: ['none'],
        due_at: '2013-09-01T10:00:00Z',
        position: 9,
        assignment_group_id: '2'
      }
    ]
  },
  {
    id: '4',
    name: 'Silent Assignments',
    position: 2,
    group_weight: 0,
    assignments: [
      {
        id: '20',
        name: 'Published Assignment',
        points_possible: 10,
        grading_type: 'percent',
        submission_types: ['none'],
        due_at: '2013-09-01T10:00:00Z',
        position: 5,
        assignment_group_id: '4',
        published: true
      },
      {
        id: '22',
        name: 'Not Graded',
        points_possible: 10,
        grading_type: 'percent',
        submission_types: ['not_graded'],
        due_at: '2013-09-01T10:00:00Z',
        position: 1,
        assignment_group_id: '4',
        published: true
      }
    ]
  },
  {
    id: '5',
    name: 'Invalid AG',
    position: 3,
    group_weight: 0,
    assignments: [
      {
        id: '24',
        name: 'No Points Assignment',
        points_possible: 0,
        grading_type: 'percent',
        submission_types: ['not_graded'],
        due_at: '2013-09-01T10:00:00Z',
        position: 1,
        assignment_group_id: '4',
        published: true
      }
    ]
  },
  {
    id: '6',
    name: 'moderated grading',
    position: 4,
    group_weight: 0,
    assignments: [
      {
        id: '25',
        name: 'muted, moderated, grades not published',
        points_possible: 10,
        grading_type: 'percent',
        submission_types: ['not_graded'],
        due_at: '2013-09-01T10:00:00Z',
        position: 1,
        assignment_group_id: '4',
        muted: true,
        moderated_grading: true,
        grades_published: false,
        published: true
      },
      {
        id: '26',
        name: 'not muted, moderated, grades not published',
        points_possible: 10,
        grading_type: 'percent',
        submission_types: ['not_graded'],
        due_at: '2013-09-01T10:00:00Z',
        position: 1,
        assignment_group_id: '4',
        muted: false,
        moderated_grading: true,
        grades_published: false,
        published: true
      },
      {
        id: '27',
        name: 'muted, not moderated, grades not published',
        points_possible: 10,
        grading_type: 'percent',
        submission_types: ['not_graded'],
        due_at: '2013-09-01T10:00:00Z',
        position: 1,
        assignment_group_id: '4',
        muted: true,
        moderated_grading: false,
        grades_published: false,
        published: true
      },
      {
        id: '28',
        name: 'muted, moderated, grades published',
        points_possible: 10,
        grading_type: 'percent',
        submission_types: ['not_graded'],
        due_at: '2013-09-01T10:00:00Z',
        position: 1,
        assignment_group_id: '4',
        muted: true,
        moderated_grading: true,
        grades_published: true,
        published: true
      }
    ]
  }
]

const submissions = [
  {
    user_id: '1',
    submissions: [
      {id: '1', user_id: '1', assignment_id: '1', grade: '3', score: '3'},
      {id: '2', user_id: '1', assignment_id: '2', grade: null, score: null},
      {
        id: '5',
        user_id: '1',
        assignment_id: '6',
        grade: 'incomplete',
        score: 'incomplete',
        entered_grade: 'incomplete',
        entered_score: 'incomplete'
      }
    ]
  },
  {
    user_id: '2',
    submissions: [
      {id: '3', user_id: '2', assignment_id: '1', grade: '9', score: '9'},
      {id: '4', user_id: '2', assignment_id: '2', grade: null, score: null}
    ]
  },
  {
    user_id: '3',
    submissions: [
      {id: '5', user_id: '3', assignment_id: '1', grade: '10', score: '10'},
      {id: '6', user_id: '3', assignment_id: '2', grade: null, score: null}
    ]
  },
  {
    user_id: '4',
    submissions: []
  },
  {
    user_id: '5',
    submissions: []
  },
  {
    user_id: '6',
    submissions: []
  },
  {
    user_id: '7',
    submissions: []
  },
  {
    user_id: '8',
    submissions: []
  },
  {
    user_id: '9',
    submissions: []
  },
  {
    user_id: '10',
    submissions: []
  }
]

const sections = [{id: '1', name: 'Vampires and Demons'}, {id: '2', name: 'Slayers and Scoobies'}]

const customColumns = [
  {
    hidden: false,
    id: '1',
    position: 1,
    teacher_notes: true,
    title: 'Notes'
  }
]

const outcomesRaw = [
  {outcome: {id: '1', title: 'Eating', mastery_points: 3}},
  {outcome: {id: '2', title: 'Drinking', mastery_points: 5}}
]

const outcomes = [
  {id: '1', title: 'Eating', mastery_points: 3},
  {id: '2', title: 'Drinking', mastery_points: 5}
]

const outcomeRollupsRaw = {
  rollups: [
    {
      links: {user: '1'},
      scores: [{links: {outcome: '1'}, score: 5}, {links: {outcome: '2'}, score: 4}]
    },
    {
      links: {user: '2'},
      scores: [{links: {outcome: '2'}, score: 3}]
    }
  ]
}

const outcomeRollups = [
  {outcome_id: '1', user_id: '1', score: 5},
  {outcome_id: '2', user_id: '1', score: 4},
  {outcome_id: '2', user_id: '2', score: 3}
]

export default {
  custom_columns: customColumns,
  set_default_grade_response: default_grade_response,
  students,
  concluded_enrollments: concludedStudents,
  assignment_groups: assignmentGroups,
  submissions,
  sections,
  outcomes,
  outcome_rollups: outcomeRollups,
  create(overrides) {
    window.ENV = {
      current_user_id: 1,
      context_asset_string: 'course_1',
      GRADEBOOK_OPTIONS: {
        effective_due_dates_url: '/api/v1/courses/1/effective_due_dates',
        enrollments_url: '/api/v1/enrollments',
        enrollments_with_concluded_url: '/api/v1/concluded_enrollments',
        assignment_groups_url: '/api/v1/assignment_groups',
        submissions_url: '/api/v1/submissions',
        sections_url: '/api/v1/sections',
        context_url: '/courses/1',
        context_id: 1,
        group_weighting_scheme: 'equal',
        change_grade_url: '/api/v1/courses/1/assignments/:assignment/submissions/:submission',
        custom_columns_url: 'api/v1/courses/1/custom_gradebook_columns',
        custom_column_data_url: 'api/v1/courses/1/custom_gradebook_columns/:id',
        setting_update_url: 'api/v1/courses/1/settings',
        outcome_gradebook_enabled: true,
        outcome_links_url: 'api/v1/courses/1/outcome_group_links',
        outcome_rollups_url: 'api/v1/courses/1/outcome_rollups',
        active_grading_periods: [
          {
            id: '1',
            title: 'Fall Period 1',
            start_date: '2013-08-01T00:00:00Z',
            end_date: '2013-09-01T00:00:00Z',
            close_date: '2013-09-08T00:00:00Z',
            is_closed: true
          },
          {
            id: '2',
            title: 'Fall Period 2',
            start_date: '2013-09-01T00:00:00Z',
            end_date: '2013-11-01T00:00:00Z',
            close_date: '2013-11-08T00:00:00Z',
            is_closed: true
          },
          {
            id: '3',
            title: 'Fall Period 3',
            start_date: '2013-11-01T00:00:00Z',
            end_date: '2014-01-01T00:00:00Z',
            close_date: '2014-01-08T00:00:00Z',
            is_closed: false
          }
        ]
      }
    }

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.enrollments_url, {
      response: clone(students),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.enrollments_with_concluded_url, {
      response: clone(concludedStudents),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.assignment_groups_url, {
      response: clone(assignmentGroups),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.submissions_url, {
      response: clone(submissions),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.sections_url, {
      response: clone(sections),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.custom_columns_url, {
      response: clone(customColumns),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    // the qUnit specs were sending a request for this that was 404'ing so I just
    // added this so it wouldn't
    ajax.defineFixture(`${window.ENV.GRADEBOOK_OPTIONS.custom_columns_url}/1`, {
      response: {},
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.setting_update_url, {
      response: true,
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.outcome_links_url, {
      response: clone(outcomesRaw),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })

    return ajax.defineFixture(window.ENV.GRADEBOOK_OPTIONS.outcome_rollups_url, {
      response: clone(outcomeRollupsRaw),
      jqXHR: {
        getResponseHeader() {
          return {}
        }
      },
      textStatus: 'success'
    })
  }
}
