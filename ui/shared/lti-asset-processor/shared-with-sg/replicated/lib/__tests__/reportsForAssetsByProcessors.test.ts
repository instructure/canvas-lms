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

import {describe, expect, it} from '../../../__tests__/testPlatformShims'
import {reportsForAssetsByProcessors} from '../reportsForAssetsByProcessors'
import {defaultLtiAssetProcessors} from '../../__fixtures__/default/ltiAssetProcessors'
import {defaultLtiAssetReports, makeMockReport} from '../../__fixtures__/default/ltiAssetReports'
import type {LtiAssetReport} from '../../types/LtiAssetReports'

describe('reportsForAssetsByProcessors', () => {
  const mockProcessors = defaultLtiAssetProcessors

  describe('with online_text_entry submission type', () => {
    const reportsAssetSelector = {
      submissionType: 'online_text_entry' as const,
      attachments: [],
      attempt: '2',
    }

    it('groups reports by processor and filters by submission attempt', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: 2},
        }),
        makeMockReport({
          _id: 'report2',
          title: 'Report 2',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: 1}, // Different attempt
        }),
        makeMockReport({
          _id: 'report3',
          title: 'Report 3',
          processorId: mockProcessors[1]?._id || 'oops',
          asset: {submissionAttempt: 2},
        }),
      ]

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result).toHaveLength(2)

      // First processor
      expect(result[0]?.processor).toEqual(mockProcessors[0])
      expect(result[0]?.reportGroups).toHaveLength(1)
      expect(result[0]?.reportGroups[0]).toEqual({
        key: 'online_text_entry',
        displayName: 'Text submitted to Canvas',
        reports: [reports[0]], // Only report with attempt "2"
      })

      // Second processor
      expect(result[1]?.processor).toEqual(mockProcessors[1])
      expect(result[1]?.reportGroups).toHaveLength(1)
      expect(result[1]?.reportGroups[0]).toEqual({
        key: 'online_text_entry',
        displayName: 'Text submitted to Canvas',
        reports: [reports[2]],
      })
    })

    it('returns empty report groups when no reports match the attempt', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: 1}, // Different attempt
        }),
      ]

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result).toHaveLength(2)
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(0)
      expect(result[1]?.reportGroups[0]?.reports).toHaveLength(0)
    })

    it('handles string comparison for attempt matching', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: 2}, // Number
        }),
      ]

      const result = reportsForAssetsByProcessors(reports, mockProcessors, {
        ...reportsAssetSelector,
        attempt: '2', // String
      })

      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(1)
    })
  })

  describe('with online_upload submission type', () => {
    const attachments = [
      {_id: 'attachment1', displayName: 'Document.pdf'},
      {_id: 'attachment2', displayName: 'Spreadsheet.xlsx'},
    ]

    const reportsAssetSelector = {
      submissionType: 'online_upload' as const,
      attachments,
      attempt: '1',
    }

    it('groups reports by attachment', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report for PDF',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {attachmentId: 'attachment1'},
        }),
        makeMockReport({
          _id: 'report2',
          title: 'Report for Excel',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {attachmentId: 'attachment2'},
        }),
        makeMockReport({
          _id: 'report3',
          title: 'Another PDF Report',
          processorId: mockProcessors[1]?._id || 'oops',
          asset: {attachmentId: 'attachment1'},
        }),
      ]

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result).toHaveLength(2)

      // First processor
      expect(result[0]?.processor).toEqual(mockProcessors[0])
      expect(result[0]?.reportGroups).toHaveLength(2)

      expect(result[0]?.reportGroups[0]).toEqual({
        key: 'attachment1',
        displayName: 'Document.pdf',
        reports: [reports[0]],
      })

      expect(result[0]?.reportGroups[1]).toEqual({
        key: 'attachment2',
        displayName: 'Spreadsheet.xlsx',
        reports: [reports[1]],
      })

      // Second processor
      expect(result[1]?.processor).toEqual(mockProcessors[1])
      expect(result[1]?.reportGroups).toHaveLength(2)

      expect(result[1]?.reportGroups[0]).toEqual({
        key: 'attachment1',
        displayName: 'Document.pdf',
        reports: [reports[2]],
      })

      expect(result[1]?.reportGroups[1]).toEqual({
        key: 'attachment2',
        displayName: 'Spreadsheet.xlsx',
        reports: [],
      })
    })

    it('handles empty attachments list', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {attachmentId: 'attachment1'},
        }),
      ]

      const result = reportsForAssetsByProcessors(reports, mockProcessors, {
        ...reportsAssetSelector,
        attachments: [],
      })

      expect(result[0]?.reportGroups).toHaveLength(0)
      expect(result[1]?.reportGroups).toHaveLength(0)
    })

    it('handles reports with no matching attachment', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {attachmentId: 'nonexistent_attachment'},
        }),
      ]

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      // Should still create groups for all attachments, but with empty reports
      expect(result[0]?.reportGroups).toHaveLength(2)
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(0)
      expect(result[0]?.reportGroups[1]?.reports).toHaveLength(0)
    })
  })

  describe('with no reports', () => {
    it('returns empty report groups for all processors', () => {
      const reports: LtiAssetReport[] = []
      const reportsAssetSelector = {
        submissionType: 'online_text_entry' as const,
        attachments: [],
        attempt: '1',
      }

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result).toHaveLength(2)
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(0)
      expect(result[1]?.reportGroups[0]?.reports).toHaveLength(0)
    })
  })

  describe('with no processors', () => {
    it('returns empty array', () => {
      const reports = defaultLtiAssetReports({submissionAttempt: 1})
      const reportsAssetSelector = {
        submissionType: 'online_text_entry' as const,
        attachments: [],
        attempt: '1',
      }

      const result = reportsForAssetsByProcessors(reports, [], reportsAssetSelector)

      expect(result).toHaveLength(0)
    })
  })

  describe("with reports that don't match any processor", () => {
    it('filters out reports with unknown processor IDs', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: 'unknown_processor_id',
          asset: {submissionAttempt: 1},
        }),
      ]

      const reportsAssetSelector = {
        submissionType: 'online_text_entry' as const,
        attachments: [],
        attempt: '1',
      }

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result).toHaveLength(2)
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(0)
      expect(result[1]?.reportGroups[0]?.reports).toHaveLength(0)
    })
  })

  describe('using fixture data', () => {
    it('correctly groups default fixture reports', () => {
      const reports = defaultLtiAssetReports({
        attachmentId: 'test_attachment',
        submissionAttempt: 1,
      })

      const reportsAssetSelector = {
        submissionType: 'online_upload' as const,
        attachments: [{_id: 'test_attachment', displayName: 'Test File.pdf'}],
        attempt: '1',
      }

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result).toHaveLength(2)

      // First processor should have the first report
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(1)
      expect(result[0]?.reportGroups[0]?.reports[0]?.title).toBe('My OK Report')

      // Second processor should have the other two reports
      expect(result[1]?.reportGroups[0]?.reports).toHaveLength(2)
      expect(result[1]?.reportGroups[0]?.reports[0]?.title).toBe('My Failed Report')
      expect(result[1]?.reportGroups[0]?.reports[1]?.title).toBe('My Pending Report')
    })
  })

  describe('edge cases', () => {
    it('handles null/undefined asset properties', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: null},
        }),
      ]

      const reportsAssetSelector = {
        submissionType: 'online_text_entry' as const,
        attachments: [],
        attempt: '1',
      }

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      // Should not match since null !== "1"
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(0)
    })

    it('handles mixed data types for submission attempt', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: 2}, // String in asset
        }),
      ]

      const reportsAssetSelector = {
        submissionType: 'online_text_entry' as const,
        attachments: [],
        attempt: '2', // String in selector
      }

      const result = reportsForAssetsByProcessors(reports, mockProcessors, reportsAssetSelector)

      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(1)
    })
  })
})
