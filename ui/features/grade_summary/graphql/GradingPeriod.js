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
      createdAt
      displayTotals
      closeDate
      title
      weight
      isLast
      id
      startDate
      updatedAt
      endDate
    }
  `,
  shape: {
    _id: string,
    createdAt: string,
    displayTotals: bool,
    closeDate: string,
    title: string,
    weight: float,
    isLast: bool,
    id: string,
    startDate: string,
    updatedAt: string,
    endDate: string,
  },
  mock: ({
    _id = '1',
    createdAt = '2020-01-01',
    closeDate = '2020-01-03',
    title = 'Grading Period 1',
    weight = 50,
    isLast = false,
    displayTotals = true,
    id = '1',
    startDate = '2020-01-01',
    updatedAt = '2020-01-01',
    endDate = '2020-01-02',
  } = {}) => ({
    _id,
    createdAt,
    closeDate,
    title,
    weight,
    isLast,
    displayTotals,
    id,
    startDate,
    updatedAt,
    endDate,
  }),
}
