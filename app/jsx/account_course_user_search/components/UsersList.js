/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import preventDefault from 'compiled/fn/preventDefault'
import IconMiniArrowUpSolid from 'instructure-icons/lib/Solid/IconMiniArrowUpSolid'
import IconMiniArrowDownSolid from 'instructure-icons/lib/Solid/IconMiniArrowDownSolid'
import ApplyTheme from '@instructure/ui-core/lib/components/ApplyTheme'
import Tooltip from '@instructure/ui-core/lib/components/Tooltip'
import Link from '@instructure/ui-core/lib/components/Link'
import Table from '@instructure/ui-core/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import React from 'react'
import {arrayOf, string, object, func} from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import UsersListRow from './UsersListRow'


export default function UsersList (props) {

  function UserListHeader ({id, tipAsc, tipDesc, label}) {
    const {sort, order, search_term, role_filter_id} = props.userList.searchFilter
    const newOrder = (sort === id && order === 'asc') || (!sort && id === 'username')
      ? 'desc'
      : 'asc'

    return (
      <th scope="col">
        <ApplyTheme theme={{[Link.theme]: {fontWeight: 'bold'}}}>
          <Tooltip
            as={Link}
            tip={(sort === id && order === 'asc') ? tipAsc : tipDesc}
            onClick={preventDefault(() => {
              props.onUpdateFilters({search_term, sort: id, order: newOrder, role_filter_id})
            })}
          >
            {label}
            {sort === id ?
              (order === 'asc' ? <IconMiniArrowDownSolid /> : <IconMiniArrowUpSolid />) :
              ''
            }
          </Tooltip>
        </ApplyTheme>
      </th>
    )
  }

  return (
    <Table margin="small 0" caption={<ScreenReaderContent>{I18n.t('Users')}</ScreenReaderContent>}>
      <thead>
        <tr>
          <UserListHeader
            id="username"
            label={I18n.t('Name')}
            tipDesc={I18n.t('Click to sort by name ascending')}
            tipAsc={I18n.t('Click to sort by name descending')}
          />
          <UserListHeader
            id="email"
            label={I18n.t('Email')}
            tipDesc={I18n.t('Click to sort by email ascending')}
            tipAsc={I18n.t('Click to sort by email descending')}
          />
          <UserListHeader
            id="sis_id"
            label={I18n.t('SIS ID')}
            tipDesc={I18n.t('Click to sort by SIS ID ascending')}
            tipAsc={I18n.t('Click to sort by SIS ID descending')}
          />
          <UserListHeader
            id="last_login"
            label={I18n.t('Last Login')}
            tipDesc={I18n.t('Click to sort by last login ascending')}
            tipAsc={I18n.t('Click to sort by last login descending')}
          />
          <th width="1" scope="col">
            <ScreenReaderContent>{I18n.t('User option links')}</ScreenReaderContent>
          </th>
        </tr>
      </thead>
      <tbody data-automation="users list">
        {props.users.map(user =>
          <UsersListRow
            handlers={props.handlers}
            key={user.id}
            accountId={props.accountId}
            user={user}
            permissions={props.permissions}
          />
        )}
      </tbody>
    </Table>
  )
}

UsersList.propTypes = {
  accountId: string.isRequired,
  users: arrayOf(object).isRequired,
  permissions: object.isRequired,
  handlers: object.isRequired,
  userList: object.isRequired,
  onUpdateFilters: func.isRequired,
  onApplyFilters: func.isRequired
}
