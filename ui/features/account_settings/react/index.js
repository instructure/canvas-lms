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

import React from 'react'
import {render} from 'react-dom'
import {Provider} from 'react-redux'
import {ConnectedSecurityPanel} from './components/SecurityPanel'
import {configStore, defaultState} from './store'

export function start(element, props = {}, state = defaultState) {
  const initialState = {...state}
  if (props.initialCspSettings) {
    initialState.cspEnabled = props.initialCspSettings.enabled
    initialState.cspInherited = props.initialCspSettings.inherited
  }
  const store = configStore(initialState, props.api)

  const config = {
    maxDomains: 50,
    accountId: window.ENV.ACCOUNT.id,
  }

  render(
    <Provider store={store}>
      <ConnectedSecurityPanel {...config} {...props} />
    </Provider>,
    element
  )
}
