/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import '@canvas/grading-standards'
import ready from '@instructure/ready'
import DiscussionTopic from '@canvas/discussions/backbone/models/DiscussionTopic'
import Announcement from '@canvas/discussions/backbone/models/Announcement'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import EditView from './backbone/views/EditView'
import OverrideView from '@canvas/due-dates'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import splitAssetString from '@canvas/util/splitAssetString'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import SectionsAutocomplete from './react/SectionsAutocomplete'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {AnonymousPostSelector} from './react/AnonymousPostSelector/AnonymousPostSelector'

const I18n = useI18nScope('discussions')

const isAnnouncement =
  ENV.DISCUSSION_TOPIC.ATTRIBUTES != null
    ? ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement
    : undefined
const isUnpublishedAnnouncement =
  isAnnouncement && !ENV.DISCUSSION_TOPIC.ATTRIBUTES.course_published
const isEditingAnnouncement = isAnnouncement && ENV.DISCUSSION_TOPIC.ATTRIBUTES.id
const model = new (isAnnouncement ? Announcement : DiscussionTopic)(
  ENV.DISCUSSION_TOPIC.ATTRIBUTES,
  {parse: true}
)
model.urlRoot = ENV.DISCUSSION_TOPIC.URL_ROOT
const assignment = model.get('assignment')

const announcementsLocked = ENV.ANNOUNCEMENTS_LOCKED
const sectionList = new SectionCollection(ENV.SECTION_LIST)
const dueDateList = new DueDateList(assignment.get('assignment_overrides'), sectionList, assignment)

const [contextType] = splitAssetString(ENV.context_asset_string)

function renderSectionsAutocomplete(view) {
  if (sectionSpecificEnabled()) {
    const container = document.querySelector('#sections_autocomplete_root')
    if (container) {
      const gcs = view.groupCategorySelector
      const isGradedDiscussion = view.gradedChecked()
      const isGroupDiscussion = gcs !== undefined ? gcs.groupDiscussionChecked() : false
      const enableDiscussionOptions = () => {
        view.enableGradedCheckBox()
        if (gcs !== undefined) {
          view.groupCategorySelector.enableGroupDiscussionCheckbox()
        }
      }
      const disableDiscussionOptions = () => {
        view.disableGradedCheckBox()
        if (gcs !== undefined) {
          view.groupCategorySelector.disableGroupDiscussionCheckbox()
        }
      }

      const sectionsAreDisabled = isGradedDiscussion || isGroupDiscussion
      ReactDOM.render(
        <SectionsAutocomplete
          selectedSections={ENV.SELECTED_SECTION_LIST}
          disabled={sectionsAreDisabled}
          disableDiscussionOptions={disableDiscussionOptions}
          enableDiscussionOptions={enableDiscussionOptions}
          sections={ENV.SECTION_LIST}
        />,
        container
      )
    }
  }
}

function sectionSpecificEnabled() {
  if (!ENV.context_asset_string.startsWith('course')) {
    return false
  }

  return isAnnouncement || ENV.SECTION_SPECIFIC_DISCUSSIONS_ENABLED
}

ready(() => {
  const lockManager = new LockManager()
  lockManager.init({itemType: 'discussion_topic', page: 'edit'})

  const lockedItems = lockManager.isChildContent() ? lockManager.getItemLocks() : {}

  const view = new EditView({
    model,
    permissions: ENV.DISCUSSION_TOPIC.PERMISSIONS,
    contextType,
    views: {
      'js-assignment-overrides': new OverrideView({
        model: dueDateList,
        views: {},
        dueDatesReadonly: !!lockedItems.due_dates,
        availabilityDatesReadonly: !!lockedItems.availability_dates,
        inPacedCourse: model.get('in_paced_course'),
        isModuleItem: ENV.IS_MODULE_ITEM,
        courseId: assignment.courseID(),
      }),
    },
    lockedItems: model.id ? lockedItems : {}, // if no id, creating a new discussion
    announcementsLocked,
    homeroomCourse: window.ENV.K5_HOMEROOM_COURSE,
    isEditing: model.id,
    anonymousState: ENV.DISCUSSION_TOPIC.ATTRIBUTES.anonymous_state,
    react_discussions_post: ENV.REACT_DISCUSSIONS_POST,
    allow_student_anonymous_discussion_topics: ENV.allow_student_anonymous_discussion_topics,
    context_is_not_group: ENV.context_is_not_group,
    is_student: ENV.current_user_is_student,
  })
  view.setRenderSectionsAutocomplete(() => renderSectionsAutocomplete(view))

  if (
    contextType === 'courses' &&
    !isAnnouncement &&
    ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT
  ) {
    const agc = new AssignmentGroupCollection()
    agc.options.params = {}
    agc.contextAssetString = ENV.context_asset_string
    view.assignmentGroupCollection = agc
  }

  view.render().$el.appendTo('#content')

  if (isUnpublishedAnnouncement || isEditingAnnouncement) {
    const alertProps = isUnpublishedAnnouncement
      ? {
          id: 'announcement-course-unpublished-alert',
          key: 'announcement-course-unpublished-alert',
          variant: 'warning',
          text: I18n.t(
            'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Delay Posting option and set to publish on a future date.'
          ),
        }
      : {
          id: 'announcement-no-notification-on-edit',
          key: 'announcement-no-notification-on-edit',
          variant: 'info',
          text: I18n.t(
            'Users do not receive updated notifications when editing an announcement. If you wish to have users notified of this update via their notification settings, you will need to create a new announcement.'
          ),
        }
    ReactDOM.render(
      <View display="block" id={alertProps.id} key={alertProps.key}>
        <Alert variant={alertProps.variant}>{alertProps.text}</Alert>
      </View>,
      document.querySelector('#announcement-alert-holder')
    )
  }

  document.querySelector('#discussion-title').focus()

  setTimeout(() => renderSectionsAutocomplete(view))

  setTimeout(() => {
    const groupsNotAllowedRoot = document.querySelector('#sections_groups_not_allowed_root')
    const anonymousPostSelector = document.querySelector('#sections_anonymous_post_selector')

    const radioButtons = document.querySelectorAll('input[name=anonymous_state]')
    radioButtons.forEach(radioButton => {
      radioButton.addEventListener('change', () => {
        const anonymousState = document.querySelector('input[name=anonymous_state]:checked').value
        const hasGroupCategory = document.querySelector(
          'input[name=has_group_category][type=checkbox]'
        )
        const isPartiallyAnonymous = anonymousState === 'partial_anonymity'
        const isFullyAnonymous = anonymousState === 'full_anonymity'
        const isAnonymous = isPartiallyAnonymous || isFullyAnonymous

        document.querySelector('#group_category_options').hidden = isAnonymous
        groupsNotAllowedRoot.style.display = isAnonymous ? 'inline' : 'none'

        if (isAnonymous && hasGroupCategory) {
          hasGroupCategory.checked = false
        }

        if (anonymousPostSelector) {
          anonymousPostSelector.style.display = isPartiallyAnonymous ? 'inline' : 'none'
        }
      })
    })

    ReactDOM.render(
      <View width="580px" display="block" data-testid="groups_grading_not_allowed">
        <Alert variant="info" margin="small">
          {I18n.t('Grading and Groups are not supported in Anonymous Discussions.')}
        </Alert>
      </View>,
      groupsNotAllowedRoot
    )

    if (anonymousPostSelector) {
      ReactDOM.render(<AnonymousPostSelector />, anonymousPostSelector)
    }
  })
})
