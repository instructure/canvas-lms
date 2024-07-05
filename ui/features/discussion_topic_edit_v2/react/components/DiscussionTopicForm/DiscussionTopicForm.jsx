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

import React, {useState, useRef, useEffect, useContext, useCallback} from 'react'
import PropTypes from 'prop-types'
import {CreateOrEditSetModal} from '@canvas/groups/react/CreateOrEditSetModal'
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {
  IconAddLine,
  IconPublishSolid,
  IconUnpublishedLine,
  IconInfoLine,
} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {Tooltip} from '@instructure/ui-tooltip'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import CanvasMultiSelect from '@canvas/multi-select'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {Alert} from '@instructure/ui-alerts'
import theme from '@instructure/canvas-theme'
import {FormControlButtons} from './FormControlButtons'
import {GradedDiscussionOptions} from '../DiscussionOptions/GradedDiscussionOptions'
import {NonGradedDateOptions} from '../DiscussionOptions/NonGradedDateOptions'
import {AnonymousSelector} from '../DiscussionOptions/AnonymousSelector'
import {
  DiscussionDueDatesContext,
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  masteryPathsOption,
  useShouldShowContent,
  REPLY_TO_TOPIC,
  REPLY_TO_ENTRY,
} from '../../util/constants'

import {AttachmentDisplay} from '@canvas/discussions/react/components/AttachmentDisplay/AttachmentDisplay'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'
import {UsageRightsContainer} from '../../containers/usageRights/UsageRightsContainer'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {
  prepareAssignmentPayload,
  prepareCheckpointsPayload,
  prepareUngradedDiscussionOverridesPayload,
} from '../../util/payloadPreparations'
import {validateTitle, validateFormFields} from '../../util/formValidation'

import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'

import {
  addNewGroupCategoryToCache,
  buildAssignmentOverrides,
  buildDefaultAssignmentOverride,
} from '../../util/utils'
import {MissingSectionsWarningModal} from '../MissingSectionsWarningModal/MissingSectionsWarningModal'
import {flushSync} from 'react-dom'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {ItemAssignToTrayWrapper} from '../DiscussionOptions/ItemAssignToTrayWrapper'
import {SendEditNotificationModal} from '../SendEditNotificationModal'
import {Views, DiscussionTopicFormViewSelector} from './DiscussionTopicFormViewSelector'
import {MasteryPathsReactWrapper} from '@canvas/conditional-release-editor/react/MasteryPathsReactWrapper'
import {showPostToSisFlashAlert} from '@canvas/due-dates/util/differentiatedModulesUtil'

const I18n = useI18nScope('discussion_create')

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

export const getAbGuidArray = event => {
  const {data} = event.data

  return Array.isArray(data) ? data : [data]
}

export const isGuidDataValid = event => {
  if (event?.data?.subject !== 'assignment.set_ab_guid') {
    return false
  }

  const abGuidArray = getAbGuidArray(event)

  const regexPattern =
    /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/

  if (abGuidArray.find(abGuid => !regexPattern.test(abGuid))) {
    return false
  }

  return true
}

function DiscussionTopicForm({
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
  isSubmitting,
  setIsSubmitting,
  breakpoints,
}) {
  const rceRef = useRef()
  const textInputRef = useRef()
  const sectionInputRef = useRef()
  const dateInputRef = useRef()
  const groupOptionsRef = useRef()
  const gradedDiscussionRef = useRef()
  const {setOnFailure} = useContext(AlertManagerContext)

  const isAnnouncement = ENV?.DISCUSSION_TOPIC?.ATTRIBUTES?.is_announcement ?? false
  const isUnpublishedAnnouncement =
    isAnnouncement && !ENV.DISCUSSION_TOPIC?.ATTRIBUTES.course_published
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
    } else {
      return null
    }
  }

  const allSectionsOption = {id: 'all', name: 'All Sections'}

  const checkpointsToolTipText = I18n.t(
    'Checkpoints can be set to have different due dates and point values for the initial response and the subsequent replies.'
  )

  const inputWidth = '100%'

  const initialSelectedView = window.location.hash.includes('mastery-paths-editor')
    ? Views.MasteryPaths
    : Views.Details
  const [selectedView, setSelectedView] = useState(initialSelectedView)

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
  const [assignedInfoList, setAssignedInfoList] = useState(
    isEditing ? buildAssignmentOverrides(currentDiscussionTopic) : buildDefaultAssignmentOverride()
  )

  const [gradedDiscussionRefMap, setGradedDiscussionRefMap] = useState(new Map())

  const [importantDates, setImportantDates] = useState(
    currentDiscussionTopic?.assignment?.importantDates || false
  )

  const [abGuid, setAbGuid] = useState(null)

  // Checkpoints states
  const [isCheckpoints, setIsCheckpoints] = useState(
    currentDiscussionTopic?.assignment?.hasSubAssignments || false
  )
  const getCheckpointsPointsPossible = checkpointLabel => {
    const checkpoint = currentDiscussionTopic?.assignment?.checkpoints?.find(
      c => c.tag === checkpointLabel
    )
    return checkpoint ? checkpoint.pointsPossible : 0
  }
  const [pointsPossibleReplyToTopic, setPointsPossibleReplyToTopic] = useState(
    getCheckpointsPointsPossible(REPLY_TO_TOPIC)
  )
  const [pointsPossibleReplyToEntry, setPointsPossibleReplyToEntry] = useState(
    getCheckpointsPointsPossible(REPLY_TO_ENTRY)
  )
  const [replyToEntryRequiredCount, setReplyToEntryRequiredCount] = useState(
    currentDiscussionTopic?.replyToEntryRequiredCount || 1
  )

  const [showGroupCategoryModal, setShowGroupCategoryModal] = useState(false)

  const [attachment, setAttachment] = useState(currentDiscussionTopic?.attachment || null)
  const [attachmentToUpload, setAttachmentToUpload] = useState(false)

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

  const [lastShouldPublish, setLastShouldPublish] = useState(false)
  const [missingSections, setMissingSections] = useState([])
  const [shouldShowMissingSectionsWarning, setShouldShowMissingSectionsWarning] = useState(false)

  const [showEditAnnouncementModal, setShowEditAnnouncementModal] = useState(false)
  const [shouldPublish, setShouldPublish] = useState(false)

  const handleSettingUsageRightsData = data => {
    setUsageRightsErrorState(false)
    setUsageRightsData(data)
  }

  const assignmentDueDateContext = {
    assignedInfoList,
    setAssignedInfoList,
    studentEnrollments,
    sections,
    groups:
      groupCategories.find(groupCategory => groupCategory._id === groupCategoryId)?.groupsConnection
        ?.nodes || [],
    groupCategoryId,
    gradedDiscussionRefMap,
    setGradedDiscussionRefMap,
    pointsPossibleReplyToTopic,
    setPointsPossibleReplyToTopic,
    pointsPossibleReplyToEntry,
    setPointsPossibleReplyToEntry,
    replyToEntryRequiredCount,
    setReplyToEntryRequiredCount,
    title,
    assignmentID: currentDiscussionTopic?.assignment?._id || null,
    importantDates,
    setImportantDates,
    pointsPossible,
    isGraded,
    isCheckpoints,
    postToSis,
  }

  useEffect(() => {
    if (isAnnouncement && availableFrom) {
      const rightNow = new Date()
      const availableFromIntoDate = new Date(availableFrom)
      setWillAnnouncementPostRightAway(availableFromIntoDate <= rightNow)
    } else {
      setWillAnnouncementPostRightAway(true)
    }
  }, [availableFrom, isAnnouncement])

  useEffect(() => {
    if (!isGroupDiscussion) setGroupCategoryId(null)
  }, [isGroupDiscussion])

  const setAbGuidPostMessageListener = event => {
    const validatedAbGuid = isGuidDataValid(event)
    if (validatedAbGuid) {
      setAbGuid(getAbGuidArray(event))
    }
  }

  useEffect(() => {
    window.addEventListener('message', setAbGuidPostMessageListener)

    if (document.querySelector('#assignment_external_tools') && ENV.context_is_not_group) {
      AssignmentExternalTools.attach(
        document.querySelector('#assignment_external_tools'),
        'assignment_edit',
        parseInt(ENV.context_id, 10),
        parseInt(currentDiscussionTopic?.assignment?._id, 10)
      )
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    const assignmentInfo = {
      id: null,
      grading_standard_id: gradingSchemeId,
      grading_type: displayGradeAs,
      points_possible: pointsPossible,
      submission_types: 'discussion_topic',
    }

    window.dispatchEvent(
      new CustomEvent('triggerMasteryPathsUpdateAssignment', {detail: {assignmentInfo}})
    )
  }, [gradingSchemeId, displayGradeAs, pointsPossible, isGraded])

  const {
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
    shouldShowAssignToForUngradedDiscussions,
  } = useShouldShowContent(
    isGraded,
    isAnnouncement,
    isGroupDiscussion,
    isGroupContext,
    discussionAnonymousState,
    isEditing,
    isStudent,
    published
  )

  const canGroupDiscussion = !isEditing || currentDiscussionTopic?.canGroup || false

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
      assignment: prepareAssignmentPayload(
        abGuid,
        isEditing,
        title,
        pointsPossible,
        displayGradeAs,
        assignmentGroup,
        gradingSchemeId,
        isGraded,
        assignedInfoList,
        defaultEveryoneOption,
        defaultEveryoneElseOption,
        postToSis,
        peerReviewAssignment,
        peerReviewsPerStudent,
        peerReviewDueDate,
        intraGroupPeerReviews,
        masteryPathsOption,
        importantDates,
        isCheckpoints,
        currentDiscussionTopic?.assignment
      ),
      checkpoints: prepareCheckpointsPayload(
        assignedInfoList,
        pointsPossibleReplyToTopic,
        pointsPossibleReplyToEntry,
        replyToEntryRequiredCount,
        isCheckpoints
      ),
      groupCategoryId: isGroupDiscussion ? groupCategoryId : null,
      specificSections: shouldShowPostToSectionOption ? sectionIdsToPostTo.join() : 'all',
      locked: shouldShowAnnouncementOnlyOptions ? locked : false,
      // we allow requireInitial posts for group discussions created from the course,
      // just not from discussions created from within the group context directly
      requireInitialPost: ENV.context_is_not_group ? requireInitialPost : false,
      todoDate: addToTodo ? todoDate : null,
      allowRating: shouldShowLikingOption ? allowLiking : false,
      onlyGradersCanRate: shouldShowLikingOption ? onlyGradersCanLike : false,
      ...(shouldShowUsageRightsOption && {usageRightsData}),
    }

    if (
      !isGraded &&
      ENV.FEATURES?.selective_release_ui_api &&
      !isAnnouncement
    ) {
      delete payload.specificSections
      Object.assign(
        payload,
        prepareUngradedDiscussionOverridesPayload(
          assignedInfoList,
          defaultEveryoneOption,
          defaultEveryoneElseOption,
          masteryPathsOption
        )
      )
    }

    const previousAnonymousState = !currentDiscussionTopic?.anonymousState
      ? 'off'
      : currentDiscussionTopic.anonymousState

    // Additional properties for editing mode
    if (isEditing) {
      const editingPayload = {
        ...payload,
        discussionTopicId: currentDiscussionTopic._id,
        published: shouldPublish,
        removeAttachment: !attachment?._id,
        ...(previousAnonymousState !== discussionAnonymousState && {
          anonymousState: discussionAnonymousState,
        }),
      }

      if (currentDiscussionTopic?.assignment?.hasSubAssignments && isGraded) {
        editingPayload.setCheckpoints = isCheckpoints
      }

      return editingPayload
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

  const continueSubmitForm = (shouldPublish, shouldNotifyUsers = false) => {
    setTimeout(() => {
      setIsSubmitting(true)
    }, 0)

    if (
      validateFormFields(
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
        assignedInfoList,
        postToSis,
        showPostToSisFlashAlert('manage-assign-to')
      )
    ) {
      const payload = createSubmitPayload(shouldPublish)
      onSubmit(payload, shouldNotifyUsers)
      return true
    }

    setTimeout(() => {
      setIsSubmitting(false)
    }, 0)

    return false
  }

  const submitForm = (shouldPublish, shouldNotifyUsers = false) => {
    if (shouldShowAvailabilityOptions) {
      const selectedAssignedTo = assignedInfoList.map(info => info.assignedList).flatMap(x => x)
      const isEveryoneOrEveryoneElseSelected = selectedAssignedTo.some(
        assignedTo =>
          assignedTo === defaultEveryoneOption.assetCode ||
          assignedTo === defaultEveryoneElseOption.assetCode
      )

      if (!isEveryoneOrEveryoneElseSelected) {
        const selectedSectionIds = selectedAssignedTo
          .filter(assignedTo => String(assignedTo).startsWith('course_section_'))
          .map(assignedTo => assignedTo.split('_')[2])

        const missingSectionObjs = sections.filter(
          section => !selectedSectionIds.includes(section.id)
        )

        if (missingSectionObjs.length > 0 && isGraded) {
          setLastShouldPublish(shouldPublish)
          setMissingSections(missingSectionObjs)
          setShouldShowMissingSectionsWarning(true)

          return false
        }
      }
    }

    return continueSubmitForm(shouldPublish, shouldNotifyUsers)
  }

  const renderLabelWithPublishStatus = () => {
    if (instUINavEnabled()) {
      return <></>
    }

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

  const closeMissingSectionsWarningModal = () => {
    // If we don't do this, the focus will not go to the correct field if there is a validation error.
    flushSync(() => {
      setShouldShowMissingSectionsWarning(false)
      setMissingSections([])
    })
  }

  const renderAvailabilityOptions = useCallback(() => {
    if (isGraded && !isAnnouncement) {
      return (
        <View as="div" data-testid="assignment-settings-section">
          <DiscussionDueDatesContext.Provider value={assignmentDueDateContext}>
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
              isCheckpoints={isCheckpoints && ENV.DISCUSSION_CHECKPOINTS_ENABLED}
              canManageAssignTo={ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MANAGE_ASSIGN_TO_GRADED}
            />
          </DiscussionDueDatesContext.Provider>
        </View>
      )
    } else if (shouldShowAssignToForUngradedDiscussions && !isGroupDiscussion) {
      return (
        <View as="div" data-testid="assignment-settings-section">
          <Text weight="bold">{I18n.t('Assign Access')}</Text>
          <DiscussionDueDatesContext.Provider value={assignmentDueDateContext}>
            <ItemAssignToTrayWrapper />
          </DiscussionDueDatesContext.Provider>
        </View>
      )
    } else {
      return (
        <View as="div" data-testid="non-graded-date-options">
          <NonGradedDateOptions
            availableFrom={availableFrom}
            setAvailableFrom={setAvailableFrom}
            availableUntil={availableUntil}
            setAvailableUntil={setAvailableUntil}
            isGraded={isGraded}
            setAvailabilityValidationMessages={setAvailabilityValidationMessages}
            availabilityValidationMessages={availabilityValidationMessages}
            inputWidth={inputWidth}
            setDateInputRef={ref => {
              dateInputRef.current = ref
            }}
          />
        </View>
      )
    }
  }, [
    assignmentDueDateContext,
    assignmentGroup,
    assignmentGroups,
    availabilityValidationMessages,
    availableFrom,
    availableUntil,
    displayGradeAs,
    gradingSchemeId,
    intraGroupPeerReviews,
    isAnnouncement,
    isCheckpoints,
    isGraded,
    peerReviewAssignment,
    peerReviewDueDate,
    peerReviewsPerStudent,
    pointsPossible,
    postToSis,
    shouldShowAssignToForUngradedDiscussions,
  ])

  return (
    <>
      <DiscussionTopicFormViewSelector
        selectedView={selectedView}
        setSelectedView={setSelectedView}
        breakpoints={breakpoints}
        shouldMasteryPathsBeVisible={ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && !isAnnouncement}
        shouldMasteryPathsBeEnabled={isGraded}
      />
      <div style={{display: selectedView === Views.Details ? 'block' : 'none'}}>
        <FormFieldGroup description="" rowSpacing="small">
          {isUnpublishedAnnouncement && (
            <Alert variant={announcementAlertProps().variant}>
              {announcementAlertProps().text}
            </Alert>
          )}
          <TextInput
            renderLabel={renderLabelWithPublishStatus()}
            type={I18n.t('text')}
            placeholder={I18n.t('Topic Title')}
            value={title}
            ref={textInputRef}
            onChange={(_event, value) => {
              validateTitle(value, setTitleValidationMessages)
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
            resourceType={isAnnouncement ? 'announcement.body' : 'discussion_topic.body'}
            resourceId={currentDiscussionTopic?._id}
          />
          {ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH && (
            <AttachmentDisplay
              attachment={attachment}
              setAttachment={setAttachment}
              setAttachmentToUpload={setAttachmentToUpload}
              attachmentToUpload={attachmentToUpload}
              responsiveQuerySizes={responsiveQuerySizes}
              checkContextQuota={true}
              canAttach={ENV.DISCUSSION_TOPIC?.PERMISSIONS.CAN_ATTACH}
            />
          )}
          {shouldShowPostToSectionOption && !shouldShowAssignToForUngradedDiscussions && (
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
                setInputRef={ref => {
                  sectionInputRef.current = ref
                }}
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
            <AnonymousSelector
              discussionAnonymousState={discussionAnonymousState}
              setDiscussionAnonymousState={setDiscussionAnonymousState}
              isSelectDisabled={
                (isEditing && currentDiscussionTopic?.entryCounts?.repliesCount) || isGraded
              }
              setIsGraded={setIsGraded}
              setIsGroupDiscussion={setIsGroupDiscussion}
              setGroupCategoryId={setGroupCategoryId}
              shouldShowPartialAnonymousSelector={shouldShowPartialAnonymousSelector}
              setAnonymousAuthorState={setAnonymousAuthorState}
            />
          )}
          <FormFieldGroup description="" rowSpacing="small">
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
                label={I18n.t(
                  'Participants must respond to the topic before viewing other replies'
                )}
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
                onChange={() => {
                  if (isGraded) {
                    setIsCheckpoints(false)
                  }
                  setIsGraded(!isGraded)
                }}
                // disabled={sectionIdsToPostTo === [allSectionsOption._id]}
              />
            )}
            {shouldShowCheckpointsOptions && (
              <>
                <View display="inline-block">
                  <Checkbox
                    data-testid="checkpoints-checkbox"
                    label={I18n.t('Assign graded checkpoints')}
                    value="checkpoints"
                    checked={isCheckpoints}
                    onChange={() => setIsCheckpoints(!isCheckpoints)}
                  />
                </View>
                <Tooltip renderTip={checkpointsToolTipText} on={['hover', 'focus']} color="primary">
                  <div
                    style={{display: 'inline-block', marginLeft: theme.spacing.xxSmall}}
                    // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
                    tabIndex="0"
                  >
                    <IconInfoLine />
                    <ScreenReaderContent>{checkpointsToolTipText}</ScreenReaderContent>
                  </div>
                </Tooltip>
              </>
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
                    margin="small 0 0 0"
                  >
                    <DateTimeInput
                      timezone={ENV.TIMEZONE}
                      description=""
                      dateRenderLabel={I18n.t('Date')}
                      timeRenderLabel={I18n.t('Time')}
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
                disabled={!canGroupDiscussion}
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
                  disabled={!canGroupDiscussion}
                  inputRef={ref => {
                    groupOptionsRef.current = ref
                  }}
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
            {!canGroupDiscussion && isEditing && (
              <View display="block" data-testid="group-category-not-editable">
                <Alert variant="warning" margin="small none small none">
                  {I18n.t(
                    'Students have already submitted to this discussion, so group settings cannot be changed.'
                  )}
                </Alert>
              </View>
            )}
          </FormFieldGroup>
          {discussionAnonymousState.includes('anonymity') && !isEditing && (
            <View width="580px" display="block" data-testid="groups_grading_not_allowed">
              <Alert variant="info" margin="small">
                {I18n.t('Grading and Groups are not supported in Anonymous Discussions.')}
              </Alert>
            </View>
          )}
          {shouldShowAvailabilityOptions && renderAvailabilityOptions()}
          {(!isAnnouncement || !ENV.ASSIGNMENT_EDIT_PLACEMENT_NOT_ON_ANNOUNCEMENTS) &&
            ENV.context_is_not_group && (
              <div id="assignment_external_tools" data-testid="assignment-external-tools" />
            )}
        </FormFieldGroup>
      </div>
      <div style={{display: selectedView === Views.MasteryPaths ? 'block' : 'none'}}>
        {ENV.CONDITIONAL_RELEASE_ENV && (
          <MasteryPathsReactWrapper
            type="discussion topic"
            env={ENV.CONDITIONAL_RELEASE_ENV}
          />
        )}
      </div>
      <FormFieldGroup description="" rowSpacing="small">
        <FormControlButtons
          isAnnouncement={isAnnouncement}
          isEditing={isEditing}
          published={published}
          shouldShowSaveAndPublishButton={shouldShowSaveAndPublishButton}
          submitForm={publish => {
            if (isAnnouncement && isEditing && willAnnouncementPostRightAway) {
              // remember publish value for SendEditNotificationModal later
              setShowEditAnnouncementModal(true)
              setShouldPublish(publish)
            } else {
              submitForm(publish)
            }
          }}
          isSubmitting={isSubmitting}
          willAnnouncementPostRightAway={willAnnouncementPostRightAway}
        />
      </FormFieldGroup>
      {shouldShowMissingSectionsWarning && (
        <MissingSectionsWarningModal
          sections={missingSections}
          onClose={closeMissingSectionsWarningModal}
          onContinue={() => {
            closeMissingSectionsWarningModal()
            continueSubmitForm(lastShouldPublish)
          }}
        />
      )}
      {showEditAnnouncementModal && (
        <SendEditNotificationModal
          onClose={() => setShowEditAnnouncementModal(false)}
          submitForm={shouldNotify => {
            submitForm(shouldPublish, shouldNotify)
          }}
        />
      )}
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
  isSubmitting: PropTypes.bool,
  setIsSubmitting: PropTypes.func,
  breakpoints: breakpointsShape,
}

DiscussionTopicForm.defaultProps = {
  isEditing: false,
  currentDiscussionTopic: {},
  isStudent: false,
  sections: [],
  groupCategories: [],
  onSubmit: () => {},
  isSubmitting: false,
  setIsSubmitting: () => {},
}

export default WithBreakpoints(DiscussionTopicForm)
