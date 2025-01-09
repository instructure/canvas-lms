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
import {TempEnrollSearchConfirmation} from '../TempEnrollSearchConfirmation'
import {render} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import type {User, DuplicateUser} from '../types'

const props = {
  foundUsers: [],
  duplicateUsers: {},
  searchFailure: jest.fn(),
  readySubmit: jest.fn(),
  canReadSIS: true,
  duplicateReq: false,
}

const oneUser = {
  name: 'username_1',
  id: '1',
  sis_user_id: 'sis_1',
  primary_email: 'user1@email.com',
} as User

const twoUser = {
  name: 'brother_2',
  user_name: 'brother_2',
  user_id: '21',
  id: '21',
  sis_user_id: 'sis_2',
  primary_email: 'user2@email.com',
} as User

// @ts-expect-error
const twoBrotherUser = {
  user_name: 'brother_2',
  user_id: '21',
  sis_user_id: 'sis_2',
  primary_email: 'user2@email.com',
} as DuplicateUser

// @ts-expect-error
const twoSisterUser = {
  name: 'sister_2',
  user_name: 'sister_2',
  user_id: '22',
  id: '22',
  sis_user_id: 'sis_2',
  primary_email: 'user2@email.com',
} as DuplicateUser

const threeBrotherUser = {
  user_name: 'brother_3',
  user_id: '31',
  sis_user_id: 'sis_3',
  primary_email: 'user3@email.com',
}

const threeSisterUser = {
  user_name: 'sister_3',
  user_id: '32',
  sis_user_id: 'sis_3',
  primary_email: 'user3@email.com',
}

const userDetailsUriMock = (userId: string, response: object) =>
  fetchMock.getOnce(`/api/v1/users/${userId}/profile`, response)

describe('TempEnrollSearchConfirmation', () => {
  beforeEach(() => {
    fetchMock.reset()
    jest.clearAllMocks()
  })

  it('render one user', async () => {
    userDetailsUriMock('1', oneUser)
    const {findByText} = render(<TempEnrollSearchConfirmation {...props} foundUsers={[oneUser]} />)

    expect(await findByText('sis_1')).toBeInTheDocument()
    expect(await findByText('user1@email.com')).toBeInTheDocument()
    expect(await findByText('username_1')).toBeInTheDocument()
    expect(await findByText(/One user is ready/)).toBeInTheDocument()
  })

  it('render multiple users', async () => {
    userDetailsUriMock('1', oneUser)
    userDetailsUriMock('21', twoUser)
    const {findByText} = render(
      <TempEnrollSearchConfirmation {...props} foundUsers={[oneUser, twoUser]} />,
    )

    expect(await findByText('user1@email.com')).toBeInTheDocument()
    expect(await findByText('user2@email.com')).toBeInTheDocument()
    expect(await findByText(/2 users are ready/)).toBeInTheDocument()
  })

  it('render one set of duplicates', async () => {
    const duplicateObj = {sis_2: [twoBrotherUser, twoSisterUser]}
    const {getByText} = render(
      <TempEnrollSearchConfirmation {...props} duplicateUsers={duplicateObj} />,
    )

    expect(getByText('sister_2')).toBeInTheDocument()
    expect(getByText('brother_2')).toBeInTheDocument()
    expect(getByText(/No users are ready/)).toBeInTheDocument()
  })

  it('render multiple sets of duplicates', async () => {
    const duplicateObj = {
      sis_2: [twoBrotherUser, twoSisterUser],
      sis_3: [threeSisterUser, threeBrotherUser],
    }
    const {getByText, getAllByText} = render(
      // @ts-expect-error
      <TempEnrollSearchConfirmation {...props} duplicateUsers={duplicateObj} />,
    )

    expect(
      getAllByText('Possible matches for "sis_2". Select the desired one below.')[0],
    ).toBeInTheDocument()
    expect(
      getAllByText('Possible matches for "sis_3". Select the desired one below.')[0],
    ).toBeInTheDocument()
    expect(getByText(/No users are ready/)).toBeInTheDocument()
  })

  it('selecting a duplicate increments ready user count', async () => {
    const duplicateObj = {
      sis_2: [twoBrotherUser, twoSisterUser],
      sis_3: [threeSisterUser, threeBrotherUser],
    }
    const {getByLabelText, getByText} = render(
      // @ts-expect-error
      <TempEnrollSearchConfirmation {...props} duplicateUsers={duplicateObj} />,
    )

    expect(getByText(/No users are ready/)).toBeInTheDocument()

    // click on brother3
    const brother3 = getByLabelText('Click to select user brother_3')
    brother3.click()
    expect(getByText(/One user is ready/)).toBeInTheDocument()

    // click on brother3
    const sister2 = getByLabelText('Click to select user sister_2')
    sister2.click()

    expect(getByText(/2 users are ready/)).toBeInTheDocument()
  })
})
