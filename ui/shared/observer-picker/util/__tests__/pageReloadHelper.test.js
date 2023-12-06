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

import {getHandleChangeObservedUser, autoFocusObserverPicker} from '../pageReloadHelper'

describe('getHandleChangeObservedUser', () => {
  it('returns a function', () => {
    expect(typeof getHandleChangeObservedUser()).toBe('function')
  })

  describe('returned function', () => {
    let oldLocation
    let oldSessionStorage
    let mockReload
    let handleChangeObservedUser

    beforeEach(() => {
      oldSessionStorage = window.sessionStorage
      oldLocation = window.location
      delete window.location
      mockReload = jest.fn()
      window.location = {reload: mockReload}

      handleChangeObservedUser = getHandleChangeObservedUser()
    })

    afterEach(() => {
      window.location = oldLocation
      window.sessionStorage = oldSessionStorage
    })

    it('does not trigger reload on initial call', () => {
      handleChangeObservedUser('initialValue')
      expect(mockReload).not.toHaveBeenCalled()
    })

    it('triggers reload when observed user changes', () => {
      handleChangeObservedUser('initialValue')
      handleChangeObservedUser('newValue')
      expect(mockReload).toHaveBeenCalled()
    })

    it('stores auto focus setting in session storage', () => {
      handleChangeObservedUser('newValue')
      expect(window.sessionStorage.autoFocusObserverPicker).toBe('true')
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
