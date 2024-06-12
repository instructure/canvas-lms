/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {captureException} from '@sentry/browser'
import {Spinner} from '@instructure/ui-spinner'
import ready from '@instructure/ready'
import {getCurrentTheme} from '@instructure/theme-registry'

import {getAssignment} from './queries/assignmentQuery'
import {getCourse} from './queries/courseQuery'
import {getSectionsByAssignment} from './queries/sectionsByAssignmentQuery'
import {getSubmission} from './queries/submissionQuery'
import {getSubmissionsByAssignment} from './queries/submissionsByAssignmentQuery'

import {updateSubmissionGrade} from './mutations/updateSubmissionGradeMutation'
import {createSubmissionComment} from './mutations/createSubmissionCommentMutation'
import {hideAssignmentGradesForSections} from './mutations/hideAssignmentGradesForSectionsMutation'
import {postDraftSubmissionComment} from './mutations/postDraftSubmissionCommentMutation'
import {deleteSubmissionComment} from './mutations/deleteSubmissionCommentMutation'
import {
  postAssignmentGradesForSections,
  resolvePostAssignmentGradesStatus,
} from './mutations/postAssignmentGradesForSectionsMutation'

import {useScope as useI18nScope} from '@canvas/i18n'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import speedGrader from './jquery/speed_grader'

const I18n = useI18nScope('speed_grader')

ready(() => {
  // The feature must be enabled AND we must be handed the speedgrader platform URL
  if (window.ENV.FEATURES.platform_service_speedgrader && window.REMOTES?.speedgrader) {
    const theme = getCurrentTheme()
    const mountPoint = document.querySelector('#react-router-portals')
    const params = new URLSearchParams(window.location.search)
    const postMessageAliases = {
      'quizzesNext.register': 'tool.register',
      'quizzesNext.nextStudent': 'tool.nextStudent',
      'quizzesNext.previousStudent': 'tool.previousStudent',
      'quizzesNext.submissionUpdate': 'tool.submissionUpdate',
    }

    import('speedgrader/appInjector')
      .then(module => {
        module.render(mountPoint, {
          theme,
          queryFns: {
            getCourse,
            getAssignment,
            getSubmission,
            getSubmissionsByAssignment,
            getSectionsByAssignment,
            resolvePostAssignmentGradesStatus,
          },
          mutationFns: {
            updateSubmissionGrade,
            createSubmissionComment,
            deleteSubmissionComment,
            hideAssignmentGradesForSections,
            postAssignmentGradesForSections,
            postDraftSubmissionComment,
          },
          postMessageAliases,
          context: {
            courseId: window.ENV.course_id,
            assignmentId: params.get('assignment_id'),
            studentId: params.get('student_id'),
            hrefs: {
              heroIcon: `/courses/${window.ENV.course_id}/gradebook`,
            },
            emojisDenyList: window.ENV.EMOJI_DENY_LIST?.split(','),
            mediaSettings: window.INST.kalturaSettings
          },
          features: {
            extendedSubmissionState: window.ENV.FEATURES.extended_submission_state,
            gradeByQuestion: {
              supported: window.ENV.GRADE_BY_QUESTION_SUPPORTED,
              enabled: window.ENV.GRADE_BY_QUESTION,
            },
            emojisEnabled: !!window.ENV.EMOJIS_ENABLED,
          },
        })
      })
      .catch(error => {
        // eslint-disable-next-line no-console
        console.error('Failed to load SpeedGrader', error)
        captureException(error)
        ReactDOM.render(
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('SpeedGrader loading error')}
            errorCategory={I18n.t('SpeedGrader Error Page')}
          />,
          mountPoint
        )
      })
  } else {
    // touch punch simulates mouse events for touch devices
    require('./touch_punch.js')

    const mountPoint = document.getElementById('speed_grader_loading')

    ReactDOM.render(
      <div
        style={{
          position: 'fixed',
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Spinner renderTitle={I18n.t('Loading')} margin="large auto 0 auto" />
      </div>,
      mountPoint
    )
    speedGrader.setup()
  }
})
