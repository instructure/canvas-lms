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

import useLaunchConversionJobHook, {
  CONVERSION_JOB_COMPLETE,
  CONVERSION_JOB_NOT_STARTED,
  CONVERSION_JOB_RUNNING,
  CONVERSION_JOB_QUEUED,
  CONVERSION_JOB_FAILED,
} from './hooks/LaunchConversionJobHook'
import ConversionMessage from './ConversionMessage'
import ConversionProgress from './ConversionProgress'
import ConversionSuccess from './ConversionSuccess'
import ConversionFailure from './ConversionFailure'

interface CourseDifferentiationTagConverterMessageProps {
  courseId: string
  activeConversionJob: boolean
}

const CourseDifferentiationTagConverterMessage = ({
  courseId,
  activeConversionJob = false,
}: CourseDifferentiationTagConverterMessageProps) => {
  const {launchConversionJob, conversionJobState, conversionJobProgress, conversionJobError} =
    useLaunchConversionJobHook(courseId, activeConversionJob)

  return (
    <>
      {conversionJobState === CONVERSION_JOB_NOT_STARTED && (
        <ConversionMessage onCourseConvertTags={launchConversionJob} />
      )}
      {(conversionJobState === CONVERSION_JOB_QUEUED ||
        conversionJobState === CONVERSION_JOB_RUNNING) && (
        <ConversionProgress progress={conversionJobProgress} />
      )}
      {conversionJobState === CONVERSION_JOB_COMPLETE && <ConversionSuccess />}
      {conversionJobState === CONVERSION_JOB_FAILED && (
        <ConversionFailure conversionError={conversionJobError} />
      )}
    </>
  )
}

export default CourseDifferentiationTagConverterMessage
