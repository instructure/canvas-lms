/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 *
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
import DirectShareOperationStatus from '../DirectShareOperationStatus'

describe('DirectShareOperationStatus', () => {
  it('shows nothing if there is no promise', () => {
    const {queryByText} = render(
      <DirectShareOperationStatus
        promise={null}
        startingMsg="starting"
        successMsg="success"
        errorMsg="error"
      />
    )
    expect(queryByText(/starting|success|error/)).toBeNull()
  })

  it('shows the starting message when the promise is not resolved', () => {
    const promise = new Promise(() => {})
    const {getAllByText, queryByText} = render(
      <DirectShareOperationStatus
        promise={promise}
        startingMsg="starting"
        successMsg="success"
        errorMsg="error"
      />
    )
    expect(getAllByText('starting')).not.toHaveLength(0)
    expect(queryByText(/success|error/)).toBeNull()
  })

  it('does an sr alert', () => {
    const promise = new Promise(() => {})
    render(
      <DirectShareOperationStatus
        promise={promise}
        startingMsg="starting"
        successMsg="success"
        errorMsg="error"
      />
    )
    expect(document.querySelector('[role="alert"]')).toBeInTheDocument()
  })

  it('shows success when promise is fulfilled', async () => {
    const promise = Promise.resolve()
    const {findByText, queryByText} = render(
      <DirectShareOperationStatus
        promise={promise}
        startingMsg="starting"
        successMsg="success"
        errorMsg="error"
      />
    )
    expect(await findByText('success')).toBeInTheDocument()
    expect(queryByText(/starting|error/)).toBeNull()
  })

  describe('errors', () => {
    beforeEach(() => jest.spyOn(console, 'error').mockImplementation(() => {}))
    afterEach(() => console.error.mockRestore()) // eslint-disable-line no-console

    it('shows error when promise is rejected', async () => {
      const promise = Promise.reject()
      const {findByText, queryByText} = render(
        <DirectShareOperationStatus
          promise={promise}
          startingMsg="starting"
          successMsg="success"
          errorMsg="error"
        />
      )
      expect(await findByText('error')).toBeInTheDocument()
      expect(queryByText(/starting|success/)).toBeNull()
      expect(console.error).toHaveBeenCalled() // eslint-disable-line no-console
    })
  })

  it('resets when it receives a new promise', async () => {
    const promise = Promise.resolve()
    const {findByText, getAllByText, rerender} = render(
      <DirectShareOperationStatus
        promise={promise}
        startingMsg="starting"
        successMsg="success"
        errorMsg="error"
      />
    )
    expect(await findByText('success')).toBeInTheDocument()
    const newPromise = new Promise(() => {})
    rerender(
      <DirectShareOperationStatus
        promise={newPromise}
        startingMsg="starting"
        successMsg="success"
        errorMsg="error"
      />
    )
    expect(getAllByText('starting')).not.toHaveLength(0)
  })
})
