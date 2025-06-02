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
import {render, waitFor} from '@testing-library/react'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReport, LtiAssetReportsByProcessor} from '@canvas/lti/model/AssetReport'
import {LtiAssetReportsWrapper} from '../../react/LtiAssetReportsWrapper'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(),
  showFlashError: jest.fn(),
}))

jest.mock('@canvas/do-fetch-api-effect')
beforeEach(() => {
  // @ts-expect-error
  doFetchApi.mockClear()
  // @ts-expect-error
  showFlashSuccess.mockClear()
  // @ts-expect-error
  showFlashError.mockClear()
})

let lastMockReportId = 0

function makeMockReport(title: string, overrides: Partial<LtiAssetReport> = {}): LtiAssetReport {
  const _id = lastMockReportId++
  return {
    _id,
    title,
    processingProgress: 'Processed',
    reportType: 'originality',
    priority: 1,
    launchUrlPath: `/launch/report/${_id}`,
    comment: `comment for ${title}`,
    resubmitAvailable: false,
    ...overrides,
  }
}

describe('LtiAssetReports', () => {
  let assetProcessors: ExistingAttachedAssetProcessor[] = []
  let versionedAttachments: {attachment: {id: string; display_name: string}}[] = []
  let reportsByAttachment: Record<string, LtiAssetReportsByProcessor> = {}
  let firstRep: LtiAssetReport

  const setup = () => {
    const attempt = 1
    const studentId = '101'
    const props = {versionedAttachments, reportsByAttachment, assetProcessors, attempt, studentId}
    return render(<LtiAssetReportsWrapper {...props} />)
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

  describe('when there is no report for an (attachment, AP) combo', () => {
    it('renders a "no reports" message', () => {
      const {getAllByText} = setup()
      // AP 123 has no reports for attachment 20002
      expect(
        getAllByText('The document processor has not returned any reports for this file.'),
      ).toHaveLength(1)
    })
  })

  describe('resubmit button', () => {
    it('allows resubmit if there are missing reports', async () => {
      const {getAllByText} = setup()
      const resubmitButtons = getAllByText('Resubmit All Files')

      // AP 456 has a missing report for attachment 20002
      expect(resubmitButtons).toHaveLength(1)

      // @ts-expect-error
      doFetchApi.mockResolvedValue({status: 204})

      resubmitButtons[0].click()

      await waitFor(() => {
        expect(doFetchApi).toHaveBeenCalledWith({
          method: 'POST',
          path: '/api/lti/asset_processors/456/notices/101/attempts/1',
        })
      })

      await waitFor(() => {
        expect(showFlashSuccess).toHaveBeenCalledWith('Resubmitted to Document Processing App')
      })
    })

    it('does not show resubmit button if there are no resubmittable/missing reports', () => {
      // Now AP 456 cannot be resubmitted as it has all reports
      reportsByAttachment['20002']['456'] = [makeMockReport('file2-AP456-report1')]
      const {queryByText} = setup()
      expect(queryByText('Resubmit All Files')).not.toBeInTheDocument()
    })

    it('shows resubmit button if there is at least one resubmittable report', () => {
      const badreport = makeMockReport('file2-AP456-report1', {resubmitAvailable: true})
      reportsByAttachment['20002']['456'] = [badreport]
      const {getAllByText} = setup()
      const resubmitButtons = getAllByText('Resubmit All Files')
      expect(resubmitButtons).toHaveLength(1)
    })

    it('shows a resubmit button per AP', () => {
      const badreport = makeMockReport('file2-AP123-report1', {resubmitAvailable: true})
      reportsByAttachment['20002']['123'] = [badreport]
      const {getAllByText} = setup()
      const resubmitButtons = getAllByText('Resubmit All Files')
      expect(resubmitButtons).toHaveLength(2)
    })
  })
})
