// @ts-nocheck
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

import Backbone from './index'

export type CanvasStore<A> = {
  setState(newState: Partial<A>): void
  getState(): A
  clearState(): void
  addChangeListener(listener: () => void)

  removeChangeListener(listener: () => void)

  emitChange(): void
}

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
function createStore<A extends {}>(initialState: A): CanvasStore<A> {
  const events = {...Backbone.Events}
  let state: A = initialState || {}

  return {
    setState(newState) {
      Object.assign(state, newState)
      this.emitChange()
    },

    getState(): A {
      return state
    },

    clearState() {
      state = {}
      this.emitChange()
    },

    addChangeListener(listener) {
      events.on('change', listener)
    },

    removeChangeListener(listener) {
      events.off('change', listener)
    },

    emitChange() {
      events.trigger('change')
    },
  }
}

export default createStore
