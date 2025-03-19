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
import {MediaFileInfo, MediaFileInfoProps} from '../MediaFileInfo'
import type {File} from '../../../../../interfaces/File'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import userEvent from '@testing-library/user-event'
import {FAKE_MEDIA_TRACKS} from './fixtures'

const defaultProps: MediaFileInfoProps = {
  attachment: {
    id: '1',
    name: 'Sample File',
    type: 'document',
    media_entry_id: 'something',
  } as unknown as File,
  mediaTracks: FAKE_MEDIA_TRACKS,
  canAddTracks: true,
  isLoading: false,
}

const renderComponent = (props?: Partial<MediaFileInfoProps>) => {
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <MediaFileInfo {...defaultProps} {...props} />
    </MockedQueryClientProvider>,
  )
}

describe('MediaFileInfo', () => {
  it('renders None when no tracks', () => {
    renderComponent({mediaTracks: []})
    const none = screen.getByText('None')
    expect(none).toBeInTheDocument()
  })

  it('shows upload form on click', async () => {
    renderComponent()
    const formLabel = screen.queryByLabelText('Choose a language *')
    expect(formLabel).not.toBeInTheDocument()

    const button = screen.getByRole('button', {name: 'Add Captions/Subtitles'})
    await userEvent.click(button)

    const visibleFormLabel = screen.getByLabelText('Choose a language*')
    expect(visibleFormLabel).toBeInTheDocument()
  })

  it('shows captions if present', () => {
    renderComponent()
    const caption = screen.getByText('English')
    expect(caption).toBeInTheDocument()

    const none = screen.queryByText('None')
    expect(none).not.toBeInTheDocument()
  })

  it('shows Media Options header while loading', () => {
    renderComponent({isLoading: true})
    const header = screen.getByText('Media Options')
    const loadingIcon = screen.getByText('Loading')
    expect(header).toBeInTheDocument()
    expect(loadingIcon).toBeInTheDocument()
  })

  it('does not render if canAddTracks is false', () => {
    renderComponent({canAddTracks: false})
    const header = screen.queryByText('Media Options')
    expect(header).not.toBeInTheDocument()
  })

  it('does not render if file is restricted by master course', () => {
    renderComponent({
      attachment: {...defaultProps.attachment, restricted_by_master_course: true},
    })
    const header = screen.queryByText('Media Options')
    expect(header).not.toBeInTheDocument()
  })
})
