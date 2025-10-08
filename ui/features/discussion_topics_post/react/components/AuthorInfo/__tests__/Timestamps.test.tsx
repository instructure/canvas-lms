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

import {render} from '@testing-library/react'
import {Timestamps} from '../Timestamps'

const setup = (propsOverride = {}) => {
  const props = {
    timestampTextSize: 'small',
    ...propsOverride,
  }

  return render(<Timestamps {...props} />)
}

describe('Timestamps', () => {
  it('should render correctly', () => {
    const container = setup()

    expect(container).toBeTruthy()
  })

  describe('pinned post container', () => {
    const pinnedProps = {
      entry: {},
      container: 'pinned',
    }

    it('should render replies child node', () => {
      const {getByText} = setup({
        ...pinnedProps,
        replyNode: <span>2 Replies, 1 Unread</span>,
      })

      expect(getByText('2 Replies, 1 Unread')).toBeInTheDocument()
    })
  })

  describe('other containers', () => {
    it('should not render replies child node', () => {
      const {queryByText} = setup({
        container: 'topic',
        replyNode: <span>2 Replies, 1 Unread</span>,
      })

      expect(queryByText('2 Replies, 1 Unread')).not.toBeInTheDocument()

      const {queryByText: queryByText2} = setup({
        container: 'reply',
        replyNode: <span>2 Replies, 1 Unread</span>,
      })

      expect(queryByText2('2 Replies, 1 Unread')).not.toBeInTheDocument()

      const {queryByText: queryByText3} = setup({
        replyNode: <span>2 Replies, 1 Unread</span>,
      })
      expect(queryByText3('2 Replies, 1 Unread')).not.toBeInTheDocument()
    })
  })
})
