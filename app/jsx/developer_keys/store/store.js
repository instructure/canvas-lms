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

import { createStore, applyMiddleware, combineReducers } from 'redux'
import ReduxThunk from 'redux-thunk'
import listDeveloperKeysReducer from '../reducers/listDeveloperKeysReducer'
import deactivateDeveloperKeyReducer from '../reducers/deactivateDeveloperKeyReducer'
import activateDeveloperKeyReducer from '../reducers/activateDeveloperKeyReducer'
import deleteDeveloperKeyReducer from '../reducers/deleteDeveloperKeyReducer'
import createOrEditDeveloperKeyReducer from '../reducers/createOrEditDeveloperKeyReducer'
import makeVisibleDeveloperKeyReducer from '../reducers/makeVisibleDeveloperKeyReducer'
import makeInvisibleDeveloperKeyReducer from '../reducers/makeInvisibleDeveloperKeyReducer'

const createStoreWithMiddleware = applyMiddleware(
  ReduxThunk
)(createStore);

const developerKeysReducer = combineReducers({
  listDeveloperKeys: listDeveloperKeysReducer,
  deactivateDeveloperKey: deactivateDeveloperKeyReducer,
  activateDeveloperKey: activateDeveloperKeyReducer,
  deleteDeveloperKey: deleteDeveloperKeyReducer,
  createOrEditDeveloperKey: createOrEditDeveloperKeyReducer,
  makeVisibleDeveloperKey: makeVisibleDeveloperKeyReducer,
  makeInvisibleDeveloperKey: makeInvisibleDeveloperKeyReducer
});

export default createStoreWithMiddleware(developerKeysReducer)
