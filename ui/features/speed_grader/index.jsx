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

import {getAssignment} from './queries/getAssignment'
import {getCourse} from './queries/getCourse'
import {getAssignmentSections} from './queries/getAssignmentSections'
import {getSubmission} from './queries/submissionQuery'
import {getAssignmentSubmissions} from './queries/getAssignmentSubmissions'
import {getSubmissionsByStudents} from './queries/getSubmissionsByStudents'
import {getCourseAssignments} from './queries/getCourseAssignments'
import {getCourseEnrollments} from './queries/getCourseEnrollments'
import {getCommentBankItems} from './queries/getCommentBankItems'

import {updateSpeedGraderSettings} from './mutations/updateSpeedGraderSettingsMutation'
import {updateSubmissionGrade} from './mutations/updateSubmissionGradeMutation'
import {createSubmissionComment} from './mutations/createSubmissionCommentMutation'
import {hideAssignmentGradesForSections} from './mutations/hideAssignmentGradesForSectionsMutation'
import {postDraftSubmissionComment} from './mutations/postDraftSubmissionCommentMutation'
import {updateSubmissionGradeStatus} from './mutations/updateSubmissionGradeStatusMutation'
import {deleteSubmissionComment} from './mutations/deleteSubmissionCommentMutation'
import {
  postAssignmentGradesForSections,
  resolvePostAssignmentGradesStatus,
} from './mutations/postAssignmentGradesForSectionsMutation'
import {createCommentBankItem} from './mutations/comment_bank/createCommentBankItemMutation'
import {deleteCommentBankItem} from './mutations/comment_bank/deleteCommentBankItemMutation'
import {updateCommentBankItem} from './mutations/comment_bank/updateCommentBankItemMutation'
import {updateCommentSuggestionsEnabled} from './mutations/comment_bank/updateCommentSuggestionsEnabled'
import {saveRubricAssessment} from './mutations/saveRubricAssessmentMutation'
import {updateSubmissionSecondsLate} from './mutations/updateSubmissionSecondsLateMutation'

import {useScope as useI18nScope} from '@canvas/i18n'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import speedGrader from './jquery/speed_grader'
import SGUploader from './sg_uploader'

const I18n = useI18nScope('speed_grader')

ready(() => {
  const classicContainer = document.querySelector('#classic_speedgrader_container')

  if (classicContainer instanceof HTMLElement) {
    // touch punch simulates mouse events for touch devices
    // eslint-disable-next-line import/extensions
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
    return
  }

  const mountPoint = document.querySelector('#react-router-portals')

  // The feature must be enabled AND we must be handed the speedgrader platform URL
  if (!window.ENV.PLATFORM_SERVICE_SPEEDGRADER_ENABLED || !window.REMOTES?.speedgrader) {
    ReactDOM.render(
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorMessage={
          <>
            {window.ENV.PLATFORM_SERVICE_SPEEDGRADER_ENABLED ||
              I18n.t('SpeedGrader Platform is not enabled')}
            {window.REMOTES?.speedgrader || 'window.REMOTES?.speedgrader is missing'}
          </>
        }
        errorSubject={I18n.t('SpeedGrader loading error')}
        errorCategory={I18n.t('SpeedGrader Error Page')}
      />,
      mountPoint
    )
    return
  }

  const params = new URLSearchParams(window.location.search)
  const postMessageAliases = {
    'quizzesNext.register': 'tool.register',
    'quizzesNext.nextStudent': 'tool.nextStudent',
    'quizzesNext.previousStudent': 'tool.previousStudent',
    'quizzesNext.submissionUpdate': 'tool.submissionUpdate',
  }

  const sgUploader = new SGUploader('any', {defaultTItle: 'Upload Media'})

  import('speedgrader/appInjector')
    .then(module => {
      module.render(mountPoint, {
        queryFns: {
          getAssignment,
          getCourseAssignments,
          getAssignmentSubmissions,
          getCourse,
          getCourseEnrollments,
          getAssignmentSections,
          getSubmission,
          getSubmissionsByStudents,
          getCommentBankItems,
          resolvePostAssignmentGradesStatus,
        },
        mutationFns: {
          updateSubmissionGrade,
          createSubmissionComment,
          deleteSubmissionComment,
          hideAssignmentGradesForSections,
          postAssignmentGradesForSections,
          postDraftSubmissionComment,
          updateSubmissionGradeStatus,
          updateSubmissionSecondsLate,
          createCommentBankItem,
          deleteCommentBankItem,
          updateCommentBankItem,
          updateCommentSuggestionsEnabled,
          updateSpeedGraderSettings,
          postSubmissionCommentMedia: sgUploader?.doUploadByFile,
          saveRubricAssessment,
        },
        postMessageAliases,
        context: {
          userId: window.ENV.current_user_id,
          grading_role: window.ENV.grading_role,
          assignmentId: params.get('assignment_id'),
          studentId: params.get('student_id'),
          hrefs: {
            heroIcon: `/courses/${window.ENV.course_id}/gradebook`,
          },
          emojisDenyList: window.ENV.EMOJI_DENY_LIST ? window.ENV.EMOJI_DENY_LIST.split(',') : [],
          mediaSettings: window.INST.kalturaSettings,
          lang: window.navigator.language || ENV.LOCALE || ENV.BIGEASY_LOCALE,
          currentUserIsAdmin: ENV.current_user_is_admin,
          themeOverrides: window.CANVAS_ACTIVE_BRAND_VARIABLES,
          useHighContrast: window.ENV.use_high_contrast,
          commentLibrarySuggestionsEnabled: window.ENV.comment_library_suggestions_enabled,
          lateSubmissionInterval: window.ENV.late_policy?.late_submission_interval || 'day',
        },
        features: {
          extendedSubmissionState: window.ENV.FEATURES.extended_submission_state,
          emojisEnabled: !!window.ENV.EMOJIS_ENABLED,
          enhancedRubricsEnabled: window.ENV.ENHANCED_RUBRICS_ENABLED,
          commentLibraryEnabled: window.ENV.COMMENT_LIBRARY_FEATURE_ENABLED,
          restrictQuantitativeDataEnabled: window.ENV.RESTRICT_QUANTITATIVE_DATA_ENABLED,
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
          errorMessage={error.message}
          errorSubject={I18n.t('SpeedGrader loading error')}
          errorCategory={I18n.t('SpeedGrader Error Page')}
        />,
        mountPoint
      )
    })
})
