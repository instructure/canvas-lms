/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

// manage groups is for the add_group_category dialog
import ready from '@instructure/ready'
import Assignment from '@canvas/assignments/backbone/models/Assignment.coffee'
import EditHeaderView from './backbone/views/EditHeaderView.coffee'
import EditView from './backbone/views/EditView.coffee'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import DueDateOverride from '@canvas/due-dates'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector.coffee'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector.coffee'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector.coffee'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector.coffee'
import '@canvas/grading-standards'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'

const lockManager = new LockManager()
lockManager.init({itemType: 'assignment', page: 'edit'})
const lockedItems = lockManager.isChildContent() ? lockManager.getItemLocks() : {}

ENV.ASSIGNMENT.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES

const userIsAdmin = ENV.current_user_roles.includes('admin')

const assignment = new Assignment(ENV.ASSIGNMENT)
assignment.urlRoot = ENV.URL_ROOT

const sectionList = new SectionCollection(ENV.SECTION_LIST)
const dueDateList = new DueDateList(assignment.get('assignment_overrides'), sectionList, assignment)

const assignmentGroupSelector = new AssignmentGroupSelector({
  parentModel: assignment,
  assignmentGroups:
    (typeof ENV !== 'undefined' && ENV !== null ? ENV.ASSIGNMENT_GROUPS : undefined) || []
})
const gradingTypeSelector = new GradingTypeSelector({
  parentModel: assignment,
  preventNotGraded: assignment.submissionTypesFrozen(),
  lockedItems
})
const groupCategorySelector = new GroupCategorySelector({
  parentModel: assignment,
  groupCategories:
    (typeof ENV !== 'undefined' && ENV !== null ? ENV.GROUP_CATEGORIES : undefined) || [],
  inClosedGradingPeriod: assignment.inClosedGradingPeriod()
})
const peerReviewsSelector = new PeerReviewsSelector({
  parentModel: assignment
})

const editView = new EditView({
  el: '#edit_assignment_form',
  model: assignment,
  assignmentGroupSelector,
  gradingTypeSelector,
  groupCategorySelector,
  peerReviewsSelector,
  views: {
    'js-assignment-overrides': new DueDateOverride({
      model: dueDateList,
      views: {},
      postToSIS: assignment.postToSIS(),
      dueDatesReadonly: !!lockedItems.due_dates,
      availabilityDatesReadonly: !!lockedItems.availability_dates
    })
  },
  lockedItems: assignment.id ? lockedItems : {} // if no id, creating a new assignment
})

const editHeaderView = new EditHeaderView({
  el: '#edit_assignment_header',
  model: assignment,
  userIsAdmin,
  views: {
    edit_assignment_form: editView
  }
})

ready(() => {
  editHeaderView.render()
})
