/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {render, act, fireEvent} from '@testing-library/react'
import React from 'react'
import {RemovableItem} from '../RemovableItem'

const setup = props => {
  return render(
    <RemovableItem
      onRemove={Function.prototype}
      screenReaderLabel="removable"
      childrenAriaLabel="item"
      {...props}
    >
      <div />
    </RemovableItem>
  )
}

describe('RemovableItem', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  it('renders remove icon while hovered', () => {
    const {getByTestId, queryByTestId} = setup()
    const item = getByTestId('removable-item')
    expect(queryByTestId('remove-button')).toBeFalsy()
    fireEvent.mouseOver(item)
    expect(getByTestId('remove-button')).toBeTruthy()
    fireEvent.mouseOut(item)
    act(() => jest.advanceTimersByTime(1))
    expect(queryByTestId('remove-button')).toBeFalsy()
  })

  it('renders remove icon while focused', () => {
    const {getByTestId, queryByTestId} = setup()
    const item = getByTestId('removable-item')
    expect(queryByTestId('remove-button')).toBeFalsy()
    fireEvent.focus(item)
    expect(getByTestId('remove-button')).toBeTruthy()
    fireEvent.blur(item)
    act(() => jest.advanceTimersByTime(1))
    expect(queryByTestId('remove-button')).toBeFalsy()
  })

  it('calls onRemove when clicked', () => {
    const onRemoveMock = jest.fn()
    const {getByTestId} = setup({onRemove: onRemoveMock})
    const item = getByTestId('removable-item')
    fireEvent.mouseOver(item)
    expect(onRemoveMock.mock.calls.length).toBe(0)
    fireEvent.click(getByTestId('remove-button'))
    expect(onRemoveMock.mock.calls.length).toBe(1)
  })
})
