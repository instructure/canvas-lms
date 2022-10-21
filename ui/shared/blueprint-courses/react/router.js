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

import page from 'page'

export default class BlueprintRouter {
  static PATHS = {
    singleMigration: '/blueprint/:blueprintType/:templateId/:changeId',
  }

  static handleEnter(route) {
    return (ctx, next) => {
      route.onEnter(ctx)
      next()
    }
  }

  static handleExit(route) {
    return (ctx, next) => {
      route.onExit(ctx)
      next()
    }
  }

  constructor(pageInstance = page) {
    this.page = pageInstance
  }

  registerRoutes(routes) {
    routes.forEach(this.registerRoute)
  }

  registerRoute = route => {
    if (route.onEnter) {
      this.page(route.path, BlueprintRouter.handleEnter(route))
    }

    if (route.onExit) {
      this.page.exit(route.path, BlueprintRouter.handleExit(route))
    }
  }

  start() {
    this.page.base(window.location.pathname)
    this.page({hashbang: true})
  }

  stop() {
    // it's possible that we're not the only thing using page
    // page.stop()
  }
}
