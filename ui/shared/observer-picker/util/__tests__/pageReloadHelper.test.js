// @vitest-environment jsdom
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {reloadWindow} from '@canvas/util/globalUtils'
import {autoFocusObserverPicker, getHandleChangeObservedUser} from '../pageReloadHelper'

// mock reloadWindow
jest.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: jest.fn(),
}))

describe('getHandleChangeObservedUser', () => {
  it('returns a function', () => {
    expect(typeof getHandleChangeObservedUser()).toBe('function')
  })

  describe('returned function', () => {
    let oldSessionStorage
    let handleChangeObservedUser

    beforeEach(() => {
      oldSessionStorage = window.sessionStorage
      delete window.location

      // Mock sessionStorage
      window.sessionStorage = {
        getItem: jest.fn(),
        setItem: jest.fn(),
        removeItem: jest.fn(),
      }

      handleChangeObservedUser = getHandleChangeObservedUser()
    })

    afterEach(() => {
      window.sessionStorage = oldSessionStorage
      jest.clearAllMocks()
    })

    it('does not trigger reload on initial call', () => {
      handleChangeObservedUser('initialValue')
      expect(reloadWindow).not.toHaveBeenCalled()
    })

    it('triggers reload when observed user changes', () => {
      handleChangeObservedUser('initialValue')
      handleChangeObservedUser('newValue')
      expect(reloadWindow).toHaveBeenCalled()
    })

    it('stores auto focus setting in session storage', () => {
      handleChangeObservedUser('initialValue')
      handleChangeObservedUser('newValue')
      expect(window.sessionStorage.setItem).toHaveBeenCalledWith('autoFocusObserverPicker', true)
    })
  })
})

describe('autoFocusObserverPicker', () => {
  let oldSessionStorage

  beforeEach(() => {
    oldSessionStorage = window.sessionStorage
  })

  afterEach(() => {
    window.sessionStorage = oldSessionStorage
  })

  it('returns false when value not present', () => {
    window.sessionStorage.removeItem('autoFocusObserverPicker')
    expect(autoFocusObserverPicker()).toBe(false)
  })

  it('returns true when value present and clears storage', () => {
    window.sessionStorage.setItem('autoFocusObserverPicker', true)
    expect(autoFocusObserverPicker()).toBe(true)
    expect(window.sessionStorage.getItem('autoFocusObserverPicker')).toBeNull()
  })
})
