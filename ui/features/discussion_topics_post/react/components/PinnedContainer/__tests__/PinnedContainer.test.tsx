/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import {PinnedContainer} from '../PinnedContainer'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'

const setup = (props = {}) => {
  return render(
    <PinnedContainer
      entries={[]}
      topic={{
        isAnnouncement: false,
      }}
      breakpoints={{}}
      {...props}
    />,
  )
}

describe('PinnedContainer', () => {
  it('does not render without entries', () => {
    const {container} = setup()
    expect(container).toBeEmptyDOMElement()
  })

  it('renders the headers and entries', () => {
    const entries = [
      {
        ...DiscussionEntry.mock({
          _id: 'DiscussionEntry-pinned-mock',
          id: 'DiscussionEntry-pinned-mock',
          message: 'Pinned message',
        }),
      },
    ]

    const {getByText} = setup({
      entries,
    })

    expect(getByText('Pinned Replies')).toBeInTheDocument()
    expect(getByText('1 reply')).toBeInTheDocument()
    expect(getByText('Pinned message')).toBeInTheDocument()
  })

  it('closes by clicking on the header', () => {
    const entries = [
      {
        ...DiscussionEntry.mock({
          _id: 'DiscussionEntry-pinned-mock',
          id: 'DiscussionEntry-pinned-mock',
          message: 'Pinned message',
        }),
      },
      {
        ...DiscussionEntry.mock({
          _id: 'DiscussionEntry-pinned-mock-2',
          id: 'DiscussionEntry-pinned-mock-2',
          message: 'Pinned message 2',
        }),
      },
    ]

    const {getByText, queryByText} = setup({
      entries,
    })

    expect(getByText('Pinned Replies')).toBeInTheDocument()
    expect(getByText('2 replies')).toBeInTheDocument()
    expect(getByText('Pinned message')).toBeInTheDocument()

    fireEvent.click(getByText('Pinned Replies'))

    expect(queryByText('Pinned message')).not.toBeInTheDocument()
    expect(queryByText('Pinned message 2')).not.toBeInTheDocument()
  })
})
