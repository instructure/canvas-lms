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

import {arrayOf, bool, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {Rating} from './Rating'

export const Criterion = {
  fragment: gql`
    fragment Criterion on Criterion {
      id
      criterion_use_range: criterionUseRange
      description
      long_description: longDescription
      points
      ratings {
        ...Rating
      }
    }
    ${Rating.fragment}
  `,

  shape: shape({
    id: string.isRequired,
    criterion_use_range: bool.isRequired,
    description: string.isRequired,
    long_description: string,
    points: number,
    ratings: arrayOf(Rating.shape)
  })
}

export const CriterionDefaultMocks = {
  Criterion: () => ({
    id: '1',
    criterionUseRange: false,
    description: 'First Criterion',
    longDescription: '',
    points: 6,
    ratings: [{}]
  })
}
