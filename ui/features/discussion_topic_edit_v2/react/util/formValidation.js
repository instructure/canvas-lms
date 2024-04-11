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

import {useScope as useI18nScope} from '@canvas/i18n'

import {minimumReplyToEntryRequiredCount, maximumReplyToEntryRequiredCount} from './constants'

const I18n = useI18nScope('discussion_create')

export const validateTitle = (newTitle, setTitleValidationMessages) => {
  if (newTitle.length > 255) {
    setTitleValidationMessages([
      {text: I18n.t('Title must be less than 255 characters.'), type: 'error'},
    ])
    return false
  } else if (newTitle.length === 0) {
    setTitleValidationMessages([{text: I18n.t('Title must not be empty.'), type: 'error'}])
    return false
  } else {
    setTitleValidationMessages([{text: '', type: 'success'}])
    return true
  }
}

export const validateAvailability = (
  newAvailableFrom,
  newAvailableUntil,
  isGraded,
  setAvailabilityValidationMessages
) => {
  if (isGraded) {
    return true
  }

  if (newAvailableFrom === null || newAvailableUntil === null) {
    setAvailabilityValidationMessages([{text: '', type: 'success'}])
    return true
  } else if (newAvailableUntil < newAvailableFrom) {
    setAvailabilityValidationMessages([
      {text: I18n.t('Date must be after date available.'), type: 'error'},
    ])
    return false
  } else {
    setAvailabilityValidationMessages([{text: '', type: 'success'}])
    return true
  }
}

const validateSelectGroup = (isGroupDiscussion, groupCategoryId, setGroupCategorySelectError) => {
  if (!isGroupDiscussion) return true // if not a group discussion, no need to validate
  if (groupCategoryId) return true // if a group category is selected, validated

  // if not a group discussion and no group category is selected, show error
  setGroupCategorySelectError([{text: I18n.t('Please select a group category.'), type: 'error'}])
  return false
}

const validateUsageRights = (
  attachment,
  usageRightsData,
  setUsageRightsErrorState,
  setOnFailure
) => {
  // if usage rights is not enabled or there are no attachments, there is no need to validate
  if (
    !ENV?.FEATURES?.usage_rights_discussion_topics ||
    !ENV?.USAGE_RIGHTS_REQUIRED ||
    !attachment
  ) {
    return true
  }

  if (usageRightsData?.useJustification) return true
  setOnFailure(I18n.t('You must set usage rights'))
  setUsageRightsErrorState(true)
  return false
}

const validatePostToSections = (shouldShowPostToSectionOption, sectionIdsToPostTo) => {
  // If the PostTo section is not available, no need to validate
  if (!shouldShowPostToSectionOption) {
    return true
  }

  if (sectionIdsToPostTo.length === 0) {
    return false
  } else {
    return true
  }
}

const validateGradedDiscussionFields = (gradedDiscussionRefMap, gradedDiscussionRef, isGraded) => {
  if (!isGraded) {
    return true
  }

  for (const refMap of gradedDiscussionRefMap.values()) {
    for (const value of Object.values(refMap)) {
      if (value !== null) {
        gradedDiscussionRef.current = value.current
        return false
      }
    }
  }
  gradedDiscussionRef.current = null
  return true
}

const validateReplyToEntryRequiredCount = (isCheckpoints, replyToEntryRequiredCount) => {
  if (!isCheckpoints) {
    return true
  }
  return (
    replyToEntryRequiredCount >= minimumReplyToEntryRequiredCount &&
    replyToEntryRequiredCount <= maximumReplyToEntryRequiredCount
  )
}

export const validateFormFields = (
  title,
  availableFrom,
  availableUntil,
  isGraded,
  textInputRef,
  sectionInputRef,
  groupOptionsRef,
  dateInputRef,
  gradedDiscussionRef,
  gradedDiscussionRefMap,
  attachment,
  usageRightsData,
  setUsageRightsErrorState,
  setOnFailure,
  isGroupDiscussion,
  groupCategoryId,
  setGroupCategorySelectError,
  setTitleValidationMessages,
  setAvailabilityValidationMessages,
  shouldShowPostToSectionOption,
  sectionIdsToPostTo,
  isCheckpoints,
  replyToEntryRequiredCount,
  replyToEntryRequiredRef
) => {
  let isValid = true

  const validationRefs = [
    {
      validationFunction: validateTitle(title, setTitleValidationMessages),
      ref: textInputRef.current,
    },
    {
      validationFunction: validatePostToSections(shouldShowPostToSectionOption, sectionIdsToPostTo),
      ref: sectionInputRef.current,
    },
    {
      validationFunction: validateSelectGroup(
        isGroupDiscussion,
        groupCategoryId,
        setGroupCategorySelectError
      ),
      ref: groupOptionsRef.current,
    },
    {
      validationFunction: validateAvailability(
        availableFrom,
        availableUntil,
        isGraded,
        setAvailabilityValidationMessages
      ),
      ref: dateInputRef.current,
    },
    {
      validationFunction: validateGradedDiscussionFields(
        gradedDiscussionRefMap,
        gradedDiscussionRef,
        isGraded
      ),
      ref: gradedDiscussionRef.current,
    },
    {
      validationFunction: validateReplyToEntryRequiredCount(
        isCheckpoints,
        replyToEntryRequiredCount
      ),
      ref: replyToEntryRequiredRef.current,
    },
    {
      validationFunction: validateUsageRights(
        attachment,
        usageRightsData,
        setUsageRightsErrorState,
        setOnFailure
      ),
      ref: null,
    },
  ]

  const inValidFields = []

  validationRefs.forEach(({validationFunction, ref}) => {
    if (!validationFunction) {
      if (ref) inValidFields.push(ref)
      isValid = false
    }
  })

  inValidFields[0]?.focus()

  return isValid
}
