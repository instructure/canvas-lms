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
import { Provider } from 'react-redux'
import page from 'page'

import { ConnectedChildContent as ChildContent } from '../components/ChildContent'
import createStore from '../store'

export default class ChildCourse {
  constructor (root, data) {
    this.root = root
    this.store = createStore(data)
  }

  routes = [
    {
      path: '/blueprint/migrations/:id',
      onEnter: (ctx, next) => {
        this.app.showChangeLog(ctx.params.id)
        next()
      },
      onExit: (ctx, next) => {
        this.app.hideChangeLog()
        next()
      },
    }
  ]

  setupRoutes () {
    this.routes.forEach((route) => {
      page(route.path, route.onEnter)
      page.exit(route.path, route.onExit)
    })

    page.base(location.pathname)
    page({ hashbang: true })
  }

  unmount () {
    ReactDOM.unmountComponentAtNode(this.root)
    page.stop()
  }

  render () {
    ReactDOM.render(
      <Provider store={this.store}>
        <ChildContent goTo={page} realRef={(c) => { this.app = c }} />
      </Provider>,
      this.root
    )
  }

  start () {
    this.render()
    this.setupRoutes()
  }
}
