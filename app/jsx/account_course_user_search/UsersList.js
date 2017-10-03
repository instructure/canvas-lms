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
import Typography from 'instructure-ui/lib/components/Typography'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import Link from 'instructure-ui/lib/components/Link'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import UsersListRow from './UsersListRow'

const { string, object, func } = PropTypes

export default class UsersList extends React.Component {
  static propTypes = {
    accountId: string.isRequired,
    users: PropTypes.arrayOf(object).isRequired,
    timezones: object.isRequired,
    permissions: object.isRequired,
    handlers: object.isRequired,
    userList: object.isRequired,
    onUpdateFilters: func.isRequired,
    onApplyFilters: func.isRequired,
  }

  updateOrder = (column) => {

    let newOrder = 'asc'

    const sort = this.props.userList.searchFilter.sort
    const order = this.props.userList.searchFilter.order

    if ((column === sort && order === 'asc') || (!sort && column === 'username')) {
      newOrder = 'desc'
    }

    this.props.onUpdateFilters({
      search_term: this.props.userList.searchFilter.search_term,
      sort: column,
      order: newOrder,
      role_filter_id: this.props.userList.searchFilter.role_filter_id
    })
  }

  renderHeader ({id, label, tipDesc, tipAsc}) {
    const {sort, order} = this.props.userList.searchFilter
    return (
      <Tooltip
        as={Link}
        tip={(sort === id && order === 'asc') ? tipAsc : tipDesc}
        onClick={preventDefault(() => this.updateOrder(id))}
      >
        {label}
        {sort === id ?
          (order === 'asc' ? <IconMiniArrowDownSolid /> : <IconMiniArrowUpSolid />) :
          ''
        }
      </Tooltip>
    )
  }

  render () {
    const { users, timezones, accountId } = this.props
    return (
      <div className="content-box" role="grid">
        <div role="row" className="grid-row border border-b pad-box-mini">
          <div role="columnheader" className="col-xs-3">
            {this.renderHeader({
              id: 'username',
              label: I18n.t('Name'),
              tipDesc: I18n.t('Click to sort by name ascending'),
              tipAsc: I18n.t('Click to sort by name descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-3">
            {this.renderHeader({
              id: 'email',
              label: I18n.t('Email'),
              tipDesc: I18n.t('Click to sort by email ascending'),
              tipAsc: I18n.t('Click to sort by email descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-1">
            {this.renderHeader({
              id: 'sis_id',
              label: I18n.t('SIS ID'),
              tipDesc: I18n.t('Click to sort by SIS ID ascending'),
              tipAsc: I18n.t('Click to sort by SIS ID descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-2">
            {this.renderHeader({
              id: 'last_login',
              label: I18n.t('Last Login'),
              tipDesc: I18n.t('Click to sort by last login ascending'),
              tipAsc: I18n.t('Click to sort by last login descending')
            })}
          </div>
          <div role="columnheader" className="col-xs-2">
            <span className="screenreader-only">{I18n.t('User option links')}</span>
          </div>
        </div>
        <div className="users-list" role="rowgroup">
          {users.map(user =>
            <UsersListRow
              handlers={this.props.handlers}
              key={user.id}
              timezones={timezones}
              accountId={accountId}
              user={user}
              permissions={this.props.permissions}
            />
          )}
        </div>
      </div>
    )
  }
}
