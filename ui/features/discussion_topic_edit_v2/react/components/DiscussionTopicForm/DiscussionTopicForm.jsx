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

import React, {useState, useRef, useEffect} from 'react'
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
import {GradedDiscussionDueDatesContext} from '../../util/constants'
import {nanoid} from 'nanoid'
import {AttachmentDisplay} from '@canvas/discussions/react/components/AttachmentDisplay/AttachmentDisplay'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'
import {UsageRights} from '../GradedDiscussionOptions/UsageRights'

import {addNewGroupCategoryToCache} from '../../util/utils'

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

  const allSectionsOption = {_id: 'all', name: 'All Sections'}

  const inputWidth = '100%'

  const [title, setTitle] = useState('')
  const [titleValidationMessages, setTitleValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  const [rceContent, setRceContent] = useState('')

  const [sectionIdsToPostTo, setSectionIdsToPostTo] = useState(['all'])

  const [discussionAnonymousState, setDiscussionAnonymousState] = useState('off')
  // default anonymousAuthorState to true, since it is the default selection for partial anonymity
  // otherwise, it is just ignored anyway
  const [anonymousAuthorState, setAnonymousAuthorState] = useState(true)
  const [requireInitialPost, setRequireInitialPost] = useState(false)
  const [enablePodcastFeed, setEnablePodcastFeed] = useState(false)
  const [includeRepliesInFeed, setIncludeRepliesInFeed] = useState(false)
  const [isGraded, setIsGraded] = useState(false)
  const [allowLiking, setAllowLiking] = useState(false)
  const [onlyGradersCanLike, setOnlyGradersCanLike] = useState(false)
  const [addToTodo, setAddToTodo] = useState(false)
  const [todoDate, setTodoDate] = useState(null)
  const [isGroupDiscussion, setIsGroupDiscussion] = useState(false)
  const [groupCategoryId, setGroupCategoryId] = useState(null)
  const [groupCategorySelectError, setGroupCategorySelectError] = useState([])
  const [delayPosting, setDelayPosting] = useState(false)
  const [locked, setLocked] = useState(false)

  const [availableFrom, setAvailableFrom] = useState(null)
  const [availableUntil, setAvailableUntil] = useState(null)
  const [willAnnouncementPostRightAway, setWillAnnouncementPostRightAway] = useState(true)
  const [availabiltyValidationMessages, setAvailabilityValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  // To be implemented in phase 2, kept as a reminder
  const [pointsPossible, setPointsPossible] = useState(0)
  const [displayGradeAs, setDisplayGradeAs] = useState('points')
  const [assignmentGroup, setAssignmentGroup] = useState('')
  const [peerReviewAssignment, setPeerReviewAssignment] = useState('off')
  const [peerReviewsPerStudent, setPeerReviewsPerStudent] = useState(1)
  const [peerReviewDueDate, setPeerReviewDueDate] = useState('')
  // This contains the list of assignment due dates / overrides. This default should be set to everyone in VICE-3866
  const [assignedInfoList, setAssignedInfoList] = useState([{dueDateId: nanoid()}]) // Initialize with one object with a unique id
  const assignmentDueDateContext = {
    assignedInfoList,
    setAssignedInfoList,
    studentEnrollments,
    sections,
  }
  const [showGroupCategoryModal, setShowGroupCategoryModal] = useState(false)

  const [attachment, setAttachment] = useState(null)
  const [attachmentToUpload, setAttachmentToUpload] = useState(false)
  const affectUserFileQuota = false

  const [usageRightsData, setUsageRightsData] = useState({})
  useEffect(() => {
    if (!isEditing || !currentDiscussionTopic) return

    setTitle(currentDiscussionTopic.title)
    setRceContent(currentDiscussionTopic.message)
    const sectionIds =
      currentDiscussionTopic.courseSections && currentDiscussionTopic.courseSections.length > 0
        ? currentDiscussionTopic.courseSections.map(section => section._id)
        : ['all']
    setSectionIdsToPostTo(sectionIds)
    setDiscussionAnonymousState(currentDiscussionTopic.anonymousState || 'off')
    setAnonymousAuthorState(currentDiscussionTopic.isAnonymousAuthor)
    setRequireInitialPost(currentDiscussionTopic.requireInitialPost)
    setEnablePodcastFeed(currentDiscussionTopic.podcastEnabled)
    setIncludeRepliesInFeed(currentDiscussionTopic.podcastHasStudentPosts)

    setAllowLiking(currentDiscussionTopic.allowRating)
    setOnlyGradersCanLike(currentDiscussionTopic.onlyGradersCanRate)
    setAddToTodo(!!currentDiscussionTopic.todoDate)
    setTodoDate(currentDiscussionTopic.todoDate)
    setIsGroupDiscussion(!!currentDiscussionTopic.groupSet)
    setGroupCategoryId(currentDiscussionTopic.groupSet?._id)

    setAvailableFrom(currentDiscussionTopic.delayedPostAt)
    setAvailableUntil(currentDiscussionTopic.lockAt)
    setDelayPosting(!!currentDiscussionTopic.delayedPostAt && isAnnouncement)
    setLocked(currentDiscussionTopic.locked && isAnnouncement)
    setAttachment(currentDiscussionTopic.attachment)
  }, [isEditing, currentDiscussionTopic, discussionAnonymousState, isAnnouncement])

  useEffect(() => {
    if (delayPosting) {
      const rightNow = new Date()
      const availableFromIntoDate = new Date(availableFrom)
      setWillAnnouncementPostRightAway(availableFromIntoDate <= rightNow)
    } else {
      setWillAnnouncementPostRightAway(true)
    }
  }, [availableFrom, delayPosting])

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
    const isFileAttached = false // this is a place holder. will get replaced after VICE-3851 is completed
    if (!ENV?.FEATURES?.usage_rights_discussion_topics || !ENV?.USAGE_RIGHTS_REQUIRED) return true // if usage rights is not enabled, no need to validate
    if (usageRightsData?.selectedUsageRightsOption || !isFileAttached) return true
    console.log('REPLACE WITH ERROR MESSAGE, NEED TO SELECT USAGE RIGHT')
    // if usage rights is not selected, show error
    return false
  }

  const validateFormFields = () => {
    let isValid = true

    if (!validateTitle(title)) isValid = false
    if (!validateAvailability(availableFrom, availableUntil)) isValid = false
    if (!validateSelectGroup()) isValid = false

    if (!validateUsageRights()) isValid = false

    return isValid
  }

  const preparePeerReviewPayload = () => {
    return peerReviewAssignment === 'off'
      ? null
      : {
          automaticReviews: peerReviewAssignment === 'automatically',
          count: peerReviewsPerStudent,
          enabled: true,
          dueAt: peerReviewDueDate || null,
        }
  }

  const prepareAssignmentPayload = () => {
    return isGraded
      ? {
          courseId: ENV.context_id,
          name: title,
          pointsPossible,
          gradingType: displayGradeAs,
          assignmentGroupId: assignmentGroup,
          peerReviews: preparePeerReviewPayload(),
        }
      : null
  }

  const submitForm = shouldPublish => {
    if (validateFormFields()) {
      onSubmit({
        title,
        message: rceContent,
        sectionIdsToPostTo,
        discussionAnonymousState,
        anonymousAuthorState,
        requireInitialPost,
        enablePodcastFeed,
        includeRepliesInFeed,
        isGraded,
        allowLiking,
        onlyGradersCanLike,
        addToTodo,
        todoDate,
        isGroupDiscussion,
        groupCategoryId: isGroupDiscussion ? groupCategoryId : null,
        availableFrom,
        availableUntil,
        shouldPublish,
        locked,
        isAnnouncement,
        assignment: prepareAssignmentPayload(),
        attachment,
      })
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
        {!isAnnouncement && isEditing && <Flex.Item>{publishStatus}</Flex.Item>}
      </Flex>
    )
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
        <AttachmentDisplay
          attachment={attachment}
          setAttachment={setAttachment}
          setAttachmentToUpload={setAttachmentToUpload}
          attachmentToUpload={attachmentToUpload}
          responsiveQuerySizes={responsiveQuerySizes}
          isGradedDiscussion={!affectUserFileQuota}
          canAttach={ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH}
        />
        {!isGraded && !isGroupDiscussion && !isGroupContext && (
          <View display="block" padding="medium none">
            <CanvasMultiSelect
              data-testid="section-select"
              label={I18n.t('Post to')}
              assistiveText={I18n.t(
                'Select sections to post to. Type or use arrow keys to navigate. Multiple selections are allowed.'
              )}
              selectedOptionIds={sectionIdsToPostTo}
              onChange={value => {
                if (
                  !sectionIdsToPostTo.includes(allSectionsOption._id) &&
                  value.includes(allSectionsOption._id)
                ) {
                  setSectionIdsToPostTo([allSectionsOption._id])
                } else if (
                  sectionIdsToPostTo.includes(allSectionsOption._id) &&
                  value.includes(allSectionsOption._id) &&
                  value.length > 1
                ) {
                  setSectionIdsToPostTo(
                    value.filter(section_id => section_id !== allSectionsOption._id)
                  )
                } else {
                  setSectionIdsToPostTo(value)
                }
              }}
              width={inputWidth}
            >
              {[allSectionsOption, ...sections].map(({_id: id, name: label}) => (
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
        {ENV?.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_ATTACH &&
          ENV?.FEATURES?.usage_rights_discussion_topics &&
          ENV?.USAGE_RIGHTS_REQUIRED &&
          ENV?.PERMISSIONS?.manage_files && (
            <Flex justifyItems="start" gap="small">
              <Flex.Item>{I18n.t('Set usage rights')}</Flex.Item>
              <Flex.Item>
                <UsageRights
                  contextType={(ENV?.context_type ?? '').toLocaleLowerCase()}
                  contextId={ENV?.context_id}
                  onSaveUsageRights={setUsageRightsData}
                  currentUsageRights={usageRightsData}
                />
              </Flex.Item>
            </Flex>
          )}
        <Text size="large">{I18n.t('Options')}</Text>
        {!isGroupContext &&
          !isAnnouncement &&
          (ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE ||
            ENV.allow_student_anonymous_discussion_topics) && (
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
              {!isEditing && discussionAnonymousState === 'partial_anonymity' && isStudent && (
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
          {isAnnouncement && !isGroupContext && (
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
          {delayPosting && !isGroupContext && (
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
          {isAnnouncement && !isGroupContext && (
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

          <Checkbox
            label={I18n.t('Enable podcast feed')}
            value="enable-podcast-feed"
            checked={enablePodcastFeed}
            onChange={() => {
              setIncludeRepliesInFeed(!enablePodcastFeed && includeRepliesInFeed)
              setEnablePodcastFeed(!enablePodcastFeed)
            }}
          />
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
          {discussionAnonymousState === 'off' && !isAnnouncement && !isGroupContext && (
            <Checkbox
              label={I18n.t('Graded')}
              value="graded"
              checked={isGraded}
              onChange={() => setIsGraded(!isGraded)}
              // disabled={sectionIdsToPostTo === [allSectionsOption._id]}
            />
          )}
          {!ENV.K5_HOMEROOM_COURSE && (
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
          {!isGraded &&
            !isAnnouncement &&
            ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MANAGE_CONTENT &&
            ENV.STUDENT_PLANNER_ENABLED && (
              <Checkbox
                label={I18n.t('Add to student to-do')}
                value="add-to-student-to-do"
                checked={addToTodo}
                onChange={() => {
                  setTodoDate(!addToTodo ? todoDate : null)
                  setAddToTodo(!addToTodo)
                }}
              />
            )}
          {addToTodo && (
            <View display="block" padding="none none none large" data-testid="todo-date-section">
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
          {discussionAnonymousState === 'off' && !isAnnouncement && !isGroupContext && (
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
          {discussionAnonymousState === 'off' && isGroupDiscussion && !isGroupContext && (
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
        {!isAnnouncement &&
          !isGroupContext &&
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
                messages={availabiltyValidationMessages}
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
          <Button
            type="button"
            color="secondary"
            onClick={() => {
              window.location.assign(ENV.CANCEL_TO)
            }}
          >
            {I18n.t('Cancel')}
          </Button>
          {/* discussion moderators viewing a new or still unpublished discussion */}
          {!isAnnouncement && ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE && !published && (
            <Button
              type="submit"
              onClick={() => submitForm(true)}
              color="secondary"
              margin="xxx-small"
              data-testid="save-and-publish-button"
            >
              {I18n.t('Save and Publish')}
            </Button>
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
