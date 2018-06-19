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
import {shallow, mount} from 'enzyme'

import DetailsToggle from 'jsx/permissions/components/DetailsToggle'

const defaultProps = () => ({
  title: "Aaron's best toggler",
  detailItems: []
})

it('renders DetailsToggle component', () => {
  const props = defaultProps()
  const tree = mount(<DetailsToggle {...props} />)
  const node = tree.find('DetailsToggle')
  expect(node.exists()).toBeTruthy()
})

it('renders correct number of permission details when given list of permissions', () => {
  const props = defaultProps()
  props.permissionName = 'super_fake_permissions_name_that_should_not_exist'
  props.detailItems = [
    {
      title: 'Account Settings:',
      description:
        'Allows user to view and manage the Settings and Notifications tabs in account settings.'
    },
    {
      title: 'Authentication (Account Navigation:)',
      description: 'Allows user to view and manage Authentication for the whole account.'
    },
    {
      title: 'Subaccounts:',
      description: 'Allows user to view and manage subaccounts for the root account.'
    },
    {
      title: 'Terms:',
      description: 'Allows user to view and manage terms for the root account.'
    },
    {
      title: 'Theme Editor:',
      description: 'Allows user to access the Theme Editor.'
    }
  ]
  const tree = shallow(<DetailsToggle {...props} />)
  const node = tree.find('View')
  expect(node).toHaveLength(5)
})
