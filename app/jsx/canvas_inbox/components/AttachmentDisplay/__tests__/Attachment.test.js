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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {Attachment} from '../Attachment'

const setup = props => {
  return render(
    <Attachment
      attachment={{id: '1', displayName: '1'}}
      onReplace={Function.prototype}
      onDelete={Function.prototype}
      {...props}
    />
  )
}

describe('Attachment', () => {
  it('calls onReplace on double click', () => {
    const onReplaceMock = jest.fn()
    const {getByTestId} = setup({onReplace: onReplaceMock})
    expect(onReplaceMock.mock.calls.length).toBe(0)
    fireEvent.dblClick(getByTestId('attachment'))
    fireEvent.change(getByTestId('replacement-input'))
    expect(onReplaceMock.mock.calls.length).toBe(1)
  })

  it('calls onDelete when clicking the remove button', () => {
    const onDeleteMock = jest.fn()
    const {getByTestId} = setup({onDelete: onDeleteMock})
    expect(onDeleteMock.mock.calls.length).toBe(0)
    fireEvent.mouseOver(getByTestId('attachment'))
    fireEvent.click(getByTestId('remove-button'))
    expect(onDeleteMock.mock.calls.length).toBe(1)
  })

  describe('attachment preview', () => {
    it('renders a paperclip', () => {
      const {getByTestId} = setup()
      expect(getByTestId('paperclip')).toBeTruthy()
    })

    describe('a thumbnail url is provided', () => {
      it('replaces the paperclip with the thumbnail', () => {
        const {getByAltText, queryByTestId} = setup({
          attachment: {
            id: '1',
            displayName: 'has thumbnail',
            thumbnailUrl: 'foo.bar/thumbnail'
          }
        })
        expect(queryByTestId('paperclip')).toBeFalsy()
        expect(getByAltText('has thumbnail')).toBeTruthy()
      })
    })
  })
})
