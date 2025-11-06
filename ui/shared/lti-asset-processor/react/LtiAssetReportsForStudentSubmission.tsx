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

import {useState} from 'react'
import LtiAssetReportStatus from '../shared-with-sg/replicated/components/LtiAssetReportStatus'
import {useLtiAssetProcessorsAndReportsForStudent} from './hooks/useLtiAssetProcessorsAndReportsForStudent'
import StudentLtiAssetReportModal from './StudentLtiAssetReportModal'

/**
 * LtiAssetReports component is also used for Speedgrader (one assignment, but for a teacher)
 * and Gradebook page (multiple assignments)
 *
 * This component is specifically for Asset Reports shown for Students on the
 * Submission pages. It fetches the data and passes it to the presentational
 * LtiAssetReportStatus component.
 *
 * If attachmentId is undefined, shows reports for all attachments (including
 * RCE content) in the submission.
 */
export function LtiAssetReportsForStudentSubmission(props: {
  submissionId: string
  submissionType: string
  attachmentId?: string
}): JSX.Element | null {
  const data = useLtiAssetProcessorsAndReportsForStudent(props)
  const [showModal, setShowModal] = useState(false)

  if (!data) return null

  return (
    <>
      <LtiAssetReportStatus reports={data.reports} openModal={() => setShowModal(true)} />
      {showModal && <StudentLtiAssetReportModal {...data} onClose={() => setShowModal(false)} />}
    </>
  )
}
