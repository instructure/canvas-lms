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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'
import ConfirmCommunicationChannel, {
  type ConfirmCommunicationChannelProps,
} from '../ConfirmCommunicationChannel'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

describe('ConfirmCommunicationChannel', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    fetchMock.restore()
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })
  const props: ConfirmCommunicationChannelProps = {
    phoneNumberOrEmail: '123-456-7890',
    communicationChannel: {user_id: '1', pseudonym_id: '2', channel_id: '3'},
    children: <div />,
    onClose: jest.fn(),
    onError: jest.fn(),
    onSubmit: jest.fn(),
  }

  it('should render the provided phone number', () => {
    render(<ConfirmCommunicationChannel {...props} />)
    const embeddedPhoneNumber = screen.getByText(props.phoneNumberOrEmail)

    expect(embeddedPhoneNumber).toBeInTheDocument()
  })

  it('should show an error if the verification code is empty', async () => {
    const {getByLabelText, findByText} = render(<ConfirmCommunicationChannel {...props} />)
    const confirm = getByLabelText('Confirm')

    fireEvent.click(confirm)

    const errorText = await findByText('Code is required.')
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if the verification code is too short', async () => {
    const {getByLabelText, findByText} = render(<ConfirmCommunicationChannel {...props} />)
    const confirm = getByLabelText('Confirm')
    const code = getByLabelText('Code')

    fireEvent.input(code, {target: {value: '1'}})
    fireEvent.click(confirm)

    const errorText = await findByText('Code must be four characters.')
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if the verification code is too long', async () => {
    const {getByLabelText, findByText} = render(<ConfirmCommunicationChannel {...props} />)
    const confirm = getByLabelText('Confirm')
    const code = getByLabelText('Code')

    fireEvent.input(code, {target: {value: '12345'}})
    fireEvent.click(confirm)

    const errorText = await findByText('Code must be four characters.')
    expect(errorText).toBeInTheDocument()
  })

  it('should call onSubmit after a successful response', async () => {
    const code = '1234'
    fetchMock.post(`/register/${code}`, 200, {overwriteRoutes: true})
    const {getByLabelText} = render(<ConfirmCommunicationChannel {...props} />)
    const codeInput = getByLabelText('Code')
    const confirm = getByLabelText('Confirm')

    fireEvent.input(codeInput, {target: {value: code}})
    fireEvent.click(confirm)

    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalled()
    })
  })

  it('should call onError after a failed response', async () => {
    const code = '1234'
    fetchMock.post(`/register/${code}`, 500, {overwriteRoutes: true})
    const {getByLabelText} = render(<ConfirmCommunicationChannel {...props} />)
    const codeInput = getByLabelText('Code')
    const confirm = getByLabelText('Confirm')

    fireEvent.input(codeInput, {target: {value: code}})
    fireEvent.click(confirm)

    await waitFor(() => {
      expect(props.onError).toHaveBeenCalled()
    })
  })
})
