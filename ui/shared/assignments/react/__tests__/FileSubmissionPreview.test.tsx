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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FileSubmissionPreview from '../FileSubmissionPreview'
import {Submission} from '../AssignmentsPeerReviewsStudentTypes'

describe('FileSubmissionPreview', () => {
  const mockSubmissionWithSingleFile: Submission = {
    _id: '1',
    attempt: 1,
    submissionType: 'online_upload',
    attachments: [
      {
        _id: '101',
        displayName: 'test-file.pdf',
        mimeClass: 'pdf',
        size: '1.2 MB',
        thumbnailUrl: null,
        submissionPreviewUrl: 'http://example.com/preview/101',
        url: 'http://example.com/download/101',
      },
    ],
  }

  const mockSubmissionWithMultipleFiles: Submission = {
    _id: '2',
    attempt: 1,
    submissionType: 'online_upload',
    attachments: [
      {
        _id: '201',
        displayName: 'file1.pdf',
        mimeClass: 'pdf',
        size: '1.2 MB',
        thumbnailUrl: null,
        submissionPreviewUrl: 'http://example.com/preview/201',
        url: 'http://example.com/download/201',
      },
      {
        _id: '202',
        displayName: 'file2.docx',
        mimeClass: 'doc',
        size: '2.5 MB',
        thumbnailUrl: null,
        submissionPreviewUrl: 'http://example.com/preview/202',
        url: 'http://example.com/download/202',
      },
    ],
  }

  const mockSubmissionWithImageThumbnail: Submission = {
    _id: '3',
    attempt: 1,
    submissionType: 'online_upload',
    attachments: [
      {
        _id: '301',
        displayName: 'image.jpg',
        mimeClass: 'image',
        size: '500 KB',
        thumbnailUrl: 'http://example.com/thumb/301',
        submissionPreviewUrl: 'http://example.com/preview/301',
        url: 'http://example.com/download/301',
      },
    ],
  }

  const mockSubmissionNoPreview: Submission = {
    _id: '4',
    attempt: 1,
    submissionType: 'online_upload',
    attachments: [
      {
        _id: '401',
        displayName: 'file.zip',
        mimeClass: 'zip',
        size: '10 MB',
        thumbnailUrl: null,
        submissionPreviewUrl: null,
        url: 'http://example.com/download/401',
      },
    ],
  }

  const mockSubmissionNoFiles: Submission = {
    _id: '5',
    attempt: 1,
    submissionType: 'online_upload',
    attachments: [],
  }

  describe('with a single file', () => {
    it('renders file preview without table', () => {
      render(<FileSubmissionPreview submission={mockSubmissionWithSingleFile} />)
      expect(screen.queryByTestId('uploaded_files_table')).not.toBeInTheDocument()
      expect(screen.getByTestId('file_submission_preview')).toBeInTheDocument()
    })

    it('displays preview iframe with correct src', () => {
      render(<FileSubmissionPreview submission={mockSubmissionWithSingleFile} />)
      const iframe = screen.getByTitle('preview')
      expect(iframe).toHaveAttribute('src', 'http://example.com/preview/101')
    })
  })

  describe('with multiple files', () => {
    it('renders file table with all files', () => {
      render(<FileSubmissionPreview submission={mockSubmissionWithMultipleFiles} />)
      const table = screen.getByTestId('uploaded_files_table')
      expect(table).toBeInTheDocument()
      expect(screen.getAllByText('file1.pdf').length).toBeGreaterThan(0)
      expect(screen.getAllByText('file2.docx').length).toBeGreaterThan(0)
    })

    it('displays file sizes in table', () => {
      render(<FileSubmissionPreview submission={mockSubmissionWithMultipleFiles} />)
      const fileSizeCells = screen.getAllByTestId('file-size')
      expect(fileSizeCells[0]).toHaveTextContent('1.2 MB')
      expect(fileSizeCells[1]).toHaveTextContent('2.5 MB')
    })

    it('allows selecting different files', async () => {
      const user = userEvent.setup()
      render(<FileSubmissionPreview submission={mockSubmissionWithMultipleFiles} />)

      const iframe = screen.getByTitle('preview')
      expect(iframe).toHaveAttribute('src', 'http://example.com/preview/201')

      const fileLinks = screen.getAllByText('file2.docx')
      await user.click(fileLinks[fileLinks.length - 1])

      expect(iframe).toHaveAttribute('src', 'http://example.com/preview/202')
    })
  })

  describe('with image thumbnail', () => {
    it('displays thumbnail in table for multiple image files', () => {
      const submissionWithMultipleImages = {
        ...mockSubmissionWithImageThumbnail,
        attachments: [
          mockSubmissionWithImageThumbnail.attachments![0],
          {
            _id: '302',
            displayName: 'image2.jpg',
            mimeClass: 'image',
            size: '600 KB',
            thumbnailUrl: 'http://example.com/thumb/302',
            submissionPreviewUrl: 'http://example.com/preview/302',
            url: 'http://example.com/download/302',
          },
        ],
      }
      render(<FileSubmissionPreview submission={submissionWithMultipleImages} />)
      const thumbnail = screen.getByAltText('image.jpg preview')
      expect(thumbnail).toBeInTheDocument()
      expect(thumbnail).toHaveAttribute('src', 'http://example.com/thumb/301')
    })
  })

  describe('without preview URL', () => {
    it('shows preview unavailable message and download button', () => {
      render(<FileSubmissionPreview submission={mockSubmissionNoPreview} />)
      expect(screen.getByText('Preview Unavailable')).toBeInTheDocument()
      expect(screen.getByText('file.zip')).toBeInTheDocument()

      const downloadButton = screen.getByText('Download')
      expect(downloadButton).toBeInTheDocument()
      expect(downloadButton.closest('a')).toHaveAttribute('href', 'http://example.com/download/401')
    })
  })

  describe('with no files', () => {
    it('shows no submission message', () => {
      render(<FileSubmissionPreview submission={mockSubmissionNoFiles} />)
      expect(screen.getByText('No Submission')).toBeInTheDocument()
    })
  })

  describe('with null attachments', () => {
    it('shows no submission message', () => {
      const submissionNullAttachments: Submission = {
        _id: '6',
        attempt: 1,
        submissionType: 'online_upload',
        attachments: null,
      }
      render(<FileSubmissionPreview submission={submissionNullAttachments} />)
      expect(screen.getByText('No Submission')).toBeInTheDocument()
    })
  })

  describe('when submission changes', () => {
    it('resets to first file when submission prop changes', async () => {
      const user = userEvent.setup()
      const {rerender} = render(
        <FileSubmissionPreview submission={mockSubmissionWithMultipleFiles} />,
      )

      const iframe = screen.getByTitle('preview')
      expect(iframe).toHaveAttribute('src', 'http://example.com/preview/201')

      const fileLinks = screen.getAllByText('file2.docx')
      await user.click(fileLinks[fileLinks.length - 1])
      expect(iframe).toHaveAttribute('src', 'http://example.com/preview/202')

      const newSubmission: Submission = {
        _id: '7',
        attempt: 2,
        submissionType: 'online_upload',
        attachments: [
          {
            _id: '701',
            displayName: 'new-file1.pdf',
            mimeClass: 'pdf',
            size: '3 MB',
            thumbnailUrl: null,
            submissionPreviewUrl: 'http://example.com/preview/701',
            url: 'http://example.com/download/701',
          },
          {
            _id: '702',
            displayName: 'new-file2.pdf',
            mimeClass: 'pdf',
            size: '4 MB',
            thumbnailUrl: null,
            submissionPreviewUrl: 'http://example.com/preview/702',
            url: 'http://example.com/download/702',
          },
        ],
      }

      rerender(<FileSubmissionPreview submission={newSubmission} />)
      expect(iframe).toHaveAttribute('src', 'http://example.com/preview/701')
    })
  })
})
