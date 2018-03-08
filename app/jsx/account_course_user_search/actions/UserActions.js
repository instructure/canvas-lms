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

import I18n from 'i18n!user_actions'
import UsersStore from '../store/UsersStore'

export default {
  gotUserList(users, xhr) {
    return {
      type: 'GOT_USERS',
      payload: {
        users,
        xhr
      }
    }
  },

  gotUserUpdate(user) {
    return {
      type: 'GOT_USER_UPDATE',
      payload: user
    }
  },

  updateSearchFilter(filter) {
    return {
      type: 'UPDATE_SEARCH_FILTER',
      payload: filter
    }
  },

  displaySearchTermTooShortError(minSearchLength) {
    return {
      type: 'SEARCH_TERM_TOO_SHORT',
      errors: {
        termTooShort: I18n.t('Search term must be at least %{num} characters', {
          num: minSearchLength
        })
      }
    }
  },

  loadingUsers() {
    return {
      type: 'LOADING_USERS'
    }
  },

  applySearchFilter(minSearchLength, store = UsersStore) {
    return (dispatch, getState) => {
      const searchFilter = getState().userList.searchFilter

      if (
        !searchFilter ||
        searchFilter.search_term.length >= minSearchLength ||
        searchFilter.search_term === ''
      ) {
        dispatch(this.loadingUsers())
        store.load(searchFilter).then((response, _, xhr) => {
          dispatch(this.gotUserList(response, xhr))
        })
      } else {
        dispatch(this.displaySearchTermTooShortError(minSearchLength))
      }
    }
  }
}
