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

import type {GetLtiAssetProcessorsAndReportsForStudentResult} from '../getLtiAssetProcessorsAndReportsForStudent'
import type {LtiAssetReportForStudent} from '../../model/LtiAssetReport'
import {defaultLtiAssetProcessors} from '../../shared-with-sg/replicated/__fixtures__/default/ltiAssetProcessors'
import {defaultLtiAssetReports} from '../../shared-with-sg/replicated/__fixtures__/default/ltiAssetReports'

export function defaultLtiAssetReportsForStudent({
  attachmentId,
  submissionAttempt,
  attachmentName,
}: {
  attachmentId?: string
  submissionAttempt?: number
  attachmentName?: string
} = {}): LtiAssetReportForStudent[] {
  return defaultLtiAssetReports({attachmentId, submissionAttempt}).map(report => ({
    ...report,
    asset: {
      ...report.asset,
      attachmentName,
    },
  }))
}

export function defaultGetLtiAssetProcessorsAndReportsForStudentResult({
  assignmentName = 'Test Assignment',
  attachmentId,
  submissionAttempt,
  attachmentName,
}: {
  assignmentName?: string
  attachmentId?: string
  submissionAttempt?: number
  attachmentName?: string
} = {}): GetLtiAssetProcessorsAndReportsForStudentResult {
  return {
    submission: {
      attempt: submissionAttempt || 1,
      ltiAssetReportsConnection: {
        nodes: defaultLtiAssetReportsForStudent({attachmentId, submissionAttempt, attachmentName}),
      },
      assignment: {
        name: assignmentName,
        ltiAssetProcessorsConnection: {
          nodes: defaultLtiAssetProcessors,
        },
      },
    },
  }
}
