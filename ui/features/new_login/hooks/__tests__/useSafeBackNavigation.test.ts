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

import {assignLocation} from '@canvas/util/globalUtils'
import {renderHook} from '@testing-library/react-hooks'
import {useLocation, useNavigate, useNavigationType} from 'react-router-dom'
import {useSafeBackNavigation} from '../useSafeBackNavigation'
import {waitFor} from '@testing-library/react'
import {vi, type Mock} from 'vitest'

vi.mock('react-router-dom', () => ({
  useNavigate: vi.fn(),
  useNavigationType: vi.fn(),
  useLocation: vi.fn(),
}))

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

const mockNavigate = vi.fn()
const mockedUseNavigate = useNavigate as Mock
const mockedUseNavigationType = useNavigationType as Mock
const mockedUseLocation = useLocation as Mock

describe('useSafeBackNavigation', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedUseNavigate.mockReturnValue(mockNavigate)
  })

  it('navigates back when navigationType is PUSH and location key is not "default"', () => {
    mockedUseNavigationType.mockReturnValue('PUSH')
    mockedUseLocation.mockReturnValue({key: 'abc123'})
    const {result} = renderHook(() => useSafeBackNavigation())
    // invoke the logic of handleCancel()
    result.current()
    expect(mockNavigate).toHaveBeenCalledWith(-1)
  })

  it('navigates to fallback when navigationType is not PUSH', async () => {
    mockedUseNavigationType.mockReturnValue('POP')
    mockedUseLocation.mockReturnValue({key: 'abc123'})
    const {result} = renderHook(() => useSafeBackNavigation())
    result.current()
    await waitFor(() => {
      expect(assignLocation).toHaveBeenCalledWith('/login')
    })
  })

  it('navigates to fallback when location key is "default"', async () => {
    mockedUseNavigationType.mockReturnValue('PUSH')
    mockedUseLocation.mockReturnValue({key: 'default'})
    const {result} = renderHook(() => useSafeBackNavigation())
    result.current()
    await waitFor(() => {
      expect(assignLocation).toHaveBeenCalledWith('/login')
    })
  })
})
