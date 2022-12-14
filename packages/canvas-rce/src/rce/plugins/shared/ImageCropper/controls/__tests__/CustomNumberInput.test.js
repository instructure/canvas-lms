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
import {fireEvent, render, waitFor} from '@testing-library/react'

import {CustomNumberInput} from '../CustomNumberInput'

describe('CustomNumberInput', () => {
  const timeout = 2000
  let onChangeFn

  beforeEach(() => (onChangeFn = jest.fn()))

  afterEach(() => jest.clearAllMocks())
  const subject = (otherSettings = {}) =>
    render(
      <CustomNumberInput
        value={0}
        onChange={onChangeFn}
        parseValueCallback={parseInt}
        processValueCallback={v => (v > 10 ? 10 : v)}
        formatValueCallback={v => `${v}%`}
        {...otherSettings}
      />
    )

  it('increment using up arrow', () => {
    const {container} = subject()
    const input = container.querySelector('label input[type="text"]')
    fireEvent.keyDown(input, {keyCode: 38})
    expect(onChangeFn).toHaveBeenCalledWith(1)
  })

  it('increment using down arrow', () => {
    const {container} = subject()
    const input = container.querySelector('label input[type="text"]')
    fireEvent.keyDown(input, {keyCode: 40})
    expect(onChangeFn).toHaveBeenCalledWith(-1)
  })

  describe('on blur', () => {
    it('calls parseValueCallback with correct value', () => {
      const callback = jest.fn()
      const {container} = subject({parseValueCallback: callback})
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '10'}})
      fireEvent.blur(input)
      expect(callback).toHaveBeenCalledWith('10')
    })

    it('sets processed & formatted value', async () => {
      const {container} = subject()
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '15'}})
      fireEvent.blur(input)
      expect(input.value).toEqual('10%')
    })

    it('calls onChange with processed value', async () => {
      const {container} = subject()
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '15'}})
      fireEvent.blur(input)
      expect(onChangeFn).toHaveBeenCalledWith(10)
    })

    it("doesn't show messages", async () => {
      const {container} = subject()
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '15'}})
      fireEvent.blur(input)
      const messageContainer = container.querySelector('label > span > span:last-child')
      expect(messageContainer.textContent).toEqual('')
    })

    it('shows error messages after parsing', async () => {
      const {container} = subject({parseValueCallback: () => null})
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: 'x'}})
      fireEvent.blur(input)
      const messageContainer = container.querySelector('label > span > span:last-child')
      expect(messageContainer.textContent).toEqual('Invalid entry.')
    })
  })

  describe('on debounce', () => {
    it('calls parseValueCallback with correct value', async () => {
      const callback = jest.fn()
      const {container} = subject({parseValueCallback: callback})
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '10'}})
      await waitFor(
        () => {
          expect(callback).toHaveBeenCalledWith('10')
        },
        {timeout}
      )
    })

    it('sets processed & formatted value', async () => {
      const {container} = subject()
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '15'}})
      await waitFor(
        () => {
          expect(input.value).toEqual('10%')
        },
        {timeout}
      )
    })

    it('calls onChange with processed value', async () => {
      const {container} = subject()
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '15'}})
      await waitFor(
        () => {
          expect(onChangeFn).toHaveBeenCalledWith(10)
        },
        {timeout}
      )
    })

    it("doesn't show messages", async () => {
      const {container} = subject()
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '15'}})
      await waitFor(() => {
        const messageContainer = container.querySelector('label > span > span:last-child')
        expect(messageContainer.textContent).toEqual('')
      })
    })

    it('shows error messages after parsing', async () => {
      const {container} = subject({parseValueCallback: () => null})
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: 'x'}})
      await waitFor(
        () => {
          const messageContainer = container.querySelector('label > span > span:last-child')
          expect(messageContainer.textContent).toEqual('Invalid entry.')
        },
        {timeout}
      )
    })
  })
})
