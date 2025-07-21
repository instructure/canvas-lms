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

import {useScope as createI18nScope} from '@canvas/i18n'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'
import {filterReportsByAttempt} from '@canvas/lti-asset-processor/react/AssetProcessorHelper'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useMemo, useState} from 'react'
import AssetReportStatus from '@canvas/lti-asset-processor/react/AssetReportStatus'
import StudentAssetReportModal from '@canvas/lti-asset-processor/react/StudentAssetReportModal'

export const ASSET_REPORT_MODAL_EVENT = 'openAssetReportModal'
const I18n = createI18nScope('text_entry_asset_report_status_link')

interface Props {
  reports: LtiAssetReportWithAsset[]
  assetProcessors: ExistingAttachedAssetProcessor[]
  attempt: string
  assignmentName: string
}

/**
 * Asset Processor report status link in old student submission view for online text entry submissions.
 */
export default function TextEntryAssetReportStatusLink({
  reports,
  assetProcessors,
  attempt,
  assignmentName,
}: Props) {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const filteredReports = useMemo(
    () => filterReportsByAttempt(reports, attempt),
    [reports, attempt],
  )

  function handleClose() {
    setIsModalOpen(false)
  }

  return (
    <>
      <Flex gap="x-small" alignItems="end">
        <Text weight="bold">{I18n.t('Document Processors:')}</Text>
        <AssetReportStatus reports={filteredReports} openModal={() => setIsModalOpen(true)} />
      </Flex>
      {isModalOpen && (
        <StudentAssetReportModal
          assetProcessors={assetProcessors}
          assignmentName={assignmentName}
          open={isModalOpen}
          onClose={handleClose}
          reports={filteredReports}
          submissionType="online_text_entry"
        />
      )}
    </>
  )
}
