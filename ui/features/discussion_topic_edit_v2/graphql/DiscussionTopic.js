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

import {arrayOf, bool, shape, string, number} from 'prop-types'
import {Section} from './Section'
import {gql} from '@apollo/client'
import {Attachment} from './Attachment'
import {GroupSet} from './GroupSet'
import {Assignment} from './Assignment'
import {AssignmentOverride} from './AssignmentOverride'

export const DiscussionTopic = {
  fragment: gql`
    fragment DiscussionTopic on Discussion {
      _id
      id
      title
      message
      requireInitialPost
      podcastEnabled
      podcastHasStudentPosts
      isSectionSpecific
      isAnnouncement
      discussionType
      anonymousState
      allowRating
      todoDate
      onlyGradersCanRate
      delayedPostAt
      lockAt
      locked
      published
      canGroup
      replyToEntryRequiredCount
      expanded
      expandedLocked
      sortOrder
      sortOrderLocked
      visibleToEveryone
      onlyVisibleToOverrides
      isSectionSpecific
      courseSections {
        ...Section
      }
      groupSet {
        ...GroupSet
      }
      attachment {
        ...Attachment
      }
      assignment {
        ...Assignment
      }
      ungradedDiscussionOverrides {
        nodes {
          ...AssignmentOverride
        }
      }
      entryCounts {
        repliesCount
      }
    }
    ${Attachment.fragment}
    ${Assignment.fragment}
    ${Section.fragment}
    ${GroupSet.fragment}
    ${AssignmentOverride.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    title: string,
    message: string,
    requireInitialPost: bool,
    podcastEnabled: bool,
    podcastHasStudentPosts: bool,
    isSectionSpecific: bool,
    isAnnouncement: bool,
    discussionType: string,
    anonymousState: string,
    allowRating: bool,
    todoDate: string,
    onlyGradersCanRate: bool,
    delayedPostAt: string,
    lockAt: string,
    published: bool,
    replyToEntryRequiredCount: number,
    expanded: bool,
    expandedLocked: bool,
    sortOrder: string,
    sortOrderLocked: bool,
    visibleToEveryone: bool,
    onlyVisibleToOverrides: bool,
    courseSections: arrayOf(Section.shape),
    groupSet: GroupSet.shape,
    attachment: Attachment.shape,
    assignment: Assignment.shape,
    canGroup: bool,
    ungradedDiscussionOverrides: AssignmentOverride.shape(),
    entryCounts: shape({
      repliesCount: number,
    }),
  }),

  mock: ({
    _id = '4',
    id = 'A83Ndbd3D9',
    title = 'X-Men Powers Discussion',
    message = 'This is a Discussion Topic Message',
    requireInitialPost = false,
    podcastEnabled = true,
    podcastHasStudentPosts = true,
    isSectionSpecific = false,
    isAnnouncement = false,
    discussionType = 'threaded',
    anonymousState = null,
    allowRating = true,
    todoDate = '2023-08-12T23:59:00-06:00',
    onlyGradersCanRate = false,
    delayedPostAt = null,
    lockAt = null,
    published = true,
    replyToEntryRequiredCount = 1,
    expanded = false,
    expandedLocked = false,
    sortOrder = 'desc',
    sortOrderLocked = false,
    visibleToEveryone = false,
    onlyVisibleToOverrides = false,
    courseSections = [Section.mock()],
    groupSet = GroupSet.mock(),
    attachment = Attachment.mock(),
    assignment = null,
    canGroup = false,
    ungradedDiscussionOverrides = null,
    entryCounts = {repliesCount: 0},
  } = {}) => ({
    _id,
    id,
    title,
    message,
    requireInitialPost,
    podcastEnabled,
    podcastHasStudentPosts,
    isSectionSpecific,
    isAnnouncement,
    anonymousState,
    allowRating,
    todoDate,
    onlyGradersCanRate,
    delayedPostAt,
    lockAt,
    published,
    replyToEntryRequiredCount,
    expanded,
    expandedLocked,
    sortOrder,
    sortOrderLocked,
    visibleToEveryone,
    onlyVisibleToOverrides,
    courseSections,
    groupSet,
    attachment,
    assignment,
    canGroup,
    ungradedDiscussionOverrides,
    __typename: 'Discussion',
    entryCounts,
  }),
}
