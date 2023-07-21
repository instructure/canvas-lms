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
import RoleList from './RoleList'

export default {
  title: 'Examples/Outcomes/RoleList',
  component: RoleList,
  args: {
    description: 'Allowed Roles',
    roles: [
      {
        id: '1',
        role: 'Teacher_role',
        label: 'Teacher',
        base_role_type: 'Teacher',
      },
      {
        id: '2',
        role: 'Admin',
        label: 'Admin',
        base_role_type: 'Admin',
      },
    ],
  },
}

const Template = args => <RoleList {...args} />

export const Default = Template.bind({})
