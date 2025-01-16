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

describe('Blueprint router', () => {
  test('registerRoutes calls registerRoute for each item', () => {
    const router = new Router()
    const registerSpy = jest.spyOn(router, 'registerRoute')
    router.registerRoutes([{}, {}])
    expect(registerSpy.mock.calls).toHaveLength(2)
  })

  test('registerRoutes registers route onEnter and onExit handlers for each route', () => {
    const pageSpy = jest.fn()
    pageSpy.exit = jest.fn()

    const router = new Router(pageSpy)
    router.registerRoutes([
      {onEnter: () => {}, onExit: () => {}},
      {onEnter: () => {}, onExit: () => {}},
    ])
    expect(pageSpy.exit.mock.calls).toHaveLength(2)
    expect(pageSpy.mock.calls).toHaveLength(2)
  })

  test('registerRoute does not register route onEnter and onExit handlers if not provided', () => {
    const pageSpy = jest.fn()
    pageSpy.exit = jest.fn()

    const router = new Router(pageSpy)
    router.registerRoute({onEnter: null, onExit: null})
    expect(pageSpy.mock.calls).toHaveLength(0)
    expect(pageSpy.exit.mock.calls).toHaveLength(0)
  })

  test('registerRoute registers route onEnter and onExit handlers if provided', () => {
    const pageSpy = jest.fn()
    pageSpy.exit = jest.fn()

    const router = new Router(pageSpy)
    router.registerRoute({onEnter: () => {}, onExit: () => {}})
    expect(pageSpy.mock.calls).toHaveLength(1)
    expect(pageSpy.exit.mock.calls).toHaveLength(1)
  })

  test('start sets base and starts pagejs', () => {
    const pageSpy = jest.fn()
    pageSpy.base = jest.fn()

    const router = new Router(pageSpy)
    router.start()
    expect(pageSpy.mock.calls).toHaveLength(1)
    expect(pageSpy.base.mock.calls).toHaveLength(1)
  })

  test('handleEnter returns a function that calls enter handler and next', () => {
    const ctx = {params: {id: '5'}}
    const nextSpy = jest.fn()
    const route = {
      onEnter: jest.fn(),
    }

    const handler = Router.handleEnter(route)
    handler(ctx, nextSpy)

    expect(route.onEnter.mock.calls).toHaveLength(1)
    expect(route.onEnter.mock.calls[0]).toEqual([ctx])
    expect(nextSpy.mock.calls).toHaveLength(1)
  })

  test('handleExit returns a function that calls exit handler and next', () => {
    const ctx = {params: {id: '5'}}
    const nextSpy = jest.fn()
    const route = {
      onExit: jest.fn(),
    }

    const handler = Router.handleExit(route)
    handler(ctx, nextSpy)

    expect(route.onExit.mock.calls).toHaveLength(1)
    expect(route.onExit.mock.calls[0]).toEqual([ctx])
    expect(nextSpy.mock.calls).toHaveLength(1)
  })
})
