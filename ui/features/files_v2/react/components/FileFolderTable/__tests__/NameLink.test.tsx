/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import NameLink from '../NameLink'
import {BrowserRouter} from 'react-router-dom'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../../fixtures/fakeData'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import userEvent from '@testing-library/user-event'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(() => jest.fn()),
}))

const defaultProps = {
  isStacked: false,
  item: {...FAKE_FILES[0]},
  collection: [...FAKE_FILES],
}

const renderComponent = (props = {}) => {
  return render(
    <BrowserRouter>
      <MockedQueryClientProvider client={queryClient}>
        <NameLink {...defaultProps} {...props} />
      </MockedQueryClientProvider>
    </BrowserRouter>,
  )
}

describe('NameLink', () => {
  it('renders folder with folder icon', () => {
    const folder = {...FAKE_FOLDERS[0]}
    renderComponent({item: folder})

    expect(screen.getByText(folder.name)).toBeInTheDocument()
    expect(screen.getByTestId('folder-icon')).toBeInTheDocument()
  })

  it('renders locked folder with locked folder icon', () => {
    const folder = {...FAKE_FOLDERS[0], for_submissions: true}
    renderComponent({item: folder})

    expect(screen.getByText(folder.name)).toBeInTheDocument()
    expect(screen.getByTestId('locked-folder-icon')).toBeInTheDocument()
  })

  it('renders file with thumbnail if url is present', () => {
    const file = {...FAKE_FILES[0], thumbnail_url: 'https://example.com/image.jpg'}
    renderComponent({item: file})

    expect(screen.getByText(file.display_name)).toBeInTheDocument()
    expect(screen.getByTestId('name-icon')).toBeInTheDocument()
  })

  it('renders file with mime icon if thumbnail url is not present', () => {
    const file = {...FAKE_FILES[0], thumbnail_url: null}
    renderComponent({item: file})

    expect(screen.getByText(file.display_name)).toBeInTheDocument()
    expect(screen.getByRole('img', {name: /file/i})).toBeInTheDocument()
  })

  it('renders folder with url', () => {
    const folder = {...FAKE_FOLDERS[1]}
    renderComponent({item: folder})

    expect(screen.getByRole('link')).toHaveAttribute(
      'href',
      `/folder/${encodeURIComponent(folder.name)}`,
    )
  })

  it('Does not allow user to navigate to locked folder', async () => {
    const user = userEvent.setup()
    const folder = {...FAKE_FOLDERS[0], locked_for_user: true}
    renderComponent({item: folder})

    expect(screen.getByText(folder.name)).toBeInTheDocument()
    user.click(screen.getByText(folder.name))
    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith(
        `${folder.name} is currently locked and unavailable to view.`,
      )
    })
  })
})
