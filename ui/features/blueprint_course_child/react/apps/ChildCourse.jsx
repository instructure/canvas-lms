/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {ConnectedChildContent as ChildContent} from '../components/ChildContent'
import FlashNotifications from '@canvas/blueprint-courses/react/flashNotifications'
import createStore from '@canvas/blueprint-courses/react/store'
import Router from '@canvas/blueprint-courses/react/router'

export default class ChildCourse {
  constructor(root, data) {
    this.root = root
    this.store = createStore(data)
    this.router = new Router()
  }

  routes = [
    {
      path: Router.PATHS.singleMigration,
      onEnter: ({params}) => this.app.showChangeLog(params),
      onExit: () => this.app.hideChangeLog(),
    },
  ]

  setupRouter() {
    this.router.registerRoutes(this.routes)
    this.router.start()
  }

  unmount() {
    ReactDOM.unmountComponentAtNode(this.root)
    this.router.stop()
  }

  render() {
    const routeTo = isBlueprintShabang() ? this.router.page : noop
    ReactDOM.render(
      <Provider store={this.store}>
        <ChildContent
          routeTo={routeTo}
          realRef={c => {
            this.app = c
          }}
        />
      </Provider>,
      this.root
    )
  }

  start() {
    FlashNotifications.subscribe(this.store)
    this.render()
    if (isBlueprintShabang()) {
      this.setupRouter()
    }
  }
}

function noop() {}

function isBlueprintShabang() {
  return window.location.hash.indexOf('#!/blueprint') === 0
}
