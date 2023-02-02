// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import store from '../index'
import type {Assessment} from '../index'

const originalState = store.getState()

const assessmentObject: Assessment = {
  artifactAttempt: 1,
  assessment_type: 'peer_review',
  assessor: {
    name: 'Student 1',
    enrollments: [
      {
        type: 'StudentEnrollment',
        __typename: 'Enrollment',
      },
    ],
    __typename: 'User',
    _id: '2',
  },
  data: [
    {
      artifactAttempt: 1,
      comments: 'foo bar',
      comments_html: 'foo bar',
      criterion_id: '_9802',
      description: 'Full Marks',
      id: 'blank',
      learning_outcome_id: null,
      points: 5,
      __typename: 'RubricAssessmentRating',
      _id: 'blank',
    },
  ],
  rubric_association: {
    hide_points: false,
    hide_score_total: false,
    use_for_grading: false,
    __typename: 'RubricAssociation',
    _id: '44',
  },
  score: 5,
  __typename: 'RubricAssessment',
  _id: '34',
}

describe('index', () => {
  afterEach(() => {
    store.setState(originalState, true)
  })

  it('initialize the value of displayedAssessment as null', () => {
    expect(store.getState().displayedAssessment).toEqual(null)
  })

  it('store and retrieves displayedAssessment', async () => {
    await store.setState({displayedAssessment: assessmentObject})
    expect(store.getState().displayedAssessment).toMatchObject(assessmentObject)
  })
})
