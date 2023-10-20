/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import gql from 'graphql-tag'
import {number} from 'prop-types'

export const ScoreStatistic = {
  fragment: gql`
    fragment ScoreStatistic on Assignment {
      count
      lowerQ
      maximum
      mean
      median
      minimum
      upperQ
    }
  `,
  shape: {
    count: number,
    lowerQ: number,
    maximum: number,
    mean: number,
    median: number,
    minimum: number,
    upperQ: number,
  },
  mock: (
    count = 5,
    lowerQ = 5,
    maximum = 15,
    mean = 10,
    median = 10,
    minimum = 5,
    upperQ = 15
  ) => ({
    count,
    lowerQ,
    maximum,
    mean,
    median,
    minimum,
    upperQ,
  }),
}
