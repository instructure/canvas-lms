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
import {useLocation, useNavigate, useNavigationType} from 'react-router-dom'
import {useSafeBackNavigation} from '../useSafeBackNavigation'

jest.mock('react-router-dom', () => ({
  useNavigate: jest.fn(),
  useNavigationType: jest.fn(),
  useLocation: jest.fn(),
}))

const mockNavigate = jest.fn()
const mockedUseNavigate = useNavigate as jest.Mock
const mockedUseNavigationType = useNavigationType as jest.Mock
const mockedUseLocation = useLocation as jest.Mock

describe('useSafeBackNavigation', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockedUseNavigate.mockReturnValue(mockNavigate)
  })

  it('navigates back when navigationType is PUSH and location key is not "default"', () => {
    mockedUseNavigationType.mockReturnValue('PUSH')
    mockedUseLocation.mockReturnValue({key: 'abc123'})
    const {result} = renderHook(() => useSafeBackNavigation('/login/canvas'))
    // invoke the logic of handleCancel()
    result.current()
    expect(mockNavigate).toHaveBeenCalledWith(-1)
  })

  it('navigates to fallback when navigationType is not PUSH', () => {
    mockedUseNavigationType.mockReturnValue('POP')
    mockedUseLocation.mockReturnValue({key: 'abc123'})
    const {result} = renderHook(() => useSafeBackNavigation('/login/canvas'))
    result.current()
    expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
  })

  it('navigates to fallback when location key is "default"', () => {
    mockedUseNavigationType.mockReturnValue('PUSH')
    mockedUseLocation.mockReturnValue({key: 'default'})
    const {result} = renderHook(() => useSafeBackNavigation('/login/canvas'))
    result.current()
    expect(mockNavigate).toHaveBeenCalledWith('/login/canvas')
  })
})
