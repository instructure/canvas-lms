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

import type {GetCourseAssignmentsAssetReportsResult} from '../getCourseAssignmentsAssetReports'

export function defaultGetCourseAssignmentsAssetReportsResult({
  assignmentId = '1',
  assignmentName = 'Test Assignment',
  hasProcessor = true,
  hasReport = true,
  submissionType = 'online_upload',
  processorId = '100',
  processorTitle = 'Test Processor',
  toolId = '200',
  toolName = 'Test Tool',
  submissionId = '300',
  reportId = '400',
  attachmentId = '500',
  attachmentName = 'test.pdf',
  submissionAttempt = 1,
  processingProgress = 'Processed' as const,
  hasNextPage = false,
  endCursor = null,
}: {
  assignmentId?: string
  assignmentName?: string
  hasProcessor?: boolean
  hasReport?: boolean
  submissionType?: string
  processorId?: string
  processorTitle?: string
  toolId?: string
  toolName?: string
  submissionId?: string
  reportId?: string
  attachmentId?: string
  attachmentName?: string
  submissionAttempt?: number
  processingProgress?: 'Processed' | 'Processing' | 'Failed'
  hasNextPage?: boolean
  endCursor?: string | null
} = {}): GetCourseAssignmentsAssetReportsResult {
  return {
    __typename: 'Query',
    legacyNode: {
      __typename: 'Course',
      assignmentsConnection: {
        __typename: 'AssignmentConnection',
        nodes: [
          {
            __typename: 'Assignment',
            _id: assignmentId,
            name: assignmentName,
            ltiAssetProcessorsConnection: {
              __typename: 'LtiAssetProcessorConnection',
              nodes: hasProcessor
                ? [
                    {
                      __typename: 'LtiAssetProcessor',
                      _id: processorId,
                      title: processorTitle,
                      iconOrToolIconUrl: null,
                      externalTool: {
                        __typename: 'ExternalTool',
                        _id: toolId,
                        name: toolName,
                        labelFor: null,
                      },
                    },
                  ]
                : [],
            },
            submissionsConnection: {
              __typename: 'SubmissionConnection',
              nodes: [
                {
                  __typename: 'Submission',
                  _id: submissionId,
                  submissionType: submissionType as any,
                  ltiAssetReportsConnection: {
                    __typename: 'LtiAssetReportConnection',
                    nodes: hasReport
                      ? [
                          {
                            __typename: 'LtiAssetReport',
                            _id: reportId,
                            priority: 0,
                            resubmitAvailable: false,
                            processingProgress,
                            processorId,
                            comment: null,
                            errorCode: null,
                            indicationAlt: null,
                            indicationColor: null,
                            launchUrlPath: null,
                            result: null,
                            resultTruncated: null,
                            title: null,
                            asset: {
                              __typename: 'LtiAsset',
                              attachmentId,
                              attachmentName,
                              submissionAttempt,
                              discussionEntryVersion: null,
                            },
                          },
                        ]
                      : [],
                  },
                },
              ],
            },
          },
        ],
        pageInfo: {
          endCursor,
          hasPreviousPage: false,
          hasNextPage,
          startCursor: null,
        },
      },
    },
  }
}

export function emptyGetCourseAssignmentsAssetReportsResult(): GetCourseAssignmentsAssetReportsResult {
  return {
    __typename: 'Query',
    legacyNode: {
      __typename: 'Course',
      assignmentsConnection: {
        __typename: 'AssignmentConnection',
        nodes: [],
        pageInfo: {
          endCursor: null,
          hasPreviousPage: false,
          hasNextPage: false,
          startCursor: null,
        },
      },
    },
  }
}
