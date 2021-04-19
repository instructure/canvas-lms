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
import rootReducer from '../reducers'
import initialState from './initialState'
import thunkMiddleware from 'redux-thunk'
import {batch, batching} from 'redux-batch-middleware'

export default function(props, state) {
  const store = createStore(
    batching(rootReducer),
    state || initialState(props),
    applyMiddleware(thunkMiddleware, batch)
  )

  // We want the links accordion tabs to be the same when the sidebar tray
  // is opened and closed, so we persist the index of the open accordion
  // to session storage.
  store.subscribe(() => {
    try {
      const accordionIndex = store.getState().ui.selectedAccordionIndex
      if (accordionIndex !== window.sessionStorage.getItem('canvas_rce_links_accordion_index')) {
        window.sessionStorage.setItem('canvas_rce_links_accordion_index', accordionIndex)
      }
    } catch (err) {
      // If there is an error accessing session storage, just ignore it.
      // We are likely in a test environment
    }
  })

  return store
}
