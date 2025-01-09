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
import {render} from '@testing-library/react'
import {TempEnrollSearch} from '../TempEnrollSearch'
import fetchMock from 'fetch-mock'
import type {User} from '../types'

describe('TempEnrollSearch', () => {
  const props = {
    user: {
      name: 'user1',
      id: '1',
    } as User,
    accountId: '1',
    searchFail: jest.fn(),
    searchSuccess: jest.fn(),
    canReadSIS: true,
    foundUsers: [],
    duplicateReq: false,
  }

  beforeAll(() => {
    // @ts-expect-error
    window.ENV = {ACCOUNT_ID: '1'}
  })

  afterEach(() => {
    fetchMock.restore()
  })

  afterAll(() => {
    // @ts-expect-error
    window.ENV = {}
  })

  it('shows search page', () => {
    const {getByText} = render(<TempEnrollSearch page={0} {...props} />)
    expect(getByText('Find recipient(s) of temporary enrollments from user1')).toBeInTheDocument()
  })

  it('changes label when different search type is chosen', () => {
    const {getAllByText, getByText} = render(<TempEnrollSearch page={0} {...props} />)
    expect(
      getByText('Enter the email addresses of the users you would like to temporarily enroll'),
    ).toBeInTheDocument()

    const sis = getAllByText('SIS ID')[0]
    sis.click()
    expect(
      getByText('Enter the SIS IDs of the users you would like to temporarily enroll'),
    ).toBeInTheDocument()

    const login = getAllByText('Login ID')[0]
    login.click()
    expect(
      getByText('Enter the login IDs of the users you would like to temporarily enroll'),
    ).toBeInTheDocument()
  })

  it('hides SIS search when user does not have permission', () => {
    const {queryByText} = render(<TempEnrollSearch page={0} {...props} canReadSIS={false} />)
    expect(queryByText('SIS ID')).toBeFalsy()
  })
})
