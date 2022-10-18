/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import sinon from 'sinon'
import {configure, mount, unmount} from '../index'
import {findByTestId} from '@testing-library/dom'

const fixture = {
  '/api/v1/courses/1/quizzes/1/statistics': {
    quiz_statistics: [
      {
        id: '7',
        url: 'http://lvh.me:3000/api/v1/courses/1/quizzes/1/statistics',
        html_url: 'http://lvh.me:3000/courses/1/quizzes/1/statistics',
        multiple_attempts_exist: true,
        generated_at: '2021-01-05T17:21:14Z',
        includes_all_versions: false,
        includes_sis_ids: true,
        points_possible: 9.0,
        anonymous_survey: false,
        speed_grader_url: 'http://lvh.me:3000/courses/1/gradebook/speed_grader?assignment_id=2',
        quiz_submissions_zip_url: 'http://lvh.me:3000/courses/1/quizzes/1/submissions?zip=1',
        question_statistics: [
          {
            id: '1',
            question_type: 'multiple_choice_question',
            question_text: "\u003cp\u003ewhat's the right choice!?\u003c/p\u003e",
            position: 1,
            responses: 2,
            answers: [
              {
                id: '8725',
                text: 'a',
                correct: true,
                responses: 1,
                user_ids: [4],
                user_names: ['Ryu'],
              },
              {
                id: '2033',
                text: 'b',
                correct: false,
                responses: 1,
                user_ids: [2],
                user_names: ['Blanka'],
              },
              {id: '3360', text: 'c', correct: false, responses: 0, user_ids: [], user_names: []},
              {id: '4760', text: 'd', correct: false, responses: 0, user_ids: [], user_names: []},
            ],
            answered_student_count: 2,
            top_student_count: 1,
            middle_student_count: 0,
            bottom_student_count: 1,
            correct_student_count: 2,
            incorrect_student_count: 0,
            correct_student_ratio: 1.0,
            incorrect_student_ratio: 0.0,
            correct_top_student_count: 1,
            correct_middle_student_count: 0,
            correct_bottom_student_count: 1,
            variance: 0.0,
            stdev: 0.0,
            difficulty_index: 1.0,
            alpha: 2.0,
            point_biserials: [
              {answer_id: 8725, point_biserial: null, correct: true, distractor: false},
              {answer_id: 2033, point_biserial: null, correct: false, distractor: true},
              {answer_id: 3360, point_biserial: null, correct: false, distractor: true},
              {answer_id: 4760, point_biserial: null, correct: false, distractor: true},
            ],
          },
          {
            id: '2',
            question_type: 'matching_question',
            question_text: "\u003cp\u003ematch it like there's no tomorrow\u003c/p\u003e",
            position: 2,
            correct: 1,
            partially_correct: 1,
            incorrect: 0,
            responses: 2,
            answered: 2,
            answer_sets: [
              {
                id: '923',
                text: 'a',
                correct: false,
                responses: 0,
                user_ids: [],
                user_names: [],
                answers: [
                  {
                    id: '7669',
                    text: 'f',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '6786',
                    text: 'h',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '8671',
                    text: 'b',
                    correct: true,
                    responses: 2,
                    user_ids: [4, 2],
                    user_names: ['Ryu', 'Blanka'],
                  },
                  {
                    id: '5959',
                    text: 'd',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                ],
              },
              {
                id: '3099',
                text: 'c',
                correct: false,
                responses: 0,
                user_ids: [],
                user_names: [],
                answers: [
                  {
                    id: '7669',
                    text: 'f',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '6786',
                    text: 'h',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '8671',
                    text: 'b',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '5959',
                    text: 'd',
                    correct: true,
                    responses: 2,
                    user_ids: [4, 2],
                    user_names: ['Ryu', 'Blanka'],
                  },
                ],
              },
              {
                id: '8251',
                text: 'e',
                correct: false,
                responses: 0,
                user_ids: [],
                user_names: [],
                answers: [
                  {
                    id: '7669',
                    text: 'f',
                    correct: true,
                    responses: 1,
                    user_ids: [4],
                    user_names: ['Ryu'],
                  },
                  {
                    id: '6786',
                    text: 'h',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '8671',
                    text: 'b',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '5959',
                    text: 'd',
                    correct: false,
                    responses: 1,
                    user_ids: [2],
                    user_names: ['Blanka'],
                  },
                ],
              },
              {
                id: '1310',
                text: 'g',
                correct: false,
                responses: 0,
                user_ids: [],
                user_names: [],
                answers: [
                  {
                    id: '7669',
                    text: 'f',
                    correct: false,
                    responses: 1,
                    user_ids: [2],
                    user_names: ['Blanka'],
                  },
                  {
                    id: '6786',
                    text: 'h',
                    correct: true,
                    responses: 1,
                    user_ids: [4],
                    user_names: ['Ryu'],
                  },
                  {
                    id: '8671',
                    text: 'b',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '5959',
                    text: 'd',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                ],
              },
            ],
          },
          {
            id: '3',
            question_type: 'true_false_question',
            question_text:
              '\u003cp\u003eTo entertain doubt is to dance with death, truth?\u003c/p\u003e',
            position: 3,
            responses: 2,
            answers: [
              {
                id: '1894',
                text: 'True',
                correct: true,
                responses: 2,
                user_ids: [4, 2],
                user_names: ['Ryu', 'Blanka'],
              },
              {
                id: '8359',
                text: 'False',
                correct: false,
                responses: 0,
                user_ids: [],
                user_names: [],
              },
            ],
            answered_student_count: 1,
            top_student_count: 1,
            middle_student_count: 0,
            bottom_student_count: 0,
            correct_student_count: 1,
            incorrect_student_count: 0,
            correct_student_ratio: 1.0,
            incorrect_student_ratio: 0.0,
            correct_top_student_count: 1,
            correct_middle_student_count: 0,
            correct_bottom_student_count: 0,
            variance: 0,
            stdev: 0.0,
            difficulty_index: 1.0,
            alpha: 2.0,
            point_biserials: [
              {answer_id: 1894, point_biserial: null, correct: true, distractor: false},
              {answer_id: 8359, point_biserial: null, correct: false, distractor: true},
            ],
          },
          {
            id: '4',
            question_type: 'short_answer_question',
            question_text:
              '\u003cp\u003e______ the emperor who sits alone on his throne.\u003c/p\u003e',
            position: 4,
            responses: 2,
            answers: [
              {
                id: '8253',
                text: 'Pity',
                correct: true,
                responses: 2,
                user_ids: [4, 2],
                user_names: ['Ryu', 'Blanka'],
              },
              {
                id: '974',
                text: 'Praise',
                correct: true,
                responses: 0,
                user_ids: [],
                user_names: [],
              },
            ],
            correct: 2,
          },
          {
            id: '5',
            question_type: 'fill_in_multiple_blanks_question',
            question_text:
              '\u003cp\u003e\u003cspan\u003eThere is a fine line between [consideration] and [hesitation]. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e',
            position: 5,
            responses: 2,
            answered: 2,
            correct: 0,
            partially_correct: 0,
            incorrect: 2,
            answer_sets: [
              {
                id: '51f7900825222a800b07aad9891e8258',
                text: 'consideration',
                answers: [
                  {
                    id: '9687',
                    text: 'fear',
                    correct: true,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '4251',
                    text: 'intimidation',
                    correct: true,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: 'other',
                    text: 'Other',
                    correct: false,
                    responses: 2,
                    user_ids: [4, 2],
                    user_names: ['Ryu', 'Blanka'],
                  },
                ],
              },
              {
                id: 'ff8066590e11ffb6d7e7df85aa9b026e',
                text: 'hesitation',
                answers: [
                  {
                    id: '5647',
                    text: 'joy',
                    correct: true,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: '7341',
                    text: 'grace',
                    correct: true,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                  {
                    id: 'other',
                    text: 'Other',
                    correct: false,
                    responses: 2,
                    user_ids: [4, 2],
                    user_names: ['Ryu', 'Blanka'],
                  },
                ],
              },
            ],
          },
          {
            id: '6',
            question_type: 'multiple_answers_question',
            question_text:
              '\u003cp\u003e\u003cspan\u003eWisdom is the offspring of:\u003c/span\u003e\u003c/p\u003e',
            position: 6,
            responses: 2,
            correct: 0,
            partially_correct: 0,
            answers: [
              {id: '5601', text: '', correct: true, responses: 0, user_ids: [], user_names: []},
              {id: '2284', text: '', correct: false, responses: 0, user_ids: [], user_names: []},
              {
                id: '6969',
                text: 'Suffering',
                correct: false,
                responses: 2,
                user_ids: [4, 2],
                user_names: ['Ryu', 'Blanka'],
              },
              {
                id: '269',
                text: 'Time',
                correct: false,
                responses: 2,
                user_ids: [4, 2],
                user_names: ['Ryu', 'Blanka'],
              },
              {
                id: '4627',
                text: 'Void',
                correct: false,
                responses: 0,
                user_ids: [],
                user_names: [],
              },
            ],
          },
          {
            id: '7',
            question_type: 'multiple_dropdowns_question',
            question_text:
              '\u003cdiv class="quiz_sortable question_holder" role="region" aria-label="Question" data-group-id=""\u003e\n\u003cdiv id="question_5" class="question display_question fill_in_multiple_blanks_question"\u003e\n\u003cdiv class="text"\u003e\n\u003cdiv id="question_new_question_text" class="question_text user_content enhanced"\u003e\n\u003cp\u003e\u003cspan\u003eThere is a fine line between [consideration] and [hesitation]. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e',
            position: 7,
            responses: 2,
            answered: 2,
            correct: 2,
            partially_correct: 0,
            incorrect: 0,
            answer_sets: [
              {
                id: '51f7900825222a800b07aad9891e8258',
                text: 'consideration',
                answers: [
                  {
                    id: '3236',
                    text: 'suffering',
                    correct: true,
                    responses: 2,
                    user_ids: [4, 2],
                    user_names: ['Ryu', 'Blanka'],
                  },
                  {
                    id: '5757',
                    text: 'joy',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                ],
              },
              {
                id: 'ff8066590e11ffb6d7e7df85aa9b026e',
                text: 'hesitation',
                answers: [
                  {
                    id: '9810',
                    text: 'fear',
                    correct: true,
                    responses: 2,
                    user_ids: [4, 2],
                    user_names: ['Ryu', 'Blanka'],
                  },
                  {
                    id: '1030',
                    text: 'ecstasy',
                    correct: false,
                    responses: 0,
                    user_ids: [],
                    user_names: [],
                  },
                ],
              },
            ],
          },
          {
            id: '8',
            question_type: 'numerical_question',
            question_text: "\u003cp\u003eWhat's the answer?\u003c/p\u003e",
            position: 8,
            responses: 2,
            full_credit: 2,
            correct: 2,
            incorrect: 0,
            answers: [
              {
                id: '4480',
                text: '0.00',
                correct: true,
                responses: 0,
                user_ids: [],
                user_names: [],
                value: [0.0, 0.0],
                margin: 0.0,
                is_range: false,
              },
              {
                id: '1312',
                text: '0.00',
                correct: true,
                responses: 0,
                user_ids: [],
                user_names: [],
                value: [0.0, 0.0],
                margin: 0.0,
                is_range: false,
              },
              {
                id: '8731',
                text: '[0.00..100.00]',
                correct: true,
                responses: 2,
                user_ids: [4, 2],
                user_names: ['Ryu', 'Blanka'],
                value: [0.0, 100.0],
                margin: 0.0,
                is_range: true,
              },
            ],
          },
          {
            id: '9',
            question_type: 'essay_question',
            question_text: '\u003cp\u003eEnlighten us\u003c/p\u003e',
            position: 9,
            responses: 1,
            graded: 0,
            full_credit: 0,
            point_distribution: [{score: 0.0, count: 1}],
            answers: [
              {
                user_ids: [4],
                user_names: ['Ryu'],
                responses: 1,
                id: 'ungraded',
                score: 0.0,
                full_credit: false,
              },
            ],
          },
        ],
        submission_statistics: {
          scores: {67: 1, 50: 1},
          score_average: 5.25,
          score_high: 6.0,
          score_low: 4.5,
          score_stdev: 0.75,
          correct_count_average: 5.0,
          incorrect_count_average: 2.5,
          duration_average: 59.0,
          unique_count: 2,
        },
        links: {quiz: 'http://lvh.me:3000/api/v1/courses/1/quizzes/1'},
      },
    ],
  },
  '/api/v1/courses/1/quizzes/1/reports': {
    quiz_reports: [
      {
        id: '9',
        report_type: 'student_analysis',
        readable_type: 'Student Analysis',
        includes_all_versions: true,
        includes_sis_ids: true,
        generatable: true,
        anonymous: false,
        url: 'http://lvh.me:3000/api/v1/courses/1/quizzes/1/reports/9',
        created_at: '2021-01-05T17:21:14Z',
        updated_at: '2021-01-05T17:24:45Z',
        links: {quiz: 'http://lvh.me:3000/api/v1/courses/1/quizzes/1'},
        progress: {
          id: 6,
          context_id: 9,
          context_type: 'Quizzes::QuizStatistics',
          user_id: null,
          tag: 'Quizzes::QuizStatistics',
          completion: 100.0,
          workflow_state: 'completed',
          created_at: '2021-01-05T17:24:44Z',
          updated_at: '2021-01-05T17:24:45Z',
          message: null,
          url: 'http://lvh.me:3000/api/v1/progress/6',
        },
        file: {
          id: 5,
          uuid: 'Vx9k9UaPZQoTlwfJ1NCZF6fjmEUTqQEVKcTCI0bn',
          folder_id: null,
          display_name: 'The Emperor Quiz Student Analysis Report.csv',
          filename: 'quiz_student_analysis_report.csv',
          upload_status: 'success',
          'content-type': 'unknown/unknown',
          url: 'http://lvh.me:3000/files/5/download?download_frd=1\u0026verifier=Vx9k9UaPZQoTlwfJ1NCZF6fjmEUTqQEVKcTCI0bn',
          size: 1144,
          created_at: '2021-01-05T17:24:45Z',
          updated_at: '2021-01-05T17:24:45Z',
          unlock_at: null,
          locked: false,
          hidden: false,
          lock_at: null,
          hidden_for_user: false,
          thumbnail_url: null,
          modified_at: '2021-01-05T17:24:45Z',
          mime_class: 'file',
          media_entry_id: null,
          locked_for_user: false,
        },
      },
      {
        id: '8',
        report_type: 'item_analysis',
        readable_type: 'Item Analysis',
        includes_all_versions: true,
        includes_sis_ids: false,
        generatable: true,
        anonymous: false,
        url: 'http://lvh.me:3000/api/v1/courses/1/quizzes/1/reports/8',
        created_at: '2021-01-05T17:21:14Z',
        updated_at: '2021-01-05T17:24:52Z',
        links: {quiz: 'http://lvh.me:3000/api/v1/courses/1/quizzes/1'},
        progress: {
          id: 7,
          context_id: 8,
          context_type: 'Quizzes::QuizStatistics',
          user_id: null,
          tag: 'Quizzes::QuizStatistics',
          completion: 100.0,
          workflow_state: 'completed',
          created_at: '2021-01-05T17:24:49Z',
          updated_at: '2021-01-05T17:24:52Z',
          message: null,
          url: 'http://lvh.me:3000/api/v1/progress/7',
        },
        file: {
          id: 6,
          uuid: 'sRretFwNE5atUtNevxF6EnXtBuNzOehAJoMiIHzz',
          folder_id: null,
          display_name: 'The Emperor Quiz Item Analysis Report.csv',
          filename: 'quiz_item_analysis_report.csv',
          upload_status: 'success',
          'content-type': 'unknown/unknown',
          url: 'http://lvh.me:3000/files/6/download?download_frd=1\u0026verifier=sRretFwNE5atUtNevxF6EnXtBuNzOehAJoMiIHzz',
          size: 621,
          created_at: '2021-01-05T17:24:52Z',
          updated_at: '2021-01-05T17:24:52Z',
          unlock_at: null,
          locked: false,
          hidden: false,
          lock_at: null,
          hidden_for_user: false,
          thumbnail_url: null,
          modified_at: '2021-01-05T17:24:52Z',
          mime_class: 'file',
          media_entry_id: null,
          locked_for_user: false,
        },
      },
    ],
  },
  '/api/v1/courses/1/sections': [
    {
      id: '1',
      course_id: '1',
      name: 'Craiceann Ice Cream',
      start_at: null,
      end_at: null,
      created_at: '2020-12-08T17:25:43Z',
      restrict_enrollments_to_section_dates: null,
      nonxlist_course_id: null,
      sis_section_id: null,
      sis_course_id: null,
      integration_id: null,
      sis_import_id: null,
    },
  ],
}

describe('canvas_quizzes/statistics', () => {
  let fakeServer

  beforeEach(() => {
    fakeServer = sinon.createFakeServer()
    fakeServer.autoRespond = true
    fakeServer.respondImmediately = true

    for (const url of Object.keys(fixture)) {
      fakeServer.respondWith('GET', new RegExp(`^${url}`), [
        200,
        {'Content-Type': 'application/json'},
        JSON.stringify(fixture[url]),
      ])
    }

    configure({
      ajax: $.ajax,
      loadOnStartup: true,
      quizStatisticsUrl: '/api/v1/courses/1/quizzes/1/statistics',
      quizReportsUrl: '/api/v1/courses/1/quizzes/1/reports',
      courseSectionsUrl: '/api/v1/courses/1/sections',
    })
  })

  afterEach(() => {
    fakeServer.restore()
    fakeServer = null

    return unmount()
  })

  it('renders', () => {
    const node = document.createElement('div')

    return mount(node)
      .then(() => findByTestId(node, 'summary-statistics'))
      .then(el => {
        expect(el.textContent).toContain(
          '11 students scored above or at the average, and 1 below. 1 student in percentile 50. 1 student in percentile 67.'
        )
      })
  })
})
