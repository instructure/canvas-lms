/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export const testUnsupportedQuestion = {
  id: '1',
  position: 1,
  points_possible: 1.0,
  properties: {},
  entry_type: 'Item',
  entry_editable: true,
  stimulus_quiz_entry_id: '',
  status: 'mutable',
  entry: {
    title: 'Why should we categorize things?',
    item_body: '<p>Categorize these things so they make sense.</p>',
    calculator_type: 'none',
    interaction_data: {
      categories: {
        '6ed03a7f-813b-4cd2-9313-125754180d04': {
          id: '6ed03a7f-813b-4cd2-9313-125754180d04',
          item_body: 'category 1',
        },
        'f8d0f08b-96ee-43ec-9e65-f9a5329d7343': {
          id: 'f8d0f08b-96ee-43ec-9e65-f9a5329d7343',
          item_body: 'category 2',
        },
      },
      distractors: {
        '48687dcd-fb6d-4c90-971e-6f4ee7484a27': {
          id: '48687dcd-fb6d-4c90-971e-6f4ee7484a27',
          item_body: '2',
        },
        '5a0f6d12-2b6f-499f-809f-ea6626fa9459': {
          id: '5a0f6d12-2b6f-499f-809f-ea6626fa9459',
          item_body: '4',
        },
        'b4094d4b-5250-4382-a8ee-58707292b76d': {
          id: 'b4094d4b-5250-4382-a8ee-58707292b76d',
          item_body: '1',
        },
        'dbff66e1-0cce-408d-9482-397b9ff1573d': {
          id: 'dbff66e1-0cce-408d-9482-397b9ff1573d',
          item_body: '3',
        },
        'fd2e3570-d4b3-43fd-9d09-97ae1bda6c16': {
          id: 'fd2e3570-d4b3-43fd-9d09-97ae1bda6c16',
          item_body: '10',
        },
      },
      category_order: [
        '6ed03a7f-813b-4cd2-9313-125754180d04',
        'f8d0f08b-96ee-43ec-9e65-f9a5329d7343',
      ],
    },
    properties: {
      shuffle_rules: {
        questions: {
          shuffled: false,
        },
      },
    },
    scoring_data: {
      value: [
        {
          id: '6ed03a7f-813b-4cd2-9313-125754180d04',
          scoring_data: {
            value: ['b4094d4b-5250-4382-a8ee-58707292b76d', 'dbff66e1-0cce-408d-9482-397b9ff1573d'],
          },
          scoring_algorithm: 'AllOrNothing',
        },
        {
          id: 'f8d0f08b-96ee-43ec-9e65-f9a5329d7343',
          scoring_data: {
            value: ['48687dcd-fb6d-4c90-971e-6f4ee7484a27', '5a0f6d12-2b6f-499f-809f-ea6626fa9459'],
          },
          scoring_algorithm: 'AllOrNothing',
        },
      ],
      score_method: 'all_or_nothing',
    },
    answer_feedback: {},
    scoring_algorithm: 'Categorization',
    interaction_type_slug: 'categorization',
    feedback: {},
  },
}

export const testSupportedQuestion = {
  id: '2',
  position: 2,
  points_possible: 1.0,
  properties: {},
  entry_type: 'Item',
  entry_editable: true,
  stimulus_quiz_entry_id: '',
  status: 'mutable',
  entry: {
    title: 'Is this true or false?',
    item_body: '<p>Blue is better than Octopus?</p>',
    calculator_type: 'none',
    interaction_data: {
      true_choice: 'True',
      false_choice: 'False',
    },
    properties: {},
    scoring_data: {
      value: true,
    },
    answer_feedback: {},
    scoring_algorithm: 'Equivalence',
    interaction_type_slug: 'true-false',
    feedback: {
      neutral: '<p>Always shown</p>',
      correct: '<p>This is correct!</p>',
      incorrect: '<p>Nope.</p>',
    },
  },
}

export const testMissingValuesQuestion = {
  id: '3',
  position: 3,
  points_possible: 1.0,
  properties: {},
  entry_type: 'Item',
  entry_editable: true,
  stimulus_quiz_entry_id: '',
  status: 'mutable',
  entry: {
    title: null,
    item_body: null,
    calculator_type: 'none',
    interaction_data: {
      true_choice: 'True',
      false_choice: 'False',
    },
    properties: {},
    scoring_data: {
      value: true,
    },
    answer_feedback: {},
    scoring_algorithm: 'Equivalence',
    interaction_type_slug: 'true-false',
    feedback: {
      neutral: '<p>Always shown</p>',
      correct: '<p>This is correct!</p>',
      incorrect: '<p>Nope.</p>',
    },
  },
}

export const testQuestions = [
  testUnsupportedQuestion,
  testSupportedQuestion,
  testMissingValuesQuestion,
]
