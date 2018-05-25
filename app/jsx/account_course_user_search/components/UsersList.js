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

import Table from '@instructure/ui-core/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import React from 'react'
import {arrayOf, string, object, func} from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import UsersListRow from './UsersListRow'
import UsersListHeader from './UsersListHeader'


export default class UsersList extends React.Component {

  shouldComponentUpdate(nextProps) {
    let count = 0
    for (let prop in this.props) {
      ++count
      if (this.props[prop] !== nextProps[prop]) {
        // a change to searchFilter on it's own should not cause the list
        // to re-render
        if (prop !== 'searchFilter') {
          return true
        }
      }
    }
    return count !== Object.keys(nextProps).length
  }

  render() {
    return (
      <Table margin="small 0" caption={<ScreenReaderContent>{I18n.t('Users')}</ScreenReaderContent>}>
        <thead>
          <tr>
            <UsersListHeader
              id="username"
              label={I18n.t('Name')}
              tipDesc={I18n.t('Click to sort by name ascending')}
              tipAsc={I18n.t('Click to sort by name descending')}
              searchFilter={this.props.searchFilter}
              onUpdateFilters={this.props.onUpdateFilters}
            />
            <UsersListHeader
              id="email"
              label={I18n.t('Email')}
              tipDesc={I18n.t('Click to sort by email ascending')}
              tipAsc={I18n.t('Click to sort by email descending')}
              searchFilter={this.props.searchFilter}
              onUpdateFilters={this.props.onUpdateFilters}
            />
            <UsersListHeader
              id="sis_id"
              label={I18n.t('SIS ID')}
              tipDesc={I18n.t('Click to sort by SIS ID ascending')}
              tipAsc={I18n.t('Click to sort by SIS ID descending')}
              searchFilter={this.props.searchFilter}
              onUpdateFilters={this.props.onUpdateFilters}
            />
            <UsersListHeader
              id="last_login"
              label={I18n.t('Last Login')}
              tipDesc={I18n.t('Click to sort by last login ascending')}
              tipAsc={I18n.t('Click to sort by last login descending')}
              searchFilter={this.props.searchFilter}
              onUpdateFilters={this.props.onUpdateFilters}
            />
            <th width="1" scope="col">
              <ScreenReaderContent>{I18n.t('User option links')}</ScreenReaderContent>
            </th>
          </tr>
        </thead>
        <tbody data-automation="users list">
          {this.props.users.map(user =>
            <UsersListRow
              handleSubmitEditUserForm={this.props.handleSubmitEditUserForm}
              key={user.id}
              accountId={this.props.accountId}
              user={user}
              permissions={this.props.permissions}
            />
          )}
        </tbody>
      </Table>
    )
  }
}

UsersList.propTypes = {
  accountId: string.isRequired,
  users: arrayOf(object).isRequired,
  permissions: object.isRequired,
  handleSubmitEditUserForm: func.isRequired,
  searchFilter: object.isRequired,
  onUpdateFilters: func.isRequired
}
