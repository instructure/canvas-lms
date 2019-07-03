/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export const allowExtraCredit = false
export const customRatings = []
export const flexWidth = false
export const isSummary = false
export const onAssessmentChange = null
export const rubric = {
  context_id: '6',
  context_type: 'Course',
  criteria: [
    {
      criterion_use_range: false,
      description: 'Criterion 1 description',
      id: '1',
      long_description: 'Long criterion 1 description',
      points: 5,
      ratings: [
        {
          description: 'Full Marks',
          long_description: 'Full Marks Awarded',
          points: 5,
          criterion_id: 3,
          id: 'blank'
        },
        {
          description: 'No Marks',
          long_description: 'No Marks Awarded',
          points: 0,
          criterion_id: 3,
          id: 'blank'
        }
      ]
    },
    {
      criterion_use_range: false,
      description: 'Criterion 2 description',
      id: '2',
      long_description: '',
      points: 10,
      ratings: [
        {
          description: 'Full Marks',
          long_description: '',
          points: 10,
          criterion_id: 3,
          id: 'blank'
        },
        {
          description: 'Partial Marks',
          long_description: '',
          points: 5,
          criterion_id: 3,
          id: 'blank'
        },
        {
          description: 'No Marks',
          long_description: '',
          points: 0,
          criterion_id: 3,
          id: 'blank'
        }
      ]
    }
  ],
  data: {
    description: 'Data description',
    long_description: 'Long data description',
    points: 5,
    id: '1',
    criterion_use_range: false
  },
  free_form_criterion_comments: false,
  hide_score_total: false,
  id: '6',
  points_possible: 15,
  public: false,
  read_only: false,
  reusable: false,
  title: 'Rubric Title'
}

export const rubricAssessment = null

export const rubricAssociation = {
  association_id: '16',
  association_type: 'Assignment',
  bookmarked: true,
  context_code: 'course_6',
  context_id: '6',
  context_type: 'Course',
  created_at: '2019-07-12T18:05:56Z',
  hide_outcome_results: false,
  hide_points: false,
  hide_score_total: false,
  id: '6',
  purpose: 'grading',
  rubric_id: '6',
  summary_data: null,
  title: '02',
  updated_at: '2019-07-12T18:05:56Z',
  url: null,
  use_for_grading: false
}

export default rubricAssociation
