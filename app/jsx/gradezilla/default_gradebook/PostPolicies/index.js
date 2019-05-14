/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import AssignmentPostingPolicyTray from '../../../grading/AssignmentPostingPolicyTray'
import HideAssignmentGradesTray from '../../../grading/HideAssignmentGradesTray'
import PostAssignmentGradesTray from '../../../grading/PostAssignmentGradesTray'

function getSubmission(student, assignmentId) {
  const submission = student[`assignment_${assignmentId}`] || {posted_at: null}
  return {postedAt: submission.posted_at}
}

export default class PostPolicies {
  constructor(gradebook) {
    this._coursePostPolicy = {postManually: !!gradebook.options.post_manually}
    this._gradebook = gradebook

    this._onGradesPostedOrHidden = this._onGradesPostedOrHidden.bind(this)
  }

  initialize() {
    const $hideContainer = document.getElementById('hide-assignment-grades-tray')
    const bindHideTray = ref => {
      this._hideAssignmentGradesTray = ref
    }
    ReactDOM.render(<HideAssignmentGradesTray ref={bindHideTray} />, $hideContainer)

    const $postContainer = document.getElementById('post-assignment-grades-tray')
    const bindPostTray = ref => {
      this._postAssignmentGradesTray = ref
    }
    ReactDOM.render(<PostAssignmentGradesTray ref={bindPostTray} />, $postContainer)

    const $assignmentPolicyContainer = document.getElementById('assignment-posting-policy-tray')
    const bindAssignmentPolicyTray = ref => {
      this._assignmentPolicyTray = ref
    }
    ReactDOM.render(
      <AssignmentPostingPolicyTray ref={bindAssignmentPolicyTray} />,
      $assignmentPolicyContainer
    )
  }

  destroy() {
    ReactDOM.unmountComponentAtNode(document.getElementById('assignment-posting-policy-tray'))
    ReactDOM.unmountComponentAtNode(document.getElementById('hide-assignment-grades-tray'))
    ReactDOM.unmountComponentAtNode(document.getElementById('post-assignment-grades-tray'))
  }

  _onGradesPostedOrHidden({assignmentId, postedAt, userIds}) {
    const columnId = this._gradebook.getAssignmentColumnId(assignmentId)

    userIds.forEach(userId => {
      const submission = this._gradebook.getSubmission(userId, assignmentId)
      submission.posted_at = postedAt
      this._gradebook.updateSubmission(submission)
    })

    this._gradebook.updateColumnHeaders([columnId])
  }

  showAssignmentPostingPolicyTray({assignmentId, onExited}) {
    const {id, name, postManually} = this._gradebook.getAssignment(assignmentId)

    this._assignmentPolicyTray.show({
      assignment: {id, name, postManually},
      onExited
    })
  }

  showHideAssignmentGradesTray({assignmentId, onExited}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    const {anonymize_students, grades_published, id, name} = assignment
    const sections = this._gradebook.getSections()

    this._hideAssignmentGradesTray.show({
      assignment: {
        anonymizeStudents: anonymize_students,
        gradesPublished: grades_published,
        id,
        name
      },
      onExited,
      onHidden: this._onGradesPostedOrHidden,
      sections
    })
  }

  showPostAssignmentGradesTray({assignmentId, onExited}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    const {anonymize_students, grades_published, id, name} = assignment
    const sections = this._gradebook.getSections()
    const studentsWithVisibility = Object.values(
      this._gradebook.studentsThatCanSeeAssignment(assignment.id)
    )
    const submissions = studentsWithVisibility.map(student => getSubmission(student, assignment.id))

    this._postAssignmentGradesTray.show({
      assignment: {
        anonymizeStudents: anonymize_students,
        gradesPublished: grades_published,
        id,
        name
      },
      onExited,
      sections,
      submissions,
      onPosted: this._onGradesPostedOrHidden
    })
  }

  get coursePostPolicy() {
    return this._coursePostPolicy
  }

  setCoursePostPolicy(policy) {
    this._coursePostPolicy = policy
  }
}
