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

import type {GetLtiAssetReportsResult} from '../../../dependenciesShims'
import type {LtiAssetReport} from '../../types/LtiAssetReports'
import {defaultLtiAssetProcessors} from './ltiAssetProcessors'

let lastMockReportId = 100000

export function makeMockReport(
  params: Pick<LtiAssetReport, 'title' | 'asset' | 'processorId'> & Partial<LtiAssetReport>,
): LtiAssetReport {
  const {asset, title, processorId, ...overrides} = params
  const _id = overrides._id || String(lastMockReportId++)
  return {
    _id,
    asset,
    title,
    processorId,
    resultTruncated: '',
    processingProgress: 'Processed',
    priority: 1,
    launchUrlPath: `/launch/report/${_id}`,
    comment: `comment for ${title}`,
    errorCode: null,
    indicationAlt: null,
    indicationColor: null,
    result: '',
    resubmitAvailable: false,
    ...overrides,
  }
}

export function defaultLtiAssetReports({
  attachmentId,
  submissionAttempt,
}: {
  attachmentId?: string
  submissionAttempt?: number
}): LtiAssetReport[] {
  return [
    makeMockReport({
      _id: '1234',
      title: 'My OK Report',
      processorId: defaultLtiAssetProcessors[0]?._id || 'oops1',
      asset: {attachmentId, submissionAttempt},
    }),
    makeMockReport({
      _id: '1235',
      title: 'My Failed Report',
      errorCode: 'ASSET_TOO_LARGE',
      processingProgress: 'Failed',
      processorId: defaultLtiAssetProcessors[1]?._id || 'oops2',
      asset: {attachmentId, submissionAttempt},
    }),
    makeMockReport({
      _id: '1236',
      title: 'My Pending Report',
      processingProgress: 'PendingManual',
      processorId: defaultLtiAssetProcessors[1]?._id || 'oops3',
      resubmitAvailable: true,
      asset: {attachmentId, submissionAttempt},
    }),
  ]
}

export function defaultLtiAssetReportsForDiscussion({
  discussionEntryVersionId,
  createdAt,
  messageIntro,
}: {
  discussionEntryVersionId?: string
  createdAt?: string
  messageIntro?: string
} = {}): LtiAssetReport[] {
  return [
    makeMockReport({
      _id: '1237',
      title: 'Discussion Analysis Report',
      processorId: defaultLtiAssetProcessors[0]?._id || 'oops1',
      asset: {
        discussionEntryVersion: {
          _id: discussionEntryVersionId || 'entry_123',
          createdAt: createdAt || '2025-01-15T16:45:00Z',
          messageIntro: messageIntro || 'This is a test discussion entry message',
        },
      },
    }),
    makeMockReport({
      _id: '1238',
      title: 'Discussion Content Check',
      processorId: defaultLtiAssetProcessors[1]?._id || 'oops2',
      asset: {
        discussionEntryVersion: {
          _id: discussionEntryVersionId || 'entry_123',
          createdAt: createdAt || '2025-01-15T16:45:00Z',
          messageIntro: messageIntro || 'This is a test discussion entry message',
        },
      },
    }),
    makeMockReport({
      _id: '1239',
      title: 'Discussion Failed Report',
      errorCode: 'ASSET_TOO_LARGE',
      processingProgress: 'Failed',
      processorId: defaultLtiAssetProcessors[1]?._id || 'oops3',
      asset: {
        discussionEntryVersion: {
          _id: discussionEntryVersionId || 'entry_123',
          createdAt: createdAt || '2025-01-15T16:45:00Z',
          messageIntro: messageIntro || 'This is a test discussion entry message',
        },
      },
    }),
  ]
}

export function defaultGetLtiAssetReportsResult({
  attachmentId,
  submissionAttempt,
}: {
  attachmentId?: string
  submissionAttempt?: number
} = {}): GetLtiAssetReportsResult {
  return {
    submission: {
      ltiAssetReportsConnection: {
        nodes: defaultLtiAssetReports({attachmentId, submissionAttempt}),
        pageInfo: {
          hasNextPage: false,
        },
      },
    },
  }
}

export function defaultGetLtiAssetReportsResultForDiscussion({
  discussionEntryVersionId,
  createdAt,
  messageIntro,
}: {
  discussionEntryVersionId?: string
  createdAt?: string
  messageIntro?: string
} = {}): GetLtiAssetReportsResult {
  return {
    submission: {
      ltiAssetReportsConnection: {
        nodes: defaultLtiAssetReportsForDiscussion({
          discussionEntryVersionId,
          createdAt,
          messageIntro,
        }),
        pageInfo: {
          hasNextPage: false,
        },
      },
    },
  }
}
