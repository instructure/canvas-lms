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
import {render, rerender} from '@canvas/react'
import {Provider} from 'react-redux'

type Root = ReturnType<typeof render>

// TODO: we probably want this one eventually
// import { subscribeFlashNotifications } from '../shared/reduxNotifications'
import {ConnectedPermissionsIndex} from './components/PermissionsIndex'

import createStore from './store'
import TopNavPortal from '@canvas/top-navigation/react/TopNavPortal'

export default function createPermissionsIndex(root: HTMLElement, data = {}) {
  const store = createStore(data)
  let rootInstance: Root | null = null

  function unmount() {
    rootInstance?.unmount()
  }

  function renderPermissionsIndex() {
    const element = (
      <>
        <TopNavPortal />
        <Provider store={store}>
          <ConnectedPermissionsIndex />
        </Provider>
      </>
    )
    if (!rootInstance) rootInstance = render(element, root)
    else rerender(rootInstance, element)
  }

  // For some reason this is not working  TODO figure this out
  // subscribeFlashNotifications(store)

  return {unmount, render: renderPermissionsIndex}
}
