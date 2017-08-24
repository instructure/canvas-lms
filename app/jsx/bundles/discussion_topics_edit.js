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
import DiscussionTopic from 'compiled/models/DiscussionTopic'
import Announcement from 'compiled/models/Announcement'
import DueDateList from 'compiled/models/DueDateList'
import EditView from 'compiled/views/DiscussionTopics/EditView'
import OverrideView from 'compiled/views/assignments/DueDateOverride'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import SectionCollection from 'compiled/collections/SectionCollection'
import splitAssetString from 'compiled/str/splitAssetString'
import LockManager from 'jsx/blueprint_courses/apps/LockManager'
import 'grading_standards'

const lockManager = new LockManager()
lockManager.init({ itemType: 'discussion_topic', page: 'edit' })

const lockedItems = lockManager.isChildContent() ? lockManager.getItemLocks() : {}

const isAnnouncement = ENV.DISCUSSION_TOPIC.ATTRIBUTES != null ? ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement : undefined
const model = new (isAnnouncement ? Announcement : DiscussionTopic)(ENV.DISCUSSION_TOPIC.ATTRIBUTES, {parse: true})
model.urlRoot = ENV.DISCUSSION_TOPIC.URL_ROOT
const assignment = model.get('assignment')

const sectionList = new SectionCollection(ENV.SECTION_LIST)
const dueDateList = new DueDateList(assignment.get('assignment_overrides'), sectionList, assignment)

const [contextType] = splitAssetString(ENV.context_asset_string)
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
  lockedItems: model.id ? lockedItems : {}  // if no id, creating a new discussion
})

if ((contextType === 'courses') && !isAnnouncement && ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT) {
  const agc = new AssignmentGroupCollection();
  agc.options.params = {};
  agc.contextAssetString = ENV.context_asset_string;
  view.assignmentGroupCollection = agc;
}

$(() => {
  view.render().$el.appendTo('#content')
  $('#discussion-title').focus()
})

export default view
