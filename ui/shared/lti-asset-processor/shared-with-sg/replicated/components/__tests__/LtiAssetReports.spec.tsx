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

import {fireEvent, waitFor} from '@testing-library/react'
import {HttpResponse, http} from 'msw'
import {setupServer} from 'msw/node'
import {renderComponent} from '../../../__tests__/renderingShims'
import {clearAllMocks, describe, expect, fn, it} from '../../../__tests__/testPlatformShims'
import {defaultLtiAssetProcessors} from '../../__fixtures__/default/ltiAssetProcessors'
import {
  defaultLtiAssetReportsForDiscussion,
  makeMockReport,
} from '../../__fixtures__/default/ltiAssetReports'
import type {ResubmitLtiAssetReportsParams} from '../../mutations/resubmitLtiAssetReports'
import type {LtiAssetReport} from '../../types/LtiAssetReports'
import {LtiAssetReports} from '../LtiAssetReports'

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

const mockResubmitLtiAssetReports = fn((_params: ResubmitLtiAssetReportsParams) =>
  Promise.resolve(),
)

function setupMSWForResubmitLtiAssetReports() {
  server.use(
    http.post<{processorId: string; studentId: string; attempt: string}>(
      '/api/lti/asset_processors/:processorId/notices/:studentId/attempts/:attempt',
      async req => {
        await mockResubmitLtiAssetReports(req.params)
        return HttpResponse.json({})
      },
    ),
  )
}

describe('LtiAssetReports', () => {
  let attachments: {_id: string; displayName: string}[]
  let reports: LtiAssetReport[]
  let firstRep: LtiAssetReport

  const setup = (submissionType: 'online_upload' | 'online_text_entry') => {
    const attempt = '1'
    const studentId = '101'

    return renderComponent(
      <LtiAssetReports
        attachments={attachments}
        reports={reports}
        assetProcessors={defaultLtiAssetProcessors}
        attempt={attempt}
        studentIdForResubmission={studentId}
        submissionType={submissionType}
        showDocumentDisplayName={true}
      />,
    )
  }

  beforeEach(() => {
    clearAllMocks()

    attachments = [
      {_id: '20001', displayName: 'file1.pdf'},
      {_id: '20002', displayName: 'file2.pdf'},
    ]
    firstRep = makeMockReport({
      title: 'file1-AP1000-report1',
      processorId: '1000',
      asset: {
        attachmentId: '20001',
      },
    })
    reports = [
      firstRep,
      makeMockReport({
        title: 'file1-AP1000-report2',
        processorId: '1000',
        asset: {
          attachmentId: '20001',
          discussionEntryVersion: null,
        },
      }),
      makeMockReport({
        title: 'file1-AP1001-report1',
        processorId: '1001',
        asset: {
          attachmentId: '20001',
          discussionEntryVersion: null,
        },
      }),
      makeMockReport({
        title: 'file2-AP1000-report1',
        processorId: '1000',
        asset: {
          attachmentId: '20002',
          discussionEntryVersion: null,
        },
      }),
    ]
  })

  it('shows a heading for each file per AP', () => {
    const {getAllByText} = setup('online_upload')
    expect(getAllByText('file1.pdf')).toHaveLength(2)
  })

  it('shows a heading per AP (with tool title and AP title)', () => {
    const {getAllByText} = setup('online_upload')
    expect(getAllByText('MyToolTitle1 · MyAssetProcessor1')).toHaveLength(1)
    expect(getAllByText('MyToolTitle2 · MyAssetProcessor2')).toHaveLength(1)
  })

  it('renders report comments', () => {
    const {getAllByText} = setup('online_upload')
    expect(getAllByText('comment for file1-AP1000-report1')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP1000-report2')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP1001-report1')).toHaveLength(1)
    expect(getAllByText('comment for file2-AP1000-report1')).toHaveLength(1)
  })

  it('renders View Report button if launchUrlPath is present', () => {
    firstRep.launchUrlPath = null
    const {getAllByText} = setup('online_upload')
    expect(getAllByText('View Report')).toHaveLength(3)
  })

  it('renders error message (and comment) for failed reports', () => {
    firstRep.processingProgress = 'Failed'
    firstRep.errorCode = 'UNSUPPORTED_ASSET_TYPE'
    const {getAllByText} = setup('online_upload')
    expect(getAllByText('Unable to process: Invalid file type.')).toHaveLength(1)
    expect(getAllByText('comment for file1-AP1000-report1')).toHaveLength(1)
  })

  it('provides a default error message for unrecognized error codes', () => {
    firstRep.processingProgress = 'Failed'
    firstRep.errorCode = 'UNKNOWN_ERROR'
    const {getAllByText} = setup('online_upload')
    expect(
      getAllByText('The content could not be processed, or the processing failed.'),
    ).toHaveLength(1)
  })

  it('renders default info text for processing reports', () => {
    firstRep.processingProgress = 'Processing'
    firstRep.comment = null
    const {getAllByText} = setup('online_upload')
    expect(
      getAllByText('The content is being processed and the final report being generated.'),
    ).toHaveLength(1)
  })

  it("doesn't render default info text if there is a comment", () => {
    firstRep.processingProgress = 'Processing'
    const {queryByText} = setup('online_upload')
    expect(
      queryByText('The content is being processed and the final report being generated.'),
    ).not.toBeInTheDocument()
  })

  it('renders default info text for pending reports', () => {
    firstRep.processingProgress = 'Pending'
    firstRep.comment = null
    const {getAllByText} = setup('online_upload')
    expect(
      getAllByText(
        'The content is not currently being processed, and does not require intervention.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for pending manual reports', () => {
    firstRep.processingProgress = 'PendingManual'
    firstRep.comment = null
    const {getAllByText} = setup('online_upload')
    expect(
      getAllByText(
        'Manual intervention is required to start or complete the processing of the content.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for not processed reports', () => {
    firstRep.processingProgress = 'NotProcessed'
    firstRep.comment = null
    const {getAllByText} = setup('online_upload')
    expect(
      getAllByText(
        'The content will not be processed, and this is expected behavior for the current processor.',
      ),
    ).toHaveLength(1)
  })

  it('renders default info text for not ready reports', () => {
    firstRep.processingProgress = 'NotReady'
    firstRep.comment = null
    const {getAllByText} = setup('online_upload')
    expect(getAllByText('There is no processing occurring by the tool.')).toHaveLength(1)
  })

  describe('when there is no report for an (attachment, AP) combo', () => {
    it('renders a "no reports" message', () => {
      const {getAllByText} = setup('online_upload')
      // AP 1000 has no reports for attachment 20002
      expect(
        getAllByText('The document processor has not returned any reports for this file.'),
      ).toHaveLength(1)
    })
  })

  describe('resubmit button', () => {
    it('allows resubmit if there are missing reports', async () => {
      setupMSWForResubmitLtiAssetReports()

      // file2-AP1001-report1 missing

      const {getAllByText} = setup('online_upload')
      const resubmitButtons = getAllByText('Resubmit All Files')

      // AP 1001 has a missing report for attachment 20002
      expect(resubmitButtons).toHaveLength(1)

      const btn = resubmitButtons[0]
      if (!btn) {
        throw new Error('no resubmit button')
      }
      fireEvent.click(btn)

      await waitFor(() => {
        expect(mockResubmitLtiAssetReports).toHaveBeenCalledWith({
          attempt: '1',
          processorId: '1001',
          studentId: '101',
        })
      })
    })

    it('does not show resubmit button if there are no resubmittable/missing reports', () => {
      // Now AP 1001 cannot be resubmitted as it has all reports
      reports.push(
        makeMockReport({
          title: 'file2-AP1001-report1',
          processorId: '1001',
          asset: {
            attachmentId: '20002',
          },
        }),
      )

      const {queryByText} = setup('online_upload')
      expect(queryByText('Resubmit All Files')).not.toBeInTheDocument()
    })

    it('shows resubmit button if there is at least one resubmittable report', () => {
      reports.push(
        makeMockReport({
          title: 'file2-AP1001-report1',
          processorId: '1001',
          asset: {
            attachmentId: '20002',
          },
          resubmitAvailable: true,
        }),
      )

      const {getAllByText} = setup('online_upload')
      const resubmitButtons = getAllByText('Resubmit All Files')
      expect(resubmitButtons).toHaveLength(1)
    })

    it('shows a resubmit button per AP', () => {
      // file2-AP1001-report1 still missing, another AP 1000 report is resubmittable
      const rep = reports.find(r => r.title === 'file2-AP1000-report1')
      if (!rep) throw new Error('bad test setup')
      rep.resubmitAvailable = true

      const {getAllByText} = setup('online_upload')
      const resubmitButtons = getAllByText('Resubmit All Files')
      expect(resubmitButtons).toHaveLength(2)
    })

    it('does not show resubmit button if studentIdForResubmission is not given', () => {
      const {queryByText} = renderComponent(
        <LtiAssetReports
          attachments={attachments}
          reports={reports}
          assetProcessors={defaultLtiAssetProcessors}
          attempt="1"
          submissionType="online_upload"
          showDocumentDisplayName={true}
        />,
      )
      expect(queryByText('Resubmit All Files')).not.toBeInTheDocument()
    })
  })

  describe('with online_text_entry submission type', () => {
    beforeEach(() => {
      attachments = []

      reports = [
        makeMockReport({
          title: 'text-entry-AP1000-report1',
          processorId: '1000',
          asset: {
            submissionAttempt: 1,
            discussionEntryVersion: null,
          },
        }),
        makeMockReport({
          title: 'text-entry-AP1000-report2',
          processorId: '1000',
          asset: {
            submissionAttempt: 1,
            discussionEntryVersion: null,
          },
        }),
        makeMockReport({
          title: 'text-entry-AP1001-report1',
          processorId: '1001',
          asset: {
            submissionAttempt: 1,
            discussionEntryVersion: null,
          },
        }),
      ]
    })

    it('shows the heading for text entries', () => {
      const {getAllByText} = setup('online_text_entry')
      expect(getAllByText('Text submitted to Canvas')).toHaveLength(2)
    })

    it('shows a heading per AP (with tool title and AP title)', () => {
      const {getAllByText} = setup('online_text_entry')
      expect(getAllByText('MyToolTitle1 · MyAssetProcessor1')).toHaveLength(1)
      expect(getAllByText('MyToolTitle2 · MyAssetProcessor2')).toHaveLength(1)
    })
  })

  describe('with discussion_topic submission type', () => {
    const setupDiscussion = () => {
      const attempt = '1'
      const studentId = '101'

      return renderComponent(
        <LtiAssetReports
          attachments={[]}
          reports={reports}
          assetProcessors={defaultLtiAssetProcessors}
          attempt={attempt}
          studentIdForResubmission={studentId}
          submissionType="discussion_topic"
          showDocumentDisplayName={true}
        />,
      )
    }

    beforeEach(() => {
      attachments = []
      reports = defaultLtiAssetReportsForDiscussion({
        discussionEntryVersionId: 'entry_456',
        createdAt: '2025-01-20T10:30:00Z',
        messageIntro: 'My discussion post content',
      })
    })

    it('shows the heading for discussion entries with formatted display name', () => {
      const {getAllByText} = setupDiscussion()

      // Should show formatted display name containing date and quoted message intro
      // There are two instances because there is one for each processor with reports for the asset
      expect(getAllByText(/"My discussion post content"/)).toHaveLength(2)
    })

    it('shows a heading per AP (with tool title and AP title)', () => {
      const {getAllByText} = setupDiscussion()
      expect(getAllByText('MyToolTitle1 · MyAssetProcessor1')).toHaveLength(1)
      expect(getAllByText('MyToolTitle2 · MyAssetProcessor2')).toHaveLength(1)
    })

    it('renders discussion report comments', () => {
      const {getByText} = setupDiscussion()
      expect(getByText('comment for Discussion Analysis Report')).toBeInTheDocument()
      expect(getByText('comment for Discussion Content Check')).toBeInTheDocument()
      expect(getByText('comment for Discussion Failed Report')).toBeInTheDocument()
    })

    it('renders error message for failed discussion reports', () => {
      const {getByText} = setupDiscussion()
      expect(getByText('Unable to process: File is too large.')).toBeInTheDocument()
    })
  })
})
