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
import fetchMock from 'fetch-mock'
import {act, render, fireEvent, waitFor} from '@testing-library/react'
import AddStudentModal from '../AddStudentModal'

const LINK_STUDENT_URL = '/api/v1/users/1/observees'

const defaultProps = {
  open: true,
  currentUserId: '1',
  handleClose: () => {},
  onStudentPaired: () => {},
}

describe('Add Student Modal', () => {
  beforeEach(() => {
    fetchMock.post(LINK_STUDENT_URL, JSON.stringify({response: {ok: true}}))
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('requests the pairing api when Pair is clicked and a pairing code is provided', () => {
    const {getByTestId} = render(<AddStudentModal {...defaultProps} />)
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: 'sQsTC'}})
    act(() => addStudentButton.click())
    expect(fetchMock.calls(url => url.match(LINK_STUDENT_URL))).toHaveLength(1)
  })

  it('does not request the pairing api when the pairing code input is empty', () => {
    const {getByTestId, getByText} = render(<AddStudentModal {...defaultProps} />)
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: ''}}) // setting to '' just to make the test case explicit
    act(() => addStudentButton.click())
    expect(fetchMock.calls(url => url.match(LINK_STUDENT_URL))).toHaveLength(0)
    expect(getByText('Please provide a pairing code.')).toBeInTheDocument()
  })

  it('calls onStudentPaired when a new student is paired successfully', async () => {
    const onStudentPaired = jest.fn()
    const {getByTestId} = render(
      <AddStudentModal {...defaultProps} onStudentPaired={onStudentPaired} />
    )
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: 'sQsTC'}})
    act(() => addStudentButton.click())
    expect(fetchMock.calls(url => url.match(LINK_STUDENT_URL))).toHaveLength(1)
    await waitFor(() => {
      expect(onStudentPaired).toHaveBeenCalled()
    })
  })

  it('does not call onStudentPaired and shows invalid code error if something goes wrong', async () => {
    fetchMock.mock(
      LINK_STUDENT_URL,
      {throws: new Error('422 Unprocessable Entity')},
      {overwriteRoutes: true}
    )
    const onStudentPaired = jest.fn()
    const {getByTestId, getByText} = render(
      <AddStudentModal {...defaultProps} onStudentPaired={onStudentPaired} />
    )
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: '12121as'}})
    act(() => addStudentButton.click())
    expect(fetchMock.calls(url => url.match(LINK_STUDENT_URL))).toHaveLength(1)
    await waitFor(() => {
      expect(getByText('Invalid pairing code.')).toBeInTheDocument()
      expect(onStudentPaired).not.toHaveBeenCalled()
    })
  })

  it('clears the error message once the user starts editing the pairing code', async () => {
    fetchMock.mock(
      LINK_STUDENT_URL,
      {throws: new Error('422 Unprocessable Entity')},
      {overwriteRoutes: true}
    )
    const onStudentPaired = jest.fn()
    const {getByTestId, getByText, queryByText} = render(
      <AddStudentModal {...defaultProps} onStudentPaired={onStudentPaired} />
    )
    const pairingCodeInput = getByTestId('pairing-code-input')
    const addStudentButton = getByTestId('add-student-btn')
    fireEvent.change(pairingCodeInput, {target: {value: '12121as'}})
    act(() => addStudentButton.click())
    expect(fetchMock.calls(url => url.match(LINK_STUDENT_URL))).toHaveLength(1)
    await waitFor(() => {
      expect(getByText('Invalid pairing code.')).toBeInTheDocument()
      expect(onStudentPaired).not.toHaveBeenCalled()
    })
    // up to this point, same as the prior spec
    fireEvent.change(pairingCodeInput, {target: {value: '12121a'}})
    expect(queryByText('Invalid pairing code.')).toBeNull()
  })

  it('calls handleClose when close is clicked', () => {
    const handleClose = jest.fn()
    const {getByTestId} = render(<AddStudentModal {...defaultProps} handleClose={handleClose} />)
    const closeBtn = getByTestId('close-modal')
    act(() => closeBtn.click())
    expect(handleClose).toHaveBeenCalled()
  })
})
