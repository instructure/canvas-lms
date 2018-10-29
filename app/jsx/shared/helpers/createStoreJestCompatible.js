/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

  /**
   * Creates a data store with some initial state.
   *
   * ```js
   * var UserStore = createStore({loaded: false, users: []});
   *
   * UserStore.load = function() {
   *   $.getJSON('/users', function(users) {
   *     UserStore.setState({loaded: true, users});
   *   });
   * };
   * ```
   *
   * Then in a component:
   *
   * ```js
   * var UsersView = React.createClass({
   *   getInitialState () {
   *     return UserStore.getState();
   *   },
   *
   *   componentDidMount () {
   *     UserStore.addChangeListener(this.handleStoreChange);
   *     UserStore.load();
   *   },
   *
   *   handleStoreChange () {
   *     this.setState(UserStore.getState());
   *   }
   * });
   * ```
   */

function createStore(initialState = {}) {
  let state = initialState
  const listeners = {}

  return {
    setState (newState) {
      state = Object.assign({}, state, newState)
      this.emitChange()
    },

    getState () {
      return state
    },

    clearState () {
      state = {}
      this.emitChange()
    },

    addChangeListener (listener) {
      listeners[listener] = listener
    },

    removeChangeListener (listener) {
      delete listeners[listener]
    },

    emitChange () {
      Object.values(listeners).forEach(listener => listener())
    }
  }
}

export default createStore
