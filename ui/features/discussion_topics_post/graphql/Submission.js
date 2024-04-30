/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {shape, string} from 'prop-types'

export const Submission = {
  fragment: gql`
    fragment Submission on Submission {
      id
      _id
      submissionStatus
      subAssignmentTag
      cachedDueDate
      submittedAt
    }
  `,

  shape: shape({
    id: string,
    _id: string,
    submissionStatus: string,
    subAssignmentTag: string,
    submittedAt: string,
    cachedDueDate: string,
  }),

  mock: ({
    id = 'BXMzaWdebTVubC0x',
    _id = '3',
    submissionStatus = 'submitted',
    subAssignmentTag = 'reply_to_topic',
    cachedDueDate = null,
    submittedAt = '2024-07-17T23:59:59Z',
  } = {}) => ({
    id,
    _id,
    submissionStatus,
    subAssignmentTag,
    cachedDueDate,
    submittedAt,
    __typename: 'Submission',
  }),
}
