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

import {z} from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
// biome-ignore lint/nursery/noImportCycles: replicated/ directory should be kept identical to the code in canvas-lms
import {type GqlTemplateStringType, gql} from '../../dependenciesShims'

const I18n = createI18nScope('lti_asset_processor')

export const LTI_ASSET_REPORT_COMMON_FIELDS: GqlTemplateStringType = gql`
  fragment LtiAssetReportCommonFields on LtiAssetReport {
    _id
    comment
    errorCode
    indicationAlt
    indicationColor
    launchUrlPath
    priority
    processingProgress
    processorId
    resubmitAvailable
    result
    resultTruncated
    title
    asset {
      attachmentId,
      submissionAttempt,
      discussionEntryVersion {
        _id
        messageIntro
        createdAt
      }
    }
  }
`

// For Student views in Canvas.
export const LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT: GqlTemplateStringType = gql`
  fragment LtiAssetReportForStudent on LtiAssetReport {
    ...LtiAssetReportCommonFields
    asset {
      attachmentName
    }
  }
  ${LTI_ASSET_REPORT_COMMON_FIELDS}
`

// Query used in SpeedGrader. Exported for use in Canvas.
export const LTI_ASSET_REPORTS_QUERY: GqlTemplateStringType = gql`
  query SpeedGrader_LtiAssetReportsQuery($assignmentId: ID!, $studentUserId: ID, $studentAnonymousId: ID) {
    submission(assignmentId: $assignmentId, userId: $studentUserId, anonymousId: $studentAnonymousId) {
      ltiAssetReportsConnection(first: 100) {
        nodes {
          ...LtiAssetReportCommonFields
        }
        pageInfo {
          hasNextPage
        }
      }
    }
  }
  ${LTI_ASSET_REPORT_COMMON_FIELDS}
`

// Disallows both studentUserId and studentAnonymousId being set
export const ZStudentUserIdOrAnonymousId: z.ZodSchema<
  | {studentUserId: string; studentAnonymousId: null}
  | {studentUserId: null; studentAnonymousId: string}
  | {studentUserId: null; studentAnonymousId: null}
> = z.union([
  z.object({
    studentUserId: z.string().min(1),
    studentAnonymousId: z.null(),
  }),
  z.object({
    studentUserId: z.null(),
    studentAnonymousId: z.string().min(1),
  }),
  z.object({
    studentUserId: z.null(),
    studentAnonymousId: z.null(),
  }),
])

export type StudentUserIdOrAnonymousId = z.infer<typeof ZStudentUserIdOrAnonymousId>

/**
 * Convenience function to extract user id & annonymous from an object
 * which contains other properties, and still keep the StudentUserIdOrAnonymousId
 * union type (tricky to keep in Typescript).
 */
export function extractStudentUserIdOrAnonymousId(
  params: StudentUserIdOrAnonymousId,
): StudentUserIdOrAnonymousId {
  const {studentUserId, studentAnonymousId} = params
  return {studentUserId, studentAnonymousId} as StudentUserIdOrAnonymousId
}

export const ZGetLtiAssetReportsParams: z.ZodSchema<
  {
    assignmentId: string
  } & StudentUserIdOrAnonymousId
> = z.intersection(ZStudentUserIdOrAnonymousId, z.object({assignmentId: z.string().min(1)}))

export type GetLtiAssetReportsParams = z.infer<typeof ZGetLtiAssetReportsParams>

export function getLtiAssetReportsErrorMessage(): string {
  return I18n.t('Error loading Document Processor Reports')
}
