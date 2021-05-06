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

export const DiscussionPermissions = {
  fragment: gql`
    fragment DiscussionPermissions on DiscussionPermissions {
      attach
      create
      delete
      duplicate
      rate
      read
      readAsAdmin
      readReplies
      reply
      update
      speedGrader
      peerReview
      showRubric
    }
  `,

  shape: shape({
    attach: bool,
    create: bool,
    delete: bool,
    duplicate: bool,
    rate: bool,
    read: bool,
    readAsAdmin: bool,
    readReplies: bool,
    reply: bool,
    update: bool,
    speedGrader: bool,
    peerReview: bool,
    showRubric: bool
  }),

  mock: ({
    attach = true,
    create = true,
    canDelete = true, // Special case because `delete` is a special word
    duplicate = true,
    rate = true,
    read = true,
    readAsAdmin = true,
    readReplies = true,
    reply = true,
    update = true,
    speedGrader = true,
    peerReview = true,
    showRubric = true
  } = {}) => ({
    attach,
    create,
    delete: canDelete,
    duplicate,
    rate,
    read,
    readAsAdmin,
    readReplies,
    reply,
    update,
    speedGrader,
    peerReview,
    showRubric,
    __typename: 'DiscussionPermissions'
  })
}
