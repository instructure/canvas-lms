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

import {gql} from '@apollo/client'

const MAX_CUSTOM_GRADE_STATUSES_PER_ACCOUNT = 3
const MAX_STANDARD_GRADE_STATUSES_PER_ACCOUNT = 6

export const ACCOUNT_GRADING_STATUS_QUERY = gql`
  query AccountGradingStatusQuery($accountId: ID!) {
    account(id: $accountId) {
      customGradeStatusesConnection(first: ${MAX_CUSTOM_GRADE_STATUSES_PER_ACCOUNT}) {
        nodes {
          color
          id: _id
          name
        }
      }
      standardGradeStatusesConnection(first: ${MAX_STANDARD_GRADE_STATUSES_PER_ACCOUNT}) {
        nodes {
          color
          id: _id
          name
        }
      }
    }
  }
`
