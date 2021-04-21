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

const files = [
  {
    _id: '1',
    displayName: 'file_1.png',
    id: '1',
    mimeClass: 'image',
    submissionPreviewUrl: '/preview_url',
    thumbnailUrl: '/thumbnail_url',
    url: '/url'
  },
  {
    _id: '2',
    displayName: 'file_2.zip',
    id: '2',
    mimeClass: 'file',
    submissionPreviewUrl: null,
    thumbnailUrl: null,
    url: '/url'
  }
]

describe('FilePreview', () => {
  it('renders a message if there are no files to display', () => {
    const {getByText} = render(<FilePreview files={[]} />)
    expect(getByText('No Submission')).toBeInTheDocument()
  })

  it('renders the appropriate file icons', () => {
    const {container, getByTestId} = render(<FilePreview files={files} />)
    expect(getByTestId('assignments_2_file_icons')).toBeInTheDocument()

    // renders a thumbnail for the file with a preview url
    expect(getByTestId('assignments_2_file_icons')).toContainElement(
      container.querySelector('img[alt="file_1.png preview"]')
    )

    // renders an icon for the file without a preview url
    expect(getByTestId('assignments_2_file_icons')).toContainElement(
      container.querySelector('svg[name="IconPaperclip"]')
    )
  })

  it('does not render the file icons if there is only one file', () => {
    const {queryByTestId} = render(<FilePreview files={[files[0]]} />)
    expect(queryByTestId('assignments_2_file_icons')).not.toBeInTheDocument()
  })

  it('renders the file preview', () => {
    const {getByTestId} = render(<FilePreview files={files} />)
    expect(getByTestId('assignments_2_submission_preview')).toBeInTheDocument()
  })

  it('renders no preview available if the given file has no preview url', () => {
    const {getByText} = render(<FilePreview files={[files[1]]} />)
    expect(getByText('Preview Unavailable')).toBeInTheDocument()
  })

  it('renders a download button for files without canvadoc preview', () => {
    const {container, getByText} = render(<FilePreview files={[files[1]]} />)
    expect(getByText('Preview Unavailable')).toBeInTheDocument()
    expect(container.querySelector('a[href="/url"]')).toBeInTheDocument()
  })

  it('changes the preview when a different file icon is clicked', () => {
    const {container, getByTestId, getByText} = render(<FilePreview files={files} />)
    expect(getByTestId('assignments_2_submission_preview')).toBeInTheDocument()

    const secondFileIcon = container.querySelector('svg[name="IconPaperclip"]')
    expect(secondFileIcon).not.toBeNull()
    fireEvent.click(secondFileIcon)

    expect(getByText('Preview Unavailable')).toBeInTheDocument()
  })
})
