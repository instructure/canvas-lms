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

import HideAssignmentGradesTray from '../../grading/HideAssignmentGradesTray'
import PostAssignmentGradesTray from '../../grading/PostAssignmentGradesTray'

function submissionsPostedAtUpdater({submissionsMap, updateSubmission, afterUpdateSubmission}) {
  return function({postedAt, userIds}) {
    userIds.forEach(userId => {
      const submission = submissionsMap[userId]
      submission.posted_at = postedAt
      updateSubmission(submission)
    })
    afterUpdateSubmission()
  }
}

export default class PostPolicies {
  constructor({assignment, sections, updateSubmission, afterUpdateSubmission}) {
    this._assignment = assignment
    this._sections = sections
    this._updateSubmission = updateSubmission
    this._afterUpdateSubmission = afterUpdateSubmission

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
  }

  destroy() {
    const $hideContainer = document.getElementById('hide-assignment-grades-tray')
    const $postContainer = document.getElementById('post-assignment-grades-tray')

    if ($hideContainer) {
      ReactDOM.unmountComponentAtNode($hideContainer)
    }

    if ($postContainer) {
      ReactDOM.unmountComponentAtNode($postContainer)
    }
  }

  showHideAssignmentGradesTray({submissionsMap}) {
    const onHidden = submissionsPostedAtUpdater({
      afterUpdateSubmission: this._afterUpdateSubmission,
      submissionsMap,
      updateSubmission: this._updateSubmission
    })
    this._hideAssignmentGradesTray.show({
      assignment: this._assignment,
      onHidden,
      sections: this._sections
    })
  }

  showPostAssignmentGradesTray({submissionsMap, submissions}) {
    const onPosted = submissionsPostedAtUpdater({
      afterUpdateSubmission: this._afterUpdateSubmission,
      submissionsMap,
      updateSubmission: this._updateSubmission
    })
    this._postAssignmentGradesTray.show({
      assignment: this._assignment,
      onPosted,
      sections: this._sections,
      submissions
    })
  }
}
