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

import {shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const DiscussionEntryDraft = {
  fragment: gql`
    fragment DiscussionEntryDraft on DiscussionEntryDraft {
      _id
      id
      discussionTopicId
      rootEntryId
      discussionEntryId
      message
    }
  `,

  shape: shape({
    _id: string,
    id: string,
    discussionTopicId: string,
    rootEntryId: string,
    discussionEntryId: string,
    message: string,
  }),

  mock: ({
    _id = '1',
    id = '1',
    createdAt = '2021-03-25T13:22:24-06:00',
    updatedAt = '2021-03-25T13:22:24-06:00',
    message = 'Howdy Partner, this is a draft message!',
    discussionTopicId = '5',
    discussionEntryId = '8',
    rootEntryId = null,
  } = {}) => ({
    id,
    _id,
    discussionTopicId,
    discussionEntryId,
    createdAt,
    updatedAt,
    message,
    rootEntryId,
    __typename: 'DiscussionEntryDraft',
  }),
}

export const DefaultMocks = {
  DiscussionEntryDraft: () => ({
    _id: '1',
    id: '1',
    createdAt: '2021-03-25T13:22:24-06:00',
    updatedAt: '2021-03-25T13:22:24-06:00',
    message: 'Howdy Partner, this is a draft message!',
    discussionTopicId: '5',
    discussionEntryId: '8',
    rootEntryId: null,
  }),
}
