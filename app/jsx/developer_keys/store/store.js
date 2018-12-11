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

import {createStore, applyMiddleware, combineReducers} from 'redux'
import ReduxThunk from 'redux-thunk'
import listDeveloperKeysReducer from '../reducers/listDeveloperKeysReducer'
import deactivateDeveloperKeyReducer from '../reducers/deactivateReducer'
import activateDeveloperKeyReducer from '../reducers/activateReducer'
import deleteDeveloperKeyReducer from '../reducers/deleteReducer'
import createOrEditDeveloperKeyReducer from '../reducers/createOrEditReducer'
import makeVisibleDeveloperKeyReducer from '../reducers/makeVisibleReducer'
import makeInvisibleDeveloperKeyReducer from '../reducers/makeInvisibleReducer'
import listDeveloperKeyScopesReducer from '../reducers/listScopesReducer'
import createLtiKeyReducer from '../reducers/createLtiKeyReducer'

const middleware = [
  ReduxThunk,

  // this is so redux-logger is not included in the production webpack bundle
  (process.env.NODE_ENV !== 'production') && require('redux-logger').logger
].filter(Boolean)
const createStoreWithMiddleware = applyMiddleware(...middleware)(createStore)

const developerKeysReducer = combineReducers({
  listDeveloperKeys: listDeveloperKeysReducer,
  deactivateDeveloperKey: deactivateDeveloperKeyReducer,
  activateDeveloperKey: activateDeveloperKeyReducer,
  deleteDeveloperKey: deleteDeveloperKeyReducer,
  createOrEditDeveloperKey: createOrEditDeveloperKeyReducer,
  makeVisibleDeveloperKey: makeVisibleDeveloperKeyReducer,
  makeInvisibleDeveloperKey: makeInvisibleDeveloperKeyReducer,
  listDeveloperKeyScopes: listDeveloperKeyScopesReducer,
  createLtiKey: createLtiKeyReducer
})

export default createStoreWithMiddleware(developerKeysReducer)
