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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import NotificationSettings, {type NotificationSettingsProps} from '..'

function formDataToObject(formData: FormData): Record<string, string> {
  const obj: Record<string, string> = {}
  for (const e of formData) {
    obj[e[0]] = e[1] as string
  }
  return obj
}

function renderComponent(overrideProps = {}) {
  const props: NotificationSettingsProps = {
    accountId: '1',
    externalWarning: false,
    customNameOption: 'default',
    customName: undefined,
    defaultName: 'default name',
    ...overrideProps,
  }
  return render(<NotificationSettings {...props} />)
}

describe('NotificationSettings::', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('renders all sections', () => {
    const {getByText} = renderComponent()
    expect(getByText('Email Notification "From" Settings')).toBeInTheDocument()
    expect(getByText('Reply-To')).toBeInTheDocument()
    expect(getByText('Notifications Sent to External Services')).toBeInTheDocument()
  })
  it('renders the combobox but not the input field when customNameOption is default', () => {
    const {queryByTestId} = renderComponent()
    expect(queryByTestId('from-select')).toBeInTheDocument()
    expect(queryByTestId('custom-name-input')).toBeNull()
  })

  it('renders both combobox and input field when customNameOption is custom', () => {
    const {queryByTestId} = renderComponent({
      customNameOption: 'custom',
      customName: 'Jackson Roykirk',
    })
    const input = queryByTestId('custom-name-input')
    expect(queryByTestId('from-select')).toBeInTheDocument()
    expect(input).toBeInTheDocument()
    expect(input).toHaveValue('Jackson Roykirk')
  })

  it('does not make an API call and highlights an empty required field', async () => {
    const id = '1'
    // simulate an API error so we don't try to reload the window
    fetchMock.putOnce(`/accounts/${id}`, 500)
    const {container, getByTestId} = renderComponent({
      accountId: id,
      customNameOption: 'custom',
      customName: '',
    })
    const input = getByTestId('custom-name-input')
    const updateButton = getByTestId('update-button')
    await userEvent.click(updateButton)
    expect(input).toHaveFocus()
    expect(container).toHaveTextContent('Please enter a custom "From" name.')
    // wait just a bit... long enough for a (wrong) API call to be made if it's going to
    await new Promise(resolve => setTimeout(resolve, 50))
    expect(fetchMock.called()).toBe(false)
  })

  it('sends the right data when updating', async () => {
    const id = '52'
    // simulate an API error so we don't try to reload the window
    fetchMock.putOnce(`/accounts/${id}`, 500)
    // Render with a custom (but blank) name and external warning disabled
    // Then we will fill in the name and check the warning box
    // The result should be that the update succeeds (makes the API call)
    // with the correct form data in the body
    const {getByTestId} = renderComponent({accountId: id, customNameOption: 'custom'})
    const warningCheckbox = getByTestId('external-warning')
    const customNameInput = getByTestId('custom-name-input')
    const updateButton = getByTestId('update-button')
    await userEvent.click(warningCheckbox) // enable external warning
    await userEvent.type(customNameInput, 'Jackson Roykirk')
    await userEvent.click(updateButton)
    await waitFor(() => expect(fetchMock.called()).toBe(true))
    const apiParms = fetchMock.lastOptions()
    const formData = formDataToObject(apiParms?.body as FormData)
    expect(apiParms?.method).toBe('PUT')
    expect(formData['account[settings][external_notification_warning]']).toBe('1')
    expect(formData['account[settings][outgoing_email_default_name]']).toBe('Jackson Roykirk')
  })
})
