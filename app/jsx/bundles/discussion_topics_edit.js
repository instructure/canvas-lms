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
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import 'grading_standards'
import DiscussionTopic from 'compiled/models/DiscussionTopic'
import Announcement from 'compiled/models/Announcement'
import DueDateList from 'compiled/models/DueDateList'
import EditView from 'compiled/views/DiscussionTopics/EditView'
import OverrideView from 'compiled/views/assignments/DueDateOverride'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import SectionCollection from 'compiled/collections/SectionCollection'
import splitAssetString from 'compiled/str/splitAssetString'
import LockManager from '../blueprint_courses/apps/LockManager'
import SectionsAutocomplete from '../shared/SectionsAutocomplete'

const lockManager = new LockManager()
lockManager.init({ itemType: 'discussion_topic', page: 'edit' })

const lockedItems = lockManager.isChildContent() ? lockManager.getItemLocks() : {}

const isAnnouncement = ENV.DISCUSSION_TOPIC.ATTRIBUTES != null ? ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement : undefined
const model = new (isAnnouncement ? Announcement : DiscussionTopic)(ENV.DISCUSSION_TOPIC.ATTRIBUTES, {parse: true})
model.urlRoot = ENV.DISCUSSION_TOPIC.URL_ROOT
const assignment = model.get('assignment')

const announcementsLocked = ENV.ANNOUNCEMENTS_LOCKED
const sectionList = new SectionCollection(ENV.SECTION_LIST)
const dueDateList = new DueDateList(assignment.get('assignment_overrides'), sectionList, assignment)

const [contextType] = splitAssetString(ENV.context_asset_string)

function renderSectionsAutocomplete (view) {
  if (sectionSpecificEnabled()) {
    const container = document.querySelector('#sections_autocomplete_root')
    if (container) {
      const gcs = view.groupCategorySelector
      const isGradedDiscussion = view.gradedChecked()
      const isGroupDiscussion = (gcs !== undefined) ? gcs.groupDiscussionChecked() : false
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

      ReactDOM.render(
        <SectionsAutocomplete
          selectedSections={ENV.SELECTED_SECTION_LIST}
          disabled={isGradedDiscussion || isGroupDiscussion}
          disableDiscussionOptions={disableDiscussionOptions}
          enableDiscussionOptions={enableDiscussionOptions}
          sections={ENV.SECTION_LIST}
        />
        , container
      )
    }
  }
}

const view = new EditView({
  model,
  permissions: ENV.DISCUSSION_TOPIC.PERMISSIONS,
  contextType,
  views: {
    'js-assignment-overrides': new OverrideView({
      model: dueDateList,
      views: {},
      dueDatesReadonly: !!lockedItems.due_dates,
      availabilityDatesReadonly: !!lockedItems.availability_dates
    })
  },
  lockedItems: model.id ? lockedItems : {},  // if no id, creating a new discussion
  announcementsLocked
})
view.setRenderSectionsAutocomplete(() => renderSectionsAutocomplete(view))

function sectionSpecificEnabled() {
  if (!ENV.context_asset_string.startsWith("course")) {
    return false
  }

  const isAnnouncement = ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement
  return isAnnouncement || ENV.SECTION_SPECIFIC_DISCUSSIONS_ENABLED
}

if ((contextType === 'courses') && !isAnnouncement && ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT) {
  const agc = new AssignmentGroupCollection();
  agc.options.params = {};
  agc.contextAssetString = ENV.context_asset_string;
  view.assignmentGroupCollection = agc;
}


$(() => {
  view.render().$el.appendTo('#content')
  document.querySelector('#discussion-title').focus()

  // This needs to be run in the next tick, so that the backbone views are all
  // properly created/rendered thus can be used to checked if this is a graded
  // or group discussions.
  setTimeout(() => renderSectionsAutocomplete(view))
})

export default view
