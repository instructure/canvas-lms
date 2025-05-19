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
import {LtiAssetReports, LtiAssetReportsProps} from '../LtiAssetReports'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReport} from '@canvas/lti/model/AssetReport'
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
    processingProgress: 'Processed',
    reportType: 'originality',
    priority: 1,
    launchUrlPath: `/launch/report/${id}`,
    comment: `comment for ${title}`,
    ...overrides,
  }
}

describe('LtiAssetReports', () => {
  let assetProcessors: ExistingAttachedAssetProcessor[] = []
  let versionedAttachments: {attachment: {id: string; display_name: string}}[] = []
  let reportsByAttachment: Record<string, LtiAssetReportsByProcessor> = {}
  let firstRep: LtiAssetReport

  const setup = () => {
    const props = {versionedAttachments, reportsByAttachment, assetProcessors}
    return render(<LtiAssetReports {...props} />)
  }

  beforeEach(() => {
    versionedAttachments = [
      {attachment: {id: '20001', display_name: 'file1.pdf'}},
      {attachment: {id: '20002', display_name: 'file2.pdf'}},
    ]
    reportsByAttachment = {
      '20001': {
        '123': [makeMockReport('file1-AP123-report1'), makeMockReport('file1-AP123-report2')],
        '456': [makeMockReport('file1-AP456-report1')],
      },
      '20002': {
        '123': [makeMockReport('file2-AP123-report1')],
      },
    }
    firstRep = reportsByAttachment['20001']['123'][0]
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

  it('shows a heading for each file per AP', () => {
    const {getAllByText} = setup()
    expect(getAllByText('file1.pdf')).toHaveLength(2)
  })

  it('shows a heading per AP (with tool title and AP title)', () => {
    const {getAllByText} = setup()
    expect(getAllByText('tool1000label · ap123title')).toHaveLength(1)
    expect(getAllByText('tool1001label · ap456title')).toHaveLength(1)
  })

  it('renders report comments', () => {
    const {getAllByText} = setup()
    expect(getAllByText('comment for file1-AP123-report1')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP123-report2')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP456-report1')).toHaveLength(1)
    expect(getAllByText('comment for file2-AP123-report1')).toHaveLength(1)
  })

  it('renders View Report button if launchUrlPath is present', () => {
    delete firstRep.launchUrlPath
    const {getAllByText} = setup()
    expect(getAllByText('View Report')).toHaveLength(3)
  })

  it('renders error message (and comment) for failed reports', () => {
    firstRep.processingProgress = 'Failed'
    firstRep.errorCode = 'UNSUPPORTED_ASSET_TYPE'
    const {getAllByText} = setup()
    expect(getAllByText('Unable to process: Invalid file type.')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP123-report1')).toHaveLength(1)
  })

  it('provides a default error message for unrecognized error codes', () => {
    firstRep.processingProgress = 'Failed'
    firstRep.errorCode = 'UNKNOWN_ERROR'
    const {getAllByText} = setup()
    expect(
      getAllByText('The content could not be processed, or the processing failed.'),
    ).toHaveLength(1)
  })

  it('renders default info text for processing reports', () => {
    firstRep.processingProgress = 'Processing'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText('The content is being processed and the final report being generated.'),
    ).toHaveLength(1)
  })

  it("doesn't render default info text if there is a comment", () => {
    firstRep.processingProgress = 'Processing'
    const {queryByText} = setup()
    expect(
      queryByText('The content is being processed and the final report being generated.'),
    ).not.toBeInTheDocument()
  })

  it('renders default info text for pending reports', () => {
    firstRep.processingProgress = 'Pending'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText(
        'The content is not currently being processed, and does not require intervention.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for pending manual reports', () => {
    firstRep.processingProgress = 'PendingManual'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText(
        'Manual intervention is required to start or complete the processing of the content.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for not processed reports', () => {
    firstRep.processingProgress = 'NotProcessed'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(
      getAllByText(
        'The content will not be processed, and this is expected behavior for the current processor.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for not ready reports', () => {
    firstRep.processingProgress = 'NotReady'
    delete firstRep.comment
    const {getAllByText} = setup()
    expect(getAllByText('There is no processing occurring by the tool.')).toHaveLength(1)
  })

  it('renders a "no reports" message if there is no report for an (attachment, AP) combo', () => {
    const {getAllByText} = setup()
    // AP 123 has no reports for attachment 20002
    expect(
      getAllByText('The document processor has not returned any reports for this file.'),
    ).toHaveLength(1)
  })
})
