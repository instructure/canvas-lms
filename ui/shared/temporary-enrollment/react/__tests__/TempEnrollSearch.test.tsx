/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {TempEnrollSearch} from '../TempEnrollSearch'
import fetchMock from 'fetch-mock'

describe('TempEnrollSearch', () => {
  const props = {
    user: {
      name: 'user1',
      id: '1',
    },
    accountId: '1',
    searchFail: jest.fn(),
    searchSuccess: jest.fn(),
    canReadSIS: true,
  }
  const userTemplate = {
    user_name: '',
    email: '',
    address: '',
    account_name: '',
    account_id: '',
    login_id: '',
    sis_user_id: '',
  }
  const mockSame = {
    userTemplate,
    user_id: '1',
  }
  const mockNoUser = {
    userTemplate,
    user_id: '',
  }
  const mockFindUser = {
    userTemplate,
    user_id: '2',
  }

  afterEach(() => {
    fetchMock.restore()
  })

  // passes
  it('shows search page', () => {
    const {getByText} = render(<TempEnrollSearch page={0} {...props} />)
    expect(getByText('Find an assignee of temporary enrollments from user1')).toBeInTheDocument()
  })

  it('displays error message when API call fails', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?user_list=&v2=true&search_type=cc_path`, () => {
      throw Object.assign(new Error('error'), {code: 402})
    })
    const {queryAllByText} = render(<TempEnrollSearch page={1} {...props} />)
    await waitFor(() => expect(queryAllByText('error')).toBeTruthy())
  })

  it('displays error message when user is same as original user', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?user_list=&v2=true&search_type=cc_path`, [
      {mockSame},
    ])
    const {queryAllByText} = render(<TempEnrollSearch page={1} {...props} />)
    await waitFor(() =>
      expect(
        queryAllByText(
          'The user found matches the source user. Please search for a different user.'
        )
      ).toBeTruthy()
    )
  })

  it('displays error message when no user is returned', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?user_list=&v2=true&search_type=cc_path`, [
      {mockNoUser},
    ])
    const {queryAllByText} = render(<TempEnrollSearch page={1} {...props} />)
    await waitFor(() => expect(queryAllByText('User could not be found.')).toBeTruthy())
  })

  it('displays new page when user is found', async () => {
    fetchMock.post(`/accounts/1/user_lists.json?user_list=&v2=true&search_type=cc_path`, [
      {mockFindUser},
    ])
    const {queryAllByText} = render(<TempEnrollSearch page={1} {...props} />)
    // in a future commit, this will be changed to the found user on the confirmation screen
    await waitFor(() => expect(queryAllByText('Confirmation Page')).toBeTruthy())
  })

  it('changes label when different search type is chosen', () => {
    const {getAllByText, getByText} = render(<TempEnrollSearch page={0} {...props} />)
    expect(
      getByText('Enter the email address of the user you would like to temporarily enroll')
    ).toBeInTheDocument()

    const sis = getAllByText('SIS ID')[0]
    sis.click()
    expect(
      getByText('Enter the SIS ID of the user you would like to temporarily enroll')
    ).toBeInTheDocument()

    const login = getAllByText('Login ID')[0]
    login.click()
    expect(
      getByText('Enter the login ID of the user you would like to temporarily enroll')
    ).toBeInTheDocument()
  })

  it('hides SIS search when user does not have permission', () => {
    const {queryByText} = render(<TempEnrollSearch page={0} {...props} canReadSIS={false} />)
    expect(queryByText('SIS ID')).toBeFalsy()
  })
})
