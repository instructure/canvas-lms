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

import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import AssetReportStatus from '@canvas/lti-asset-processor/react/AssetReportStatus'
import StudentAssetReportModal from '@canvas/lti-asset-processor/react/StudentAssetReportModal'
import {
  filterReports,
  filterReportsByAttempt,
  shouldRenderAssetProcessorData,
} from '@canvas/lti-asset-processor/react/AssetProcessorHelper'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'
import {Submission} from '../../assignments_show_student.d'

const I18n = createI18nScope('assignments_2_student_content')

declare const ENV: {
  ASSET_REPORTS?: LtiAssetReportWithAsset[]
  ASSET_PROCESSORS?: ExistingAttachedAssetProcessor[]
  ASSIGNMENT_NAME?: string
}

type DocumentProcessorsSectionProps = {
  submission: Submission
}
type AssetReportSelectorType = {
  type: 'attachment' | 'text_entry'
  value: string
}

/*
 * Document Processor status rendering for single file submissions.
 * If there are multiple attachments, the Document Processor status
 * is displayed in the files table (FilePreview).
 */
export default function DocumentProcessorsSection({submission}: DocumentProcessorsSectionProps) {
  const [apModalAssetReportSelector, setApModalAssetReportSelector] =
    useState<AssetReportSelectorType | null>(null)

  if (!shouldRenderAssetProcessorData()) {
    return null
  }

  if (
    submission.submissionType !== 'online_text_entry' &&
    submission.submissionType !== 'online_upload'
  ) {
    return null
  }

  const renderSingleAPStatus =
    submission.attachments.length === 1 || submission.submissionType === 'online_text_entry'

  if (!renderSingleAPStatus) {
    return null
  }

  const attempt = submission.attempt?.toString() ?? ''

  return (
    <>
      <Flex alignItems="end" margin="medium 0" gap="x-small">
        <Text weight="bold">{I18n.t('Document processors')}</Text>
        {submission.attachments.length === 1 && (
          <AssetReportStatus
            reports={filterReports(ENV.ASSET_REPORTS, submission.attachments[0]._id)}
            openModal={() =>
              setApModalAssetReportSelector({
                type: 'attachment',
                value: submission.attachments[0]._id,
              })
            }
          />
        )}
        {submission.submissionType === 'online_text_entry' && (
          <AssetReportStatus
            reports={filterReportsByAttempt(ENV.ASSET_REPORTS, attempt)}
            openModal={() =>
              setApModalAssetReportSelector({
                type: 'text_entry',
                value: attempt,
              })
            }
          />
        )}
      </Flex>
      {apModalAssetReportSelector && (
        <StudentAssetReportModal
          assetProcessors={ENV.ASSET_PROCESSORS ?? []}
          assignmentName={ENV.ASSIGNMENT_NAME ?? ''}
          open={apModalAssetReportSelector !== null}
          reports={
            apModalAssetReportSelector.type === 'attachment'
              ? filterReports(ENV.ASSET_REPORTS, apModalAssetReportSelector.value)
              : filterReportsByAttempt(ENV.ASSET_REPORTS, apModalAssetReportSelector.value)
          }
          submissionType={submission.submissionType}
          onClose={() => setApModalAssetReportSelector(null)}
        />
      )}
    </>
  )
}
