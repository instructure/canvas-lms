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

import {createDynamicUiMiddleware as createMiddleware} from '../middleware'

function createManager() {
  return {
    setStore: jest.fn(),
    handleAction: jest.fn(),
    uiStateUnchanged: jest.fn(),
  }
}

function createStore() {
  return {
    getState: jest.fn(),
    dispatch: jest.fn(),
  }
}

it('registers the store with the manager', () => {
  const mockManager = createManager()
  createMiddleware(mockManager)('the store')
  expect(mockManager.setStore).toHaveBeenCalledWith('the store')
})

it('notifies manager of actions', () => {
  const mockManager = createManager()
  const mockAction = {some: 'action'}
  createMiddleware(mockManager)(createStore())(jest.fn())({some: 'action'})
  expect(mockManager.handleAction).toHaveBeenCalledWith(mockAction)
})

it('behaves as middleware', () => {
  const mockManager = createManager()
  const mockNext = jest.fn(() => 'next result')
  const result = createMiddleware(mockManager)(createStore())(mockNext)({some: 'action'})
  expect(result).toEqual('next result')
})

it('notifies the manager when the state is unchanged', () => {
  const mockManager = createManager()
  const mockStore = createStore()
  const theState = {}
  mockStore.getState.mockReturnValue(theState)
  const theAction = {type: 'an action'}
  createMiddleware(mockManager)(mockStore)(jest.fn())(theAction)
  expect(mockManager.uiStateUnchanged).toHaveBeenCalledWith(theAction)
})

it('does not notify the manager of unchanged state when the state has changed', () => {
  const mockManager = createManager()
  const mockStore = createStore()
  mockStore.getState.mockReturnValueOnce({state: 'first'}).mockReturnValueOnce({state: 'second'})
  createMiddleware(mockManager)(mockStore)(jest.fn())({some: 'action'})
  expect(mockManager.uiStateUnchanged).not.toHaveBeenCalled()
})

it('notifies the manager of the action before it is processed by the reducers', () => {
  const mockManager = createManager()
  const mockStore = createStore()
  const actionFailure = () => {
    throw new Error('foo')
  }
  expect(() => createMiddleware(mockManager)(mockStore)(actionFailure)({some: 'action'})).toThrow()
  expect(mockManager.handleAction).toHaveBeenCalled()
})
