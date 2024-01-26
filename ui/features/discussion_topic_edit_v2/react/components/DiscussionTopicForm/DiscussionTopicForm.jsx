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

import React, {useState, useRef, useEffect, useContext} from 'react'
import PropTypes from 'prop-types'
import AnonymousResponseSelector from '@canvas/discussions/react/components/AnonymousResponseSelector/AnonymousResponseSelector'
import {CreateOrEditSetModal} from '@canvas/groups/react/CreateOrEditSetModal'
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'

import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine, IconPublishSolid, IconUnpublishedLine} from '@instructure/ui-icons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import CanvasMultiSelect from '@canvas/multi-select'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {Alert} from '@instructure/ui-alerts'
import {GradedDiscussionOptions} from '../GradedDiscussionOptions/GradedDiscussionOptions'
import {
  GradedDiscussionDueDatesContext,
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  masteryPathsOption,
} from '../../util/constants'
import {AttachmentDisplay} from '@canvas/discussions/react/components/AttachmentDisplay/AttachmentDisplay'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'
import {UsageRightsContainer} from '../../containers/usageRights/UsageRightsContainer'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

import {
  addNewGroupCategoryToCache,
  buildAssignmentOverrides,
  buildDefaultAssignmentOverride,
} from '../../util/utils'

const I18n = useI18nScope('discussion_create')

export default function DiscussionTopicForm({
  isEditing,
  currentDiscussionTopic,
  isStudent,
  assignmentGroups,
  sections,
  groupCategories,
  studentEnrollments,
  onSubmit,
  isGroupContext,
  apolloClient,
}) {
  const rceRef = useRef()
  const {setOnFailure} = useContext(AlertManagerContext)

  const isAnnouncement = ENV.DISCUSSION_TOPIC?.ATTRIBUTES?.is_announcement ?? false
  const isUnpublishedAnnouncement =
    isAnnouncement && !ENV.DISCUSSION_TOPIC?.ATTRIBUTES.course_published
  const isEditingAnnouncement = isAnnouncement && ENV.DISCUSSION_TOPIC?.ATTRIBUTES.id
  const published = currentDiscussionTopic?.published ?? false

  const announcementAlertProps = () => {
    if (isUnpublishedAnnouncement) {
      return {
        id: 'announcement-course-unpublished-alert',
        key: 'announcement-course-unpublished-alert',
        variant: 'warning',
        text: I18n.t(
          'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Delay Posting option and set to publish on a future date.'
        ),
      }
    } else if (isEditingAnnouncement) {
      return {
        id: 'announcement-no-notification-on-edit',
        key: 'announcement-no-notification-on-edit',
        variant: 'info',
        text: I18n.t(
          'Users do not receive updated notifications when editing an announcement. If you wish to have users notified of this update via their notification settings, you will need to create a new announcement.'
        ),
      }
    } else {
      return null
    }
  }

  const allSectionsOption = {id: 'all', name: 'All Sections'}

  const inputWidth = '100%'

  const [title, setTitle] = useState(currentDiscussionTopic?.title || '')
  const [titleValidationMessages, setTitleValidationMessages] = useState([
    {text: '', type: 'success'},
  ])
  const [postToValidationMessages, setPostToValidationMessages] = useState([])

  const [rceContent, setRceContent] = useState(currentDiscussionTopic?.message || '')

  const [sectionIdsToPostTo, setSectionIdsToPostTo] = useState(
    currentDiscussionTopic?.courseSections && currentDiscussionTopic?.courseSections.length > 0
      ? currentDiscussionTopic?.courseSections.map(section => section._id)
      : ['all']
  )

  const [discussionAnonymousState, setDiscussionAnonymousState] = useState(
    currentDiscussionTopic?.anonymousState || 'off'
  )
  // default anonymousAuthorState to true, since it is the default selection for partial anonymity
  // otherwise, it is just ignored anyway
  const [anonymousAuthorState, setAnonymousAuthorState] = useState(
    currentDiscussionTopic?.isAnonymousAuthor || true
  )
  const [requireInitialPost, setRequireInitialPost] = useState(
    currentDiscussionTopic?.requireInitialPost || false
  )
  const [enablePodcastFeed, setEnablePodcastFeed] = useState(
    currentDiscussionTopic?.podcastEnabled || false
  )
  const [includeRepliesInFeed, setIncludeRepliesInFeed] = useState(
    currentDiscussionTopic?.podcastHasStudentPosts || false
  )
  const [isGraded, setIsGraded] = useState(!!currentDiscussionTopic?.assignment || false)
  const [allowLiking, setAllowLiking] = useState(currentDiscussionTopic?.allowRating || false)
  const [onlyGradersCanLike, setOnlyGradersCanLike] = useState(
    currentDiscussionTopic?.onlyGradersCanRate || false
  )
  const [addToTodo, setAddToTodo] = useState(!!currentDiscussionTopic?.todoDate || false)
  const [todoDate, setTodoDate] = useState(currentDiscussionTopic?.todoDate || null)
  const [isGroupDiscussion, setIsGroupDiscussion] = useState(
    !!currentDiscussionTopic?.groupSet || false
  )
  const [groupCategoryId, setGroupCategoryId] = useState(
    currentDiscussionTopic?.groupSet?._id || null
  )
  const [groupCategorySelectError, setGroupCategorySelectError] = useState([])
  const [delayPosting, setDelayPosting] = useState(
    (!!currentDiscussionTopic?.delayedPostAt && isAnnouncement) || false
  )
  const [locked, setLocked] = useState((currentDiscussionTopic.locked && isAnnouncement) || false)

  const [availableFrom, setAvailableFrom] = useState(currentDiscussionTopic?.delayedPostAt || null)
  const [availableUntil, setAvailableUntil] = useState(currentDiscussionTopic?.lockAt || null)
  const [willAnnouncementPostRightAway, setWillAnnouncementPostRightAway] = useState(true)
  const [availabilityValidationMessages, setAvailabilityValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  const [pointsPossible, setPointsPossible] = useState(
    currentDiscussionTopic?.assignment?.pointsPossible || 0
  )
  const [displayGradeAs, setDisplayGradeAs] = useState(
    currentDiscussionTopic?.assignment?.gradingType || 'points'
  )
  const [assignmentGroup, setAssignmentGroup] = useState(
    currentDiscussionTopic?.assignment?.assignmentGroup?._id || ''
  )
  const [peerReviewAssignment, setPeerReviewAssignment] = useState(() => {
    if (currentDiscussionTopic?.assignment?.peerReviews?.enabled) {
      return currentDiscussionTopic?.assignment?.peerReviews?.automaticReviews
        ? 'automatically'
        : 'manually'
    }
    return 'off'
  })

  const [peerReviewsPerStudent, setPeerReviewsPerStudent] = useState(
    currentDiscussionTopic?.assignment?.peerReviews?.count || 1
  )
  const [peerReviewDueDate, setPeerReviewDueDate] = useState(
    currentDiscussionTopic?.assignment?.peerReviews?.dueAt || ''
  )
  const [dueDateErrorMessages, setDueDateErrorMessages] = useState([])
  const [assignedInfoList, setAssignedInfoList] = useState(
    isEditing
      ? buildAssignmentOverrides(currentDiscussionTopic?.assignment)
      : buildDefaultAssignmentOverride()
  )

  const assignmentDueDateContext = {
    assignedInfoList,
    setAssignedInfoList,
    dueDateErrorMessages,
    setDueDateErrorMessages,
    studentEnrollments,
    sections,
    groups:
      groupCategories.find(groupCategory => groupCategory._id === groupCategoryId)?.groupsConnection
        ?.nodes || [],
    groupCategoryId,
  }
  const [showGroupCategoryModal, setShowGroupCategoryModal] = useState(false)

  const [attachment, setAttachment] = useState(currentDiscussionTopic?.attachment || null)
  const [attachmentToUpload, setAttachmentToUpload] = useState(false)
  const affectUserFileQuota = false

  const [usageRightsData, setUsageRightsData] = useState(
    currentDiscussionTopic?.attachment?.usageRights || {}
  )
  const [usageRightsErrorState, setUsageRightsErrorState] = useState(false)

  const [postToSis, setPostToSis] = useState(
    !!currentDiscussionTopic?.assignment?.postToSis || false
  )

  const [gradingSchemeId, setGradingSchemeId] = useState(
    currentDiscussionTopic?.assignment?.gradingStandard?._id || undefined
  )

  const [intraGroupPeerReviews, setIntraGroupPeerReviews] = useState(
    // intra_group_peer_reviews
    !!currentDiscussionTopic?.assignment?.peerReviews?.intraReviews || false
  )

  const handleSettingUsageRightsData = data => {
    setUsageRightsErrorState(false)
    setUsageRightsData(data)
  }

  useEffect(() => {
    if (delayPosting) {
      const rightNow = new Date()
      const availableFromIntoDate = new Date(availableFrom)
      setWillAnnouncementPostRightAway(availableFromIntoDate <= rightNow)
    } else {
      setWillAnnouncementPostRightAway(true)
    }
  }, [availableFrom, delayPosting])

  useEffect(() => {
    if (!isGroupDiscussion) setGroupCategoryId(null)
  }, [isGroupDiscussion])

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

  const validateTitle = newTitle => {
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

  const validateAvailability = (newAvailableFrom, newAvailableUntil) => {
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

  const validateSelectGroup = () => {
    if (!isGroupDiscussion) return true // if not a group discussion, no need to validate
    if (groupCategoryId) return true // if a group category is selected, validated

    // if not a group discussion and no group category is selected, show error
    setGroupCategorySelectError([{text: I18n.t('Please select a group category.'), type: 'error'}])
    return false
  }

  const validateUsageRights = () => {
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

  const validatePostToSections = () => {
    // If the PostTo section is not available, no need to validate
    if (!(!isGraded && !isGroupDiscussion && !isGroupContext)) {
      return true
    }

    if (sectionIdsToPostTo.length === 0) {
      return false
    } else {
      return true
    }
  }

  const validateFormFields = () => {
    let isValid = true

    if (!validateTitle(title)) isValid = false
    if (!validateAvailability(availableFrom, availableUntil)) isValid = false
    if (!validateSelectGroup()) isValid = false
    if (!validateAssignToFields()) isValid = false
    if (!validateUsageRights()) isValid = false
    if (!validatePostToSections()) isValid = false

    return isValid
  }

  const validateAssignToFields = () => {
    // as validation is not required if not graded.
    if (!isGraded) return true

    const missingAssignToOptionError = {
      text: I18n.t('Please select at least one option.'),
      type: 'error',
    }

    // Validate each assignedInfo and collect errors.
    const errors = assignedInfoList.reduce((foundErrors, currentAssignedInfo) => {
      const isAssignedListInvalid =
        !currentAssignedInfo.assignedList ||
        !Array.isArray(currentAssignedInfo.assignedList) ||
        currentAssignedInfo.assignedList.length === 0

      if (isAssignedListInvalid) {
        foundErrors.push({
          dueDateId: currentAssignedInfo.dueDateId,
          message: missingAssignToOptionError,
        })
      }

      const illegalGroupCategoryError = {
        text: I18n.t('Groups can only be part of the actively selected group set.'),
        type: 'error',
      }

      const availableAssetCodes =
        groupCategories
          .find(groupCategory => groupCategory._id === groupCategoryId)
          ?.groupsConnection?.nodes.map(group => `group_${group._id}`) || []

      if (
        currentAssignedInfo.assignedList.filter(assetCode => {
          if (assetCode.includes('group')) {
            return !availableAssetCodes.includes(assetCode)
          } else {
            return false
          }
        }).length > 0
      ) {
        foundErrors.push({
          dueDateId: currentAssignedInfo.dueDateId,
          message: illegalGroupCategoryError,
        })
      }

      return foundErrors
    }, [])

    // If there are errors, set the error state and return false.
    if (errors.length > 0) {
      setDueDateErrorMessages(errors)
      return false
    }

    // All assignedLists are valid if no errors were found.
    return true
  }

  const prepareOverride = (
    overrideDueDate,
    overrideAvailableUntil,
    overrideAvailableFrom,
    overrideIds = {
      groupId: null,
      courseSectionId: null,
      studentIds: null,
      noopId: null,
    },
    overrideTitle = null
  ) => {
    return {
      dueAt: overrideDueDate || null,
      lockAt: overrideAvailableUntil || null,
      unlockAt: overrideAvailableFrom || null,
      groupId: overrideIds.groupIds || null,
      courseSectionId: overrideIds.courseSectionId || null,
      studentIds: overrideIds.studentIds || null,
      noopId: overrideIds.noopId || null,
      title: overrideTitle || null,
    }
  }

  const prepareAssignmentOverridesPayload = () => {
    const onlyVisibleToEveryone = assignedInfoList.every(
      info =>
        info.assignedList.length === 1 && info.assignedList[0] === defaultEveryoneOption.assetCode
    )

    if (onlyVisibleToEveryone) return null

    const preparedOverrides = []
    assignedInfoList.forEach(info => {
      const {assignedList} = info
      const studentIds = assignedList.filter(assetCode => assetCode.includes('user'))
      const sectionIds = assignedList.filter(assetCode => assetCode.includes('section'))
      const groupIds = assignedList.filter(assetCode => assetCode.includes('group'))

      // override for student ids
      if (studentIds.length > 0) {
        preparedOverrides.push(
          prepareOverride(
            info.dueDate || null,
            info.availableUntil || null,
            info.availableFrom || null,
            {
              studentIds:
                studentIds.length > 0 ? studentIds.map(id => id.split('_').reverse()[0]) : null,
            }
          )
        )
      }

      // override for section ids
      if (sectionIds.length > 0) {
        sectionIds.forEach(sectionId => {
          preparedOverrides.push(
            prepareOverride(
              info.dueDate || null,
              info.availableUntil || null,
              info.availableFrom || null,
              {
                courseSectionId: sectionId.split('_').reverse()[0] || null,
              }
            )
          )
        })
      }

      // override for group ids
      if (groupIds.length > 0) {
        groupIds.forEach(groupId => {
          preparedOverrides.push(
            prepareOverride(
              info.dueDate || null,
              info.availableUntil || null,
              info.availableFrom || null,
              {
                groupIds: groupId.split('_').reverse()[0] || null,
              }
            )
          )
        })
      }
    })

    const masteryPathOverride = assignedInfoList.find(info =>
      info.assignedList.includes(masteryPathsOption.assetCode)
    )

    if (masteryPathOverride) {
      preparedOverrides.push(
        prepareOverride(
          masteryPathOverride.dueDate || null,
          masteryPathOverride.availableUntil || null,
          masteryPathOverride.availableFrom || null,
          {
            noopId: '1',
          },
          masteryPathsOption.label
        )
      )
    }

    return preparedOverrides
  }

  const preparePeerReviewPayload = () => {
    return peerReviewAssignment === 'off'
      ? null
      : {
          automaticReviews: peerReviewAssignment === 'automatically',
          count: peerReviewsPerStudent,
          enabled: true,
          dueAt: peerReviewDueDate || null,
          intraReviews: intraGroupPeerReviews,
        }
  }

  const prepareAssignmentPayload = () => {
    // Return null immediately if the assignment is not graded
    if (!isGraded) return null

    const everyoneOverride =
      assignedInfoList.find(
        info =>
          info.assignedList.includes(defaultEveryoneOption.assetCode) ||
          info.assignedList.includes(defaultEveryoneElseOption.assetCode)
      ) || {}

    // Common payload properties for graded assignments
    let payload = {
      pointsPossible,
      postToSis,
      gradingType: displayGradeAs,
      assignmentGroupId: assignmentGroup || null,
      peerReviews: preparePeerReviewPayload(),
      assignmentOverrides: prepareAssignmentOverridesPayload(),
      dueAt: everyoneOverride.dueDate || null,
      lockAt: everyoneOverride.availableUntil || null,
      unlockAt: everyoneOverride.availableFrom || null,
      onlyVisibleToOverrides: assignedInfoList.every(
        info =>
          info.assignedList.length === 1 && info.assignedList[0] === defaultEveryoneOption.assetCode
      ),
      gradingStandardId: gradingSchemeId || null,
    }
    // Additional properties for creation of a graded assignment
    if (!isEditing) {
      payload = {
        ...payload,
        courseId: ENV.context_id,
        name: title,
        groupCategoryId: isGroupDiscussion ? groupCategoryId : null,
      }
    }
    return payload
  }

  const createSubmitPayload = shouldPublish => {
    const payload = {
      // Static payload properties
      title,
      message: rceContent,
      podcastEnabled: enablePodcastFeed,
      podcastHasStudentPosts: includeRepliesInFeed,
      published: shouldPublish,
      isAnnouncement,
      fileId: attachment?._id,
      delayedPostAt: availableFrom,
      lockAt: availableUntil,
      // Conditional payload properties
      assignment: prepareAssignmentPayload(),
      groupCategoryId: isGroupDiscussion ? groupCategoryId : null,
      specificSections: shouldShowPostToSectionOption ? sectionIdsToPostTo.join() : 'all',
      locked: shouldShowAnnouncementOnlyOptions ? locked : false,
      requireInitialPost: !isGroupDiscussion ? requireInitialPost : false,
      todoDate: addToTodo ? todoDate : null,
      allowRating: shouldShowLikingOption ? allowLiking : false,
      onlyGradersCanRate: shouldShowLikingOption ? onlyGradersCanLike : false,
      ...(shouldShowUsageRightsOption && {usageRightsData}),
    }

    // Additional properties for editing mode
    if (isEditing) {
      return {
        ...payload,
        discussionTopicId: currentDiscussionTopic._id,
        published: shouldPublish,
        removeAttachment: !attachment?._id,
      }
    }

    // Properties for creation mode
    return {
      ...payload,
      contextId: ENV.context_id,
      contextType: ENV.context_is_not_group ? 'Course' : 'Group',
      published: shouldPublish,
      isAnonymousAuthor:
        shouldShowAnonymousOptions && discussionAnonymousState !== 'off'
          ? anonymousAuthorState
          : false,
      anonymousState: shouldShowAnonymousOptions ? discussionAnonymousState : 'off',
    }
  }

  const submitForm = shouldPublish => {
    if (validateFormFields()) {
      const payload = createSubmitPayload(shouldPublish)
      onSubmit(payload)
      return true
    }
    return false
  }

  const renderLabelWithPublishStatus = () => {
    const publishStatus = published ? (
      <Text color="success" weight="normal">
        <IconPublishSolid /> {I18n.t('Published')}
      </Text>
    ) : (
      <Text color="secondary" weight="normal">
        <IconUnpublishedLine /> {I18n.t('Not Published')}
      </Text>
    )

    return (
      <Flex justifyItems="space-between">
        <Flex.Item>{I18n.t('Topic Title')}</Flex.Item>
        {!isAnnouncement && <Flex.Item>{publishStatus}</Flex.Item>}
      </Flex>
    )
  }

  const handlePostToSelect = value => {
    if (
      !sectionIdsToPostTo.includes(allSectionsOption.id) &&
      value.includes(allSectionsOption.id)
    ) {
      setSectionIdsToPostTo([allSectionsOption.id])
    } else if (
      sectionIdsToPostTo.includes(allSectionsOption.id) &&
      value.includes(allSectionsOption.id) &&
      value.length > 1
    ) {
      setSectionIdsToPostTo(value.filter(section_id => section_id !== allSectionsOption.id))
    } else {
      setSectionIdsToPostTo(value)
    }

    // Update Error message if no section is selected
    if (value.length === 0) {
      setPostToValidationMessages([{text: 'A section is required', type: 'error'}])
    } else {
      setPostToValidationMessages([])
    }
  }

  return (
    <>
      <FormFieldGroup description="" rowSpacing="small">
        {(isUnpublishedAnnouncement || isEditingAnnouncement) && (
          <Alert variant={announcementAlertProps().variant}>{announcementAlertProps().text}</Alert>
        )}
        <TextInput
          renderLabel={renderLabelWithPublishStatus()}
          type={I18n.t('text')}
          placeholder={I18n.t('Topic Title')}
          value={title}
          onChange={(_event, value) => {
            validateTitle(value)
            const newTitle = value.substring(0, 255)
            setTitle(newTitle)
          }}
          messages={titleValidationMessages}
          autoFocus={true}
          width={inputWidth}
        />
        <CanvasRce
          textareaId="discussion-topic-message-body"
          onFocus={() => {}}
          onBlur={() => {}}
          onInit={() => {}}
          ref={rceRef}
          onContentChange={setRceContent}
          editorOptions={{
            focus: false,
            plugins: [],
          }}
          height={300}
          defaultContent={isEditing ? currentDiscussionTopic?.message : ''}
          autosave={false}
        />
        {ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH && (
          <AttachmentDisplay
            attachment={attachment}
            setAttachment={setAttachment}
            setAttachmentToUpload={setAttachmentToUpload}
            attachmentToUpload={attachmentToUpload}
            responsiveQuerySizes={responsiveQuerySizes}
            isGradedDiscussion={!affectUserFileQuota}
            canAttach={ENV.DISCUSSION_TOPIC?.PERMISSIONS.CAN_ATTACH}
          />
        )}
        {shouldShowPostToSectionOption && (
          <View display="block" padding="medium none">
            <CanvasMultiSelect
              data-testid="section-select"
              label={I18n.t('Post to')}
              messages={postToValidationMessages}
              assistiveText={I18n.t(
                'Select sections to post to. Type or use arrow keys to navigate. Multiple selections are allowed.'
              )}
              selectedOptionIds={sectionIdsToPostTo}
              onChange={handlePostToSelect}
              width={inputWidth}
            >
              {[allSectionsOption, ...sections].map(({id, name: label}) => (
                <CanvasMultiSelect.Option
                  id={id}
                  value={`opt-${id}`}
                  key={id}
                  data-testid={`section-opt-${id}`}
                >
                  {label}
                </CanvasMultiSelect.Option>
              ))}
            </CanvasMultiSelect>
          </View>
        )}
        {shouldShowUsageRightsOption && (
          <Flex justifyItems="start" gap="small">
            <Flex.Item>{I18n.t('Set usage rights')}</Flex.Item>
            <Flex.Item>
              <UsageRightsContainer
                contextType={(ENV?.context_type ?? '').toLocaleLowerCase()}
                contextId={ENV?.context_id}
                onSaveUsageRights={handleSettingUsageRightsData}
                initialUsageRights={usageRightsData}
                errorState={usageRightsErrorState}
              />
            </Flex.Item>
          </Flex>
        )}
        <Text size="large">{I18n.t('Options')}</Text>
        {shouldShowAnonymousOptions && (
          <View display="block" margin="medium 0">
            <RadioInputGroup
              name="anonymous"
              description={I18n.t('Anonymous Discussion')}
              value={discussionAnonymousState}
              onChange={(_event, value) => {
                if (value !== 'off') {
                  setIsGraded(false)
                  setIsGroupDiscussion(false)
                  setGroupCategoryId(null)
                }
                setDiscussionAnonymousState(value)
              }}
              disabled={isEditing || isGraded}
            >
              <RadioInput
                key="off"
                value="off"
                label={I18n.t(
                  'Off: student names and profile pictures will be visible to other members of this course'
                )}
              />
              <RadioInput
                key="partial_anonymity"
                value="partial_anonymity"
                label={I18n.t(
                  'Partial: students can choose to reveal their name and profile picture'
                )}
              />
              <RadioInput
                key="full_anonymity"
                value="full_anonymity"
                label={I18n.t('Full: student names and profile pictures will be hidden')}
              />
            </RadioInputGroup>
            {shouldShowPartialAnonymousSelector && (
              <View display="block" margin="medium 0">
                <AnonymousResponseSelector
                  username={ENV.current_user.display_name}
                  setAnonymousAuthorState={setAnonymousAuthorState}
                  discussionAnonymousState={discussionAnonymousState}
                />
              </View>
            )}
          </View>
        )}
        <FormFieldGroup description="" rowSpacing="small">
          {shouldShowAnnouncementOnlyOptions && (
            <Checkbox
              label={I18n.t('Delay Posting')}
              value="enable-delay-posting"
              checked={delayPosting}
              onChange={() => {
                setDelayPosting(!delayPosting)
                setAvailableFrom(null)
              }}
            />
          )}
          {delayPosting && shouldShowAnnouncementOnlyOptions && (
            <DateTimeInput
              description={I18n.t('Post At')}
              prevMonthLabel={I18n.t('previous')}
              nextMonthLabel={I18n.t('next')}
              onChange={(_event, newDate) => setAvailableFrom(newDate)}
              value={availableFrom}
              invalidDateTimeMessage={I18n.t('Invalid date and time')}
              layout="columns"
              datePlaceholder={I18n.t('Select Date')}
              dateRenderLabel=""
              timeRenderLabel=""
            />
          )}
          {shouldShowAnnouncementOnlyOptions && (
            <Checkbox
              label={I18n.t('Allow Participants to Comment')}
              value="enable-participants-commenting"
              checked={!locked}
              onChange={() => {
                setLocked(!locked)
                setRequireInitialPost(false)
              }}
            />
          )}
          {!isGroupContext && (
            <Checkbox
              data-testid="require-initial-post-checkbox"
              label={I18n.t('Participants must respond to the topic before viewing other replies')}
              value="must-respond-before-viewing-replies"
              checked={requireInitialPost}
              onChange={() => setRequireInitialPost(!requireInitialPost)}
              disabled={!(isAnnouncement === false || (isAnnouncement && !locked))}
            />
          )}

          {shouldShowPodcastFeedOption && (
            <Checkbox
              label={I18n.t('Enable podcast feed')}
              value="enable-podcast-feed"
              checked={enablePodcastFeed}
              onChange={() => {
                setIncludeRepliesInFeed(!enablePodcastFeed && includeRepliesInFeed)
                setEnablePodcastFeed(!enablePodcastFeed)
              }}
            />
          )}
          {enablePodcastFeed && !isGroupContext && (
            <View display="block" padding="none none none large">
              <Checkbox
                label={I18n.t('Include student replies in podcast feed')}
                value="include-student-replies-in-podcast-feed"
                checked={includeRepliesInFeed}
                onChange={() => setIncludeRepliesInFeed(!includeRepliesInFeed)}
              />
            </View>
          )}
          {shouldShowGradedDiscussionOptions && (
            <Checkbox
              data-testid="graded-checkbox"
              label={I18n.t('Graded')}
              value="graded"
              checked={isGraded}
              onChange={() => setIsGraded(!isGraded)}
              // disabled={sectionIdsToPostTo === [allSectionsOption._id]}
            />
          )}
          {shouldShowLikingOption && (
            <>
              <Checkbox
                label={I18n.t('Allow liking')}
                value="allow-liking"
                checked={allowLiking}
                onChange={() => {
                  setOnlyGradersCanLike(!allowLiking && onlyGradersCanLike)
                  setAllowLiking(!allowLiking)
                }}
              />
              {allowLiking && (
                <View display="block" padding="small none none large">
                  <FormFieldGroup description="" rowSpacing="small">
                    <Checkbox
                      label={I18n.t('Only graders can like')}
                      value="only-graders-can-like"
                      checked={onlyGradersCanLike}
                      onChange={() => setOnlyGradersCanLike(!onlyGradersCanLike)}
                    />
                  </FormFieldGroup>
                </View>
              )}
            </>
          )}
          {shouldShowTodoSettings && (
            <>
              <Checkbox
                label={I18n.t('Add to student to-do')}
                value="add-to-student-to-do"
                checked={addToTodo}
                onChange={() => {
                  setTodoDate(!addToTodo ? todoDate : null)
                  setAddToTodo(!addToTodo)
                }}
              />
              {addToTodo && (
                <View
                  display="block"
                  padding="none none none large"
                  data-testid="todo-date-section"
                >
                  <DateTimeInput
                    description=""
                    dateRenderLabel=""
                    timeRenderLabel=""
                    prevMonthLabel={I18n.t('previous')}
                    nextMonthLabel={I18n.t('next')}
                    onChange={(_event, newDate) => setTodoDate(newDate)}
                    value={todoDate}
                    invalidDateTimeMessage={I18n.t('Invalid date and time')}
                    layout="columns"
                  />
                </View>
              )}
            </>
          )}
          {shouldShowGroupOptions && (
            <Checkbox
              data-testid="group-discussion-checkbox"
              label={I18n.t('This is a Group Discussion')}
              value="group-discussion"
              checked={isGroupDiscussion}
              onChange={() => {
                setGroupCategoryId(!isGroupDiscussion ? '' : groupCategoryId)
                setIsGroupDiscussion(!isGroupDiscussion)
              }}
            />
          )}
          {shouldShowGroupOptions && isGroupDiscussion && (
            <View display="block" padding="none none none large">
              <SimpleSelect
                renderLabel={I18n.t('Group Set')}
                defaultValue=""
                value={groupCategoryId}
                onChange={(_event, newChoice) => {
                  const value = newChoice.value
                  if (value === 'new-group-category') {
                    // new group category workflow here
                    setShowGroupCategoryModal(true)
                  } else {
                    setGroupCategoryId(value)
                    setGroupCategorySelectError([])
                  }
                }}
                messages={groupCategorySelectError}
                placeholder={I18n.t('Select a group category')}
                width={inputWidth}
              >
                {groupCategories.map(({_id: id, name: label}) => (
                  <SimpleSelect.Option
                    key={id}
                    id={`opt-${id}`}
                    value={id}
                    data-testid={`group-category-opt-${id}`}
                  >
                    {label}
                  </SimpleSelect.Option>
                ))}
                <SimpleSelect.Option
                  key="new-group-category"
                  id="opt-new-group-category"
                  value="new-group-category"
                  renderBeforeLabel={IconAddLine}
                  data-testid="group-category-opt-new-group-category"
                >
                  {I18n.t('New Group Category')}
                </SimpleSelect.Option>
              </SimpleSelect>

              {showGroupCategoryModal && (
                <CreateOrEditSetModal
                  closed={!showGroupCategoryModal}
                  onDismiss={newGroupCategory => {
                    setShowGroupCategoryModal(false)
                    if (!newGroupCategory) return
                    addNewGroupCategoryToCache(apolloClient.cache, newGroupCategory)
                    setGroupCategoryId(newGroupCategory.id)
                  }}
                  studentSectionCount={sections.length}
                  context={ENV.context_type.toLocaleLowerCase()}
                  contextId={ENV.context_id}
                  allowSelfSignup={ENV.allow_self_signup}
                />
              )}
            </View>
          )}
        </FormFieldGroup>
        {shouldShowAvailabilityOptions &&
          (isGraded ? (
            <View as="div" data-testid="assignment-settings-section">
              <GradedDiscussionDueDatesContext.Provider value={assignmentDueDateContext}>
                <GradedDiscussionOptions
                  assignmentGroups={assignmentGroups}
                  pointsPossible={pointsPossible}
                  setPointsPossible={setPointsPossible}
                  displayGradeAs={displayGradeAs}
                  setDisplayGradeAs={setDisplayGradeAs}
                  assignmentGroup={assignmentGroup}
                  setAssignmentGroup={setAssignmentGroup}
                  peerReviewAssignment={peerReviewAssignment}
                  setPeerReviewAssignment={setPeerReviewAssignment}
                  peerReviewsPerStudent={peerReviewsPerStudent}
                  setPeerReviewsPerStudent={setPeerReviewsPerStudent}
                  peerReviewDueDate={peerReviewDueDate}
                  setPeerReviewDueDate={setPeerReviewDueDate}
                  postToSis={postToSis}
                  setPostToSis={setPostToSis}
                  gradingSchemeId={gradingSchemeId}
                  setGradingSchemeId={setGradingSchemeId}
                  intraGroupPeerReviews={intraGroupPeerReviews}
                  setIntraGroupPeerReviews={setIntraGroupPeerReviews}
                />
              </GradedDiscussionDueDatesContext.Provider>
            </View>
          ) : (
            <FormFieldGroup description="" width={inputWidth}>
              <DateTimeInput
                description={I18n.t('Available from')}
                dateRenderLabel=""
                timeRenderLabel=""
                prevMonthLabel={I18n.t('previous')}
                nextMonthLabel={I18n.t('next')}
                value={availableFrom}
                onChange={(_event, newAvailableFrom) => {
                  validateAvailability(newAvailableFrom, availableUntil)
                  setAvailableFrom(newAvailableFrom)
                }}
                datePlaceholder={I18n.t('Select Date')}
                invalidDateTimeMessage={I18n.t('Invalid date and time')}
                layout="columns"
              />
              <DateTimeInput
                description={I18n.t('Until')}
                dateRenderLabel=""
                timeRenderLabel=""
                prevMonthLabel={I18n.t('previous')}
                nextMonthLabel={I18n.t('next')}
                value={availableUntil}
                onChange={(_event, newAvailableUntil) => {
                  validateAvailability(availableFrom, newAvailableUntil)
                  setAvailableUntil(newAvailableUntil)
                }}
                datePlaceholder={I18n.t('Select Date')}
                invalidDateTimeMessage={I18n.t('Invalid date and time')}
                messages={availabilityValidationMessages}
                layout="columns"
              />
            </FormFieldGroup>
          ))}
        <View
          display="block"
          textAlign="end"
          borderWidth="small none none none"
          margin="xx-large none"
          padding="large none"
        >
          <View margin="0 x-small 0 0">
            <Button
              type="button"
              color="secondary"
              onClick={() => {
                window.location.assign(ENV.CANCEL_TO)
              }}
            >
              {I18n.t('Cancel')}
            </Button>
          </View>
          {shouldShowSaveAndPublishButton && (
            <View margin="0 x-small 0 0">
              <Button
                type="submit"
                onClick={() => submitForm(true)}
                color="secondary"
                margin="xxx-small"
                data-testid="save-and-publish-button"
              >
                {I18n.t('Save and Publish')}
              </Button>
            </View>
          )}
          {/* for announcements, show publish when the available until da */}
          {isAnnouncement ? (
            <Button
              type="submit"
              // we always process announcements as published.
              onClick={() => submitForm(true)}
              color="primary"
              margin="xxx-small"
              data-testid="announcement-submit-button"
            >
              {willAnnouncementPostRightAway ? I18n.t('Publish') : I18n.t('Save')}
            </Button>
          ) : (
            <Button
              type="submit"
              data-testid="save-button"
              // when editing, use the current published state, otherwise:
              // students will always save as published while for moderators in this case they
              // can save as unpublished
              onClick={() =>
                submitForm(isEditing ? published : !ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE)
              }
              color="primary"
            >
              {I18n.t('Save')}
            </Button>
          )}
        </View>
      </FormFieldGroup>
    </>
  )
}

DiscussionTopicForm.propTypes = {
  assignmentGroups: PropTypes.arrayOf(PropTypes.object),
  isEditing: PropTypes.bool,
  currentDiscussionTopic: PropTypes.object,
  isStudent: PropTypes.bool,
  sections: PropTypes.arrayOf(PropTypes.object),
  groupCategories: PropTypes.arrayOf(PropTypes.object),
  studentEnrollments: PropTypes.arrayOf(PropTypes.object),
  onSubmit: PropTypes.func,
  isGroupContext: PropTypes.bool,
  apolloClient: PropTypes.object,
}

DiscussionTopicForm.defaultProps = {
  isEditing: false,
  currentDiscussionTopic: {},
  isStudent: false,
  sections: [],
  groupCategories: [],
  onSubmit: () => {},
}
