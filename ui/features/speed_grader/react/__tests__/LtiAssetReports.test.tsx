/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {LtiAssetReports, LtiAssetReportsProps, joinAttachmentsAndReports} from '../LtiAssetReports'
import {ExistingAttachedAssetProcessor, LtiAssetReport} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReportsByProcessor} from 'features/speed_grader/jquery/speed_grader.d'

let lastMockReportId = 0

function makeMockReport(
  title: string,
  overrides: Partial<ExistingAttachedAssetProcessor> = {},
): LtiAssetReport {
  const id = lastMockReportId++
  return {
    id,
    title,
    processing_progress: 'Processed',
    report_type: 'originality',
    priority: 1,
    launch_url_path: `/launch/report/${id}`,
    comment: `comment for ${title}`,
    ...overrides,
  }
}

describe('LtiAssetReports', () => {
  let assetProcessors: ExistingAttachedAssetProcessor[] = []
  let attachmentsAndReports: LtiAssetReportsProps['attachmentsAndReports'] = []
  let firstRep: LtiAssetReport

  const setup = () => {
    const props = {attachmentsAndReports, assetProcessors}
    return render(<LtiAssetReports {...props} />)
  }

  beforeEach(() => {
    attachmentsAndReports = [
      {
        attachmentName: 'file1.pdf',
        reportsByProcessor: {
          '123': [makeMockReport('file1-AP123-report1'), makeMockReport('file1-AP123-report2')],
          '456': [makeMockReport('file1-AP456-report1')],
        },
      },
      {
        attachmentName: 'file2.pdf',
        reportsByProcessor: {
          '123': [makeMockReport('file2-AP123-report1')],
        },
      },
    ]

    firstRep = attachmentsAndReports[0].reportsByProcessor['123'][0]

    assetProcessors = [
      {
        id: 123,
        tool_id: 1000,
        tool_name: 'tool1000',
        tool_placement_label: 'tool1000label',
        title: 'ap123title',
        icon_or_tool_icon_url: 'https://example.com/tool1000.png',
      },
      {
        id: 456,
        tool_id: 1001,
        tool_name: 'tool1001',
        tool_placement_label: 'tool1001label',
        title: 'ap456title',
        icon_or_tool_icon_url: 'https://example.com/tool1001.png',
      },
    ]
  })

  it('shows a heading for each file', () => {
    const {getAllByText} = setup()
    expect(getAllByText('file1.pdf')).toHaveLength(1)
  })

  it('shows a heading with tool title and AP title per AP and file', () => {
    const {getAllByText} = setup()
    expect(getAllByText('tool1000label · ap123title')).toHaveLength(2)
    expect(getAllByText('tool1001label · ap456title')).toHaveLength(1)
  })

  it('renders report comments', () => {
    const {getAllByText} = setup()
    expect(getAllByText('comment for file1-AP123-report1')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP123-report2')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP456-report1')).toHaveLength(1)
    expect(getAllByText('comment for file2-AP123-report1')).toHaveLength(1)
  })

  it('renders View Report button if launch_url_path is present', () => {
    delete firstRep.launch_url_path
    const {getAllByText} = setup()
    expect(getAllByText('View Report')).toHaveLength(3)
  })

  it('renders error message (and comment) for failed reports', () => {
    firstRep.processing_progress = 'Failed'
    firstRep.error_code = 'UNSUPPORTED_ASSET_TYPE'
    const {getAllByText} = setup()
    expect(getAllByText('Unable to process: Invalid file type.')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP123-report1')).toHaveLength(1)
  })

  it('provides a default error message for unrecognized error codes', () => {
    firstRep.processing_progress = 'Failed'
    firstRep.error_code = 'UNKNOWN_ERROR'
    const {getAllByText} = setup()
    expect(
      getAllByText('The content could not be processed, or the processing failed.'),
    ).toHaveLength(1)
  })

  it('renders default info text for processing reports', () => {
    firstRep.processing_progress = 'Processing'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText('The content is being processed and the final report being generated.'),
    ).toHaveLength(1)
  })

  it("doesn't renders default info text if there is a comment", () => {
    firstRep.processing_progress = 'Processing'
    const {queryByText} = setup()
    expect(
      queryByText('The content is being processed and the final report being generated.'),
    ).not.toBeInTheDocument()
  })

  it('renders default info text for pending reports', () => {
    firstRep.processing_progress = 'Pending'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText(
        'The content is not currently being processed, and does not require intervention.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for pending manual reports', () => {
    firstRep.processing_progress = 'PendingManual'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText(
        'Manual intervention is required to start or complete the processing of the content.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for not processed reports', () => {
    firstRep.processing_progress = 'NotProcessed'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText(
        'The content will not be processed, and this is expected behavior for the current processor.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for not ready reports', () => {
    firstRep.processing_progress = 'NotReady'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(getAllByText('There is no processing occurring by the tool.')).toHaveLength(1)
  })
})

describe('joinAttachmentsAndReports', () => {
  const mockReports: Record<string, LtiAssetReportsByProcessor> = {
    '1001': {'123': [makeMockReport('report1')], '345': [makeMockReport('report2')]},
    '1002': {'123': [makeMockReport('report3')]},
  }

  it('returns undefined if versionedAttachments is undefined', () => {
    expect(joinAttachmentsAndReports(undefined, mockReports)).toBeUndefined()
  })

  it('returns undefined if reportsByAttachment is undefined', () => {
    const versionedAttachments = [{attachment: {id: '1', display_name: 'test.pdf'}}]
    expect(joinAttachmentsAndReports(versionedAttachments, undefined)).toBeUndefined()
  })

  it('returns undefined if there are no matching reports', () => {
    const versionedAttachments = [{attachment: {id: '2', display_name: 'test.pdf'}}]
    expect(joinAttachmentsAndReports(versionedAttachments, mockReports)).toBeUndefined()
  })

  it('joins attachments with their reports', () => {
    const versionedAttachments = [
      {attachment: {id: '1001', display_name: 'test.pdf'}},
      {attachment: {id: '1002', display_name: 'test2.pdf'}},
    ]
    const result = joinAttachmentsAndReports(versionedAttachments, mockReports)

    expect(result).toEqual([
      {
        attachmentName: 'test.pdf',
        reportsByProcessor: {
          '123': [expect.objectContaining({title: 'report1'})],
          '345': [expect.objectContaining({title: 'report2'})],
        },
      },
      {
        attachmentName: 'test2.pdf',
        reportsByProcessor: {
          '123': [expect.objectContaining({title: 'report3'})],
        },
      },
    ])
  })
})
