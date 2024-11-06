/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'

import DetailsToggle from '../DetailsToggle'

const defaultProps = () => ({
  title: "Aaron's best toggler",
  detailItems: [
    {
      title: 'Account Settings:',
      description:
        'Allows user to view and manage the Settings and Notifications tabs in account settings.',
    },
  ],
})

it('renders DetailsToggle component', () => {
  const props = defaultProps()
  const tree = render(<DetailsToggle {...props} />)
  const node = tree.getByText(props.title)
  expect(node).toBeInTheDocument()
})

it('renders correct number of permission details when given list of permissions', async () => {
  const props = defaultProps()
  props.permissionName = 'super_fake_permissions_name_that_should_not_exist'
  props.detailItems = [
    {
      title: 'Account Settings:',
      description:
        'Allows user to view and manage the Settings and Notifications tabs in account settings.',
    },
    {
      title: 'Authentication (Account Navigation:)',
      description: 'Allows user to view and manage Authentication for the whole account.',
    },
    {
      title: 'Subaccounts:',
      description: 'Allows user to view and manage subaccounts for the root account.',
    },
    {
      title: 'Terms:',
      description: 'Allows user to view and manage terms for the root account.',
    },
    {
      title: 'Theme Editor:',
      description: 'Allows user to access the Theme Editor.',
    },
  ]
  const {getByText} = render(<DetailsToggle {...props} />)
  const toggle = getByText(props.title).closest('button')
  await userEvent.click(toggle)
  props.detailItems.forEach(item => {
    expect(getByText(item.title)).toBeInTheDocument()
    expect(getByText(item.description)).toBeInTheDocument()
  })
})
