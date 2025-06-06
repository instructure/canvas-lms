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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {configure, mount, unmount} from '../index'
import {fireEvent, findByTestId, waitFor} from '@testing-library/dom'

const fixture = {
  '/api/v1/quizzes/1/submissions/2': {
    quiz_submissions: [
      {
        id: 2,
        quiz_id: 1,
        quiz_version: 5,
        user_id: 2,
        submission_id: 2,
        score: 4.5,
        kept_score: 4.5,
        started_at: '2021-01-04T20:32:49Z',
        end_at: null,
        finished_at: '2021-01-04T20:34:02Z',
        attempt: 2,
        workflow_state: 'pending_review',
        fudge_points: null,
        quiz_points_possible: 8.0,
        extra_attempts: 1,
        extra_time: null,
        manually_unlocked: null,
        validation_token: 'b26b810c3c63a63b2684dc98549c590294e4454bd18d7740e29fbbcad6968123',
        score_before_regrade: null,
        has_seen_results: false,
        time_spent: 73,
        attempts_left: 0,
        overdue_and_needs_submission: false,
        'excused?': false,
        html_url: 'http://lvh.me:3000/courses/1/quizzes/1/submissions/2',
        result_url:
          'http://lvh.me:3000/courses/1/quizzes/1/history?quiz_submission_id=2\u0026version=2',
      },
    ],
  },
  '/api/v1/quizzes/1/submissions/2?attempt=2': {
    quiz_submissions: [
      {
        id: 2,
        quiz_id: 1,
        quiz_version: 5,
        user_id: 2,
        submission_id: 2,
        score: 4.5,
        kept_score: 4.5,
        started_at: '2021-01-04T20:32:49Z',
        end_at: null,
        finished_at: '2021-01-04T20:34:02Z',
        attempt: 2,
        workflow_state: 'pending_review',
        fudge_points: null,
        quiz_points_possible: 8.0,
        extra_attempts: 1,
        extra_time: null,
        manually_unlocked: null,
        validation_token: 'b26b810c3c63a63b2684dc98549c590294e4454bd18d7740e29fbbcad6968123',
        score_before_regrade: null,
        has_seen_results: false,
        time_spent: 73,
        attempts_left: 0,
        overdue_and_needs_submission: false,
        'excused?': false,
        html_url: 'http://lvh.me:3000/courses/1/quizzes/1/submissions/2',
        result_url:
          'http://lvh.me:3000/courses/1/quizzes/1/history?quiz_submission_id=2\u0026version=2',
      },
    ],
  },
  '/api/v1/quizzes/1/questions?quiz_submission_id=2&quiz_submission_attempt=2&page=1': [
    {
      id: 1,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 1,
      position: 1,
      question_name: 'Question 1',
      question_type: 'multiple_choice_question',
      question_text: "\u003cp\u003ewhat's the right choice!?\u003c/p\u003e",
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {id: 8725, text: 'a', html: '', comments: '', comments_html: '', weight: 100.0},
        {id: 2033, text: 'b', html: '', comments: '', comments_html: '', weight: 0.0},
        {id: 3360, text: 'c', html: '', comments: '', comments_html: '', weight: 0.0},
        {id: 4760, text: 'd', html: '', comments: '', comments_html: '', weight: 0.0},
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
    {
      id: 2,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 2,
      position: 2,
      question_name: 'Question 2',
      question_type: 'matching_question',
      question_text: "\u003cp\u003ematch it like there's no tomorrow\u003c/p\u003e",
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {
          id: 923,
          text: 'a',
          left: 'a',
          right: 'b',
          comments: '',
          comments_html: '',
          match_id: 8671,
        },
        {
          id: 3099,
          text: 'c',
          left: 'c',
          right: 'd',
          comments: '',
          comments_html: '',
          match_id: 5959,
        },
        {
          id: 8251,
          text: 'e',
          left: 'e',
          right: 'f',
          comments: '',
          comments_html: '',
          match_id: 7669,
        },
        {
          id: 1310,
          text: 'g',
          left: 'g',
          right: 'h',
          comments: '',
          comments_html: '',
          match_id: 6786,
        },
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: [
        {text: 'd', match_id: 5959},
        {text: 'h', match_id: 6786},
        {text: 'b', match_id: 8671},
        {text: 'f', match_id: 7669},
      ],
      matching_answer_incorrect_matches: '',
    },
    {
      id: 3,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 3,
      position: 3,
      question_name: 'Question 3',
      question_type: 'true_false_question',
      question_text: '\u003cp\u003eTo entertain doubt is to dance with death, truth?\u003c/p\u003e',
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {comments: '', comments_html: '', text: 'True', weight: 100, id: 1894},
        {comments: '', comments_html: '', text: 'False', weight: 0, id: 8359},
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
    {
      id: 4,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 4,
      position: 4,
      question_name: 'Question 4',
      question_type: 'short_answer_question',
      question_text: '\u003cp\u003e______ the emperor who sits alone on his throne.\u003c/p\u003e',
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {id: '8253', text: 'Pity', comments: '', comments_html: '', weight: 100},
        {id: '974', text: 'Praise', comments: '', comments_html: '', weight: 100},
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
    {
      id: 5,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 5,
      position: 5,
      question_name: 'Question 5',
      question_type: 'fill_in_multiple_blanks_question',
      question_text:
        '\u003cp\u003e\u003cspan\u003eThere is a fine line between           \u003cinput class="question_input" type="text" autocomplete="off" style="width: 120px;" name="question_5_9f245e20de41ac318cb39cf4da4961d2" value="{{question_5_9f245e20de41ac318cb39cf4da4961d2}}"\u003e\n and           \u003cinput class="question_input" type="text" autocomplete="off" style="width: 120px;" name="question_5_9987eec61d9b33b77ba6f9ce036d676c" value="{{question_5_9987eec61d9b33b77ba6f9ce036d676c}}"\u003e\n. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e',
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {
          id: 9687,
          text: 'fear',
          comments: '',
          comments_html: '',
          weight: 100.0,
          blank_id: 'consideration',
        },
        {
          id: 4251,
          text: 'intimidation',
          comments: '',
          comments_html: '',
          weight: 100.0,
          blank_id: 'consideration',
        },
        {
          id: 5647,
          text: 'joy',
          comments: '',
          comments_html: '',
          weight: 100.0,
          blank_id: 'hesitation',
        },
        {
          id: 7341,
          text: 'grace',
          comments: '',
          comments_html: '',
          weight: 100.0,
          blank_id: 'hesitation',
        },
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
    {
      id: 6,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 6,
      position: 6,
      question_name: 'Question 6',
      question_type: 'multiple_answers_question',
      question_text:
        '\u003cp\u003e\u003cspan\u003eWisdom is the offspring of:\u003c/span\u003e\u003c/p\u003e',
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {id: 5601, text: '', comments: '', comments_html: '', weight: 100.0},
        {id: 2284, text: '', comments: '', comments_html: '', weight: 0.0},
        {id: 6969, text: 'Suffering', comments: '', comments_html: '', weight: 0.0},
        {id: 269, text: 'Time', comments: '', comments_html: '', weight: 0.0},
        {id: 4627, text: 'Void', comments: '', comments_html: '', weight: 0.0},
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
    {
      id: 7,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 7,
      position: 7,
      question_name: 'Question 7',
      question_type: 'multiple_dropdowns_question',
      question_text:
        '\u003cdiv class="quiz_sortable question_holder" role="region" aria-label="Question" data-group-id=""\u003e\n\u003cdiv id="question_5" class="question display_question fill_in_multiple_blanks_question"\u003e\n\u003cdiv class="text"\u003e\n\u003cdiv id="question_new_question_text" class="question_text user_content enhanced"\u003e\n\u003cp\u003e\u003cspan\u003eThere is a fine line between           \u003cselect class="question_input" name="question_7_9f245e20de41ac318cb39cf4da4961d2"\u003e\n            \u003coption value=""\u003e\n              [ Select ]\n            \u003c/option\u003e\n            ["\u003coption value="3236"\u003esuffering\u003c/option\u003e", "\u003coption value="5757"\u003ejoy\u003c/option\u003e"]\n          \u003c/select\u003e\n and           \u003cselect class="question_input" name="question_7_9987eec61d9b33b77ba6f9ce036d676c"\u003e\n            \u003coption value=""\u003e\n              [ Select ]\n            \u003c/option\u003e\n            ["\u003coption value="9810"\u003efear\u003c/option\u003e", "\u003coption value="1030"\u003eecstasy\u003c/option\u003e"]\n          \u003c/select\u003e\n. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e',
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {
          id: 3236,
          text: 'suffering',
          comments: '',
          comments_html: '',
          weight: 100.0,
          blank_id: 'consideration',
        },
        {
          id: 5757,
          text: 'joy',
          comments: '',
          comments_html: '',
          weight: 0.0,
          blank_id: 'consideration',
        },
        {
          id: 9810,
          text: 'fear',
          comments: '',
          comments_html: '',
          weight: 100.0,
          blank_id: 'hesitation',
        },
        {
          id: 1030,
          text: 'ecstasy',
          comments: '',
          comments_html: '',
          weight: 0.0,
          blank_id: 'hesitation',
        },
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
    {
      id: 8,
      quiz_id: 1,
      quiz_group_id: null,
      assessment_question_id: 8,
      position: 8,
      question_name: 'Question 8',
      question_type: 'numerical_question',
      question_text: "\u003cp\u003eWhat's the answer?\u003c/p\u003e",
      points_possible: 1.0,
      correct_comments: '',
      incorrect_comments: '',
      neutral_comments: '',
      correct_comments_html: '',
      incorrect_comments_html: '',
      neutral_comments_html: '',
      answers: [
        {
          id: 4480,
          text: '',
          comments: '',
          comments_html: '',
          weight: 100,
          numerical_answer_type: 'exact_answer',
          exact: 0.0,
          margin: 0.0,
        },
        {
          id: 1312,
          text: '',
          comments: '',
          comments_html: '',
          weight: 100,
          numerical_answer_type: 'exact_answer',
          exact: 0.0,
          margin: 0.0,
        },
        {
          id: 8731,
          text: '',
          comments: '',
          comments_html: '',
          weight: 100,
          numerical_answer_type: 'range_answer',
          start: 0.0,
          end: 100.0,
        },
      ],
      variables: null,
      formulas: null,
      answer_tolerance: null,
      formula_decimal_places: null,
      matches: null,
      matching_answer_incorrect_matches: null,
    },
  ],
  '/api/v1/quizzes/1/submissions/2/events?attempt=2&per_page=50&page=1': {
    quiz_submission_events: [
      {
        id: '5',
        event_type: 'submission_created',
        event_data: {
          quiz_version: 5,
          quiz_data: [
            {
              id: 1,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'multiple_choice_question',
              question_name: 'Question 1',
              name: 'Question 1',
              question_text: "\u003cp\u003ewhat's the right choice!?\u003c/p\u003e",
              answers: [
                {id: 8725, text: 'a', html: '', comments: '', comments_html: '', weight: 100.0},
                {id: 2033, text: 'b', html: '', comments: '', comments_html: '', weight: 0.0},
                {id: 3360, text: 'c', html: '', comments: '', comments_html: '', weight: 0.0},
                {id: 4760, text: 'd', html: '', comments: '', comments_html: '', weight: 0.0},
              ],
              text_after_answers: '',
              assessment_question_id: 1,
              position: 1,
              published_at: '2021-01-04T13:31:24-07:00',
            },
            {
              id: 2,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'matching_question',
              question_name: 'Question 2',
              name: 'Question 2',
              question_text: "\u003cp\u003ematch it like there's no tomorrow\u003c/p\u003e",
              answers: [
                {
                  id: 923,
                  text: 'a',
                  left: 'a',
                  right: 'b',
                  comments: '',
                  comments_html: '',
                  match_id: 8671,
                },
                {
                  id: 3099,
                  text: 'c',
                  left: 'c',
                  right: 'd',
                  comments: '',
                  comments_html: '',
                  match_id: 5959,
                },
                {
                  id: 8251,
                  text: 'e',
                  left: 'e',
                  right: 'f',
                  comments: '',
                  comments_html: '',
                  match_id: 7669,
                },
                {
                  id: 1310,
                  text: 'g',
                  left: 'g',
                  right: 'h',
                  comments: '',
                  comments_html: '',
                  match_id: 6786,
                },
              ],
              text_after_answers: '',
              matching_answer_incorrect_matches: '',
              matches: [
                {text: 'd', match_id: 5959},
                {text: 'h', match_id: 6786},
                {text: 'b', match_id: 8671},
                {text: 'f', match_id: 7669},
              ],
              assessment_question_id: 2,
              position: 2,
              published_at: '2021-01-04T13:31:24-07:00',
            },
            {
              id: 3,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'true_false_question',
              question_name: 'Question 3',
              name: 'Question 3',
              question_text:
                '\u003cp\u003eTo entertain doubt is to dance with death, truth?\u003c/p\u003e',
              answers: [
                {comments: '', comments_html: '', text: 'True', weight: 100, id: 1894},
                {comments: '', comments_html: '', text: 'False', weight: 0, id: 8359},
              ],
              text_after_answers: '',
              assessment_question_id: 3,
              position: 3,
              published_at: '2021-01-04T13:31:24-07:00',
            },
            {
              id: 4,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'short_answer_question',
              question_name: 'Question 4',
              name: 'Question 4',
              question_text:
                '\u003cp\u003e______ the emperor who sits alone on his throne.\u003c/p\u003e',
              answers: [
                {id: '8253', text: 'Pity', comments: '', comments_html: '', weight: 100},
                {id: '974', text: 'Praise', comments: '', comments_html: '', weight: 100},
              ],
              text_after_answers: '',
              assessment_question_id: 4,
              position: 4,
              published_at: '2021-01-04T13:31:24-07:00',
            },
            {
              id: 5,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'fill_in_multiple_blanks_question',
              question_name: 'Question 5',
              name: 'Question 5',
              question_text:
                "\u003cp\u003e\u003cspan\u003eThere is a fine line between           \u003cinput\n            class='question_input'\n            type='text'\n            autocomplete='off'\n            style='width: 120px;'\n            name='question_5_9f245e20de41ac318cb39cf4da4961d2'\n            value='{{question_5_9f245e20de41ac318cb39cf4da4961d2}}' /\u003e\n and           \u003cinput\n            class='question_input'\n            type='text'\n            autocomplete='off'\n            style='width: 120px;'\n            name='question_5_9987eec61d9b33b77ba6f9ce036d676c'\n            value='{{question_5_9987eec61d9b33b77ba6f9ce036d676c}}' /\u003e\n. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e",
              answers: [
                {
                  id: 9687,
                  text: 'fear',
                  comments: '',
                  comments_html: '',
                  weight: 100.0,
                  blank_id: 'consideration',
                },
                {
                  id: 4251,
                  text: 'intimidation',
                  comments: '',
                  comments_html: '',
                  weight: 100.0,
                  blank_id: 'consideration',
                },
                {
                  id: 5647,
                  text: 'joy',
                  comments: '',
                  comments_html: '',
                  weight: 100.0,
                  blank_id: 'hesitation',
                },
                {
                  id: 7341,
                  text: 'grace',
                  comments: '',
                  comments_html: '',
                  weight: 100.0,
                  blank_id: 'hesitation',
                },
              ],
              text_after_answers: '',
              assessment_question_id: 5,
              position: 5,
              published_at: '2021-01-04T13:31:24-07:00',
              original_question_text:
                '\u003cp\u003e\u003cspan\u003eThere is a fine line between [consideration] and [hesitation]. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e',
            },
            {
              id: 6,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'multiple_answers_question',
              question_name: 'Question 6',
              name: 'Question 6',
              question_text:
                '\u003cp\u003e\u003cspan\u003eWisdom is the offspring of:\u003c/span\u003e\u003c/p\u003e',
              answers: [
                {id: 5601, text: '', comments: '', comments_html: '', weight: 100.0},
                {id: 2284, text: '', comments: '', comments_html: '', weight: 0.0},
                {id: 6969, text: 'Suffering', comments: '', comments_html: '', weight: 0.0},
                {id: 269, text: 'Time', comments: '', comments_html: '', weight: 0.0},
                {id: 4627, text: 'Void', comments: '', comments_html: '', weight: 0.0},
              ],
              text_after_answers: '',
              assessment_question_id: 6,
              position: 6,
              published_at: '2021-01-04T13:31:24-07:00',
            },
            {
              id: 7,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'multiple_dropdowns_question',
              question_name: 'Question 7',
              name: 'Question 7',
              question_text:
                '\u003cdiv class="quiz_sortable question_holder" role="region" aria-label="Question" data-group-id=""\u003e\n\u003cdiv id="question_5" class="question display_question fill_in_multiple_blanks_question"\u003e\n\u003cdiv class="text"\u003e\n\u003cdiv id="question_new_question_text" class="question_text user_content enhanced"\u003e\n\u003cp\u003e\u003cspan\u003eThere is a fine line between           \u003cselect class=\'question_input\' name=\'question_7_9f245e20de41ac318cb39cf4da4961d2\'\u003e\n            \u003coption value=\'\'\u003e\n              [ Select ]\n            \u003c/option\u003e\n            ["\u003coption value=\'3236\'\u003esuffering\u003c/option\u003e", "\u003coption value=\'5757\'\u003ejoy\u003c/option\u003e"]\n          \u003c/select\u003e\n and           \u003cselect class=\'question_input\' name=\'question_7_9987eec61d9b33b77ba6f9ce036d676c\'\u003e\n            \u003coption value=\'\'\u003e\n              [ Select ]\n            \u003c/option\u003e\n            ["\u003coption value=\'9810\'\u003efear\u003c/option\u003e", "\u003coption value=\'1030\'\u003eecstasy\u003c/option\u003e"]\n          \u003c/select\u003e\n. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e',
              answers: [
                {
                  id: 3236,
                  text: 'suffering',
                  comments: '',
                  comments_html: '',
                  weight: 100.0,
                  blank_id: 'consideration',
                },
                {
                  id: 5757,
                  text: 'joy',
                  comments: '',
                  comments_html: '',
                  weight: 0.0,
                  blank_id: 'consideration',
                },
                {
                  id: 9810,
                  text: 'fear',
                  comments: '',
                  comments_html: '',
                  weight: 100.0,
                  blank_id: 'hesitation',
                },
                {
                  id: 1030,
                  text: 'ecstasy',
                  comments: '',
                  comments_html: '',
                  weight: 0.0,
                  blank_id: 'hesitation',
                },
              ],
              text_after_answers: '',
              assessment_question_id: 7,
              position: 7,
              published_at: '2021-01-04T13:31:24-07:00',
              original_question_text:
                '\u003cdiv class="quiz_sortable question_holder" role="region" aria-label="Question" data-group-id=""\u003e\n\u003cdiv id="question_5" class="question display_question fill_in_multiple_blanks_question"\u003e\n\u003cdiv class="text"\u003e\n\u003cdiv id="question_new_question_text" class="question_text user_content enhanced"\u003e\n\u003cp\u003e\u003cspan\u003eThere is a fine line between [consideration] and [hesitation]. The former is wisdom, the latter is fear.\u003c/span\u003e\u003c/p\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e\n\u003c/div\u003e',
            },
            {
              id: 8,
              regrade_option: '',
              points_possible: 1.0,
              correct_comments: '',
              incorrect_comments: '',
              neutral_comments: '',
              correct_comments_html: '',
              incorrect_comments_html: '',
              neutral_comments_html: '',
              question_type: 'numerical_question',
              question_name: 'Question 8',
              name: 'Question 8',
              question_text: "\u003cp\u003eWhat's the answer?\u003c/p\u003e",
              answers: [
                {
                  id: 4480,
                  text: '',
                  comments: '',
                  comments_html: '',
                  weight: 100,
                  numerical_answer_type: 'exact_answer',
                  exact: 0.0,
                  margin: 0.0,
                },
                {
                  id: 1312,
                  text: '',
                  comments: '',
                  comments_html: '',
                  weight: 100,
                  numerical_answer_type: 'exact_answer',
                  exact: 0.0,
                  margin: 0.0,
                },
                {
                  id: 8731,
                  text: '',
                  comments: '',
                  comments_html: '',
                  weight: 100,
                  numerical_answer_type: 'range_answer',
                  start: 0.0,
                  end: 100.0,
                },
              ],
              text_after_answers: '',
              assessment_question_id: 8,
              position: 8,
              published_at: '2021-01-04T13:31:24-07:00',
            },
          ],
        },
        created_at: '2021-01-04T20:32:49Z',
      },
      {
        id: '6',
        event_type: 'session_started',
        event_data: {
          user_agent:
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36',
        },
        created_at: '2021-01-04T20:32:50Z',
      },
      {
        id: '7',
        event_type: 'question_answered',
        event_data: [
          {quiz_question_id: '1', answer: '2033'},
          {
            quiz_question_id: '2',
            answer: [
              {answer_id: '', match_id: null},
              {answer_id: '', match_id: null},
              {answer_id: '', match_id: null},
              {answer_id: '', match_id: null},
            ],
          },
          {quiz_question_id: '3', answer: null},
          {quiz_question_id: '4', answer: null},
          {quiz_question_id: '5', answer: {'': null}},
          {quiz_question_id: '6', answer: []},
          {quiz_question_id: '7', answer: {'': null}},
          {quiz_question_id: '8', answer: null},
        ],
        created_at: '2021-01-04T20:32:52Z',
      },
      {
        id: '8',
        event_type: 'question_answered',
        event_data: [{quiz_question_id: '3', answer: '1894'}],
        created_at: '2021-01-04T20:33:04Z',
      },
      {
        id: '9',
        event_type: 'question_viewed',
        event_data: ['1'],
        created_at: '2021-01-04T20:33:05Z',
      },
      {
        id: '10',
        event_type: 'question_viewed',
        event_data: ['2'],
        created_at: '2021-01-04T20:33:05Z',
      },
      {
        id: '11',
        event_type: 'question_viewed',
        event_data: ['3', '4', '5'],
        created_at: '2021-01-04T20:33:05Z',
      },
      {
        id: '12',
        event_type: 'question_answered',
        event_data: [{quiz_question_id: '4', answer: 'Pity'}],
        created_at: '2021-01-04T20:33:08Z',
      },
      {
        id: '13',
        event_type: 'question_viewed',
        event_data: ['6'],
        created_at: '2021-01-04T20:33:20Z',
      },
      {
        id: '14',
        event_type: 'question_answered',
        event_data: [{quiz_question_id: '8', answer: 33.0}],
        created_at: '2021-01-04T20:33:42Z',
      },
      {
        id: '15',
        event_type: 'question_viewed',
        event_data: ['7', '8'],
        created_at: '2021-01-04T20:33:50Z',
      },
    ],
  },
}

// Setup MSW server
const server = setupServer(
  ...Object.entries(fixture).map(([url, response]) =>
    http.get(url, () => HttpResponse.json(response)),
  ),
)

describe('canvas_quizzes/events', () => {
  let container

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    // Reset container for each test
    container = document.createElement('div')
    document.body.appendChild(container)

    configure({
      ajax: $.ajax,
      loadOnStartup: true,
      quizUrl: '/api/v1/quizzes/1',
      questionsUrl: '/api/v1/quizzes/1/questions',
      submissionUrl: '/api/v1/quizzes/1/submissions/2',
      eventsUrl: '/api/v1/quizzes/1/submissions/2/events',
      allowMatrixView: true,
      useHashRouter: true,
    })
  })

  afterEach(async () => {
    // Clean up in reverse order of setup
    await unmount()
    if (container && container.parentNode) {
      container.parentNode.removeChild(container)
    }
    container = null
  })

  it('renders event stream', async () => {
    await mount(container)

    // If we're in table view, switch to stream view
    const answerMatrix = container.querySelector('#ic-AnswerMatrix')
    if (answerMatrix) {
      const viewStreamButton = container.querySelector('a.btn.btn-default')
      await fireEvent.click(viewStreamButton)
    }

    // Now wait for the event stream to appear
    const eventStream = await findByTestId(container, 'event-stream')

    const expectedEvents = [
      '00:01Session started',
      '00:03Answered the following questions:#1#2#5#6#7',
      '00:15Answered question:#3',
      '00:16Viewed (and possibly read) question#1',
      '00:16Viewed (and possibly read) question#2',
      '00:16Viewed (and possibly read) the following questions:#3#4#5',
      '00:19Answered question:#4',
      '00:31Viewed (and possibly read) question#6',
      '00:53Answered question:#8',
      '01:01Viewed (and possibly read) the following questions:#7#8',
    ]

    await Promise.all(
      expectedEvents.map(async entry => {
        await waitFor(() => {
          expect(eventStream.textContent).toContain(entry)
        })
      }),
    )
  })

  it('renders table', async () => {
    await mount(container)

    const viewTableButton = await findByTestId(container, 'view-table-button')
    await fireEvent.click(viewTableButton)

    const answerMatrix = await findByTestId(container, 'answer-matrix')

    await waitFor(() => {
      expect(answerMatrix).toBeTruthy()
      const headers = answerMatrix.querySelectorAll('thead th')
      const rows = answerMatrix.querySelectorAll('tbody tr')
      expect(headers).toHaveLength(9) // 1 for Timestamp and 8 for questions
      expect(rows).toHaveLength(4)
    })
  })
})
