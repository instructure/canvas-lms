/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as createI18nScope} from '@canvas/i18n'
import DueDateCalendarPicker from '@canvas/due-dates/react/DueDateCalendarPicker'

const I18n = createI18nScope('sections_autocomplete')

interface DiscussionOptions {
  isTopic: boolean
  context_is_not_group: boolean
  react_discussions_post: boolean
  canModerate: boolean
  allow_student_anonymous_discussion_topics: boolean
  anonymousState?: string
  allowAnonymousEdit?: boolean
  is_student?: boolean
  threaded?: boolean
  set_assignment?: boolean
  contextIsCourse?: boolean
  homeroomCourse?: boolean
  showAssignment?: boolean
  isAnnouncement?: boolean
  announcementsLocked?: boolean
  title?: string
  unlocked?: boolean
  model?: any
  podcast_url?: string
  podcast_has_student_posts?: boolean
  allow_rating?: boolean
  only_graders_can_rate?: boolean
  allow_todo_date?: boolean
  require_initial_post?: boolean
  studentTodoAtDateValue?: string
  studentPlannerEnabled?: boolean
  createAnnouncementsUnlocked?: boolean
}

export const DiscussionFormOptions = ({
  options,
  onGradedChange,
  handleStudentTodoUpdate,
}: {
  options: DiscussionOptions
  onGradedChange: (value: boolean) => void
  handleStudentTodoUpdate?: (date: string) => void
}) => {
  return (
    <View as="div" width="100%">
      <Flex direction="column" gap="medium">
        {options.isTopic &&
          options.context_is_not_group &&
          options.react_discussions_post &&
          (options.canModerate || options.allow_student_anonymous_discussion_topics) && (
            <RenderAnonymousSelector options={options} />
          )}
        <Flex.Item>
          <RenderCheckboxes
            options={options}
            onGradedChange={onGradedChange}
            handleStudentTodoUpdate={handleStudentTodoUpdate}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

const RenderAnonymousSelector = ({options}: {options: DiscussionOptions}) => {
  const [value, setValue] = useState(options.anonymousState || 'null')
  return (
    <Flex.Item id="anonymous_selector">
      <>
        <RadioInputGroup
          name="anonymous_state"
          description={
            <>
              <View display="inline-block">
                <Heading level="h4">{I18n.t('Anonymous Discussion')}</Heading>
              </View>
            </>
          }
          value={value}
          disabled={!options.allowAnonymousEdit}
          onChange={(_event, value) => {
            setValue(value)
          }}
          data-testid="anonymous-discussion-options"
        >
          <RadioInput
            key="null"
            value="null"
            inline={true}
            label={I18n.t(
              'Off: student names and profile pictures will be visible to other members of this course',
            )}
          />
          <RadioInput
            id="anonymous-selector-partial-anonymity"
            key="partial_anonymity"
            value="partial_anonymity"
            inline={true}
            label={I18n.t('Partial: students can choose to reveal their name and profile picture')}
          />
          <RadioInput
            id="anonymous-selector-full-anonymity"
            key="full_anonymity"
            value="full_anonymity"
            inline={true}
            label={I18n.t('Full: student names and profile pictures will be hidden')}
          />
        </RadioInputGroup>
        {options.is_student && (
          <View
            id="sections_anonymous_post_selector"
            style={{display: 'none', paddingTop: 'medium'}}
          />
        )}
      </>
    </Flex.Item>
  )
}

const RenderCheckboxes = ({
  options,
  onGradedChange,
  handleStudentTodoUpdate,
}: {
  options: DiscussionOptions
  onGradedChange: (value: boolean) => void
  handleStudentTodoUpdate?: (date: string) => void
}) => {
  const [threaded, setThreaded] = useState(options.threaded || false)
  const [graded, setGraded] = useState(options.set_assignment || false)
  const [isGradedDisabled, setIsGradedDisabled] = useState(false)

  useEffect(() => {
    const handleToggleGraded = (e: CustomEvent<{disabled: boolean}>) => {
      const {disabled} = e.detail
      setIsGradedDisabled(disabled)
    }
    document.addEventListener('toggleGradedCheckBox', handleToggleGraded as EventListener)
    return () => {
      document.removeEventListener('toggleGradedCheckBox', handleToggleGraded as EventListener)
    }
  }, [])

  return (
    <Flex direction="column" gap="x-small">
      {options.isTopic && !options.react_discussions_post && (
        <Flex.Item>
          <Checkbox
            name="threaded"
            label={I18n.t('Allow threaded replies')}
            value="1"
            inline={true}
            checked={threaded}
            onChange={e => setThreaded(e.target.checked)}
          />
        </Flex.Item>
      )}

      {options.contextIsCourse && <RenderAllowUserComments options={options} />}

      {options.canModerate && !options.homeroomCourse && <RenderPodcastEnabled options={options} />}

      {options.showAssignment && (
        <Flex.Item>
          <input name="assignment[set_assignment]" type="hidden" value="0" />
          <Checkbox
            id="use_for_grading"
            name="assignment[set_assignment]"
            label={I18n.t('Graded')}
            value="1"
            inline={true}
            checked={graded}
            disabled={isGradedDisabled}
            onChange={e => {
              const value = e.target.checked
              setGraded(value)
              onGradedChange(value)
            }}
            aria-controls="assignment_options"
          />
        </Flex.Item>
      )}

      {!options.homeroomCourse && <RenderAllowLiking options={options} />}

      {options.isTopic && options.studentPlannerEnabled && !graded && (
        <RenderAllowTodoDate options={options} handleStudentTodoUpdate={handleStudentTodoUpdate} />
      )}
    </Flex>
  )
}

const RenderAllowUserComments = ({options}: {options: DiscussionOptions}) => {
  const [requireInitialPost, setRequireInitialPost] = useState(
    options.require_initial_post || false,
  )
  const [allowUserComments, setAllowUserComments] = useState(
    options.title ? options.unlocked : options.createAnnouncementsUnlocked,
  )

  if (!options.isAnnouncement) {
    return (
      <Flex.Item>
        <input name="require_initial_post" type="hidden" value="0" />
        <Checkbox
          id="require_initial_post"
          name="require_initial_post"
          label={I18n.t('Users must post before seeing replies')}
          value="1"
          inline={true}
          checked={requireInitialPost}
          onChange={e => setRequireInitialPost(e.target.checked)}
        />
      </Flex.Item>
    )
  }

  if (!options.announcementsLocked && !options.homeroomCourse) {
    return (
      <Flex.Item>
        <Flex direction="column" gap="x-small">
          <Flex.Item>
            <input name="allow_user_comments" type="hidden" value="0" />
            <Checkbox
              id="allow_user_comments"
              name="allow_user_comments"
              label={I18n.t('Allow users to comment')}
              value="1"
              inline={true}
              checked={allowUserComments}
              onChange={e => {
                const value = e.target.checked
                options.model.set('locked', !value)
                setAllowUserComments(value)
              }}
            />
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <input name="require_initial_post" type="hidden" value="0" />
            <Checkbox
              id="require_initial_post"
              name="require_initial_post"
              label={I18n.t('Users must post before seeing replies')}
              value="1"
              disabled={!allowUserComments}
              inline={true}
              checked={requireInitialPost}
              onChange={e => setRequireInitialPost(e.target.checked)}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    )
  }
  return null
}

const RenderPodcastEnabled = ({options}: {options: DiscussionOptions}) => {
  const [podcastEnabled, setPodcastEnabled] = useState(!!options.podcast_url?.length)
  const [podcastHasStudentPosts, setPodcastHasStudentPosts] = useState(
    options.podcast_has_student_posts,
  )

  return (
    <Flex direction="column" gap="x-small">
      <Flex.Item>
        <input name="podcast_enabled" type="hidden" value="0" />
        <input name="podcast_has_student_posts" type="hidden" value="0" />
        <Checkbox
          id="checkbox_podcast_enabled"
          name="podcast_enabled"
          label={I18n.t('Enable podcast feed')}
          value="1"
          inline={true}
          checked={podcastEnabled}
          onChange={e => setPodcastEnabled(e.target.checked)}
        />
      </Flex.Item>

      {options.contextIsCourse && podcastEnabled && (
        <Flex.Item margin="0 0 0 small">
          <Checkbox
            name="podcast_has_student_posts"
            label={I18n.t('Include student replies in podcast feed')}
            value="1"
            inline={true}
            checked={podcastHasStudentPosts}
            onChange={e => setPodcastHasStudentPosts(e.target.checked)}
          />
        </Flex.Item>
      )}
    </Flex>
  )
}

const RenderAllowLiking = ({options}: {options: DiscussionOptions}) => {
  const [allowRating, setAllowRating] = useState(options.allow_rating)
  const [onlyGradersCanRate, setOnlyGradersCanRate] = useState(options.only_graders_can_rate)
  return (
    <>
      <Flex.Item>
        <input name="allow_rating" type="hidden" value="0" />
        <input name="only_graders_can_rate" type="hidden" value="0" />
        <Checkbox
          name="allow_rating"
          label={I18n.t('Allow liking')}
          value="1"
          inline={true}
          checked={allowRating}
          onChange={e => setAllowRating(e.target.checked)}
        />
      </Flex.Item>
      {allowRating && (
        <Flex.Item margin="0 0 0 small">
          <Checkbox
            name="only_graders_can_rate"
            label={I18n.t('Only graders can like')}
            value="1"
            inline={true}
            checked={onlyGradersCanRate}
            onChange={e => setOnlyGradersCanRate(e.target.checked)}
          />
        </Flex.Item>
      )}
    </>
  )
}

const RenderAllowTodoDate = ({
  options,
  handleStudentTodoUpdate,
}: {options: DiscussionOptions; handleStudentTodoUpdate?: (date: string) => void}) => {
  const [allowTodoDate, setAllowTodoDate] = useState(options.allow_todo_date)
  const [todoDate, setTodoDate] = useState(options.studentTodoAtDateValue)

  return (
    <>
      <Flex.Item id="todo_options">
        <Checkbox
          id="allow_todo_date"
          name="allow_todo_date"
          label={I18n.t('Add to student planner')}
          value="1"
          inline={true}
          checked={allowTodoDate}
          onChange={e => setAllowTodoDate(e.target.checked)}
          aria-controls="todo_date_input"
        />
      </Flex.Item>
      {allowTodoDate && (
        <Flex.Item margin="0 0 0 medium" id="todo_date_input">
          <DueDateCalendarPicker
            dateType="todo_date"
            name="todo_date"
            handleUpdate={(date: string) => {
              setTodoDate(date)
              handleStudentTodoUpdate?.(date)
            }}
            rowKey="student_todo_at_date"
            labelledBy="student_todo_at_date_label"
            inputClasses=""
            disabled={false}
            isFancyMidnight={true}
            dateValue={todoDate}
            labelText={I18n.t('Discussion Topic will show on student to-do list for date')}
            labelClasses="screenreader-only"
          />
        </Flex.Item>
      )}
    </>
  )
}
