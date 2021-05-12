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

import {render} from '@testing-library/react'
import React from 'react'
import {PostMessage} from '../PostMessage'

const setup = props => {
  return render(
    <PostMessage
      authorName="Foo Bar"
      timingDisplay="Jan 1 2000"
      message="Posts are fun"
      {...props}
    />
  )
}

describe('PostMessage', () => {
  it('displays the message', () => {
    const {queryByText} = setup()
    expect(queryByText('Posts are fun')).toBeTruthy()
  })

  it('displays the children', () => {
    const {queryByText} = setup({
      children: <span>Smol children</span>
    })
    expect(queryByText('Smol children')).toBeTruthy()
  })

  describe('avatar badge', () => {
    it('displays when isUnread is true', () => {
      const {queryByText, rerender} = setup()
      expect(queryByText('Unread post')).toBeFalsy()
      rerender(<PostMessage authorName="foo" timingDisplay="foo" message="foo" isUnread />)
      expect(queryByText('Unread post')).toBeTruthy()
    })
  })

  describe('post header', () => {
    it('renders the correct post info', () => {
      const {queryByText, queryByTestId} = setup({
        authorName: 'Author Name',
        timingDisplay: 'Timing Display',
        lastReplyAtDisplayText: 'Apr 12 2:35pm'
      })
      expect(queryByText('Author Name')).toBeTruthy()
      expect(queryByText('Timing Display')).toBeTruthy()
      expect(queryByText(', last reply Apr 12 2:35pm')).toBeTruthy()
      expect(queryByTestId('post-pill')).toBeFalsy()
    })

    it('renders the correct pill if provided', () => {
      const {queryByText, queryByTestId} = setup({pillText: 'pill text'})
      expect(queryByTestId('post-pill')).toBeTruthy()
      expect(queryByText('pill text')).toBeTruthy()
    })
  })
})
