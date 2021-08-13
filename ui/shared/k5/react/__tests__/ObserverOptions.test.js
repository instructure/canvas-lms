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
import {render, act, fireEvent} from '@testing-library/react'
import getCookie from 'get-cookie'

import ObserverOptions, {SELECTED_OBSERVED_USER_COOKIE} from '../ObserverOptions'
import {MOCK_OBSERVER_LIST} from './fixtures'

describe('ObserverOptions', () => {
  const getProps = (overrides = {}) => ({
    observerList: MOCK_OBSERVER_LIST,
    currentUser: {
      id: '13',
      display_name: 'Zelda',
      avatar_image_url: 'http://avatar'
    },
    handleChangeObservedUser: jest.fn(),
    ...overrides
  })

  afterEach(() => {
    document.cookie = `${SELECTED_OBSERVED_USER_COOKIE}=`
  })

  it('displays students in the select', () => {
    const {getByRole, getByText} = render(<ObserverOptions {...getProps()} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select).toBeInTheDocument()
    expect(select.value).toBe('Zelda')
    act(() => select.click())
    expect(getByText('Student 2')).toBeInTheDocument()
    expect(getByText('Student 4')).toBeInTheDocument()
  })

  it('allows searching the select', async () => {
    const {findByRole, getByText, queryByText} = render(<ObserverOptions {...getProps()} />)
    const select = await findByRole('combobox', {name: 'Select a student to view'})
    fireEvent.change(select, {target: {value: '4'}})
    expect(getByText('Student 4')).toBeInTheDocument()
    expect(queryByText('Student 2')).not.toBeInTheDocument()
    expect(queryByText('Zelda')).not.toBeInTheDocument()
  })

  it('calls handleChangeObservedUser and saves cookie when changing the user', () => {
    const handleChangeObservedUser = jest.fn()
    const {getByRole, getByText} = render(
      <ObserverOptions {...getProps({handleChangeObservedUser})} />
    )
    const select = getByRole('combobox', {name: 'Select a student to view'})
    act(() => select.click())
    act(() => getByText('Student 2').click())
    expect(handleChangeObservedUser).toHaveBeenCalledWith('2')
    expect(getCookie(SELECTED_OBSERVED_USER_COOKIE)).toBe('2')
  })

  it('renders a label if there is only one observed student', () => {
    const {getByText, queryByRole} = render(
      <ObserverOptions {...getProps({observerList: [MOCK_OBSERVER_LIST[2]]})} />
    )
    expect(getByText('You are observing Student 2')).toBeInTheDocument()
    expect(getByText('Student 2')).toBeInTheDocument()
    expect(queryByRole('combobox', {name: 'Select a student to view'})).not.toBeInTheDocument()
  })

  it('does not render for non-observers', () => {
    const {container} = render(<ObserverOptions {...getProps({observerList: []})} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('does not render if only user is self', () => {
    const {container} = render(
      <ObserverOptions {...getProps({observerList: [MOCK_OBSERVER_LIST[0]]})} />
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('automatically selects the user previously selected', () => {
    document.cookie = `${SELECTED_OBSERVED_USER_COOKIE}=4;path=/`
    const {getByRole} = render(<ObserverOptions {...getProps()} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select.value).toBe('Student 4')
  })
})
