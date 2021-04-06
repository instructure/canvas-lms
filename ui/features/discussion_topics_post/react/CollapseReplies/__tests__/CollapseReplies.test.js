/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {CollapseReplies} from '../CollapseReplies'

const setup = props => {
  return render(<CollapseReplies onClick={Function.prototype} {...props} />)
}

describe('CollapseReplies', () => {
  it('calls provided callback when clicked', () => {
    const onClickMock = jest.fn()
    const {getByText} = setup({
      onClick: onClickMock
    })
    expect(onClickMock.mock.calls.length).toBe(0)
    fireEvent.click(getByText('Collapse replies'))
    expect(onClickMock.mock.calls.length).toBe(1)
  })

  describe('Button text', () => {
    it('indicates expansion status', () => {
      const {queryByText, rerender} = setup()
      rerender(<CollapseReplies onClick={Function.prototype} />)
      expect(queryByText('Collapse replies')).toBeTruthy()
    })
  })
})
