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
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import ready from '@instructure/ready'
import speedGrader from './jquery/speed_grader'
import {getCurrentTheme} from '@instructure/theme-registry'
import {captureException} from '@sentry/browser'
import {getAssignment} from './queries/assignmentQuery'
import {getCourse} from './queries/courseQuery'
import {getSectionsByAssignment} from './queries/sectionsByAssignmentQuery'
import {getSubmission} from './queries/submissionQuery'
import {getSubmissionsByAssignment} from './queries/submissionsByAssignmentQuery'
import {updateSubmissionGrade} from './mutations/updateSubmissionGradeMutation'
import {createSubmissionComment} from './mutations/createSubmissionCommentMutation'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = useI18nScope('speed_grader')

ready(() => {
  // The feature must be enabled AND we must be handed the speedgrader platform URL
  if (window.ENV.FEATURES.platform_service_speedgrader && window.REMOTES?.speedgrader) {
    const theme = getCurrentTheme()
    const mountPoint = document.querySelector('#react-router-portals')
    const params = new URLSearchParams(window.location.search)

    import('speedgrader/appInjector')
      .then(module => {
        module.render(mountPoint, {
          theme,
          queries: {
            getCourse,
            getAssignment,
            getSubmission,
            getSubmissionsByAssignment,
            getSectionsByAssignment,
          },
          mutations: {
            updateSubmissionGrade,
            createSubmissionComment,
          },
          context: {
            courseId: window.ENV.course_id,
            assignmentId: params.get('assignment_id'),
            studentId: params.get('student_id'),
            gradeBookIconHref: `/courses/${window.ENV.course_id}/gradebook`,
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
