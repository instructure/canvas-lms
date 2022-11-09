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
import gql from 'graphql-tag'
import {shape} from 'prop-types'
import {
  SubmissionInterface,
  DefaultMocks as SubmissionInterfaceDefaultMocks,
} from './SubmissionInterface'

export const SubmissionHistory = {
  fragment: gql`
    fragment SubmissionHistory on SubmissionHistory {
      ...SubmissionInterface
    }
    ${SubmissionInterface.fragment}
  `,

  shape: shape({
    // eslint-disable-next-line react/forbid-foreign-prop-types
    ...SubmissionInterface.shape.propTypes,
  }),
}

export const DefaultMocks = {
  SubmissionHistory: () => ({
    ...SubmissionInterfaceDefaultMocks.SubmissionInterface(),
  }),
}
