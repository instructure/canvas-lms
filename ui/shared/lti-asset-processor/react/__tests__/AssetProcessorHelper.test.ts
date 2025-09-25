/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {filterReports, filterReportsByAttempt} from '../AssetProcessorHelper'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'

/**
 * Helper function to create a mock LtiAssetReportWithAsset
 */
const createMockReport = (
  overrides: Partial<LtiAssetReportWithAsset> = {},
): LtiAssetReportWithAsset => {
  return {
    _id: 1,
    priority: 0,
    processingProgress: 'Processed',
    reportType: 'test',
    resubmitAvailable: false,
    asset_processor_id: 1,
    asset: {
      id: 1,
      attachment_id: '123',
      attachment_name: 'test.pdf',
      submission_id: '1',
      submission_attempt: '1',
    },
    ...overrides,
  }
}

describe('AssetProcessorHelper', () => {
  describe('filterReports', () => {
    it('returns an empty array when asset reports is undefined', () => {
      const result = filterReports(undefined, '123')

      expect(result).toEqual([])
    })

    it('returns an empty array when attachmentId is undefined', () => {
      const result = filterReports([createMockReport()], undefined)

      expect(result).toEqual([])
    })

    it('returns filtered reports by attachment ID', () => {
      const mockReport1 = createMockReport()
      const mockReport2 = createMockReport({
        _id: 2,
        asset: {
          id: 2,
          attachment_id: '456',
          attachment_name: 'test2.pdf',
          submission_id: '1',
          submission_attempt: '1',
        },
      })

      const reports = [mockReport1, mockReport2]

      const result = filterReports(reports, '123')

      expect(result).toEqual([reports[0]])
    })
  })

  describe('filterReportsByAttempt', () => {
    it('returns an empty array when reports is undefined', () => {
      const result = filterReportsByAttempt(undefined, '1')

      expect(result).toEqual([])
    })

    it('returns an empty array when attemptId is undefined', () => {
      const result = filterReportsByAttempt([createMockReport()], undefined)

      expect(result).toEqual([])
    })

    it('returns filtered reports by attempt ID', () => {
      const mockReport1 = createMockReport()
      const mockReport2 = createMockReport({
        _id: 2,
        asset_processor_id: 2,
        asset: {
          id: 2,
          attachment_id: '456',
          attachment_name: 'test2.pdf',
          submission_id: '2',
          submission_attempt: '2',
        },
      })

      const reports = [mockReport1, mockReport2]

      const result = filterReportsByAttempt(reports, '1')

      expect(result).toEqual([reports[0]])
    })
  })
})
