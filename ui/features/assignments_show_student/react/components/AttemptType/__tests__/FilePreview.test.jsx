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
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'

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
    submissionPreviewUrl: null,
    thumbnailUrl: null,
    url: '/url',
    size: '107 GB',
  },
  {
    _id: '3',
    displayName: 'file_2.zip',
    id: '3',
    mimeClass: 'file',
    submissionPreviewUrl: null,
    thumbnailUrl: null,
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

describe('FilePreview', () => {
  it('renders a message if there are no files to display', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: []},
      }),
    }
    const {getByText} = render(<FilePreview {...props} />)
    expect(getByText('No Submission')).toBeInTheDocument()
  })

  it('renders the appropriate file icons', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: files},
      }),
    }
    const {container, getByTestId} = render(<FilePreview {...props} />)
    expect(getByTestId('uploaded_files_table')).toBeInTheDocument()

    // renders a thumbnail for the file with a preview url
    expect(getByTestId('uploaded_files_table')).toContainElement(
      container.querySelector('img[alt="file_1.png preview"]')
    )

    // renders an icon for the file without a preview url
    expect(getByTestId('uploaded_files_table')).toContainElement(
      container.querySelector('svg[name="IconPaperclip"]')
    )
  })

  it('does not render the file icons if there is only one file', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: [files[0]]},
      }),
    }
    const {queryByTestId} = render(<FilePreview {...props} />)
    expect(queryByTestId('assignments_2_file_icons')).not.toBeInTheDocument()
  })

  it('renders orignality reports for each file if turnitin data exists and there is more than one attachment', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: files, originalityData, submissionType: 'online_upload'},
      }),
      isOriginalityReportVisible: true,
    }
    const {getAllByTestId} = render(<FilePreview {...props} />)
    const reports = getAllByTestId('originality_report')

    expect(reports.length).toBe(2)
    expect(reports[0].textContent).toBe('75%')
    expect(reports[1].textContent).toBe('10%')
  })

  it('does not render orignality reports if only one attachment exists', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: [files[0]], originalityData, submissionType: 'online_upload'},
      }),
      isOriginalityReportVisible: true,
    }
    const {queryByTestId} = render(<FilePreview {...props} />)

    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('does not render orignality reports if the reports are not visible to the student', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: files, originalityData, submissionType: 'online_upload'},
      }),
      isOriginalityReportVisible: false,
    }
    const {queryByTestId} = render(<FilePreview {...props} />)

    expect(queryByTestId('originality_report')).not.toBeInTheDocument()
  })

  it('renders the size of each file being uploaded', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: files},
      }),
    }
    const {getAllByTestId} = render(<FilePreview {...props} />)

    const sizes = getAllByTestId('file-size')

    expect(sizes[0].textContent).toBe('670 Bytes')
    expect(sizes[1].textContent).toBe('107 GB')
  })

  it('renders the file preview', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: [files[0]]},
      }),
    }
    const {getByTestId} = render(<FilePreview {...props} />)
    expect(getByTestId('assignments_2_submission_preview')).toBeInTheDocument()
  })

  it('renders no preview available if the given file has no preview url', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: [files[1]]},
      }),
    }
    const {getByText} = render(<FilePreview {...props} />)
    expect(getByText('Preview Unavailable')).toBeInTheDocument()
  })

  it('renders a download button for files without canvadoc preview', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: [files[1]]},
      }),
    }
    const {container, getByText} = render(<FilePreview {...props} />)
    expect(getByText('Preview Unavailable')).toBeInTheDocument()
    expect(container.querySelector('a[href="/url"]')).toBeInTheDocument()
  })

  it('changes the preview when a different file icon is clicked', async () => {
    const props = {
      submission: await mockSubmission({
        Submission: {attachments: files},
      }),
    }
    const {container, getByTestId, getByText} = render(<FilePreview {...props} />)
    expect(getByTestId('assignments_2_submission_preview')).toBeInTheDocument()

    const secondFileIcon = container.querySelector('svg[name="IconPaperclip"]')
    expect(secondFileIcon).not.toBeNull()
    fireEvent.click(secondFileIcon)

    expect(getByText('Preview Unavailable')).toBeInTheDocument()
  })

  it('displays the first file upload in the preview when switching between attempts', async () => {
    // file[0] = image, file[1] = zip, file[2] = zip
    const propsAttempt1 = {
      submission: await mockSubmission({
        Submission: {attachments: [files[0], files[1]], attempt: 1},
      }),
    }

    const propsAttempt2 = {
      submission: await mockSubmission({
        Submission: {attachments: files, attempt: 2},
      }),
    }

    const {container, rerender} = render(<FilePreview {...propsAttempt2} />)
    const thirdFileIcon = container.querySelectorAll('svg[name="IconPaperclip"]')[1]
    fireEvent.click(thirdFileIcon)

    rerender(<FilePreview {...propsAttempt1} />)

    const iframe = container.querySelector('iframe')
    expect(iframe).toHaveAttribute('src', '/preview_url')
  })
})
