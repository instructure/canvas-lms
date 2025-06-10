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

// Mock ENV global variable
declare const ENV: {AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS?: string}
jest.mock('../../../hooks/useManageThreadedRepliesStore', () => ({
  useManageThreadedRepliesStore: jest.fn(),
}))

const mockUseManageThreadedRepliesStore =
  require('../../../hooks/useManageThreadedRepliesStore').useManageThreadedRepliesStore

describe('ManageThreadedRepliesAlert', () => {
  beforeEach(() => {
    jest.resetAllMocks()
  })

  it('does not render when AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS is 0', () => {
    ENV.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS = '0'
    mockUseManageThreadedRepliesStore.mockReturnValue(false)

    render(<ManageThreadedRepliesAlert onOpen={jest.fn()} />)

    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('renders correctly when AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS is greater than 0 and showAlert is true', () => {
    const count = Math.floor(Math.random() * 1000) + 1
    ENV.AMOUNT_OF_SIDE_COMMENT_DISCUSSIONS = count.toString()
    mockUseManageThreadedRepliesStore.mockReturnValue(true)

    render(<ManageThreadedRepliesAlert onOpen={jest.fn()} />)

    expect(screen.getByText(`${count} ${count > 1 ? 'decisions' : 'decision'}`)).toBeInTheDocument()
    expect(screen.getByTestId('manage-threaded-discussions')).toBeInTheDocument()
  })
})
