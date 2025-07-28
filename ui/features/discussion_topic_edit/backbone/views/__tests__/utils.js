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

import {extend} from 'lodash'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import Section from '@canvas/sections/backbone/models/Section'
import DiscussionTopic from '@canvas/discussions/backbone/models/DiscussionTopic'
import Announcement from '@canvas/discussions/backbone/models/Announcement'
import DueDateOverrideView from '@canvas/due-dates'
import EditView from '../EditView'
import AssignmentGroupCollection from '@canvas/assignments/backbone/collections/AssignmentGroupCollection'
import '@canvas/jquery/jquery.simulate'

EditView.prototype.loadNewEditor = () => {}

export const editView = function (opts = {}, discussOpts = {}) {
  const ModelClass = opts.isAnnouncement ? Announcement : DiscussionTopic
  if (opts.withAssignment) {
    const assignmentOpts = extend({}, opts.assignmentOpts, {
      name: 'Test Assignment',
      assignment_overrides: [],
      graded_submissions_exist: true,
    })
    discussOpts.assignment = assignmentOpts
  }
  const discussion = new ModelClass(discussOpts, {parse: true})
  const assignment = discussion.get('assignment')
  const sectionList = new SectionCollection([Section.defaultDueDateSection()])
  const dueDateList = new DueDateList(
    assignment.get('assignment_overrides'),
    sectionList,
    assignment,
  )
  const app = new EditView({
    model: discussion,
    permissions: opts.permissions || {},
    views: {
      'js-assignment-overrides': new DueDateOverrideView({
        model: dueDateList,
        views: {},
      }),
    },
    lockedItems: opts.lockedItems || {},
    isEditing: false,
    anonymousState: ENV?.DISCUSSION_TOPIC?.ATTRIBUTES?.anonymous_state,
    react_discussions_post: ENV.REACT_DISCUSSIONS_POST,
    allow_student_anonymous_discussion_topics: ENV.allow_student_anonymous_discussion_topics,
    context_is_not_group: ENV.context_is_not_group,
  })
  ;(app.assignmentGroupCollection = new AssignmentGroupCollection()).contextAssetString =
    ENV.context_asset_string
  return app.render()
}
