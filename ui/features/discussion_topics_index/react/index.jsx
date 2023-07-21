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
import ReactDOM from 'react-dom'
import {Provider} from 'react-redux'

import {subscribeFlashNotifications} from '@canvas/notifications/redux/actions'
import {ConnectedDiscussionsIndex} from './components/DiscussionsIndex'
import createStore from './store'

export default function createDiscussionsIndex(root, data = {}) {
  const store = createStore(data)

  function unmount() {
    ReactDOM.unmountComponentAtNode(root)
  }

  function render() {
    ReactDOM.render(
      <Provider store={store}>
        <ConnectedDiscussionsIndex />
      </Provider>,
      root
    )
  }

  subscribeFlashNotifications(store)

  return {unmount, render}
}
