// @ts-nocheck
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

import * as tz from '@canvas/datetime'
import React from 'react'
import ReactDOM from 'react-dom'
import {getAssignmentColumnId} from '../Gradebook.utils'
import AsyncComponents from '../AsyncComponents'
import type Gradebook from '../Gradebook'

function getSubmission(student, assignmentId: string) {
  const submission = student[`assignment_${assignmentId}`] || {
    has_postable_comments: false,
    posted_at: null,
    score: null,
    workflow_state: null,
  }

  return {
    hasPostableComments: !!submission.has_postable_comments,
    postedAt: submission.posted_at,
    score: submission.score,
    workflowState: submission.workflow_state,
  }
}

export default class PostPolicies {
  _gradebook: Gradebook

  _coursePostPolicy: {
    postManually: boolean
  }

  constructor(gradebook: Gradebook) {
    this._coursePostPolicy = {postManually: !!gradebook.options.post_manually}
    this._gradebook = gradebook

    this._onGradesPostedOrHidden = this._onGradesPostedOrHidden.bind(this)
    this._onAssignmentPostPolicyUpdated = this._onAssignmentPostPolicyUpdated.bind(this)
  }

  destroy() {
    ;[
      'assignment-posting-policy-tray',
      'hide-assignment-grades-tray',
      'post-assignment-grades-tray',
    ].forEach(id => {
      const node = document.getElementById(id)
      if (node) ReactDOM.unmountComponentAtNode(node)
    })
  }

  _onGradesPostedOrHidden({assignmentId, postedAt, userIds}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    const parsedPostedAt = tz.parse(postedAt)

    userIds.forEach(userId => {
      const submission = this._gradebook.getSubmission(userId, assignmentId)
      if (submission != null) {
        submission.posted_at = parsedPostedAt
        this._gradebook.updateSubmission(submission)
      }
    })

    if (assignment.anonymous_grading) {
      assignment.anonymize_students = !postedAt
    }

    this._gradebook.handleSubmissionPostedChange(assignment)
  }

  _onAssignmentPostPolicyUpdated({assignmentId, postManually}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    assignment.post_manually = postManually

    const columnId = getAssignmentColumnId(assignmentId)
    this._gradebook.updateColumnHeaders([columnId])
  }

  async showAssignmentPostingPolicyTray({assignmentId, onExited}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    const {id, name} = assignment

    const AssignmentPostingPolicyTray = await AsyncComponents.loadAssignmentPostingPolicyTray()

    const $assignmentPolicyContainer = document.getElementById('assignment-posting-policy-tray')
    let tray
    const bindAssignmentPolicyTray = ref => {
      tray = ref
    }
    ReactDOM.render(
      <AssignmentPostingPolicyTray ref={bindAssignmentPolicyTray} />,
      $assignmentPolicyContainer
    )

    tray.show({
      assignment: {
        anonymousGrading: assignment.anonymous_grading,
        gradesPublished: assignment.grades_published,
        id,
        moderatedGrading: assignment.moderated_grading,
        name,
        postManually: assignment.post_manually,
      },
      onAssignmentPostPolicyUpdated: this._onAssignmentPostPolicyUpdated,
      onExited,
    })
  }

  async showHideAssignmentGradesTray({assignmentId, onExited}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    const {anonymous_grading, grades_published, id, name} = assignment
    const sections = this._gradebook.getSections()
    const studentsWithVisibility = Object.values(
      this._gradebook.studentsThatCanSeeAssignment(assignment.id)
    )
    const submissions = studentsWithVisibility.map(student => getSubmission(student, assignment.id))

    const HideAssignmentGradesTray = await AsyncComponents.loadHideAssignmentGradesTray()

    const $hideContainer = document.getElementById('hide-assignment-grades-tray')
    let tray
    const bindHideTray = ref => {
      tray = ref
    }
    ReactDOM.render(<HideAssignmentGradesTray ref={bindHideTray} />, $hideContainer)

    tray.show({
      assignment: {
        anonymousGrading: anonymous_grading,
        gradesPublished: grades_published,
        id,
        name,
      },
      onExited,
      onHidden: this._onGradesPostedOrHidden,
      sections,
      submissions,
    })
  }

  async showPostAssignmentGradesTray({assignmentId, onExited = () => {}}) {
    const assignment = this._gradebook.getAssignment(assignmentId)
    const {anonymous_grading, grades_published, id, name} = assignment
    const sections = this._gradebook.getSections()
    const studentsWithVisibility = Object.values(
      this._gradebook.studentsThatCanSeeAssignment(assignment.id)
    )
    const submissions = studentsWithVisibility.map(student => getSubmission(student, assignment.id))

    const PostAssignmentGradesTray = await AsyncComponents.loadPostAssignmentGradesTray()

    const $postContainer = document.getElementById('post-assignment-grades-tray')
    let tray
    const bindPostTray = ref => {
      tray = ref
    }
    ReactDOM.render(<PostAssignmentGradesTray ref={bindPostTray} />, $postContainer)

    tray.show({
      assignment: {
        anonymousGrading: anonymous_grading,
        gradesPublished: grades_published,
        id,
        name,
      },
      onExited: () => {
        this._gradebook.postAssignmentGradesTrayOpenChanged({
          assignmentId: assignment.id,
          isOpen: false,
        })
        onExited()
      },
      sections,
      submissions,
      onPosted: this._onGradesPostedOrHidden,
    })

    this._gradebook.postAssignmentGradesTrayOpenChanged({
      assignmentId: assignment.id,
      isOpen: true,
    })
  }

  get coursePostPolicy() {
    return this._coursePostPolicy
  }

  setCoursePostPolicy({postManually}) {
    this._coursePostPolicy = {postManually}
  }

  setAssignmentPostPolicies({assignmentPostPoliciesById}) {
    Object.keys(assignmentPostPoliciesById).forEach(id => {
      const assignment = this._gradebook.getAssignment(id)
      if (assignment != null) {
        assignment.post_manually = assignmentPostPoliciesById[id].postManually
      }
    })

    // The changed assignments may not all be visible, so update all column
    // headers rather than worrying about which ones are or aren't shown
    this._gradebook.updateColumnHeaders()
  }
}
