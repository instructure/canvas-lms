/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {thunk} from 'redux-thunk'
import ltiCollaboratorsReducer from './reducers/ltiCollaboratorsReducer'
import listCollaborationsReducer from './reducers/listCollaborationsReducer'
import deleteCollaborationReducer from './reducers/deleteCollaborationReducer'
import createCollaborationReducer from './reducers/createCollaborationReducer'
import updateCollaborationReducer from './reducers/updateCollaborationReducer'

const createStoreWithMiddleware = applyMiddleware(thunk)(createStore)

const collaboratorationsReducer = combineReducers({
  ltiCollaborators: ltiCollaboratorsReducer,
  listCollaborations: listCollaborationsReducer,
  deleteCollaboration: deleteCollaborationReducer,
  createCollaboration: createCollaborationReducer,
  updateCollaboration: updateCollaborationReducer,
})

export default createStoreWithMiddleware(collaboratorationsReducer)
