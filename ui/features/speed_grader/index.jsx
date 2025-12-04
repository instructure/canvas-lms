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
import iframeAllowances from '@canvas/external-apps/iframeAllowances'

import {useScope as createI18nScope} from '@canvas/i18n'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {executeQuery} from '@canvas/graphql'
import {initializePendo} from '@canvas/pendo'
import speedGrader from './jquery/speed_grader'
import SGUploader from './sg_uploader'
import getRCSProps from '@canvas/rce/getRCSProps'

const I18n = createI18nScope('speed_grader')

ready(() => {
  async function speedGraderProps() {
    const pendo = await initializePendo().catch(error => {
      console.error('Failed to initialize Pendo for platform SpeedGrader', error)
      // let's be explicit. if we run into an error, the pendo prop should be undefined.
      return undefined
    })

    const params = new URLSearchParams(window.location.search)
    const postMessageAliases = {
      'quizzesNext.register': 'tool.register',
      'quizzesNext.nextStudent': 'tool.nextStudent',
      'quizzesNext.previousStudent': 'tool.previousStudent',
      'quizzesNext.submissionUpdate': 'tool.submissionUpdate',
    }
    const sgUploader = new SGUploader()

    return {
      executeQuery,
      platform: 'canvas',
      postMessageAliases,
      mutationFns: {
        postSubmissionCommentMedia: sgUploader?.doUploadByFile,
      },
      context: {
        userId: window.ENV.current_user_id,
        assignmentId: params.get('assignment_id'),
        studentId: params.get('student_id'),
        hrefs: {
          heroIcon: `/courses/${window.ENV.course_id}/gradebook`,
        },
        emojisDenyList: window.ENV.EMOJI_DENY_LIST ? window.ENV.EMOJI_DENY_LIST.split(',') : [],
        mediaSettings: window.INST.kalturaSettings,
        lang: ENV.LOCALE || ENV.BIGEASY_LOCALE || window.navigator.language,
        currentUserIsAdmin: ENV.current_user_is_admin ?? false,
        themeOverrides: window.CANVAS_ACTIVE_BRAND_VARIABLES ?? null,
        useHighContrast: window.ENV.use_high_contrast ?? false,
        commentLibrarySuggestionsEnabled: window.ENV.comment_library_suggestions_enabled ?? false,
        lateSubmissionInterval: window.ENV.late_policy?.late_submission_interval || 'day',
        ltiIframeAllowances: iframeAllowances(),
        pendo,
        permissions: {
          canViewAuditTrail: window.ENV.can_view_audit_trail ?? false,
          canManageGrades: window.ENV.MANAGE_GRADES ?? false,
          canViewAllGrades: window.ENV.VIEW_ALL_GRADES ?? false,
        },
        gradebookGroupFilterId: window.ENV.gradebook_group_filter_id ?? null,
        gradebookSectionFilters: window.ENV.gradebook_section_filter_id ?? null,
        showInactiveEnrollments: window.ENV.show_inactive_enrollments ?? false,
        showConcludedEnrollments: window.ENV.show_concluded_enrollments ?? false,
        userTimeZone:
          window.ENV.TIMEZONE ||
          Intl.DateTimeFormat().resolvedOptions().timeZone ||
          window.ENV.CONTEXT_TIMEZONE ||
          'UTC',
        masquerade: window.ENV.masquerade ?? null,
        rceTrayProps: getRCSProps(),
      },
      features: {
        a2StudentEnabled: window.ENV.A2_STUDENT_ENABLED ?? false,
        extendedSubmissionState: window.ENV.FEATURES.extended_submission_state ?? false,
        emojisEnabled: !!window.ENV.EMOJIS_ENABLED,
        enhancedRubricsEnabled: window.ENV.ENHANCED_RUBRICS_ENABLED ?? false,
        commentLibraryEnabled: window.ENV.COMMENT_LIBRARY_FEATURE_ENABLED ?? false,
        consolidatedMediaPlayerEnabled: window.ENV.FEATURES.consolidated_media_player ?? false,
        restrictQuantitativeDataEnabled: window.ENV.RESTRICT_QUANTITATIVE_DATA_ENABLED ?? false,
        gradeByStudentEnabled: window.ENV.GRADE_BY_STUDENT_ENABLED ?? false,
        discussionCheckpointsEnabled: window.ENV.FEATURES.discussion_checkpoints ?? false,
        stickersEnabled: window.ENV.STICKERS_ENABLED_FOR_ASSIGNMENT ?? false,
        filterSpeedGraderByStudentGroupEnabled:
          window.ENV.FILTER_SPEEDGRADER_BY_STUDENT_GROUP_ENABLED ?? false,
        projectLhotseEnabled: window.ENV.PROJECT_LHOTSE_ENABLED ?? false,
        gradingAssistanceFileUploadEnabled:
          window.ENV.GRADING_ASSISTANCE_FILE_UPLOADS_ENABLED ?? false,
        discussionInsightsEnabled: window.ENV.DISCUSSION_INSIGHTS_ENABLED ?? false,
        multiselectFiltersEnabled: window.ENV.MULTISELECT_FILTERS_ENABLED ?? false,
        ltiAssetProcessor: window.ENV.FEATURES.lti_asset_processor ?? false,
        commentBankPerAssignmentEnabled: window.ENV.COMMENT_BANK_PER_ASSIGNMENT_ENABLED ?? false,
        peerReviewAllocationAndGrading:
          window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED ?? false,
      },
    }
  }

  const classicContainer = document.querySelector('#classic_speedgrader_container')

  if (classicContainer instanceof HTMLElement) {
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
      mountPoint,
    )
    speedGrader.setup()
    return
  }

  speedGrader.setupForSG2()

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
      mountPoint,
    )
    return
  }

  import('speedgrader/appInjector')
    .then(async module => {
      const props = await speedGraderProps()
      module.render(mountPoint, props)
    })
    .catch(error => {
      console.error('Failed to load SpeedGrader', error)
      captureException(error)

      ReactDOM.render(
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorMessage={error.message}
          errorSubject={I18n.t('SpeedGrader loading error')}
          errorCategory={I18n.t('SpeedGrader Error Page')}
        />,
        mountPoint,
      )
    })
})
