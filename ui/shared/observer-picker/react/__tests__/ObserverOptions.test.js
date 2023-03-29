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
import getCookie from '@instructure/get-cookie'

import ObserverOptions from '../ObserverOptions'
import {OBSERVER_COOKIE_PREFIX} from '../../ObserverGetObservee'
import {MOCK_OBSERVED_USERS_LIST} from './fixtures'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

const userId = '13'
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${userId}`

describe('ObserverOptions', () => {
  const getProps = (overrides = {}) => ({
    observedUsersList: MOCK_OBSERVED_USERS_LIST,
    currentUser: {
      id: userId,
      display_name: 'Zelda',
      avatarUrl: 'http://avatar',
    },
    handleChangeObservedUser: jest.fn(),
    canAddObservee: false,
    ...overrides,
  })

  afterEach(() => {
    document.cookie = `${observedUserCookieName}=`
  })

  it('displays students in the select', () => {
    const props = getProps()
    const {getByRole, getByText} = render(<ObserverOptions {...getProps()} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select).toBeInTheDocument()
    expect(select.value).toBe('Zelda')
    act(() => select.click())

    const student2 = props.observedUsersList[2]
    expect(getByText(student2.name)).toBeInTheDocument()
    expect(
      getByText(student2.name).parentElement.querySelector(`[src="${student2.avatar_url}"]`)
    ).toBeInTheDocument()

    const student4 = props.observedUsersList[1]
    expect(getByText(student4.name)).toBeInTheDocument()
    expect(getByText('S4')).toBeInTheDocument()
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
    expect(getCookie(observedUserCookieName)).toBe('2')
  })

  it('renders a label if there is only one observed student', () => {
    const {getByText, queryByRole} = render(
      <ObserverOptions {...getProps({observedUsersList: [MOCK_OBSERVED_USERS_LIST[2]]})} />
    )
    expect(getByText('You are observing Student 2')).toBeInTheDocument()
    expect(getByText('Student 2')).toBeInTheDocument()
    expect(queryByRole('combobox', {name: 'Select a student to view'})).not.toBeInTheDocument()
  })

  it('does not render for non-observers', () => {
    const {container} = render(<ObserverOptions {...getProps({observedUsersList: []})} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('does not render if only user is self', () => {
    const {container} = render(
      <ObserverOptions {...getProps({observedUsersList: [MOCK_OBSERVED_USERS_LIST[0]]})} />
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('automatically selects the user previously selected', () => {
    document.cookie = `${observedUserCookieName}=4;path=/`
    const {getByRole} = render(<ObserverOptions {...getProps()} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select.value).toBe('Student 4')
  })

  it('displays the add student option if the user can add observees', () => {
    const {getByRole, getByText} = render(<ObserverOptions {...getProps()} canAddObservee={true} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select).toBeInTheDocument()
    act(() => select.click())
    expect(getByText('Add Student')).toBeInTheDocument()
  })

  it("does not display the add student option if the user can't add observees", () => {
    const {getByRole, queryByText} = render(
      <ObserverOptions {...getProps()} canAddObservee={false} />
    )
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select).toBeInTheDocument()
    act(() => select.click())
    expect(queryByText('Add Student')).not.toBeInTheDocument()
  })

  it('opens the add student modal when Add Student option is clicked', () => {
    const {getByRole, getByText} = render(<ObserverOptions {...getProps()} canAddObservee={true} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select).toBeInTheDocument()
    act(() => select.click())
    act(() => getByText('Add Student').click())
    expect(getByText('Pair with student')).toBeInTheDocument()
  })

  it('highlights only the currently selected student', () => {
    const {getByRole} = render(<ObserverOptions {...getProps()} />)
    const select = getByRole('combobox', {name: 'Select a student to view'})
    act(() => select.click())
    expect(getByRole('option', {name: 'Zelda', selected: true})).toBeInTheDocument()
    expect(getByRole('option', {name: 'Student 2', selected: false})).toBeInTheDocument()
    const student4 = getByRole('option', {name: 'Student 4', selected: false})
    expect(student4).toBeInTheDocument()
    act(() => student4.click())
    act(() => select.click())
    expect(getByRole('option', {name: 'Student 4', selected: true})).toBeInTheDocument()
    expect(getByRole('option', {name: 'Zelda', selected: false})).toBeInTheDocument()
    expect(getByRole('option', {name: 'Student 2', selected: false})).toBeInTheDocument()
  })
})
