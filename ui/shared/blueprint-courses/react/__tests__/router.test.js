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

import Router from '../router'
import sinon from 'sinon'

describe('Blueprint router', () => {
  test('registerRoutes calls registerRoute for each item', () => {
    const router = new Router()
    const registerSpy = sinon.stub(router, 'registerRoute')
    router.registerRoutes([{}, {}])
    expect(registerSpy.callCount).toEqual(2)
  })

  test('registerRoutes registers route onEnter and onExit handlers for each route', () => {
    const pageSpy = sinon.spy()
    pageSpy.exit = sinon.spy()

    const router = new Router(pageSpy)
    router.registerRoutes([
      {onEnter: () => {}, onExit: () => {}},
      {onEnter: () => {}, onExit: () => {}},
    ])
    expect(pageSpy.exit.callCount).toEqual(2)
    expect(pageSpy.callCount).toEqual(2)
  })

  test('registerRoute does not register route onEnter and onExit handlers if not provided', () => {
    const pageSpy = sinon.spy()
    pageSpy.exit = sinon.spy()

    const router = new Router(pageSpy)
    router.registerRoute({onEnter: null, onExit: null})
    expect(pageSpy.callCount).toEqual(0)
    expect(pageSpy.exit.callCount).toEqual(0)
  })

  test('registerRoute registers route onEnter and onExit handlers if provided', () => {
    const pageSpy = sinon.spy()
    pageSpy.exit = sinon.spy()

    const router = new Router(pageSpy)
    router.registerRoute({onEnter: () => {}, onExit: () => {}})
    expect(pageSpy.callCount).toEqual(1)
    expect(pageSpy.exit.callCount).toEqual(1)
  })

  test('start sets base and starts pagejs', () => {
    const pageSpy = sinon.spy()
    pageSpy.base = sinon.spy()

    const router = new Router(pageSpy)
    router.start()
    expect(pageSpy.callCount).toEqual(1)
    expect(pageSpy.base.callCount).toEqual(1)
  })

  test('handleEnter returns a function that calls enter handler and next', () => {
    const ctx = {params: {id: '5'}}
    const nextSpy = sinon.spy()
    const route = {
      onEnter: sinon.spy(),
    }

    const handler = Router.handleEnter(route)
    handler(ctx, nextSpy)

    expect(route.onEnter.callCount).toEqual(1)
    expect(route.onEnter.firstCall.args).toEqual([ctx])
    expect(nextSpy.callCount).toEqual(1)
  })

  test('handleExit returns a function that calls exit handler and next', () => {
    const ctx = {params: {id: '5'}}
    const nextSpy = sinon.spy()
    const route = {
      onExit: sinon.spy(),
    }

    const handler = Router.handleExit(route)
    handler(ctx, nextSpy)

    expect(route.onExit.callCount).toEqual(1)
    expect(route.onExit.firstCall.args).toEqual([ctx])
    expect(nextSpy.callCount).toEqual(1)
  })
})
