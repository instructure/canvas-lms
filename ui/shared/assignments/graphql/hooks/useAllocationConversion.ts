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

import {useCheckAllocationConversion} from './useCheckAllocationConversion'
import {
  useConvertAllocations,
  CONVERSION_JOB_NOT_STARTED,
  CONVERSION_JOB_COMPLETE,
  CONVERSION_JOB_FAILED,
} from './useConvertAllocations'

export function useAllocationConversion(courseId: string, assignmentId: string, enabled: boolean) {
  const {hasLegacyAllocations, loading} = useCheckAllocationConversion(
    courseId,
    assignmentId,
    enabled,
  )

  const {
    launchConversion,
    launchDeletion,
    conversionAction,
    conversionJobState,
    conversionJobProgress,
    conversionJobError,
  } = useConvertAllocations(courseId, assignmentId)

  const isConversionInProgress =
    conversionJobState !== CONVERSION_JOB_NOT_STARTED &&
    conversionJobState !== CONVERSION_JOB_COMPLETE &&
    conversionJobState !== CONVERSION_JOB_FAILED

  const isConversionComplete = conversionJobState === CONVERSION_JOB_COMPLETE

  return {
    hasLegacyAllocations,
    loading,
    launchConversion,
    launchDeletion,
    conversionAction,
    conversionJobState,
    conversionJobProgress,
    conversionJobError,
    isConversionInProgress,
    isConversionComplete,
  }
}
