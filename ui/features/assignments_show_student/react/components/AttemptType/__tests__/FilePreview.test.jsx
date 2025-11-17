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

import FilePreview from '../FilePreview'
import {fireEvent, render, screen, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {
  defaultGetLtiAssetProcessorsAndReportsForStudentResult,
  defaultLtiAssetReportsForStudent,
} from '@canvas/lti-asset-processor/queries/__fixtures__/LtiAssetProcessorsAndReportsForStudent'

const files = [
  {
    _id: '1',
    displayName: 'file_1.png',
    id: '1',
    mimeClass: 'image',
    submissionPreviewUrl: '/preview_url',
    thumbnailUrl: '/thumbnail_url',
    url: '/url',
    size: '670 Bytes',
  },
  {
    _id: '2',
    displayName: 'file_2.zip',
    id: '2',
    mimeClass: 'file',
    url: '/url',
    size: '107 GB',
  },
  {
    _id: '3',
    displayName: 'file_2.zip',
    id: '3',
    mimeClass: 'file',
    url: '/url',
    size: '10 GB',
  },
]

const originalityData = {
  attachment_1: {
    similarity_score: 75,
    state: 'problem',
    report_url: 'http://example.com',
    status: 'scored',
  },
  attachment_2: {
    similarity_score: null,
    state: 'error',
    report_url: 'http://example.com',
    status: 'error',
  },
  attachment_3: {
    similarity_score: 10,
    state: 'acceptable',
    report_url: 'http://example.com',
    status: 'scored',
  },
}

// Override default URL mock
const resolvers = () => ({
  File: {
    submissionPreviewUrl: ({$ref}) => files[$ref.key - 1].submissionPreviewUrl,
    thumbnailUrl: ({$ref}) => files[$ref.key - 1].thumbnailUrl,
  },
})

const mockSubmissionWithResolvers = overrides => mockSubmission(overrides, resolvers)
let originalEnv

describe('FilePreview', () => {
  beforeEach(() => {
    originalEnv = global.ENV
    global.ENV = {...originalEnv, FEATURES: {lti_asset_processor: true}}
    jest.clearAllMocks()
  })

  afterEach(() => {
    global.ENV = originalEnv
  })

  it('renders a message if there are no files to display', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: []},
      }),
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.getByText('No Submission')).toBeInTheDocument()
  })

  it('renders the appropriate file icons', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files},
      }),
    }
    const {container} = render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.getByTestId('uploaded_files_table')).toBeInTheDocument()

    // renders a thumbnail for the file with a preview url
    expect(screen.getByTestId('uploaded_files_table')).toContainElement(
      container.querySelector('img[alt="file_1.png preview"]'),
    )

    // renders an icon for the file without a preview url
    expect(screen.getByTestId('uploaded_files_table')).toContainElement(
      container.querySelector('svg[name="IconPaperclip"]'),
    )
  })

  it('does not render the file icons if there is only one file', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: [files[0]]},
      }),
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.queryByTestId('assignments_2_file_icons')).not.toBeInTheDocument()
  })

  it('renders orignality reports for each file if turnitin data exists and there is more than one attachment', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files, originalityData, submissionType: 'online_upload'},
      }),
      isOriginalityReportVisible: true,
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    const reports = screen.getAllByTestId('originality_report')

    expect(reports).toHaveLength(2)
    expect(reports[0].textContent).toBe('75%')
    expect(reports[1].textContent).toBe('10%')
  })

  it('does not render orignality reports if only one attachment exists', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: [files[0]], originalityData, submissionType: 'online_upload'},
      }),
      isOriginalityReportVisible: true,
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('does not render orignality reports if the reports are not visible to the student', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {
          attachments: files,
          originalityData,
          submissionType: 'online_upload',
        },
      }),
      isOriginalityReportVisible: false,
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('renders the Document Processors column header and LtiAssetReportStatus when asset processors and reports are available', async () => {
    const user = userEvent.setup()

    // Mock the GraphQL query to return fixture data with reports for each file
    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult()
    // Create reports with different attachmentIds matching our test files
    mockData.submission.ltiAssetReportsConnection.nodes = files.flatMap(file =>
      defaultLtiAssetReportsForStudent({attachmentId: file._id, attachmentName: file.displayName}),
    )

    queryClient.setQueryData(['ltiAssetProcessorsAndReportsForStudent', '1'], mockData)

    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files, submissionType: 'online_upload', attempt: 1},
      }),
    }

    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    // Wait for async query to resolve and component to update
    await screen.findByText('Document Processors')

    // Check for status text based on fixture data - all reports have priority > 0, so all show "Please review"
    const needsAttentionLinks = screen.getAllByText('Please review')
    expect(needsAttentionLinks).toHaveLength(files.length) // One per file
  })

  it('does not render the Document Processors column header when asset processors are present but asset reports is null', async () => {
    // Mock the query to return processors but no reports
    const mockData = defaultGetLtiAssetProcessorsAndReportsForStudentResult()
    mockData.submission.ltiAssetReportsConnection.nodes = null

    queryClient.setQueryData(['ltiAssetProcessorsAndReportsForStudent', '1'], mockData)

    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files, submissionType: 'online_upload', attempt: 1},
      }),
    }

    act(() =>
      render(
        <MockedQueryProvider>
          <FilePreview {...props} />
        </MockedQueryProvider>,
      ),
    )

    expect(screen.queryByText('Document Processors')).not.toBeInTheDocument()
  })

  it('renders the size of each file being uploaded', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files, submissionType: 'online_upload', attempt: 1},
      }),
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    const sizes = screen.getAllByTestId('file-size')

    expect(sizes[0].textContent).toBe('670 Bytes')
    expect(sizes[1].textContent).toBe('107 GB')
  })

  it('renders the file preview', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: [files[0]]},
      }),
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.getByTestId('assignments_2_submission_preview')).toBeInTheDocument()
  })

  it('renders no preview available if the given file has no preview url', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: [files[1]]},
      }),
    }
    render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.getByText('Preview Unavailable')).toBeInTheDocument()
  })

  it('renders a download button for files without canvadoc preview', async () => {
    const props = {
      submission: await mockSubmissionWithResolvers({Submission: {attachments: [files[1]]}}),
    }
    const {container} = render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.getByText('Preview Unavailable')).toBeInTheDocument()
    expect(container.querySelector('a[href="/url"]')).toBeInTheDocument()
  })

  it('changes the preview when a different file icon is clicked', async () => {
    const user = userEvent.setup()
    const props = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files},
      }),
    }
    const {container} = render(
      <MockedQueryProvider>
        <FilePreview {...props} />
      </MockedQueryProvider>,
    )

    expect(screen.getByTestId('assignments_2_submission_preview')).toBeInTheDocument()

    const secondFileIcon = container.querySelector('svg[name="IconPaperclip"]')
    expect(secondFileIcon).not.toBeNull()
    fireEvent.click(secondFileIcon)

    expect(screen.getByText('Preview Unavailable')).toBeInTheDocument()
  })

  it('displays the first file upload in the preview when switching between attempts', async () => {
    const user = userEvent.setup()
    // file[0] = image, file[1] = zip, file[2] = zip
    const propsAttempt1 = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: [files[0], files[1]], attempt: 1},
      }),
    }

    const propsAttempt2 = {
      submission: await mockSubmissionWithResolvers({
        Submission: {attachments: files, attempt: 2},
      }),
    }

    const {rerender, container} = render(
      <MockedQueryProvider>
        <FilePreview {...propsAttempt2} />
      </MockedQueryProvider>,
    )

    const thirdFileIcon = container.querySelectorAll('svg[name="IconPaperclip"]')[1]
    fireEvent.click(thirdFileIcon)

    rerender(
      <MockedQueryProvider>
        <FilePreview {...propsAttempt1} />
      </MockedQueryProvider>,
    )

    const iframe = container.querySelector('iframe')
    expect(iframe).toHaveAttribute('src', '/preview_url')
  })
})
