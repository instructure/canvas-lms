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

import { combineReducers } from 'redux'
import _ from 'underscore'
import UserActions from '../actions/UserActions'
import parseLinkHeader from 'compiled/fn/parseLinkHeader'
import initialState from 'jsx/account_course_user_search/store/initialState'

  /**
   * Handles setting the editUserDialogOpen state
   * state - the redux state
   * action - the redux action
   * visibility - boolean that editUserDialogOpen should be set to.
   */
  function setEditUserDialogOpenState (state, action, visibility) {
    const userObject = _.find(state.users, (user) => {
      return user.id === action.payload.id;
    });

    const userIndex = state.users.indexOf(userObject);
    if (userIndex > -1) {
      state.users[userIndex].editUserDialogOpen = visibility;
    }
    return state;
  }

  const userListHandlers = {
    ADD_ERROR: (state, action) => {
      const errors = _.extend({}, state.errors);
      state.errors = _.extend(errors, action.error);
      return state;
    },
    ADD_TO_USERS: (state, action) => {
      if (action.payload.xhr) {
        const {next} = parseLinkHeader(action.payload.xhr);
        state.next = next;
      }

      const mappedEmailUsers = action.payload.users.map((user) => {
        if (user.email) {
          return user;
        } else {
          if (user.login_id) {
            user.email = user.login_id;
          }
          return user;
        }
      });
      state.users = state.users.concat(mappedEmailUsers);
      state.isLoading = false;
      return state;
    },
    GOT_USERS: (state, action) => {
      const { next } = parseLinkHeader(action.payload.xhr);
      state.users = action.payload.users;
      state.isLoading = false;
      state.next = next;
      return state;
    },
    GOT_USER_UPDATE: (state, action) => {
      const userObject = _.find(state.users, (user) => {
        return user.id === action.payload.id;
      });

      const userIndex = state.users.indexOf(userObject);
      if (userIndex > -1) {
        state.users[userIndex] = action.payload;
      }
      return state;
    },
    OPEN_EDIT_USER_DIALOG: (state, action) => {
      return setEditUserDialogOpenState(state, action, true);
    },
    CLOSE_EDIT_USER_DIALOG: (state, action) => {
      return setEditUserDialogOpenState(state, action, false);
    },
    UPDATE_SEARCH_FILTER: (state, action) => {
      state.searchFilter = _.extend({}, state.searchFilter, action.payload);
      state.errors = {
        search_term: ''
      };
      return state;
    },
    SEARCH_TERM_TOO_SHORT: (state, action) => {
      state.errors.search_term = action.errors.termTooShort;
      return state;
    },
    LOADING_USERS: (state, action) => {
      state.isLoading = true;
      return state;
    }

  };

  const userList = (state = initialState, action) => {
    if (userListHandlers[action.type]) {
      const newState = _.extend({}, state);
      return userListHandlers[action.type](newState, action);
    } else {
      return state;
    }
  };

  const tabListHandlers = {
    SELECT_TAB: (state, action) => {
      state.selected = action.payload.tabIndex;
      return state;
    }
  };

  const tabList = (state = initialState, action) => {
    if (tabListHandlers[action.type]) {
      const newState = _.extend({}, state);
      return tabListHandlers[action.type](newState, action);
    } else {
      return state;
    }
  };


export default combineReducers({
    userList,
    tabList
  });
