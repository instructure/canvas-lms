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
import GroupsTray from '../GroupsTray'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

const render = (children: unknown) =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

describe('GroupsTray', () => {
  const groups = [
    {
      id: '1',
      name: 'Group1',
      context_name: 'Course1',
      context_type: 'Course',
      can_access: true,
    },
    {
      id: '2',
      name: 'Group2',
      context_name: 'Account1',
      context_type: 'Account',
      can_access: true,
    },
  ]

  beforeEach(() => {
    queryClient.setQueryData(['groups', 'self', 'can_access'], groups)
  })

  afterEach(() => {
    queryClient.removeQueries()
  })

  it('renders the header', () => {
    const {getByText} = render(<GroupsTray />)
    expect(getByText('Groups')).toBeVisible()
  })

  it('renders a link for each group', () => {
    const {getByText} = render(<GroupsTray />)
    getByText('Group1')
    getByText('Group2')
  })

  it('renders a group context name', () => {
    const {getByText} = render(<GroupsTray />)
    getByText('Course1')
  })

  it('does not render an account context name', () => {
    const {queryByText} = render(<GroupsTray />)
    expect(queryByText('Account1')).toBeNull()
  })

  it('renders all groups link', () => {
    const {getByText} = render(<GroupsTray />)
    getByText('All Groups')
  })
})
