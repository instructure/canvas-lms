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
import {arrayOf, string, shape} from 'prop-types'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {getSortedRoles} from '@canvas/permissions/util'

const RoleList = ({description, roles}) => {
  if (roles?.length > 0) {
    const accountAdmin = roles.find(element => element.role === 'AccountAdmin')

    return (
      <>
        <p>
          <Text>{description}</Text>
        </p>
        <List>
          {getSortedRoles(roles, accountAdmin).map(role => (
            <List.Item key={role.id}>{role.label}</List.Item>
          ))}
        </List>
      </>
    )
  } else {
    return null
  }
}

RoleList.propTypes = {
  description: string.isRequired,
  roles: arrayOf(
    shape({
      id: string.isRequired,
      role: string.isRequired,
      label: string.isRequired,
      base_role_type: string.isRequired,
    })
  ).isRequired,
}

export default RoleList
