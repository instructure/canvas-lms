/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

// this is called by speed grader to enable communication
// between quizzesNext LTI tool and speed grader
// and modify normal speedGrader behavior to be more compatible
// with our LTI tool

// it sets up event listeners for postMessage communication
// from the LTI tool

// registerCb replaces the base speedgrader submissionChange callback
// with whatever callback is passed in as an argument

// refreshGradesCb executes the normal speedGrader refresh grades
// actions, plus whatever callback is passed in as an argument

import type {Submission} from './jquery/speed_grader.d'
import $ from 'jquery'

function quizzesNextSpeedGrading(
  EG,
  $iframe_holder,
  registerCb,
  refreshGradesCb,
  speedGraderWindow = window
) {
  function quizzesNextChange(submission) {
    EG.refreshSubmissionsToView()
    if (submission && submission.submission_history) {
      const lastIndex = submission.submission_history.length - 1
      // set submission to selected in dropdown
      $('#submission_to_view option:eq(' + lastIndex + ')').attr('selected', 'selected')
    }
    EG.showGrade()
    EG.showDiscussion()
    EG.showRubric()
    EG.updateStatsInHeader()
    EG.refreshFullRubric()
    EG.setGradeReadOnly(true)
  }

  function retryRefreshGrades(
    submission: Submission,
    originalSubmission: Submission,
    numRequests: number
  ) {
    const maxRequests = 5
    if (numRequests >= maxRequests) return false
    if (!originalSubmission.graded_at) return !submission.graded_at
    if (!submission.graded_at) return true

    return Date.parse(submission.graded_at) <= Date.parse(originalSubmission.graded_at)
  }

  // gets the submission from the speed_grader.js
  // function that will call this
  function postChangeSubmissionMessage(submission) {
    const frame = $iframe_holder.children()[0]
    if (frame && frame.contentWindow) {
      frame.contentWindow.postMessage(
        {
          submission,
          subject: 'canvas.speedGraderSubmissionChange'
        },
        '*'
      )
    }
    EG.showSubmissionDetails()
    quizzesNextChange(submission)
  }

  function onMessage(e) {
    const message = e.data
    switch (message.subject) {
      case 'quizzesNext.register':
        EG.setGradeReadOnly(true)
        return registerCb(postChangeSubmissionMessage)
      case 'quizzesNext.submissionUpdate':
        return refreshGradesCb(quizzesNextChange, retryRefreshGrades, 1000)
    }
  }

  speedGraderWindow.addEventListener('message', onMessage)

  // expose for testing
  return {
    onMessage,
    postChangeSubmissionMessage,
    quizzesNextChange
  }
}

export default quizzesNextSpeedGrading
