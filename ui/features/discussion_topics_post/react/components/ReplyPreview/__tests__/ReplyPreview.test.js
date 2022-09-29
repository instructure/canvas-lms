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

import React from 'react'
import {render} from '@testing-library/react'

import {ReplyPreview} from '../ReplyPreview'
import {AnonymousUser} from '../../../../graphql/AnonymousUser'

const mockProps = ({
  createdAt = '2021-08-10T12:10:38-06:00',
  previewMessage = 'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.',
  author = {
    shortName: 'Albus Dumbledore',
  },
  anonymousAuthor = null,
  editor = {
    shortName: 'Harry Potter',
  },
  deleted = false,
} = {}) => ({createdAt, previewMessage, author, anonymousAuthor, editor, deleted})

const setup = props => {
  return render(<ReplyPreview {...props} />)
}

describe('Reply Preview', () => {
  it('should render', () => {
    const container = setup(mockProps())
    expect(container).toBeTruthy()
  })

  it('author name renders', () => {
    const container = setup(mockProps())
    expect(container.getByText('Albus Dumbledore')).toBeTruthy()
  })

  it('created at timestamp renders', () => {
    const container = setup(mockProps())
    expect(container.getByText('Aug 10, 2021 6:10pm')).toBeTruthy()
  })

  it('message renders', () => {
    const container = setup(mockProps())
    expect(
      container.getByText(
        'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.'
      )
    ).toBeTruthy()
  })

  it('shows deleted message when deleted', () => {
    const container = setup(mockProps({deleted: true}))
    expect(container.getByText('Deleted by Harry Potter')).toBeTruthy()
  })

  it('shows deleted without by message when deleted', () => {
    const container = setup(mockProps({editor: null, deleted: true}))
    expect(container.getByText('Deleted')).toBeTruthy()
  })

  it('read more button should be visible when message length is greater than 170 characters', () => {
    const container = setup(
      mockProps({
        previewMessage:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras nec lectus neque. Sed eu molestie purus. Phasellus laoreet ante eget augue mollis sollicitudin. Quisque congue',
      })
    )
    expect(container.getByText('Read More')).toBeTruthy()
  })

  it('read more button should not be visible when message length is less than 170 characters', () => {
    const container = setup(
      mockProps({
        previewMessage:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras nec lectus neque. Sed eu molestie purus.',
      })
    )
    expect(container.queryByText('Read More')).toBeNull()
  })

  describe('anonymous author', () => {
    beforeAll(() => {
      window.ENV.discussion_anonymity_enabled = true
    })

    afterAll(() => {
      window.ENV.discussion_anonymity_enabled = false
    })

    it('renders name', () => {
      const container = setup(
        mockProps({author: null, editor: null, anonymousAuthor: AnonymousUser.mock()})
      )
      expect(container.getByText('Anonymous 1')).toBeTruthy()
    })
  })
})
