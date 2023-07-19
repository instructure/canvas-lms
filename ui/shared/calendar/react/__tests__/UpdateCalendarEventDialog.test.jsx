/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {render, act, within} from '@testing-library/react'
import {getByText as domGetByText, waitFor} from '@testing-library/dom'

import {
  UpdateCalendarEventDialog,
  renderUpdateCalendarEventDialog,
} from '../UpdateCalendarEventDialog'

const eventMock = {
  url: 'http://localhost',
  series_head: true,
}

const paramsMock = {
  'calendar_event[title]': 'test',
}
const handleCancel = jest.fn()
const handleUpdate = jest.fn()
const handleUpdated = jest.fn()
const handleError = jest.fn()

const defaultProps = {
  event: eventMock,
  params: paramsMock,
  isOpen: true,
  onCancel: handleCancel,
  onUpdate: handleUpdate,
  onUpdated: handleUpdated,
  onError: handleError,
}

function renderDialog(overrideProps = {}) {
  const props = {...defaultProps, ...overrideProps}
  return render(<UpdateCalendarEventDialog {...props} />)
}

jest.mock('@canvas/do-fetch-api-effect')

describe('UpdateCalendarEventDialog', () => {
  beforeEach(() => doFetchApi.mockImplementation(() => Promise.resolve({})))

  afterEach(() => doFetchApi.mockClear())

  it('renders event series dialog', () => {
    const {getByText} = renderDialog()
    expect(getByText('Confirm Changes')).toBeInTheDocument()
    expect(getByText('This event')).toBeInTheDocument()
    expect(getByText('All events')).toBeInTheDocument()
    expect(getByText('This and all following events')).toBeInTheDocument()
  })

  it('renders event series dialog excluding all for a not head event', () => {
    const {getByText, queryByText} = renderDialog({
      event: {
        calendarEvent: {
          url: 'http://localhost',
          series_head: false,
        },
      },
    })
    expect(getByText('Confirm Changes')).toBeInTheDocument()
    expect(getByText('This event')).toBeInTheDocument()
    expect(queryByText('All events')).not.toBeInTheDocument()
    expect(getByText('This and all following events')).toBeInTheDocument()
  })

  it('closes on cancel', async () => {
    const {getByText} = renderDialog()
    act(() => getByText('Cancel').closest('button').click())
    expect(handleCancel).toHaveBeenCalled()
  })

  it('calls callbacks when updating', async () => {
    const {getByText} = renderDialog()
    act(() => getByText('Confirm').closest('button').click())
    expect(handleUpdate).toHaveBeenCalled()
    await waitFor(() => expect(handleUpdated).toHaveBeenCalled())
  })

  it('calls callbacks when updating has errors', async () => {
    const {getByText} = renderDialog()
    doFetchApi.mockImplementationOnce(() => Promise.reject())
    act(() => getByText('Confirm').closest('button').click())
    expect(handleUpdate).toHaveBeenCalled()
    await waitFor(() => expect(handleError).toHaveBeenCalled())
  })

  describe('sends correct params when', () => {
    const selectEventOption = optionText => {
      const {getByText} = renderDialog()
      getByText(optionText).click()
      act(() => getByText('Confirm').closest('button').click())
    }

    it('"this event" is selected', () => {
      selectEventOption('This event')
      expect(doFetchApi.mock.calls.length).toBe(1)
      expect(doFetchApi.mock.calls[0][0].params.which).toBe('one')
    })

    it('"this and all following" is selected', () => {
      selectEventOption('This and all following events')
      expect(doFetchApi.mock.calls.length).toBe(1)
      expect(doFetchApi.mock.calls[0][0].params.which).toBe('following')
    })

    it('"all events" is selected', () => {
      selectEventOption('All events')
      expect(doFetchApi.mock.calls.length).toBe(1)
      expect(doFetchApi.mock.calls[0][0].params.which).toBe('all')
    })
  })

  describe('while updating is in flight', () => {
    beforeEach(() => {
      doFetchApi.mockImplementation(() => new Promise(resolve => setTimeout(() => resolve()), 1))
    })

    it('shows cancel and update tooltip', () => {
      const {getByRole, getAllByText} = renderDialog()
      const confirmButton = getByRole('button', {name: 'Confirm'})
      act(() => confirmButton.click())
      expect(getAllByText('Wait for update to complete').length).toEqual(2)
    })

    it('renders a spinner inside the update button', () => {
      const {getByRole} = renderDialog()
      const confirmButton = getByRole('button', {name: 'Confirm'})
      act(() => confirmButton.click())
      const spinner = within(confirmButton).getByRole('img', {name: 'Updating'})
      expect(spinner).toBeInTheDocument()
    })
  })

  describe('render function', () => {
    it('renders', () => {
      const container = document.createElement('div')
      document.body.appendChild(container)
      renderUpdateCalendarEventDialog(container, defaultProps)
      expect(domGetByText(document.body, 'Confirm Changes')).toBeInTheDocument()
    })
  })
})
