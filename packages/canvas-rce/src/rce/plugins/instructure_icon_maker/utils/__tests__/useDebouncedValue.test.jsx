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

import React from 'react'
import {renderHook, act} from '@testing-library/react-hooks/dom'

import useDebouncedValue from '../useDebouncedValue'

jest.mock('@instructure/debounce', () => ({
  debounce: callback => {
    return () => {
      callback()
    }
  },
}))

describe('useDebouncedValue()', () => {
  let currentValue, onChange

  const subject = () =>
    renderHook(({value, handler}) => useDebouncedValue(value, handler), {
      initialProps: {
        value: currentValue,
        handler: onChange,
      },
    })

  beforeEach(() => {
    currentValue = 'test'
    onChange = jest.fn()
  })

  it('sets the immediate value to the current value on first render', () => {
    const [immediateValue] = subject().result.current

    expect(immediateValue).toEqual(currentValue)
  })

  it('updates the immediate value when the current value changes', () => {
    const {result} = subject()
    const [, handleValueChange] = result.current

    act(() => handleValueChange({target: {value: 'a new value'}}))

    expect(result.current[0]).toEqual('a new value')
  })

  it('calls the onChange handler', () => {
    const {result} = subject()
    const [, handleValueChange] = result.current

    act(() => handleValueChange({target: {value: 'a new value'}}))

    expect(onChange).toHaveBeenCalled()
  })

  describe('when the initial value is falsey', () => {
    beforeEach(() => {
      currentValue = ''
    })

    describe('and the current value changes to be truthy', () => {
      let result

      beforeEach(() => {
        const testComponent = subject()

        testComponent.rerender({value: 'a truthy value', handler: onChange})

        result = testComponent.result
      })

      it('updates the immediate value', () => {
        expect(result.current[0]).toEqual('a truthy value')
      })
    })
  })
})
