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
import LtiAssetProcessorCell from './LtiAssetProcessorCell'
import {
  useCourseAssignmentsAssetReports,
  UseCourseAssignmentsAssetReportsParams,
  ZUseCourseAssignmentsAssetReportsParams,
} from '@canvas/lti-asset-processor/react/hooks/useCourseAssignmentsAssetReports'
import {z} from 'zod'

const I18n = createI18nScope('gradingGradeSummary')

export const ZLtiAssetProcessorCellWithDataProps = ZUseCourseAssignmentsAssetReportsParams.extend({
  assignmentId: z.string(),
})

export type LtiAssetProcessorCellWithDataProps = z.infer<typeof ZLtiAssetProcessorCellWithDataProps>

// Used in old (non-React/graphql) Student Grades UI
export function LtiAssetProcessorCellWithData({
  assignmentId,
  ...queryProps
}: LtiAssetProcessorCellWithDataProps) {
  const query = useCourseAssignmentsAssetReports(queryProps)
  const data = query.data?.get(assignmentId)
  return data ? <LtiAssetProcessorCell {...data} /> : null
}

export function AssetProcessorHeaderForGrades(queryProps: UseCourseAssignmentsAssetReportsParams) {
  const query = useCourseAssignmentsAssetReports(queryProps)
  return query.data?.size ? <>{I18n.t('Document Processors')}</> : null
}
