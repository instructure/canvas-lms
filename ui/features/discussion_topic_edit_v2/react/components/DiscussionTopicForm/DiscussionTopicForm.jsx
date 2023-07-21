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

import React, {useState, useRef} from 'react'
import PropTypes from 'prop-types'
import AnonymousResponseSelector from '@canvas/discussions/react/components/AnonymousResponseSelector/AnonymousResponseSelector'
import {useScope as usei18NScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import CanvasMultiSelect from '@canvas/multi-select'
import CanvasRce from '@canvas/rce/react/CanvasRce'

const I18N = usei18NScope('discussion_create')

export default function DiscussionTopicForm({isEditing, isStudent, sections, groups, onSubmit}) {
  const [title, setTitle] = useState('')
  const [titleValidationMessages, setTitleValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  const [rceContent, setRceContent] = useState('')

  const [sectionsToPostTo, setSectionsToPostTo] = useState(['all-sections'])

  const [discussionAnonymousState, setDiscussionAnonymousState] = useState('off')
  const [anonymousAuthorState, setAnonymousAuthorState] = useState(false)
  const [respondBeforeReply, setRespondBeforeReply] = useState(false)
  const [enablePodcastFeed, setEnablePodcastFeed] = useState(false)
  const [includeRepliesInFeed, setIncludeRepliesInFeed] = useState(false)
  const [isGraded, setIsGraded] = useState(false)
  const [allowLiking, setAllowLiking] = useState(false)
  const [onlyGradersCanLike, setOnlyGradersCanLike] = useState(false)
  const [addToTodo, setAddToTodo] = useState(false)
  const [todoDate, setTodoDate] = useState(null)
  const [isGroupDiscussion, setIsGroupDiscussion] = useState(false)
  const [groupSet, setGroupSet] = useState(null)

  const [availableFrom, setAvailableFrom] = useState(null)
  const [availableUntil, setAvailableUntil] = useState(null)
  const [availabiltyValidationMessages, setAvailabilityValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  // To be implemented in phase 2, kept as a reminder
  // const [pointsPossible, setPointsPossible] = useState(0)
  // const [displayGradeAs, setDisplayGradeAs] = useState('letter')
  // const [assignmentGroup, setAssignmentGroup] = useState('')
  // const [peerReviewAssignment, setPeerReviewAssignment] = useState('off')
  // const [assignTo, setAssignTo] = useState('')
  // const [dueDate, setDueDate] = useState(0)

  const validateTitle = newTitle => {
    if (newTitle.length > 255) {
      setTitleValidationMessages([
        {text: I18N.t('Title must be less than 255 characters.'), type: 'error'},
      ])
      return false
    } else if (newTitle.length === 0) {
      setTitleValidationMessages([{text: I18N.t('Title must not be empty.'), type: 'error'}])
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
        {text: I18N.t('Date must be after date available.'), type: 'error'},
      ])
      return false
    } else {
      setAvailabilityValidationMessages([{text: '', type: 'success'}])
      return true
    }
  }

  const validateFormFields = () => {
    return validateTitle(title) && validateAvailability(availableFrom, availableUntil)
  }

  const submitForm = shouldPublish => {
    if (validateFormFields()) {
      onSubmit({
        title,
        message: rceContent,
        sectionsToPostTo,
        discussionAnonymousState,
        anonymousAuthorState,
        respondBeforeReply,
        enablePodcastFeed,
        includeRepliesInFeed,
        isGraded,
        allowLiking,
        onlyGradersCanLike,
        addToTodo,
        todoDate,
        isGroupDiscussion,
        groupSet,
        availableFrom,
        availableUntil,
        shouldPublish,
      })
      return true
    }
    return false
  }

  const rceRef = useRef()
  const textAreaId = useRef(`discussion-message-body`)

  const allSectionsOption = {id: 'all-sections', label: 'All Sections'}

  const inputWidth = '50%'

  return (
    <>
      <FormFieldGroup description="" rowSpacing="small">
        <TextInput
          renderLabel={I18N.t('Topic Title')}
          type={I18N.t('text')}
          placeholder={I18N.t('Topic Title')}
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
          textareaId={textAreaId.current}
          onFocus={() => {}}
          onBlur={() => {}}
          onInit={() => {}}
          ref={rceRef}
          onContentChange={content => {
            setRceContent(content)
          }}
          editorOptions={{}}
          height={300}
          defaultContent=""
        />
        {!isGraded && !isGroupDiscussion && (
          <View display="block" padding="medium none">
            <CanvasMultiSelect
              label={I18N.t('Post to')}
              assistiveText={I18N.t(
                'Select sections to post to. Type or use arrow keys to navigate. Multiple selections are allowed.'
              )}
              selectedOptionIds={sectionsToPostTo}
              onChange={value => {
                if (
                  !sectionsToPostTo.includes(allSectionsOption.id) &&
                  value.includes(allSectionsOption.id)
                ) {
                  setSectionsToPostTo([allSectionsOption.id])
                } else {
                  setSectionsToPostTo(value)
                }
              }}
              width={inputWidth}
            >
              {[allSectionsOption, ...sections].map(({id, label}) => (
                <CanvasMultiSelect.Option id={id} value={`opt-${id}`} key={id}>
                  {label}
                </CanvasMultiSelect.Option>
              ))}
            </CanvasMultiSelect>
          </View>
        )}
        <Text size="large">{I18N.t('Options')}</Text>
        <View display="block" margin="medium 0">
          <RadioInputGroup
            name="anonymous"
            description={I18N.t('Anonymous Discussion')}
            value={discussionAnonymousState}
            onChange={(_event, value) => {
              if (value !== 'off') {
                setIsGraded(false)
                setIsGroupDiscussion(false)
                setGroupSet(null)
              }
              setDiscussionAnonymousState(value)
            }}
            disabled={isEditing}
          >
            <RadioInput
              key="off"
              value="off"
              label={I18N.t(
                'Off: student names and profile pictures will be visible to other members of this course'
              )}
            />
            <RadioInput
              key="partial_anonymity"
              value="partial_anonymity"
              label={I18N.t(
                'Partial: students can choose to reveal their name and profile picture'
              )}
            />
            <RadioInput
              key="full_anonymity"
              value="full_anonymity"
              label={I18N.t('Full: student names and profile pictures will be hidden')}
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
        <FormFieldGroup description="" rowSpacing="small">
          <Checkbox
            label={I18N.t('Participants must respond to the topic before viewing other replies')}
            value="must-respond-before-viewing-replies"
            checked={respondBeforeReply}
            onChange={() => setRespondBeforeReply(!respondBeforeReply)}
          />
          <Checkbox
            label={I18N.t('Enable podcast feed')}
            value="enable-podcast-feed"
            checked={enablePodcastFeed}
            onChange={() => {
              setIncludeRepliesInFeed(!enablePodcastFeed && includeRepliesInFeed)
              setEnablePodcastFeed(!enablePodcastFeed)
            }}
          />
          {enablePodcastFeed && (
            <View display="block" padding="none none none large">
              <Checkbox
                label={I18N.t('Include student replies in podcast feed')}
                value="include-student-replies-in-podcast-feed"
                checked={includeRepliesInFeed}
                onChange={() => setIncludeRepliesInFeed(!includeRepliesInFeed)}
              />
            </View>
          )}
          {discussionAnonymousState === 'off' && (
            <Checkbox
              label={I18N.t('Graded')}
              value="graded"
              checked={isGraded}
              onChange={() => setIsGraded(!isGraded)}
            />
          )}
          <Checkbox
            label={I18N.t('Allow liking')}
            value="allow-liking"
            checked={allowLiking}
            onChange={() => {
              setOnlyGradersCanLike(!allowLiking && onlyGradersCanLike)
              setAllowLiking(!allowLiking)
            }}
          />
          {allowLiking && (
            <View display="block" padding="none none none large">
              <FormFieldGroup description="" rowSpacing="small">
                <Checkbox
                  label={I18N.t('Only graders can like')}
                  value="only-graders-can-like"
                  checked={onlyGradersCanLike}
                  onChange={() => setOnlyGradersCanLike(!onlyGradersCanLike)}
                />
              </FormFieldGroup>
            </View>
          )}
          {!isGraded && (
            <Checkbox
              label={I18N.t('Add to student to-do')}
              value="add-to-student-to-do"
              checked={addToTodo}
              onChange={() => {
                setTodoDate(!addToTodo ? todoDate : null)
                setAddToTodo(!addToTodo)
              }}
            />
          )}
          {addToTodo && (
            <View display="block" padding="none none none large">
              <DateTimeInput
                dateRenderLabel=""
                timeRenderLabel=""
                prevMonthLabel={I18N.t('previous')}
                nextMonthLabel={I18N.t('next')}
                onChange={(_event, newDate) => setTodoDate(newDate)}
                value={todoDate}
                invalidDateTimeMessage={I18N.t('Invalid date and time')}
                layout="columns"
              />
            </View>
          )}
          {discussionAnonymousState === 'off' && (
            <Checkbox
              label={I18N.t('This is a Group Discussion')}
              value="group-discussion"
              checked={isGroupDiscussion}
              onChange={() => {
                setGroupSet(!isGroupDiscussion ? '' : groupSet)
                setIsGroupDiscussion(!isGroupDiscussion)
              }}
            />
          )}
          {discussionAnonymousState === 'off' && isGroupDiscussion && (
            <View display="block" padding="none none none large">
              <SimpleSelect
                renderLabel={I18N.t('Group Set')}
                defaultValue=""
                value={groupSet}
                onChange={(_event, newChoice) => {
                  const value = newChoice.value
                  if (value === 'new-group-category') {
                    // new group category workflow here
                    // setGroupSet(the new category)
                  } else {
                    setGroupSet(value)
                  }
                }}
                placeholder={I18N.t('Select Group')}
                width={inputWidth}
              >
                {groups.map(({id, label}) => (
                  <SimpleSelect.Option key={id} id={`opt-${id}`} value={id}>
                    {label}
                  </SimpleSelect.Option>
                ))}
                <SimpleSelect.Option
                  key="new-group-category"
                  id="opt-new-group-category"
                  value="new-group-category"
                  renderBeforeLabel={IconAddLine}
                >
                  New Group Category
                </SimpleSelect.Option>
              </SimpleSelect>
            </View>
          )}
        </FormFieldGroup>
        {isGraded ? (
          <div>Graded options here</div>
        ) : (
          <FormFieldGroup description="" width={inputWidth}>
            <DateTimeInput
              description={I18N.t('Available from')}
              dateRenderLabel=""
              timeRenderLabel=""
              prevMonthLabel={I18N.t('previous')}
              nextMonthLabel={I18N.t('next')}
              value={availableFrom}
              onChange={(_event, newAvailableFrom) => {
                validateAvailability(newAvailableFrom, availableUntil)
                setAvailableFrom(newAvailableFrom)
              }}
              datePlaceholder={I18N.t('Select Date')}
              invalidDateTimeMessage={I18N.t('Invalid date and time')}
              layout="columns"
            />
            <DateTimeInput
              description={I18N.t('Until')}
              dateRenderLabel=""
              timeRenderLabel=""
              prevMonthLabel={I18N.t('previous')}
              nextMonthLabel={I18N.t('next')}
              value={availableUntil}
              onChange={(_event, newAvailableUntil) => {
                validateAvailability(availableFrom, newAvailableUntil)
                setAvailableUntil(newAvailableUntil)
              }}
              datePlaceholder={I18N.t('Select Date')}
              invalidDateTimeMessage={I18N.t('Invalid date and time')}
              messages={availabiltyValidationMessages}
              layout="columns"
            />
          </FormFieldGroup>
        )}
        <View
          display="block"
          textAlign="end"
          borderWidth="small none none none"
          margin="xx-large none"
          padding="large none"
        >
          <Button type="button" color="secondary">
            {I18N.t('Cancel')}
          </Button>
          <Button
            type="submit"
            onClick={() => submitForm(true)}
            color="secondary"
            margin="xxx-small"
          >
            {I18N.t('Save and Publish')}
          </Button>
          <Button type="submit" onClick={() => submitForm(false)} color="primary">
            {I18N.t('Save')}
          </Button>
        </View>
      </FormFieldGroup>
    </>
  )
}

DiscussionTopicForm.propTypes = {
  isEditing: PropTypes.bool,
  isStudent: PropTypes.bool,
  sections: PropTypes.arrayOf(PropTypes.string),
  groups: PropTypes.arrayOf(PropTypes.string),
  onSubmit: PropTypes.func,
}

DiscussionTopicForm.defaultProps = {
  isEditing: false,
  isStudent: false,
  sections: [],
  groups: [],
  onSubmit: () => {},
}
