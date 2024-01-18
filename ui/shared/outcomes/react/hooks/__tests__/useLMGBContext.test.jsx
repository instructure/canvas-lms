/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {renderHook} from '@testing-library/react-hooks/dom'
import LMGBContext from '../../contexts/LMGBContext'
import useLMGBContext from '../useLMGBContext'

describe('useLMGBContext', () => {
  it('can return values if they are set', () => {
    const wrapper = ({children}) => (
      <LMGBContext.Provider
        value={{env: {accountLevelMasteryScalesFF: true, outcomesFriendlyDescriptionFF: true}}}
      >
        {children}
      </LMGBContext.Provider>
    )
    const {result} = renderHook(() => useLMGBContext(), {wrapper})
    expect(result.current.accountLevelMasteryScalesFF).toBe(true)
    expect(result.current.outcomesFriendlyDescriptionFF).toBe(true)
    expect(result.current.contextURL).toBe(undefined)
    expect(result.current.outcomeProficiency).toBe(undefined)
  })

  it('returns undefined if values are not set', () => {
    const wrapper = ({children}) => (
      <LMGBContext.Provider value={{}}>{children}</LMGBContext.Provider>
    )
    const {result} = renderHook(() => useLMGBContext(), {wrapper})
    expect(result.current.accountLevelMasteryScalesFF).toBe(undefined)
    expect(result.current.outcomesFriendlyDescriptionFF).toBe(undefined)
    expect(result.current.contextURL).toBe(undefined)
    expect(result.current.outcomeProficiency).toBe(undefined)
  })
})
