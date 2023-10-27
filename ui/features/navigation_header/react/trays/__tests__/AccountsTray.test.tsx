/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render as testingLibraryRender} from '@testing-library/react'
import AccountsTray from '../AccountsTray'
import {QueryProvider, queryClient} from '@canvas/query'

const render = (children: unknown) =>
  testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

describe('AccountsTray', () => {
  const accounts = [
    {
      id: '1',
      name: 'Account1',
    },
    {
      id: '2',
      name: 'Account2',
    },
  ]

  beforeEach(() => {
    queryClient.setQueryData(['accounts'], accounts)
  })

  afterEach(() => {
    queryClient.removeQueries()
  })

  it('renders the header', () => {
    const {getByText} = render(<AccountsTray />)
    expect(getByText('Admin')).toBeVisible()
  })

  it('renders a link for each account', () => {
    const {getByText} = render(<AccountsTray />)
    getByText('Account1')
    getByText('Account2')
  })

  it('renders all accounts link', () => {
    const {getByText} = render(<AccountsTray />)
    getByText('All Accounts')
  })
})
