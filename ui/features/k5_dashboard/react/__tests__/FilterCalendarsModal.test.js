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
import {act, render, waitFor} from '@testing-library/react'

import FilterCalendarsModal from '../FilterCalendarsModal'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import {IMPORTANT_DATES_CONTEXTS} from '@canvas/k5/react/__tests__/fixtures'

const SAVED_SELECTED_CONTEXTS_URL = /\/api\/v1\/calendar_events\/save_selected_contexts.*/

const defaultProps = {
  closeModal: jest.fn(),
  contexts: IMPORTANT_DATES_CONTEXTS,
  isOpen: true,
  selectedContextCodes: ['course_2'],
  selectedContextsLimit: 2,
  updateSelectedContextCodes: jest.fn(),
}

beforeEach(() => {
  fetchMock.post(SAVED_SELECTED_CONTEXTS_URL, JSON.stringify({status: 'ok'}))
})

afterEach(() => {
  jest.resetAllMocks()
  fetchMock.restore()
  destroyContainer()
})

describe('FilterCalendarsModal', () => {
  it('renders nothing when not open', () => {
    const {queryByText} = render(<FilterCalendarsModal {...defaultProps} isOpen={false} />)
    expect(queryByText('Calendars')).not.toBeInTheDocument()
  })

  it('renders a modal with a list of selected calendars when open', () => {
    const {getByRole, getByText} = render(<FilterCalendarsModal {...defaultProps} />)
    expect(getByText('Calendars')).toBeInTheDocument()
    expect(getByText('Choose up to 2 subject calendars')).toBeInTheDocument()

    expect(getByRole('checkbox', {name: 'Economics 101', checked: false})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'Home Room', checked: true})).toBeInTheDocument()
    expect(getByRole('checkbox', {name: 'The Maths', checked: false})).toBeInTheDocument()
  })

  it('renders a cancel button that closes the modal', () => {
    const {getByRole} = render(<FilterCalendarsModal {...defaultProps} />)

    act(() => getByRole('button', {name: 'Cancel'}).click())

    expect(defaultProps.closeModal).toHaveBeenCalledTimes(1)
  })

  it('renders a submit button that updates and saves the selected contexts', async () => {
    const {getByRole} = render(<FilterCalendarsModal {...defaultProps} />)

    act(() => getByRole('checkbox', {name: 'The Maths'}).click())
    act(() => getByRole('checkbox', {name: 'Home Room'}).click())
    act(() => getByRole('button', {name: 'Submit'}).click())

    expect(defaultProps.closeModal).toHaveBeenCalledTimes(1)
    expect(defaultProps.updateSelectedContextCodes).toHaveBeenCalledWith(['course_3'])

    await waitFor(() => expect(fetchMock.called(SAVED_SELECTED_CONTEXTS_URL, 'POST')).toBe(true))
    expect(fetchMock.lastUrl(SAVED_SELECTED_CONTEXTS_URL)).toMatch(
      'selected_contexts%5B%5D=course_3'
    )
  })

  it('renders an error message if saving selected contexts fails', async () => {
    fetchMock.post(SAVED_SELECTED_CONTEXTS_URL, 500, {overwriteRoutes: true})

    const {findAllByText, getByRole} = render(<FilterCalendarsModal {...defaultProps} />)

    act(() => getByRole('button', {name: 'Submit'}).click())

    expect((await findAllByText('Failed to save selected calendars'))[0]).toBeInTheDocument()
  })

  it('disables unselected calendars when the max selected number is reached', async () => {
    const {getByRole} = render(<FilterCalendarsModal {...defaultProps} />)

    expect(getByRole('checkbox', {name: 'Economics 101', checked: false})).not.toBeDisabled()
    expect(getByRole('checkbox', {name: 'Home Room', checked: true})).not.toBeDisabled()
    expect(getByRole('checkbox', {name: 'The Maths', checked: false})).not.toBeDisabled()

    act(() => getByRole('checkbox', {name: 'Economics 101'}).click())

    expect(getByRole('checkbox', {name: 'Economics 101', checked: true})).not.toBeDisabled()
    expect(getByRole('checkbox', {name: 'Home Room', checked: true})).not.toBeDisabled()
    expect(getByRole('checkbox', {name: 'The Maths', checked: false})).toBeDisabled()

    act(() => getByRole('checkbox', {name: 'Home Room'}).click())

    expect(getByRole('checkbox', {name: 'Economics 101', checked: true})).not.toBeDisabled()
    expect(getByRole('checkbox', {name: 'Home Room', checked: false})).not.toBeDisabled()
    expect(getByRole('checkbox', {name: 'The Maths', checked: false})).not.toBeDisabled()
  })

  it('indicates the number of calendars left to select as checkboxes are checked', async () => {
    const {getByRole, getByText} = render(
      <FilterCalendarsModal {...defaultProps} selectedContextCodes={[]} />
    )
    expect(getByText('You have 2 calendars left')).toBeInTheDocument()

    act(() => getByRole('checkbox', {name: 'Home Room', checked: false}).click())

    expect(getByText('You have 1 calendar left')).toBeInTheDocument()

    act(() => getByRole('checkbox', {name: 'The Maths', checked: false}).click())

    expect(getByText('You have 0 calendars left')).toBeInTheDocument()
  })
})
