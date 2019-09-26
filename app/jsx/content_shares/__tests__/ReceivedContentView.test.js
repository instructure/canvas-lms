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

import React from 'react'
import {render} from '@testing-library/react'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import ReceivedContentView from 'jsx/content_shares/ReceivedContentView'
import {assignmentShare} from 'jsx/content_shares/__tests__/test-utils'

jest.mock('jsx/shared/effects/useFetchApi')

describe('view of received content', () => {
  it('renders spinner while loading', () => {
    useFetchApi.mockImplementationOnce(({loading}) => loading(true))
    const {getByText} = render(<ReceivedContentView />)
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('hides spinner when not loading', () => {
    useFetchApi.mockImplementationOnce(({loading}) => loading(false))
    const {queryByText} = render(<ReceivedContentView />)
    expect(queryByText(/loading/i)).not.toBeInTheDocument()
  })

  it('displays table with successful retrieval and not loading', () => {
    const shares = [assignmentShare]
    useFetchApi.mockImplementationOnce(({loading, success}) => {
      loading(false)
      success(shares)
    })
    const {getByText} = render(<ReceivedContentView />)
    expect(getByText(shares[0].name)).toBeInTheDocument()
  })

  it('raises an error on unsuccessful retrieval', () => {
    useFetchApi.mockImplementationOnce(({loading, error}) => {
      loading(false)
      error('fetch error')
    })
    expect(() => {
      render(<ReceivedContentView />)
    }).toThrow('Retrieval of Received Shares failed')
  })
})
