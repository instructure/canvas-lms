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

import { createStore, applyMiddleware } from 'redux'
import ReduxThunk from 'redux-thunk'
import rootReducer from './rootReducer'

export default function configStore (initialState) {
  const middleware = [
    ReduxThunk,

    // this is so redux-logger is not included in the production webpack bundle
    (process.env.NODE_ENV !== 'production') && require('redux-logger')() // eslint-disable-line global-require
  ].filter(Boolean)
  return applyMiddleware(...middleware)(createStore)(rootReducer, initialState)
}
