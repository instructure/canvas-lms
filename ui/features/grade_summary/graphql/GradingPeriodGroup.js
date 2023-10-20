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
import {bool, string} from 'prop-types'

import {GradingPeriod} from './GradingPeriod'

export const GradingPeriodGroup = {
  fragment: gql`
    fragment GradingPeriodGroup on GradingPeriodGroup {
      createdAt
      displayTotals
      enrollmentTermIds
      _id
      id
      title
      updatedAt
      weighted
      gradingPeriodsConnection {
        nodes {
          ...GradingPeriod
        }
      }
    }
    ${GradingPeriod.fragment}
  `,
  shape: {
    createdAt: string,
    displayTotals: bool,
    enrollmentTermIds: [string],
    _id: string,
    id: string,
    title: string,
    updatedAt: string,
    weighted: bool,
    gradingPeriodsConnection: {
      nodes: [GradingPeriod.shape],
    },
  },
  mock: ({
    _id = '1',
    id = '1',
    title = 'Grading Period Group 1',
    createdAt = '2020-01-01',
    updatedAt = '2020-01-01',
    displayTotals = true,
    enrollmentTermIds = ['1'],
    weighted = true,
    gradingPeriodsConnection = {
      nodes: [GradingPeriod.mock()],
    },
  } = {}) => ({
    _id,
    id,
    title,
    createdAt,
    updatedAt,
    displayTotals,
    enrollmentTermIds,
    weighted,
    gradingPeriodsConnection,
  }),
}
