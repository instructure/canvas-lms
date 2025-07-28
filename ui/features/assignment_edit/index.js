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
import {useEffect} from 'react'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import EditHeaderView from './backbone/views/EditHeaderView'
import EditView from './backbone/views/EditView'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import DueDateOverride from '@canvas/due-dates'
import MasteryPathToggle from '@canvas/mastery-path-toggle'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import '@canvas/grading-standards'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import renderEditAssignmentsApp from './react/index'
import {renderEnhancedRubrics} from './react/AssignmentRubric'

function loadBackboneComponents() {
  function maybeScrollToTarget() {
    const params = new URLSearchParams(window.location.search)
    const targetId = params.get('scrollTo')
    const target = document.getElementById(targetId)

    if (target) target.scrollIntoView({behavior: 'smooth'})
  }

  if (document.readyState === 'complete') maybeScrollToTarget()
  else window.addEventListener('load', maybeScrollToTarget, {once: true})

  if (ENV.ASSIGNMENT_EDIT_ENHANCEMENTS_TEACHER_VIEW) {
    const div = document.createElement('div')
    renderEditAssignmentsApp(document.getElementById('content').appendChild(div))
  } else {
    const lockManager = new LockManager()
    lockManager.init({itemType: 'assignment', page: 'edit'})
    const lockedItems = lockManager.isChildContent() ? lockManager.getItemLocks() : {}

    if (ENV.ASSIGNMENT) ENV.ASSIGNMENT.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES

    const userIsAdmin = ENV.current_user_is_admin
    const canEditGrades = ENV.PERMISSIONS?.can_edit_grades ?? false

    const assignment = new Assignment(ENV.ASSIGNMENT)
    assignment.urlRoot = ENV.URL_ROOT

    const sectionList = new SectionCollection(ENV.SECTION_LIST)
    const dueDateList = new DueDateList(
      assignment.get('assignment_overrides'),
      sectionList,
      assignment,
    )

    const assignmentGroupSelector = new AssignmentGroupSelector({
      parentModel: assignment,
      assignmentGroups:
        (typeof ENV !== 'undefined' && ENV !== null ? ENV.ASSIGNMENT_GROUPS : undefined) || [],
    })
    const gradingTypeSelector = new GradingTypeSelector({
      parentModel: assignment,
      preventNotGraded: assignment.submissionTypesFrozen(),
      lockedItems,
      canEditGrades,
    })
    const groupCategorySelector = new GroupCategorySelector({
      parentModel: assignment,
      groupCategories:
        (typeof ENV !== 'undefined' && ENV !== null ? ENV.GROUP_CATEGORIES : undefined) || [],
      inClosedGradingPeriod: assignment.inClosedGradingPeriod(),
      showNewErrors: true,
    })
    const peerReviewsSelector = new PeerReviewsSelector({
      parentModel: assignment,
    })

    const editView = new EditView({
      el: '#edit_assignment_form',
      model: assignment,
      assignmentGroupSelector,
      gradingTypeSelector,
      ...(!ENV.horizon_course && {groupCategorySelector}),
      ...(!ENV.horizon_course && {peerReviewsSelector}),
      views: {
        'js-assignment-overrides': new DueDateOverride({
          model: dueDateList,
          views: {},
          postToSIS: assignment.postToSIS(),
          dueDatesReadonly: !!lockedItems.due_dates,
          availabilityDatesReadonly: !!lockedItems.availability_dates,
          inPacedCourse: assignment.inPacedCourse(),
          isModuleItem: ENV.IS_MODULE_ITEM,
          courseId: assignment.courseID(),
          ...(!ENV.horizon_course && {groupCategorySelector}),
        }),
        'js-assignment-overrides-mastery-path': new MasteryPathToggle({
          model: dueDateList,
        }),
      },
      lockedItems: assignment.id ? lockedItems : {}, // if no id, creating a new assignment
      canEditGrades: canEditGrades || !assignment.gradedSubmissionsExist(),
    })

    const editHeaderView = new EditHeaderView({
      el: '#edit_assignment_header',
      model: assignment,
      userIsAdmin,
      views: {
        edit_assignment_form: editView,
      },
    })
    editHeaderView.render()
    renderEnhancedRubrics()
  }
}

export function Component() {
  useEffect(() => {
    // Need to make sure the DOM has settled down before loading the Backbone
    // stuff, because it in turn wants to render stuff into the DOM and we need
    // to make sure everything is in place before that happens.
    requestAnimationFrame(loadBackboneComponents)
  }, [])
  return null
}
