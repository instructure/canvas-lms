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
import {AttachmentDisplay} from '../AttachmentDisplay'

const setup = props => {
  return render(
    <AttachmentDisplay
      attachments={[
        {id: '1', displayName: '1'},
        {id: '2', displayName: '2'},
      ]}
      onReplaceItem={Function.prototype}
      onDeleteItem={Function.prototype}
      {...props}
    />
  )
}

describe('AttachmentDisplay', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  it('renders the attachments', () => {
    const {getAllByTestId} = setup()
    expect(getAllByTestId('attachment').length).toBe(2)
  })

  describe('replacing', () => {
    it('calls onReplaceItem with the appropriate attachment', () => {
      const onReplaceItemMock = jest.fn()
      const {getAllByTestId} = setup({onReplaceItem: onReplaceItemMock})
      const attachments = getAllByTestId('attachment')
      const replacementInputs = getAllByTestId('replacement-input')
      expect(onReplaceItemMock.mock.calls.length).toBe(0)

      // replace first attachment
      fireEvent.dblClick(attachments[0])
      fireEvent.change(replacementInputs[0])
      expect(onReplaceItemMock.mock.calls.length).toBe(1)
      expect(onReplaceItemMock.mock.calls[0][0]).toBe('1')

      // replace second attachment
      fireEvent.dblClick(attachments[1])
      fireEvent.change(replacementInputs[1])
      expect(onReplaceItemMock.mock.calls.length).toBe(2)
      expect(onReplaceItemMock.mock.calls[1][0]).toBe('2')
    })
  })

  describe('deleting', () => {
    it('calls onDeleteItem with the appropriate attachment', () => {
      const onDeleteItemMock = jest.fn()
      const {getByTestId, getAllByTestId} = setup({onDeleteItem: onDeleteItemMock})
      const attachments = getAllByTestId('attachment')
      expect(onDeleteItemMock.mock.calls.length).toBe(0)

      // delete first attachment
      fireEvent.mouseOver(attachments[0])
      fireEvent.click(getByTestId('remove-button'))
      expect(onDeleteItemMock.mock.calls.length).toBe(1)
      expect(onDeleteItemMock.mock.calls[0][0]).toBe('1')
      fireEvent.mouseOut(attachments[0])
      act(() => jest.advanceTimersByTime(1))

      // delete second attachment
      fireEvent.mouseOver(attachments[1])
      fireEvent.click(getByTestId('remove-button'))
      expect(onDeleteItemMock.mock.calls.length).toBe(2)
      expect(onDeleteItemMock.mock.calls[1][0]).toBe('2')
      fireEvent.mouseOut(attachments[1])
      act(() => jest.advanceTimersByTime(1))
    })
  })
})
