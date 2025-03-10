/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {render} from '@testing-library/react'
import {createStore, applyMiddleware} from 'redux'
import {Provider} from 'react-redux'
import {thunk} from 'redux-thunk'

import {DEFAULT_STORE_STATE} from './fixtures'
import type {StoreState} from '../types'
import reducers from '../reducers/reducers'

export const renderConnected = (
  component: React.ReactElement,
  preloadedState: StoreState = DEFAULT_STORE_STATE,
) => render(<Provider store={withMiddleware(reducers, preloadedState)}>{component}</Provider>)

// We need to use a middleware to mock async actions
const withMiddleware = (rootReducer: typeof reducers, initialState: StoreState) =>
  applyMiddleware(thunk)(createStore)(rootReducer, initialState)
