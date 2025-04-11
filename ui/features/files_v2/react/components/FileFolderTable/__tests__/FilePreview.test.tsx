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

import {render, screen} from '@testing-library/react'
import {FilePreview, FilePreviewProps} from '../FilePreview'
import {FAKE_FILES} from '../../../../fixtures/fakeData'

jest.mock('@canvas/canvas-studio-player', () => {
  const mockDefault = jest.fn(() => <div data-testid="media-player">Media Player</div>)
  return {
    __esModule: true,
    default: mockDefault,
  }
})

const defaultProps: FilePreviewProps = {
  item: FAKE_FILES[0],
  isFilePreview: true,
  isMediaPreview: false,
  mediaId: '',
  mediaSources: [],
  mediaTracks: [],
  isFetchingMedia: false,
}

const renderComponent = (props?: Partial<FilePreviewProps>) => {
  return render(<FilePreview {...defaultProps} {...props} />)
}

describe('File Preview', () => {
  it('renders preview for non-media files', () => {
    renderComponent()
    const iframe = screen.getByTitle(`Preview for file: ${FAKE_FILES[0].display_name}`)
    expect(iframe).toBeInTheDocument()
  })

  it('renders no preview for non-previewable files', () => {
    renderComponent({isFilePreview: false})
    const noPreview = screen.getByText('No Preview Available')
    expect(noPreview).toBeInTheDocument()
  })

  it('renders loading icon when loading media preview', () => {
    renderComponent({
      isFilePreview: false,
      isMediaPreview: true,
      mediaId: '123',
      isFetchingMedia: true,
    })
    const loadingIcon = screen.getByText('Loading')
    expect(loadingIcon).toBeInTheDocument()
  })

  it('renders media player for media files', () => {
    renderComponent({
      isFilePreview: false,
      isMediaPreview: true,
      mediaId: '123',
      isFetchingMedia: false,
    })
    const mediaPlayer = screen.getByTestId('media-player')
    expect(mediaPlayer).toBeInTheDocument()
  })
})
