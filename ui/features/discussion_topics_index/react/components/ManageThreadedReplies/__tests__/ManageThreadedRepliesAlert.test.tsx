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
import ManageThreadedRepliesAlert from '../ManageThreadedRepliesAlert'
import {useManageThreadedRepliesStore} from '../../../hooks/useManageThreadedRepliesStore'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../../../hooks/useManageThreadedRepliesStore', () => ({
  useManageThreadedRepliesStore: vi.fn(),
}))

const mockUseManageThreadedRepliesStore = useManageThreadedRepliesStore as unknown as ReturnType<
  typeof vi.fn
>

describe('ManageThreadedRepliesAlert', () => {
  beforeEach(() => {
    fakeENV.setup()
    vi.clearAllMocks()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('does not render when AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS is 0', () => {
    window.ENV.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS = '0'
    mockUseManageThreadedRepliesStore.mockReturnValue(false)

    render(<ManageThreadedRepliesAlert onOpen={vi.fn()} />)

    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('renders correctly when AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS is greater than 0 and showAlert is true', () => {
    window.ENV.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS = '5'
    mockUseManageThreadedRepliesStore.mockReturnValue(true)

    render(<ManageThreadedRepliesAlert onOpen={vi.fn()} />)

    expect(screen.getByText('5 decisions')).toBeInTheDocument()
    expect(screen.getByTestId('manage-threaded-discussions')).toBeInTheDocument()
  })

  it('renders singular "decision" when count is 1', () => {
    window.ENV.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS = '1'
    mockUseManageThreadedRepliesStore.mockReturnValue(true)

    render(<ManageThreadedRepliesAlert onOpen={vi.fn()} />)

    expect(screen.getByText('1 decision')).toBeInTheDocument()
  })

  it('does not render when showAlert is false', () => {
    window.ENV.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS = '5'
    mockUseManageThreadedRepliesStore.mockReturnValue(false)

    render(<ManageThreadedRepliesAlert onOpen={vi.fn()} />)

    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })
})
