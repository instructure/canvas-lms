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
      manageContent
      manageCourseContentAdd
      manageCourseContentEdit
      manageCourseContentDelete
      readReplies
      reply
      update
      speedGrader
      studentReporting
      peerReview
      showRubric
      addRubric
      openForComments
      closeForComments
      copyAndSendTo
      moderateForum
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
    manageContent: bool,
    manageCourseContentAdd: bool,
    manageCourseContentEdit: bool,
    manageCourseContentDelete: bool,
    readReplies: bool,
    reply: bool,
    update: bool,
    speedGrader: bool,
    studentReporting: bool,
    peerReview: bool,
    showRubric: bool,
    addRubric: bool,
    openForComments: bool,
    closeForComment: bool,
    copyAndSendTo: bool,
    moderateForum: bool,
  }),

  mock: ({
    attach = true,
    create = true,
    canDelete = true, // Special case because `delete` is a special word
    duplicate = true,
    rate = true,
    read = true,
    readAsAdmin = true,
    manageContent = true,
    manageCourseContentAdd = true,
    manageCourseContentEdit = true,
    manageCourseContentDelete = true,
    readReplies = true,
    reply = true,
    update = true,
    speedGrader = true,
    studentReporting = true,
    peerReview = true,
    showRubric = true,
    addRubric = true,
    openForComments = true,
    closeForComments = false,
    copyAndSendTo = true,
    moderateForum = true,
  } = {}) => ({
    attach,
    create,
    delete: canDelete,
    duplicate,
    rate,
    read,
    readAsAdmin,
    manageContent,
    manageCourseContentAdd,
    manageCourseContentEdit,
    manageCourseContentDelete,
    readReplies,
    reply,
    update,
    speedGrader,
    studentReporting,
    peerReview,
    showRubric,
    addRubric,
    openForComments,
    closeForComments,
    copyAndSendTo,
    moderateForum,
    __typename: 'DiscussionPermissions',
  }),
}
