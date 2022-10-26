/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {bool, shape} from 'prop-types'
import gql from 'graphql-tag'

export const DiscussionEntryPermissions = {
  fragment: gql`
    fragment DiscussionEntryPermissions on DiscussionEntryPermissions {
      attach
      create
      delete
      rate
      read
      reply
      update
      viewRating
    }
  `,

  shape: shape({
    attach: bool,
    create: bool,
    delete: bool,
    rate: bool,
    read: bool,
    reply: bool,
    update: bool,
    viewRating: bool,
  }),

  mock: ({
    attach = true,
    create = true,
    canDelete = true, // Special case because `delete` is a special word
    rate = true,
    read = true,
    reply = true,
    update = true,
    viewRating = true,
  } = {}) => ({
    attach,
    create,
    delete: canDelete,
    rate,
    read,
    reply,
    update,
    viewRating,
    __typename: 'DiscussionEntryPermissions',
  }),
}
