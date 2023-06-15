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
import {bool, float, string} from 'prop-types'

export const GradingPeriod = {
  fragment: gql`
    fragment GradingPeriod on GradingPeriod {
      _id
      title
      weight
      displayTotals
    }
  `,
  shape: {
    _id: string,
    title: string,
    weight: float,
    displayTotals: bool,
  },
  mock: ({_id = '1', title = 'Grading Period 1', weight = 50, displayTotals = true} = {}) => ({
    _id,
    title,
    weight,
    displayTotals,
  }),
}
