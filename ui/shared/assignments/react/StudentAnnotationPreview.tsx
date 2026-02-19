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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {View} from '@instructure/ui-view'
import {Submission} from './AssignmentsPeerReviewsStudentTypes'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('student_annotation_preview')

interface StudentAnnotationPreviewProps {
  submission: Submission
}

interface CanvadocSessionResponse {
  canvadocs_session_url: string
}

const StudentAnnotationPreview: React.FC<StudentAnnotationPreviewProps> = ({submission}) => {
  const {
    data: iframeURL,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ['canvadocSession', submission._id, submission.attempt],
    queryFn: async () => {
      const {json} = await doFetchApi<CanvadocSessionResponse>({
        path: '/api/v1/canvadoc_session',
        method: 'POST',
        body: {
          submission_attempt: submission.attempt,
          submission_id: submission._id,
        },
      })
      return json?.canvadocs_session_url ?? null
    },
  })

  return (
    <View
      as="div"
      height="100%"
      background="secondary"
      data-testid="canvadocs-pane"
      overflowY="hidden"
    >
      {isLoading && <LoadingIndicator />}
      {isError ? (
        <View as="div" padding="medium" data-testid="canvadoc-error">
          {I18n.t('There was an error loading the document.')}
        </View>
      ) : (
        iframeURL && (
          <div className="ef-file-preview-stretch" style={{height: '100%'}}>
            <iframe
              src={iframeURL}
              data-testid="canvadocs-iframe"
              allowFullScreen={true}
              title={I18n.t('Document to annotate')}
              className="ef-file-preview-frame annotated-document-submission"
              style={{width: '100%', height: '100%', border: 'none'}}
            />
          </div>
        )
      )}
    </View>
  )
}

export default StudentAnnotationPreview
