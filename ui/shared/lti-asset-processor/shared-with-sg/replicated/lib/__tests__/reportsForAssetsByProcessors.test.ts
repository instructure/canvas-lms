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
import {defaultLtiAssetProcessors} from '../../__fixtures__/default/ltiAssetProcessors'
import {defaultLtiAssetReports, makeMockReport} from '../../__fixtures__/default/ltiAssetReports'
import type {LtiAssetReport} from '../../types/LtiAssetReports'
import {reportsForAssetsByProcessors} from '../reportsForAssetsByProcessors'

const dateTimeFmtOpts = {
  timeStyle: 'long',
  dateStyle: 'long',
  timeZone: 'UTC',
} as const
const formatDateTime = new Intl.DateTimeFormat('en-US', dateTimeFmtOpts).format

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        {
          ...reportsAssetSelector,
          attempt: '2', // String
        },
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        {
          ...reportsAssetSelector,
          attachments: [],
        },
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(reports, [], reportsAssetSelector, formatDateTime)

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

  describe('with discussion_topic submission type', () => {
    const reportsAssetSelector = {
      submissionType: 'discussion_topic' as const,
      attachments: [],
      attempt: '1',
    }

    it('groups reports by discussion entry version ID', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Discussion Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {
            discussionEntryVersion: {
              _id: 'entry1',
              createdAt: '2025-01-15T16:45:00Z',
              messageIntro: 'This is a test discussion entry message that is quite long',
            },
          },
        }),
        makeMockReport({
          _id: 'report2',
          title: 'Discussion Report 2',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {
            discussionEntryVersion: {
              _id: 'entry1',
              createdAt: '2025-01-15T16:45:00Z',
              messageIntro: 'This is a test discussion entry message that is quite long',
            },
          },
        }),
        makeMockReport({
          _id: 'report3',
          title: 'Discussion Report 3',
          processorId: mockProcessors[1]?._id || 'oops',
          asset: {
            discussionEntryVersion: {
              _id: 'entry2',
              createdAt: '2025-02-20T09:30:00Z',
              messageIntro: 'Another discussion entry',
            },
          },
        }),
      ]

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

      expect(result).toHaveLength(2)

      // First processor - should have one group with two reports
      expect(result[0]?.processor).toEqual(mockProcessors[0])
      expect(result[0]?.reportGroups).toHaveLength(1)
      expect(result[0]?.reportGroups[0]?.key).toBe('entry1')
      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(2)

      // Second processor - should have one group with one report
      expect(result[1]?.processor).toEqual(mockProcessors[1])
      expect(result[1]?.reportGroups).toHaveLength(1)
      expect(result[1]?.reportGroups[0]?.key).toBe('entry2')
      expect(result[1]?.reportGroups[0]?.reports).toHaveLength(1)
    })

    it('formats display name with localized date and quoted messageIntro', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Discussion Report',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {
            discussionEntryVersion: {
              _id: 'entry1',
              createdAt: '2025-01-15T16:45:00Z',
              messageIntro: 'This is a test discussion entry message',
            },
          },
        }),
      ]

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

      // Display name should contain formatted date, colon, and quoted messageIntro
      const displayName = result[0]?.reportGroups[0]?.displayName
      expect(displayName).not.toContain('2025-01-15T16:45:00Z')
      expect(displayName).toContain(
        'January 15, 2025 at 4:45:00 PM UTC: "This is a test discussion entry message"',
      )
    })

    it('handles reports with no discussion entry version', () => {
      const reports: LtiAssetReport[] = [
        makeMockReport({
          _id: 'report1',
          title: 'Report without discussion',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {submissionAttempt: 1},
        }),
      ]

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

      // Should return empty report groups since no discussion entries
      expect(result[0]?.reportGroups).toHaveLength(0)
      expect(result[1]?.reportGroups).toHaveLength(0)
    })

    it('includes both attachment assets and discussion entry assets', () => {
      const attachments = [
        {_id: 'attachment1', displayName: 'Document.pdf'},
        {_id: 'attachment2', displayName: 'Spreadsheet.xlsx'},
      ]

      const reportsAssetSelectorWithAttachments = {
        submissionType: 'discussion_topic' as const,
        attachments,
        attempt: '1',
      }

      const reports: LtiAssetReport[] = [
        // Attachment reports
        makeMockReport({
          _id: 'report1',
          title: 'Attachment Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {attachmentId: 'attachment1'},
        }),
        makeMockReport({
          _id: 'report2',
          title: 'Attachment Report 2',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {attachmentId: 'attachment2'},
        }),
        // Discussion entry reports
        makeMockReport({
          _id: 'report3',
          title: 'Discussion Report 1',
          processorId: mockProcessors[0]?._id || 'oops',
          asset: {
            discussionEntryVersion: {
              _id: 'entry1',
              createdAt: '2025-01-15T16:45:00Z',
              messageIntro: 'This is a discussion entry',
            },
          },
        }),
        makeMockReport({
          _id: 'report4',
          title: 'Discussion Report 2',
          processorId: mockProcessors[1]?._id || 'oops',
          asset: {
            discussionEntryVersion: {
              _id: 'entry2',
              createdAt: '2025-02-20T09:30:00Z',
              messageIntro: 'Another discussion entry',
            },
          },
        }),
      ]

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelectorWithAttachments,
        formatDateTime,
      )

      expect(result).toHaveLength(2)

      // First processor should have attachment groups + discussion groups
      expect(result[0]?.processor).toEqual(mockProcessors[0])
      expect(result[0]?.reportGroups).toHaveLength(3) // 2 attachments + 1 discussion entry

      // Check attachment groups
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

      // Check discussion entry group
      expect(result[0]?.reportGroups[2]?.key).toBe('entry1')
      expect(result[0]?.reportGroups[2]?.reports).toHaveLength(1)
      expect(result[0]?.reportGroups[2]?.reports[0]).toEqual(reports[2])

      // Second processor should have attachment groups (empty) + discussion groups
      expect(result[1]?.processor).toEqual(mockProcessors[1])
      expect(result[1]?.reportGroups).toHaveLength(3) // 2 attachments + 1 discussion entry

      // Check attachment groups (should be empty for second processor)
      expect(result[1]?.reportGroups[0]).toEqual({
        key: 'attachment1',
        displayName: 'Document.pdf',
        reports: [],
      })
      expect(result[1]?.reportGroups[1]).toEqual({
        key: 'attachment2',
        displayName: 'Spreadsheet.xlsx',
        reports: [],
      })

      // Check discussion entry group
      expect(result[1]?.reportGroups[2]?.key).toBe('entry2')
      expect(result[1]?.reportGroups[2]?.reports).toHaveLength(1)
      expect(result[1]?.reportGroups[2]?.reports[0]).toEqual(reports[3])
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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

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

      const result = reportsForAssetsByProcessors(
        reports,
        mockProcessors,
        reportsAssetSelector,
        formatDateTime,
      )

      expect(result[0]?.reportGroups[0]?.reports).toHaveLength(1)
    })
  })
})
