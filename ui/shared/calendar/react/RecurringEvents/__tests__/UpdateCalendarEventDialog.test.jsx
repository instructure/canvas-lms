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
import {render, act, within} from '@testing-library/react'
import {getByText as domGetByText, waitFor} from '@testing-library/dom'

import {
  UpdateCalendarEventDialog,
  renderUpdateCalendarEventDialog,
} from '../UpdateCalendarEventDialog'

const eventMock = {
  url: 'http://localhost',
  series_head: false,
}

const handleCancel = jest.fn()
const handleUpdate = jest.fn()

const defaultProps = {
  event: eventMock,
  isOpen: true,
  onCancel: handleCancel,
  onUpdate: handleUpdate,
}

function renderDialog(overrideProps = {}) {
  const props = {...defaultProps, ...overrideProps}
  return render(<UpdateCalendarEventDialog {...props} />)
}

describe('UpdateCalendarEventDialog', () => {
  it('renders event series dialog', () => {
    const {getByText} = renderDialog()
    expect(getByText('Confirm Changes')).toBeInTheDocument()
    expect(getByText('This event')).toBeInTheDocument()
    expect(getByText('All events')).toBeInTheDocument()
    expect(getByText('This and all following events')).toBeInTheDocument()
  })

  it('renders event series dialog except "following" option for a head event', () => {
    const {getByText, queryByText} = renderDialog({
      event: {
        url: 'http://localhost',
        series_head: true,
      },
    })
    expect(getByText('Confirm Changes')).toBeInTheDocument()
    expect(getByText('This event')).toBeInTheDocument()
    expect(getByText('All events')).toBeInTheDocument()
    expect(queryByText('This and all following events')).not.toBeInTheDocument()
  })

  it('closes on cancel', async () => {
    const {getByText} = renderDialog()
    act(() => getByText('Cancel').closest('button').click())
    expect(handleCancel).toHaveBeenCalled()
  })

  it('calls callbacks with selected option', () => {
    const {getByText} = renderDialog()
    act(() => getByText('All events').click())
    act(() => getByText('Confirm').closest('button').click())
    expect(handleUpdate).toHaveBeenCalledWith('all')
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
