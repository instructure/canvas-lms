/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import '@canvas/jquery/jquery.simulate'
import '@canvas/rails-flash-notifications'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {CourseReport} from '../types'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {POLL_DOCX_DELAY} from '../utils/constants'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Modal} from '@instructure/ui-modal'
import {ProgressBar} from '@instructure/ui-progress'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('course_paces_app')

export interface PaceDownloadModalProps {
  courseReport: CourseReport | undefined
  showCourseReport: (courseReport: CourseReport) => Promise<CourseReport | undefined>
  setCourseReport: (courseReport: CourseReport | undefined) => void
}

const PaceDownloadModal = ({
  courseReport,
  showCourseReport,
  setCourseReport,
}: PaceDownloadModalProps) => {
  useEffect(() => {
    const interval = setInterval(async () => {
      if (courseReport?.id && !courseReport?.file_url) {
        const updatedReport = await showCourseReport(courseReport)
        setCourseReport(updatedReport)
      }
    }, POLL_DOCX_DELAY)

    return () => clearInterval(interval)
  }, [courseReport])

  useEffect(() => {
    if (courseReport?.file_url) {
      window.location.href = courseReport.file_url

      showFlashAlert({
        message: I18n.t('The Course Pace download is complete.'),
        type: 'success',
      })
      setCourseReport(undefined)
    } else if (courseReport) {
      if (courseReport.status == 'error') {
        showFlashAlert({
          message: I18n.t('The course pace download encountered an error.'),
          type: 'error',
        })
        setCourseReport(undefined)
      }
    }
  }, [courseReport, courseReport?.status, courseReport?.file_url])

  return (
    <Modal
      label={I18n.t('Download Course Pace')}
      open={!!courseReport}
      onDismiss={() => setCourseReport(undefined)}
      shouldCloseOnDocumentClick={false}
      size="medium"
    >
      <Modal.Header>
        <Heading>{I18n.t('Download Course Pace')}</Heading>
        <CloseButton
          placement="end"
          offset="small"
          onClick={() => setCourseReport(undefined)}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body>
        <div data-testid="download-course-pace-modal">
          <Text as="div">
            {I18n.t(
              'Preparing your Course Pace download.  This can take a while for large courses.  If you wish to cancel, please close this window.  This window will close automatically when your Course Pace download is complete.',
            )}
          </Text>
          <Text as="div">{I18n.t('Processing...')}</Text>
          <ProgressBar
            screenReaderLabel={I18n.t('Course Pace download completion')}
            valueNow={courseReport?.progress || 0}
            renderValue={({valueNow, valueMax}) => (
              <Text>{Math.round((valueNow / valueMax) * 100)}%</Text>
            )}
          />
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Button color="primary" onClick={() => setCourseReport(undefined)}>
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default PaceDownloadModal
