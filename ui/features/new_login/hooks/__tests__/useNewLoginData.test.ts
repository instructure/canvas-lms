/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks'
import {useNewLoginData} from '../useNewLoginData'

const createMockContainer = (authProviders: string | null, loginHandleName: string | null) => {
  const container = document.createElement('div')
  container.id = 'new_login_data'
  if (authProviders !== null) {
    container.setAttribute('data-auth-providers', authProviders)
  }
  if (loginHandleName !== null) {
    container.setAttribute('data-login-handle-name', loginHandleName)
  }
  document.body.appendChild(container)
}

describe('useNewLoginData', () => {
  afterEach(() => {
    const container = document.getElementById('new_login_data')
    if (container) {
      container.remove()
    }
  })

  it('mounts without crashing', () => {
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current).toBeDefined()
  })

  it('returns default values when container is not present', () => {
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toEqual([])
    expect(result.current.loginHandleName).toBe('')
  })

  it('returns parsed values from the container when present', () => {
    createMockContainer(
      JSON.stringify([{id: '1', name: 'Google', auth_type: 'google'}]),
      'Username'
    )
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toEqual([{id: '1', name: 'Google', auth_type: 'google'}])
    expect(result.current.loginHandleName).toBe('Username')
  })

  it('returns default login handle name when data-login-handle-name attribute is missing', () => {
    createMockContainer(JSON.stringify([{id: '1', name: 'Google', auth_type: 'google'}]), null)
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toEqual([{id: '1', name: 'Google', auth_type: 'google'}])
    expect(result.current.loginHandleName).toBe('Email')
  })

  it('handles empty data-auth-providers attribute', () => {
    createMockContainer('', 'Email')
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toEqual([])
    expect(result.current.loginHandleName).toBe('Email')
  })
})
