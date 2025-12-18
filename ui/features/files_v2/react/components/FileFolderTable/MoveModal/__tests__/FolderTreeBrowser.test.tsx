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
import {FAKE_FOLDERS} from '../../../../../fixtures/fakeData'
import FolderTreeBrowser from '../FolderTreeBrowser'
import {useFoldersQuery} from '../hooks'

vi.mock('../hooks', () => ({
  useFoldersQuery: vi.fn(),
}))

const defaultProps = {
  rootFolder: FAKE_FOLDERS[0],
  onSelectFolder: vi.fn(),
}

const renderComponent = (props: any = {}) =>
  render(<FolderTreeBrowser {...defaultProps} {...props} />)

describe('FolderTreeBrowser', () => {
  beforeEach(() => {
    ;(useFoldersQuery as any).mockReturnValue({
      folders: {[FAKE_FOLDERS[1].id]: FAKE_FOLDERS[1]},
      foldersLoading: false,
      foldersSuccessful: true,
      foldersError: false,
    })
  })

  it('renders tree', async () => {
    renderComponent()
    expect(await screen.findByText(FAKE_FOLDERS[1].name)).toBeInTheDocument()
  })

  it('calls onSelectFolder', async () => {
    renderComponent()
    await userEvent.click(await screen.findByText(FAKE_FOLDERS[1].name))
    expect(defaultProps.onSelectFolder).toBeCalledWith(FAKE_FOLDERS[1])
  })
})
