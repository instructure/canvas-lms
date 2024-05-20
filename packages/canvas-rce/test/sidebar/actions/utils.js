/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {createStore, applyMiddleware} from 'redux'
import {thunk} from 'redux-thunk'
import {batch, batching} from 'redux-batch-middleware'
import sinon from 'sinon'

// creates a reducer that just alerts a spy on each action and leaves state
// alone. the associated spy is hung off the returned reducer
export function spiedReducer() {
  const spy = sinon.spy()
  const reducer = (state = {}, action) => {
    if (action.type !== '@@redux/INIT') {
      spy(action)
    }
    return state
  }
  reducer.spy = spy
  return reducer
}

// creates a store with the given state and with a spiedReducer; the spy from
// the reducer is also hung off the returned store
export function spiedStore(state) {
  const reducer = spiedReducer()
  const store = createStore(batching(reducer), state, applyMiddleware(thunk, batch))
  store.spy = reducer.spy
  return store
}
