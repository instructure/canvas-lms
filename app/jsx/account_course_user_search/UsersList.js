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
import IconArrowUpSolid from 'instructure-icons/lib/Solid/IconArrowUpSolid'
import IconArrowDownSolid from 'instructure-icons/lib/Solid/IconArrowDownSolid'
import Typography from 'instructure-ui/lib/components/Typography'
import Tooltip from 'instructure-ui/lib/components/Tooltip'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import UsersListRow from './UsersListRow'

const { string, object, func } = PropTypes

class UsersList extends React.Component {
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
    this.props.onApplyFilters()
  }

  render () {
    const { users, timezones, accountId } = this.props;

    const sort = this.props.userList.searchFilter.sort
    const order = this.props.userList.searchFilter.order

    const nameLabel = I18n.t('Name')
    const lastLoginLabel = I18n.t('Last Login')
    const emailLabel = I18n.t('Email')
    const idLabel = I18n.t('SIS ID')

    let nameTip
    let lastLoginTip
    let emailTip
    let idTip

    let nameArrow = ''
    let lastLoginArrow = ''
    let emailArrow = ''
    let idArrow = ''

    if (sort === 'username' || !sort) {
      emailTip = I18n.t('Click to order by email ascending')
      lastLoginTip = I18n.t('Click to order by last login ascending')
      idTip = I18n.t('Click to order by SIS ID ascending')
      if (order === 'asc' || !order) {
        nameTip = I18n.t('Click to sort by name descending')
        nameArrow = <IconArrowDownSolid />
      } else {
        nameTip = I18n.t('Click to sort by name ascending')
        nameArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'last_login') {
      nameTip = I18n.t('Click to sort by name ascending')
      emailTip = I18n.t('Click to order by email ascending')
      idTip = I18n.t('Click to order by SIS ID ascending')
      if (order === 'asc' || !order) {
        lastLoginTip = I18n.t('Click to sort by last login descending')
        lastLoginArrow = <IconArrowDownSolid />
      } else {
        lastLoginTip = I18n.t('Click to sort by last login ascending')
        lastLoginArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'email') {
      nameTip = I18n.t('Click to sort by name ascending')
      idTip = I18n.t('Click to order by SIS ID ascending')
      lastLoginTip = I18n.t('Click to order by last login ascending')
      if (order === 'asc' || !order) {
        emailTip = I18n.t('Click to sort by email descending')
        emailArrow = <IconArrowDownSolid />
      } else {
        emailTip = I18n.t('Click to sort by email ascending')
        emailArrow = <IconArrowUpSolid />
      }
    } else if (sort === 'sis_id') {
      nameTip = I18n.t('Click to sort by name ascending')
      emailTip = I18n.t('Click to order by email ascending')
      lastLoginTip = I18n.t('Click to order by last login ascending')
      if (order === 'asc' || !order) {
        idTip = I18n.t('Click to sort by SIS ID descending')
        idArrow = <IconArrowDownSolid />
      } else {
        idTip = I18n.t('Click to sort by SIS ID ascending')
        idArrow = <IconArrowUpSolid />
      }
    }

    return (
      <div className="content-box" role="grid">
        <div role="row" className="grid-row border border-b pad-box-mini">
          <div role="columnheader" className="col-xs-3">
            <a
              role="button"
              href="#"
              className="courses-user-list-header"
              onClick={preventDefault(() => this.updateOrder('username'))}
            >
              <Tooltip as={Typography} tip={nameTip}>
                {nameLabel}
                {nameArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-3">
            <a
              role="button"
              href="#"
              className="courses-user-list-header"
              onClick={preventDefault(() => this.updateOrder('email'))}
            >
              <Tooltip as={Typography} tip={emailTip}>
                {emailLabel}
                {emailArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-1">
            <a
              role="button"
              href="#"
              className="courses-user-list-header"
              onClick={preventDefault(() => this.updateOrder('sis_id'))}
            >
              <Tooltip as={Typography} tip={idTip}>
                {idLabel}
                {idArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-2">
            <a
              role="button"
              href="#"
              className="courses-user-list-header"
              onClick={preventDefault(() => this.updateOrder('last_login'))}
            >
              <Tooltip as={Typography} tip={lastLoginTip}>
                {lastLoginLabel}
                {lastLoginArrow}
              </Tooltip>
            </a>
          </div>
          <div role="columnheader" className="col-xs-2">
            <span className="screenreader-only">{I18n.t('User option links')}</span>
          </div>
        </div>
        <div className="users-list" role="rowgroup">
          {
              users.map(user => (
                <UsersListRow
                  handlers={this.props.handlers}
                  key={user.id}
                  timezones={timezones}
                  accountId={accountId}
                  user={user}
                  permissions={this.props.permissions}
                />
                ))
            }
        </div>
      </div>
    )
  }
  }

export default UsersList
