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

import {arrayOf, bool, number, shape, string} from 'prop-types'
import {Assignment} from './Assignment'
import {Section} from './Section'
import {DiscussionPermissions} from './DiscussionPermissions'
import gql from 'graphql-tag'
import {User} from './User'

export const Discussion = {
  fragment: gql`
    fragment Discussion on Discussion {
      id
      _id
      title
      message
      createdAt
      updatedAt
      postedAt
      requireInitialPost
      isSectionSpecific
      discussionType
      allowRating
      onlyGradersCanRate
      delayedPostAt
      subscribed
      published
      canUnpublish
      entryCounts {
        unreadCount
        repliesCount
      }
      author {
        ...User
      }
      editor {
        ...User
      }
      assignment {
        ...Assignment
      }
      permissions {
        ...DiscussionPermissions
      }
      courseSections {
        ...Section
      }
    }
    ${User.fragment}
    ${Assignment.fragment}
    ${DiscussionPermissions.fragment}
    ${Section.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    title: string,
    message: string,
    createdAt: string,
    updatedAt: string,
    postedAt: string,
    requireInitialPost: bool,
    isSectionSpecific: bool,
    discussionType: string,
    allowRating: bool,
    onlyGradersCanRate: bool,
    delayedPostAt: string,
    subscribed: bool,
    published: bool,
    canUnpublish: bool,
    entryCounts: shape({
      unreadCount: number,
      repliesCount: number
    }),
    author: User.shape,
    editor: User.shape,
    assignment: Assignment.shape,
    permissions: DiscussionPermissions.shape,
    courseSections: arrayOf(Section.shape),
    rootEntriesTotalPages: number
  })
}

export const DefaultMocks = {
  Discussion: () => ({
    _id: '1',
    title: 'This is a Title'
  })
}
