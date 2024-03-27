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
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussion_create')

export const defaultEveryoneOption = {
  assetCode: 'everyone',
  label: I18n.t('Everyone'),
}
export const defaultEveryoneElseOption = {
  assetCode: 'everyone',
  label: I18n.t('Everyone else'),
}

export const masteryPathsOption = {
  assetCode: 'mastery_paths',
  label: I18n.t('Mastery Paths'),
}

const GradedDiscussionDueDateDefaultValues = {
  assignedInfoList: [],
  setAssignedInfoList: () => {},
  studentEnrollments: [],
  sections: [],
  groups: [],
  gradedDiscussionRefMap: new Map(),
  setGradedDiscussionRefMap: () => {},
  pointsPossibleReplyToTopic: 0,
  setPointsPossibleReplyToTopic: () => {},
  pointsPossibleReplyToEntry: 0,
  setPointsPossibleReplyToEntry: () => {},
  replyToEntryRequiredCount: 1,
  setReplyToEntryRequiredCount: () => {},
  setReplyToEntryRequiredRef: () => {},
}

export const GradedDiscussionDueDatesContext = React.createContext(
  GradedDiscussionDueDateDefaultValues
)

export const ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES = {
  ADHOC: 'AdhocStudents',
  SECTION: 'Section',
  GROUP: 'Group',
}

export const minimumReplyToEntryRequiredCount = 1
export const maximumReplyToEntryRequiredCount = 10

export const useShouldShowContent = (
  isGraded,
  isAnnouncement,
  isGroupDiscussion,
  isGroupContext,
  discussionAnonymousState,
  isEditing,
  isStudent,
  published
) => {
  const shouldShowTodoSettings =
    !isGraded &&
    !isAnnouncement &&
    ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MANAGE_CONTENT &&
    ENV.STUDENT_PLANNER_ENABLED

  const shouldShowPostToSectionOption = !isGraded && !isGroupDiscussion && !isGroupContext

  const shouldShowAnonymousOptions =
    !isGroupContext &&
    !isAnnouncement &&
    (ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE ||
      ENV.allow_student_anonymous_discussion_topics)

  const shouldShowAnnouncementOnlyOptions = isAnnouncement && !isGroupContext

  const shouldShowGroupOptions =
    discussionAnonymousState === 'off' &&
    !isAnnouncement &&
    !isGroupContext &&
    ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_SET_GROUP

  const shouldShowGradedDiscussionOptions =
    discussionAnonymousState === 'off' &&
    !isAnnouncement &&
    !isGroupContext &&
    ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT

  const shouldShowUsageRightsOption =
    ENV?.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_ATTACH &&
    ENV?.FEATURES?.usage_rights_discussion_topics &&
    ENV?.USAGE_RIGHTS_REQUIRED &&
    ENV?.PERMISSIONS?.manage_files

  const shouldShowLikingOption = !ENV.K5_HOMEROOM_COURSE

  const shouldShowPartialAnonymousSelector =
    !isEditing && discussionAnonymousState === 'partial_anonymity' && isStudent

  const shouldShowAvailabilityOptions = !isAnnouncement && !isGroupContext

  /* discussion moderators viewing a new or still unpublished discussion */
  const shouldShowSaveAndPublishButton =
    !isAnnouncement && ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE && !published

  const shouldShowPodcastFeedOption =
    ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE && !ENV.K5_HOMEROOM_COURSE

  const shouldShowCheckpointsOptions = isGraded && ENV.DISCUSSION_CHECKPOINTS_ENABLED

  return {
    shouldShowTodoSettings,
    shouldShowPostToSectionOption,
    shouldShowAnonymousOptions,
    shouldShowAnnouncementOnlyOptions,
    shouldShowGroupOptions,
    shouldShowGradedDiscussionOptions,
    shouldShowUsageRightsOption,
    shouldShowLikingOption,
    shouldShowPartialAnonymousSelector,
    shouldShowAvailabilityOptions,
    shouldShowSaveAndPublishButton,
    shouldShowPodcastFeedOption,
    shouldShowCheckpointsOptions,
  }
}
