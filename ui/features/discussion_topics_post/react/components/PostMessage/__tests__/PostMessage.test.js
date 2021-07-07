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
      hasAuthor
      authorName="Foo Bar"
      timingDisplay="Jan 1 2000"
      message="Posts are fun"
      title="Thoughts"
      {...props}
    />
  )
}

describe('PostMessage', () => {
  it('displays the title', () => {
    const {queryByText} = setup()
    expect(queryByText('Thoughts')).toBeTruthy()
  })

  it('displays the title h1', () => {
    const {queryByText} = setup()
    const screenReaderText = queryByText('Discussion Topic: Thoughts')

    expect(screenReaderText).toBeTruthy()
    expect(screenReaderText.parentElement.tagName).toBe('H1')
  })

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

  it('Should not display author name and avatar when author is null', () => {
    const {queryByTestId} = setup({hasAuthor: false})

    expect(queryByTestId('author_name')).toBeNull()
    expect(queryByTestId('author_avatar')).toBeNull()
  })

  it('Should display author name and avatar when author is set', () => {
    const {queryByTestId} = setup()

    expect(queryByTestId('author_name')).toBeTruthy()
    expect(queryByTestId('author_avatar')).toBeTruthy()
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
      expect(queryByTestId('pill-container')).toBeFalsy()
    })

    it('renders the correct pill if provided', () => {
      const {queryByText, queryByTestId} = setup({discussionRoles: ['Author']})
      expect(queryByTestId('pill-container')).toBeTruthy()
      expect(queryByText('Author')).toBeTruthy()
    })

    it('renders all default pills if provided', () => {
      const {queryByText, queryByTestId} = setup({
        discussionRoles: ['Author', 'TaEnrollment', 'TeacherEnrollment']
      })
      expect(queryByTestId('pill-container')).toBeTruthy()
      expect(queryByText('Author') && queryByText('Teacher') && queryByText('TA')).toBeTruthy()
    })
  })
})
