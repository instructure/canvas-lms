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

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {LtiAssetReportsForStudentSubmission} from '@canvas/lti-asset-processor/react/LtiAssetReportsForStudentSubmission'
import {
  AssetReportsForStudentParams,
  useShouldShowLtiAssetReportsForStudent,
} from '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent'

const I18n = createI18nScope('assignments_2_student_content')

type DocumentProcessorsSectionProps = {
  submission: AssetReportsForStudentParams & {ifLastAttemptIsNumber: number}
}

/*
 * Document Processor status rendering for single file submissions.
 * If there are multiple attachments, the Document Processor status
 * is displayed in the files table (./AttemptType/FilePreview.jsx)
 */
export default function DocumentProcessorsSection({submission}: DocumentProcessorsSectionProps) {
  const shouldShow = useShouldShowLtiAssetReportsForStudent(submission)
  return shouldShow ? (
    <Flex alignItems="end" margin="medium 0" gap="x-small">
      <Text weight="bold">{I18n.t('Document processors')}</Text>
      <LtiAssetReportsForStudentSubmission
        submissionId={submission.submissionId}
        submissionType={submission.submissionType}
      />
    </Flex>
  ) : null
}
