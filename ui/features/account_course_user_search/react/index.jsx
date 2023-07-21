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

import React from 'react'
import {string, bool, shape, func} from 'prop-types'
import {stringify} from 'qs'
import permissionFilter from './helpers/permissionFilter'
import CoursesStore from './store/CoursesStore'
import TermsStore from './store/TermsStore'
import AccountsTreeStore from './store/AccountsTreeStore'
import UsersStore from './store/UsersStore'
import useImmediate from '@canvas/use-immediate-hook'

const stores = [CoursesStore, TermsStore, AccountsTreeStore, UsersStore]

const AccountCourseUserSearch = props => {
  useImmediate(() => {
    const {accountId, rootAccountId} = props
    stores.forEach(s => {
      s.reset({accountId, rootAccountId})
    })
  }, [])

  function updateQueryParams(params) {
    const query = stringify(params)
    window.history.replaceState(null, null, `?${query}`)
  }

  const {tabList} = props.store.getState()
  const tabs = permissionFilter(tabList.tabs, props.permissions)
  const ActivePane = tabs.length === 1 ? tabs[0].pane : tabs[tabList.selected].pane

  return (
    <ActivePane
      {...props}
      onUpdateQueryParams={updateQueryParams}
      queryParams={tabList.queryParams}
    />
  )
}

AccountCourseUserSearch.propTypes = {
  accountId: string.isRequired,
  rootAccountId: string.isRequired,
  permissions: shape({
    analytics: bool.isRequired,
  }).isRequired,
  store: shape({
    getState: func.isRequired,
  }).isRequired,
}

export default AccountCourseUserSearch
