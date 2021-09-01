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
import {render, act, fireEvent, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import ObserverOptions from '../ObserverOptions'
import {MOCK_OBSERVER_ENROLLMENTS} from './fixtures'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const ENROLLMENTS_URL = encodeURI(
  '/api/v1/users/self/enrollments?type[]=ObserverEnrollment&include[]=avatar_url&include[]=observed_users&per_page=100'
)

describe('ObserverOptions', () => {
  const getProps = (overrides = {}) => ({
    currentUser: {
      id: '13',
      display_name: 'Zelda',
      avatar_image_url: 'http://avatar'
    },
    currentUserRoles: ['observer', 'student', 'user'],
    handleChangeObservedUser: jest.fn(),
    ...overrides
  })

  beforeEach(() => {
    fetchMock.get(ENROLLMENTS_URL, MOCK_OBSERVER_ENROLLMENTS)
  })

  afterEach(() => {
    fetchMock.restore()
    destroyContainer()
    sessionStorage.clear()
  })

  it('renders a loading skeleton just while loading enrollments', async () => {
    const {getByText, findByRole, queryByText} = render(<ObserverOptions {...getProps()} />)
    const skeletonText = 'Loading observed students'
    expect(getByText(skeletonText)).toBeInTheDocument()
    expect(await findByRole('combobox', {name: 'Select a student to view'})).toBeInTheDocument()
    expect(queryByText(skeletonText)).not.toBeInTheDocument()
  })

  it('shows an alert if enrollments fail to load', async () => {
    fetchMock.get(ENROLLMENTS_URL, 500, {overwriteRoutes: true})
    const {findAllByText} = render(<ObserverOptions {...getProps()} />)
    const alerts = await findAllByText('Unable to get observed students')
    expect(alerts[0]).toBeInTheDocument()
  })

  it('displays students in the select', async () => {
    const {findByRole, getByText} = render(<ObserverOptions {...getProps()} />)
    const select = await findByRole('combobox', {name: 'Select a student to view'})
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

  it('calls handleChangeObservedUser and saves to sessionStorage when changing the user', async () => {
    const handleChangeObservedUser = jest.fn()
    const {findByRole, getByText} = render(
      <ObserverOptions {...getProps({handleChangeObservedUser})} />
    )
    const select = await findByRole('combobox', {name: 'Select a student to view'})
    act(() => select.click())
    act(() => getByText('Student 2').click())
    expect(handleChangeObservedUser).toHaveBeenCalledWith('2')
    expect(sessionStorage.getItem('k5_observed_user_id')).toBe('2')
  })

  it('renders a label if there is only one observed student', async () => {
    fetchMock.get(ENROLLMENTS_URL, MOCK_OBSERVER_ENROLLMENTS[2], {overwriteRoutes: true})
    const {findByText, getByText, queryByRole} = render(
      <ObserverOptions {...getProps({currentUserRoles: ['user', 'observer']})} />
    )
    expect(await findByText('You are observing Student 2')).toBeInTheDocument()
    expect(getByText('Student 2')).toBeInTheDocument()
    expect(queryByRole('combobox', {name: 'Select a student to view'})).not.toBeInTheDocument()
  })

  it('does not render for non-observers', async () => {
    fetchMock.get(ENROLLMENTS_URL, [], {overwriteRoutes: true})
    const {getByText, queryByText, queryByRole} = render(
      <ObserverOptions {...getProps({currentUserRoles: ['user', 'teacher']})} />
    )
    const skeletonText = 'Loading observed students'
    expect(getByText(skeletonText)).toBeInTheDocument()
    await waitFor(() => expect(queryByText('Loading observed students')).not.toBeInTheDocument())
    expect(queryByRole('combobox', {name: 'Select a student to view'})).not.toBeInTheDocument()
  })

  it('automatically selects the user previously selected', async () => {
    sessionStorage.setItem('k5_observed_user_id', '4')
    const {findByRole} = render(<ObserverOptions {...getProps()} />)
    const select = await findByRole('combobox', {name: 'Select a student to view'})
    expect(select.value).toBe('Student 4')
  })
})
