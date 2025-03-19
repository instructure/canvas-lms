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
import {MediaTrackList, MediaTrackListProps} from '../MediaTrackList'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {FAKE_MEDIA_TRACKS} from './fixtures'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const defaultProps: MediaTrackListProps = {
  attachmentId: '111',
  mediaTracks: FAKE_MEDIA_TRACKS,
}

const renderComponent = (props?: Partial<MediaTrackListProps>) => {
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <MediaTrackList {...defaultProps} {...props} />
    </MockedQueryClientProvider>,
  )
}

describe('DeleteCaptionButton', () => {
  beforeEach(() => {
    fetchMock.delete(/.*\/media_tracks\/.*/, {}, {overwriteRoutes: true})
  })

  afterEach(() => {
    destroyContainer()
  })

  it('deletes on click', async () => {
    renderComponent()
    const button = screen.getAllByRole('button', {name: /delete caption/i})[0]
    await userEvent.click(button)
    expect(fetchMock.calls()[0][0]).toMatch(/.*\/media_attachments\/111\/media_tracks\/1/)
  })

  it('renders captions', () => {
    renderComponent()
    const englishCaption = screen.getByText('English')
    const arabicCaption = screen.getByText('Arabic')
    expect(englishCaption).toBeInTheDocument()
    expect(arabicCaption).toBeInTheDocument()
  })

  it('shows error message on failure', async () => {
    fetchMock.delete(/.*\/media_tracks\/.*/, {status: 500}, {overwriteRoutes: true})
    renderComponent()
    const button = screen.getAllByRole('button', {name: /delete caption/i})[0]
    await userEvent.click(button)
    const error = screen.getAllByText('An error occurred while deleting the caption.')
    // visible text and screenreader text
    expect(error).toHaveLength(2)
  })
})
