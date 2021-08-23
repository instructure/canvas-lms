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

const mockProps = {
  authorName: 'Albus Dumbledore',
  createdAt: '2021-08-10T12:10:38-06:00',
  message:
    'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.'
}

const setup = props => {
  return render(<ReplyPreview {...props} />)
}

describe('Reply Preview', () => {
  it('should render', () => {
    const container = setup(mockProps)
    expect(container).toBeTruthy()
  })

  it('author name renders', () => {
    const container = setup(mockProps)
    expect(container.getByText('Albus Dumbledore')).toBeTruthy()
  })

  it('created at timestamp renders', () => {
    const container = setup(mockProps)
    expect(container.getByText('Aug 10 6:10pm')).toBeTruthy()
  })

  it('message renders', () => {
    const container = setup(mockProps)
    expect(
      container.getByText(
        'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.'
      )
    ).toBeTruthy()
  })
})
