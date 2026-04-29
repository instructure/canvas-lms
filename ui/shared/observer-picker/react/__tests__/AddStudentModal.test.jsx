/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {act, render, fireEvent, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import AddStudentModal from '../AddStudentModal'

const LINK_STUDENT_URL = '/api/v1/users/1/observees'

const server = setupServer()

const defaultProps = {
  open: true,
  currentUserId: '1',
  handleClose: () => {},
  onStudentPaired: () => {},
}

describe('Add Student Modal', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('requests the pairing api when Pair is clicked and a pairing code is provided', async () => {
    let requestMade = false
    server.use(
      http.post(LINK_STUDENT_URL, () => {
        requestMade = true
        return HttpResponse.json({response: {ok: true}})
      }),
    )
    const {getByTestId} = render(<AddStudentModal {...defaultProps} />)
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: 'sQsTC'}})
    await act(async () => addStudentButton.click())
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(requestMade).toBe(true)
  })

  it('does not request the pairing api when the pairing code input is empty', async () => {
    let requestMade = false
    server.use(
      http.post(LINK_STUDENT_URL, () => {
        requestMade = true
        return HttpResponse.json({response: {ok: true}})
      }),
    )
    const {getByTestId, getByText} = render(<AddStudentModal {...defaultProps} />)
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: ''}}) // setting to '' just to make the test case explicit
    await act(async () => addStudentButton.click())
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(requestMade).toBe(false)
    expect(getByText('Please provide a pairing code.')).toBeInTheDocument()
  })

  it('calls onStudentPaired when a new student is paired successfully', async () => {
    let requestMade = false
    const onStudentPaired = vi.fn()
    server.use(
      http.post(LINK_STUDENT_URL, () => {
        requestMade = true
        return HttpResponse.json({response: {ok: true}})
      }),
    )
    const {getByTestId} = render(
      <AddStudentModal {...defaultProps} onStudentPaired={onStudentPaired} />,
    )
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: 'sQsTC'}})
    await act(async () => addStudentButton.click())
    expect(requestMade).toBe(true)
    await waitFor(() => {
      expect(onStudentPaired).toHaveBeenCalled()
    })
  })

  it('does not call onStudentPaired and shows invalid code error if something goes wrong', async () => {
    let requestMade = false
    const onStudentPaired = vi.fn()
    server.use(
      http.post(LINK_STUDENT_URL, () => {
        requestMade = true
        return new HttpResponse(null, {status: 422})
      }),
    )
    const {getByTestId, getByText} = render(
      <AddStudentModal {...defaultProps} onStudentPaired={onStudentPaired} />,
    )
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: '12121as'}})
    await act(async () => addStudentButton.click())
    expect(requestMade).toBe(true)
    await waitFor(() => {
      expect(getByText('Invalid pairing code.')).toBeInTheDocument()
      expect(onStudentPaired).not.toHaveBeenCalled()
    })
  })

  it('clears the error message once the user starts editing the pairing code', async () => {
    let requestMade = false
    const onStudentPaired = vi.fn()
    server.use(
      http.post(LINK_STUDENT_URL, () => {
        requestMade = true
        return new HttpResponse(null, {status: 422})
      }),
    )
    const {getByTestId, getByText, queryByText} = render(
      <AddStudentModal {...defaultProps} onStudentPaired={onStudentPaired} />,
    )
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: '12121as'}})
    await act(async () => addStudentButton.click())
    expect(requestMade).toBe(true)
    await waitFor(() => {
      expect(getByText('Invalid pairing code.')).toBeInTheDocument()
      expect(onStudentPaired).not.toHaveBeenCalled()
    })
    // up to this point, same as the prior spec
    fireEvent.change(pairingCodeInput, {target: {value: '12121a'}})
    expect(queryByText('Invalid pairing code.')).toBeNull()
  })

  it('calls handleClose when close is clicked', () => {
    const handleClose = vi.fn()
    const {getByTestId} = render(<AddStudentModal {...defaultProps} handleClose={handleClose} />)
    const closeBtn = getByTestId('close-modal')
    act(() => closeBtn.click())
    expect(handleClose).toHaveBeenCalled()
  })
})
