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

import Backbone from '@canvas/backbone'

const BackboneState = {
  _forceUpdate() {
    this.forceUpdate()
  }, // strips off args that backbone sends and react incorrectly believes is a callback

  _on(object, name, callback, context) {
    object.on(name, callback, context)
  },

  _off(object, name, callback, context) {
    object.off(name, callback, context)
  },

  _listen(func, state, exceptState) {
    for (const stateKey in state) {
      if (state.hasOwnProperty(stateKey)) {
        if (
          !(
            exceptState &&
            exceptState.hasOwnProperty(stateKey) &&
            state[stateKey] === exceptState[stateKey]
          )
        ) {
          const stateObject = state[stateKey]
          if (stateObject instanceof Backbone.Collection) {
            func(
              stateObject,
              'add remove reset sort fetch beforeFetch change',
              this._forceUpdate,
              this
            )
          } else if (stateObject instanceof Backbone.Model) {
            func(stateObject, 'change', this._forceUpdate, this)
          }
        }
      }
    }
  },

  UNSAFE_componentWillUpdate(nextProps, nextState) {
    // stop listening to backbone objects in state that aren't in nextState
    this._listen(this._off, this.state, nextState)
  },

  componentDidUpdate(prevProps, prevState) {
    // start listening to backbone objects in state that aren't in prevState
    this._listen(this._on, this.state, prevState)
  },

  componentDidMount() {
    // start listening to backbone objects in state
    this._listen(this._on, this.state)
  },

  componentWillUnmount() {
    // stop listening to backbone objects in state
    this._listen(this._off, this.state)
  },
}
export default BackboneState
