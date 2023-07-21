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

import React, {useState, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import axios from '@canvas/axios'

const I18n = useI18nScope('assignments_2_student_annotation')

export default function StudentAnnotationAttempt(props) {
  const [iframeURL, setIframeURL] = useState(null)
  const [fetchingCanvadocSession, setFetchingCanvadocSession] = useState(true)
  const [validResponse, setValidResponse] = useState(true)

  const isSubmitted = ['graded', 'submitted'].includes(props.submission.state)

  useEffect(() => {
    axios
      .post('/api/v1/canvadoc_session', {
        submission_attempt:
          isSubmitted && props.submission.attempt !== 0 ? props.submission.attempt : 'draft',
        submission_id: props.submission._id,
      })
      .then(result => {
        setIframeURL(result.data.canvadocs_session_url)
        setFetchingCanvadocSession(false)
        setValidResponse(true)

        if (!isSubmitted || props.submission.attempt === 0) {
          props.createSubmissionDraft({
            variables: {
              id: props.submission.id,
              activeSubmissionType: 'student_annotation',
              attempt: props.submission.attempt || 1,
            },
          })
        }
      })
      .catch(_error => {
        setFetchingCanvadocSession(false)
        setValidResponse(false)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isSubmitted, props.submission.attempt])

  return (
    <div data-testid="canvadocs-pane">
      {fetchingCanvadocSession && <LoadingIndicator />}
      {validResponse ? (
        <div className="ef-file-preview-stretch">
          <iframe
            src={iframeURL}
            data-testid="canvadocs-iframe"
            allowFullScreen={true}
            title={I18n.t('Document to annotate')}
            className="ef-file-preview-frame annotated-document-submission"
            style={{width: '100%'}}
          />
        </div>
      ) : (
        <div>{I18n.t('There was an error loading the document.')}</div>
      )}
    </div>
  )
}
