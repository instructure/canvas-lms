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

import tabList from './tabList'

  const initialState = {
    userList: {
      users: [],
      isLoading: true,
      errors: {search_term: ''},
      next: undefined,
      searchFilter: {search_term: ''},
      timezones: window.ENV.TIMEZONES,
      permissions: window.ENV.PERMISSIONS,
      accountId: window.ENV.ACCOUNT_ID
    },
    tabList: {
      basePath: '',
      tabs: tabList,
      selected: 0
    }
  };

export default initialState
