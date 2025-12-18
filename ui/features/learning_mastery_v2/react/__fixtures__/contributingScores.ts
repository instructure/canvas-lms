/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {
  ContributingScoreAlignment,
  ContributingScore,
  ContributingScoresResponse,
} from '../hooks/useContributingScores'

export const MOCK_ALIGNMENTS: ContributingScoreAlignment[] = [
  {
    alignment_id: 'A_1',
    associated_asset_id: '1',
    associated_asset_name: 'Assignment 1',
    associated_asset_type: 'Assignment',
    html_url: '/courses/1/assignments/1',
  },
  {
    alignment_id: 'A_2',
    associated_asset_id: '2',
    associated_asset_name: 'Assignment 2',
    associated_asset_type: 'Assignment',
    html_url: '/courses/1/assignments/2',
  },
  {
    alignment_id: 'A_3',
    associated_asset_id: '3',
    associated_asset_name: 'Assignment 3',
    associated_asset_type: 'Assignment',
    html_url: '/courses/1/assignments/3',
  },
  {
    alignment_id: 'R_1',
    associated_asset_id: '1',
    associated_asset_name: 'Rubric 1',
    associated_asset_type: 'Rubric',
    html_url: '/courses/1/rubrics/1',
  },
]

export const MOCK_CONTRIBUTING_SCORES: ContributingScore[] = [
  {
    user_id: '1',
    alignment_id: 'A_1',
    score: 3,
  },
  {
    user_id: '1',
    alignment_id: 'A_2',
    score: 4,
  },
  {
    user_id: '1',
    alignment_id: 'A_3',
    score: 5,
  },
  {
    user_id: '2',
    alignment_id: 'A_1',
    score: 2,
  },
  {
    user_id: '2',
    alignment_id: 'A_2',
    score: 3,
  },
  {
    user_id: '3',
    alignment_id: 'A_1',
    score: 5,
  },
]

export const MOCK_CONTRIBUTING_SCORES_OUTCOME_1: ContributingScoresResponse = {
  outcome: {
    id: '1',
    title: 'outcome 1',
  },
  alignments: MOCK_ALIGNMENTS.slice(0, 3),
  scores: MOCK_CONTRIBUTING_SCORES.filter(score =>
    ['A_1', 'A_2', 'A_3'].includes(score.alignment_id),
  ),
}

export const MOCK_CONTRIBUTING_SCORES_OUTCOME_2: ContributingScoresResponse = {
  outcome: {
    id: '2',
    title: 'outcome 2',
  },
  alignments: [
    {
      alignment_id: 'A_4',
      associated_asset_id: '4',
      associated_asset_name: 'Assignment 4',
      associated_asset_type: 'Assignment',
      html_url: '/courses/1/assignments/4',
    },
    {
      alignment_id: 'A_5',
      associated_asset_id: '5',
      associated_asset_name: 'Assignment 5',
      associated_asset_type: 'Assignment',
      html_url: '/courses/1/assignments/5',
    },
  ],
  scores: [
    {
      user_id: '1',
      alignment_id: 'A_4',
      score: 4,
    },
    {
      user_id: '2',
      alignment_id: 'A_4',
      score: 3,
    },
    {
      user_id: '2',
      alignment_id: 'A_5',
      score: 5,
    },
  ],
}

export const MOCK_EMPTY_CONTRIBUTING_SCORES: ContributingScoresResponse = {
  outcome: {
    id: '99',
    title: 'outcome with no alignments',
  },
  alignments: [],
  scores: [],
}
