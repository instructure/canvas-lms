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
import type {Store} from 'redux'

import type CourseSidebar from '../components/CourseSidebar'
import {ConnectedCourseSidebar} from '../components/CourseSidebar'
import FlashNotifications from '@canvas/blueprint-courses/react/flashNotifications'
import createStore from '@canvas/blueprint-courses/react/store'
import Router from '@canvas/blueprint-courses/react/router'

interface RouteParams {
  params: Record<string, string>
}

interface Route {
  path: string
  onEnter: (params: RouteParams) => void
  onExit: () => void
}

export default class BlueprintCourse {
  root: Element
  store: Store
  router: Router
  app!: CourseSidebar
  routes: Route[]

  constructor(root: Element, data: unknown) {
    this.root = root
    this.store = createStore(data)
    this.router = new Router()
    this.routes = [
      {
        path: Router.PATHS.singleMigration,
        onEnter: ({params}) => this.app.showChangeLog(params),
        onExit: () => this.app.hideChangeLog(),
      },
    ]
  }

  setupRouter(): void {
    this.router.registerRoutes(this.routes)
    this.router.start()
  }

  unmount(): void {
    ReactDOM.unmountComponentAtNode(this.root)
  }

  render(): void {
    const routeTo = isBlueprintShabang() ? this.router.page : noop
    const sidebarProps = {
      routeTo,
      realRef: (c: CourseSidebar | null) => {
        if (c) {
          this.app = c
        }
      },
      contentRef: null,
    } as unknown as React.ComponentProps<typeof ConnectedCourseSidebar>

    ReactDOM.render(
      <Provider store={this.store}>
        <ConnectedCourseSidebar {...sidebarProps} />
      </Provider>,
      this.root,
    )
  }

  start(): void {
    FlashNotifications.subscribe(this.store)
    this.render()
    if (isBlueprintShabang()) {
      this.setupRouter()
    }
  }
}

function noop(): void {}

function isBlueprintShabang(): boolean {
  return window.location.hash.indexOf('#!/blueprint') === 0
}
