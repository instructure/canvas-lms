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

import Router from '@canvas/blueprint-courses/react/router'

QUnit.module('Blueprint router')

test('registerRoutes calls registerRoute for each item', () => {
  const router = new Router()
  const registerSpy = sinon.stub(router, 'registerRoute')
  router.registerRoutes([{}, {}])
  equal(registerSpy.callCount, 2)
})

test('registerRoutes registers route onEnter and onExit handlers for each route', () => {
  const pageSpy = sinon.spy()
  pageSpy.exit = sinon.spy()

  const router = new Router(pageSpy)
  router.registerRoutes([
    {onEnter: () => {}, onExit: () => {}},
    {onEnter: () => {}, onExit: () => {}},
  ])
  equal(pageSpy.callCount, 2)
  equal(pageSpy.exit.callCount, 2)
})

test('registerRoute does not register route onEnter and onExit handlers if not provided', () => {
  const pageSpy = sinon.spy()
  pageSpy.exit = sinon.spy()

  const router = new Router(pageSpy)
  router.registerRoute({onEnter: null, onExit: null})
  equal(pageSpy.callCount, 0)
  equal(pageSpy.exit.callCount, 0)
})

test('registerRoute registers route onEnter and onExit handlers if provided', () => {
  const pageSpy = sinon.spy()
  pageSpy.exit = sinon.spy()

  const router = new Router(pageSpy)
  router.registerRoute({onEnter: () => {}, onExit: () => {}})
  equal(pageSpy.callCount, 1)
  equal(pageSpy.exit.callCount, 1)
})

test('start sets base and starts pagejs', () => {
  const pageSpy = sinon.spy()
  pageSpy.base = sinon.spy()

  const router = new Router(pageSpy)
  router.start()
  equal(pageSpy.callCount, 1)
  equal(pageSpy.base.callCount, 1)
})

test('handleEnter returns a function that calls enter handler and next', () => {
  const ctx = {params: {id: '5'}}
  const nextSpy = sinon.spy()
  const route = {
    onEnter: sinon.spy(),
  }

  const handler = Router.handleEnter(route)
  handler(ctx, nextSpy)

  equal(route.onEnter.callCount, 1)
  deepEqual(route.onEnter.firstCall.args, [ctx])
  equal(nextSpy.callCount, 1)
})

test('handleExit returns a function that calls exit handler and next', () => {
  const ctx = {params: {id: '5'}}
  const nextSpy = sinon.spy()
  const route = {
    onExit: sinon.spy(),
  }

  const handler = Router.handleExit(route)
  handler(ctx, nextSpy)

  equal(route.onExit.callCount, 1)
  deepEqual(route.onExit.firstCall.args, [ctx])
  equal(nextSpy.callCount, 1)
})
