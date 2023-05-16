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
import {arrayOf, float, string} from 'prop-types'

export const GradingStandard = {
  fragment: gql`
    fragment GradingStandard on GradingStandard {
      data {
        letterGrade
        baseValue
      }
      title
    }
  `,
  shape: {
    data: arrayOf({
      letterGrade: string,
      baseValue: float,
    }),
    title: string,
  },
  mock: ({
    data = [
      {
        letterGrade: 'A',
        baseValue: 0.94,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'A-',
        baseValue: 0.9,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'B+',
        baseValue: 0.87,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'B',
        baseValue: 0.84,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'B-',
        baseValue: 0.8,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'C+',
        baseValue: 0.77,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'C',
        baseValue: 0.74,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'C-',
        baseValue: 0.7,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'D+',
        baseValue: 0.67,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'D',
        baseValue: 0.64,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'D-',
        baseValue: 0.61,
        __typename: 'GradingStandardItem',
      },
      {
        letterGrade: 'F',
        baseValue: 0,
        __typename: 'GradingStandardItem',
      },
    ],
    title = 'Letter Grade',
  } = {}) => ({
    data,
    title,
    __typename: 'GradingStandard',
  }),
}
