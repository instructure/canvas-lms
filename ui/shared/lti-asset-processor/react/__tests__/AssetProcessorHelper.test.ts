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

import {
  clearAssetProcessorReports,
  filterReports,
  filterReportsByAttempt,
  shouldRenderAssetProcessorData,
} from '../AssetProcessorHelper'
import {LtiAssetReportWithAsset} from '@canvas/lti-asset-processor/model/AssetReport'

declare const window: {
  ENV: {
    ASSET_REPORTS?: LtiAssetReportWithAsset[] | null
    ASSET_PROCESSORS?: object[]
    ASSIGNMENT_NAME?: string
    SUBMISSION_TYPE?: string
  }
}

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
  let oldEnv: typeof window.ENV

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {}
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  describe('filterReports', () => {
    it('returns an empty array when ASSET_REPORTS is undefined', () => {
      window.ENV.ASSET_REPORTS = undefined

      const result = filterReports(window.ENV.ASSET_REPORTS, '123')

      expect(result).toEqual([])
    })

    it('returns an empty array when attachmentId is undefined', () => {
      window.ENV.ASSET_REPORTS = [createMockReport()]

      const result = filterReports(window.ENV.ASSET_REPORTS, undefined)

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
      window.ENV.ASSET_REPORTS = reports

      const result = filterReports(window.ENV.ASSET_REPORTS, '123')

      expect(result).toEqual([reports[0]])
    })
  })

  describe('filterReportsByAttempt', () => {
    it('returns an empty array when ASSET_REPORTS is undefined', () => {
      window.ENV.ASSET_REPORTS = undefined

      const result = filterReportsByAttempt(window.ENV.ASSET_REPORTS, '1')

      expect(result).toEqual([])
    })

    it('returns an empty array when attemptId is undefined', () => {
      window.ENV.ASSET_REPORTS = [createMockReport()]

      const result = filterReportsByAttempt(window.ENV.ASSET_REPORTS, undefined)

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
      window.ENV.ASSET_REPORTS = reports

      const result = filterReportsByAttempt(window.ENV.ASSET_REPORTS, '1')

      expect(result).toEqual([reports[0]])
    })
  })

  describe('shouldRenderAssetProcessorData', () => {
    it('returns false when there are no asset processors', () => {
      window.ENV.ASSET_PROCESSORS = []
      window.ENV.ASSET_REPORTS = []

      const result = shouldRenderAssetProcessorData()

      expect(result).toBe(false)
    })

    it('returns false when asset processors is undefined', () => {
      window.ENV.ASSET_PROCESSORS = undefined
      window.ENV.ASSET_REPORTS = []

      const result = shouldRenderAssetProcessorData()

      expect(result).toBe(false)
    })

    it('returns false when asset reports is undefined', () => {
      window.ENV.ASSET_PROCESSORS = [{}]
      window.ENV.ASSET_REPORTS = null

      const result = shouldRenderAssetProcessorData()

      expect(result).toBe(false)
    })

    it('returns true when both asset processors and reports exist', () => {
      window.ENV.ASSET_PROCESSORS = [{}]
      window.ENV.ASSET_REPORTS = []

      const result = shouldRenderAssetProcessorData()

      expect(result).toBe(true)
    })
  })

  describe('clearAssetProcessorReports', () => {
    it('clears the ASSET_REPORTS property', () => {
      window.ENV.ASSET_REPORTS = [createMockReport()]

      clearAssetProcessorReports()

      expect(window.ENV.ASSET_REPORTS).toBeUndefined()
    })
  })
})
