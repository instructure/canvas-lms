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

import {bool, shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const RubricAssociation = {
  fragment: gql`
    fragment RubricAssociation on RubricAssociation {
      _id
      hide_points: hidePoints
      hide_score_total: hideScoreTotal
      use_for_grading: useForGrading
    }
  `,

  shape: shape({
    _id: string.isRequired,
    hide_points: bool,
    hide_score_total: bool.isRequired,
    use_for_grading: bool.isRequired,
  }),

  mock: ({
    _id = '1',
    hide_points = false,
    hide_score_total = false,
    use_for_grading = false,
  } = {}) => ({
    _id,
    hide_points,
    hide_score_total,
    use_for_grading,
  }),
}

export const DefaultMocks = {
  RubricAssociation: () => ({
    _id: '1',
    hidePoints: false,
    hideScoreTotal: false,
    useForGrading: false,
  }),
}
