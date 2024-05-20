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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import DeprecationModal from '../DeprecationModal'

const defaultProps = {
  deprecationDate: '2024-06-15T15:00Z',
  timezone: 'America/New_York',
}

describe('DeprecationModal', () => {
  it('renders the deprecation modal', () => {
    const {getByRole, getByText} = render(<DeprecationModal {...defaultProps} />)
    expect(getByRole('heading', {level: 2, name: 'Deprecated Tool'})).toBeInTheDocument()
    expect(
      getByText(
        'Access to Faculty Journal will end on June 15, 2024. Contact your Canvas Administrator with any questions.'
      )
    ).toBeInTheDocument()
  })

  it('closes when close button is pressed', async () => {
    const {getByRole, queryByText} = render(<DeprecationModal {...defaultProps} />)
    const button = getByRole('button', {name: 'Close'})
    await userEvent.click(button)
    await waitFor(() => expect(queryByText('Deprecated Tool')).not.toBeInTheDocument())
  })

  it('immediately closes when acknowledge button is pressed without checking suppression box', async () => {
    const {getByRole, queryByText} = render(<DeprecationModal {...defaultProps} />)
    const button = getByRole('button', {name: 'I Understand'})
    await userEvent.click(button)
    await waitFor(() => expect(queryByText('Deprecated Tool')).not.toBeInTheDocument())
    await fetchMock.flush(true)
    expect(fetchMock.calls().length).toBe(0)
  })

  it('makes a request to suppress the notice when checked and acknowledge button is pressed', async () => {
    fetchMock.putOnce('/api/v1/users/self/user_notes/suppress_deprecation_notice', 204)
    const {getByRole, queryByText} = render(<DeprecationModal {...defaultProps} />)
    const checkbox = getByRole('checkbox', {name: "Don't show this again"})
    const button = getByRole('button', {name: 'I Understand'})
    await userEvent.click(checkbox)
    await userEvent.click(button)
    await fetchMock.flush(true)
    expect(fetchMock.calls().length).toBe(1)
    await waitFor(() => expect(queryByText('Deprecated Tool')).not.toBeInTheDocument())
  })
})
