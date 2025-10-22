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
import {fireEvent, render, waitFor} from '@testing-library/react'
import AvatarModal from '../AvatarModal'
import fakeENV from '@canvas/test-utils/fakeENV'
import fetchMock from 'fetch-mock'

describe('AvatarModal', () => {
  beforeAll(() => {
    fakeENV.setup({
      folder_id: '123',
      current_user_id: false,
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  it('renders modal with defaults', () => {
    const {getByText, getByTestId} = render(<AvatarModal onClose={jest.fn()} />)
    expect(getByText('Select Profile Picture')).toBeInTheDocument()
    expect(getByTestId('save-avatar-button')).toBeInTheDocument()
    expect(getByTestId('cancel-avatar-button')).toBeInTheDocument()
    // upload option is default
    const roleSelect = getByTestId('avatar-type-select') as HTMLInputElement
    expect(roleSelect.value).toBe('Upload a Picture')
    expect(getByText('choose a picture')).toBeInTheDocument()
  })

  it('calls onClose when canceling', async () => {
    const onClose = jest.fn()
    const {getByTestId} = render(<AvatarModal onClose={onClose} />)

    fireEvent.click(getByTestId('cancel-avatar-button'))
    await waitFor(() => {
      expect(onClose).toHaveBeenCalled()
    })
  })

  it('initializes preflight request when saving', async () => {
    // since no image is uploaded, we don't get past the preflight request
    const preflightPath = '/files/pending'
    fetchMock.post(preflightPath, 200)

    const {getAllByText, getByTestId} = render(<AvatarModal onClose={jest.fn()} />)
    fireEvent.click(getByTestId('save-avatar-button'))
    await waitFor(() => {
      expect(fetchMock.called(preflightPath)).toBe(true)
    })
    // error shown when no image was uploaded; SR + alert text
    expect(getAllByText('Failed to get image')).toHaveLength(2)
  })
})
