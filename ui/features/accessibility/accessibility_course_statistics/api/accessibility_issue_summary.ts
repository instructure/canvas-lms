/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import doFetchApi from '@canvas/do-fetch-api-effect'
import type {AccessibilityIssueSummary} from '../types/accessibility_issue_summary'

interface FetchAccessibilityIssueSummaryParams {
  accountId: string
}

export const fetchAccessibilityIssueSummary = async (
  params: FetchAccessibilityIssueSummaryParams,
): Promise<AccessibilityIssueSummary> => {
  const {accountId} = params

  const response = await doFetchApi<AccessibilityIssueSummary>({
    path: `/api/v1/accounts/${accountId}/accessibility_issue_summary`,
  })

  return response.json || {active: 0, resolved: 0}
}
