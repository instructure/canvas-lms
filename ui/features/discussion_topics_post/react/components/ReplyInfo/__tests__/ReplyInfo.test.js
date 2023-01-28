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
import {ReplyInfo} from '../ReplyInfo'
import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = props => {
  return render(<ReplyInfo {...props} />)
}

describe('ReplyInfo', () => {
  describe('desktop', () => {
    it('renders the expanded reply info text', () => {
      const container = setup({replyCount: 24, unreadCount: 5})
      expect(container.getAllByText('24 Replies, 5 Unread').length).toBe(2)
    })

    it('omits the unread count if there are no unread replies', () => {
      const container = setup({replyCount: 24, unreadCount: 0})
      expect(container.getAllByText('24 Replies').length).toBe(2)
    })

    it('uses the singular tense of reply if there is only one reply', () => {
      const container = setup({replyCount: 1})
      expect(container.getAllByText('1 Reply').length).toBe(2)
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1024px'},
      }))
    })

    it('renders the condensed reply info text', () => {
      const container = setup({replyCount: 24, unreadCount: 5})
      expect(container.getByText('24 Replies (5)')).toBeInTheDocument()
      // Renders the full expanded text for screen readers
      expect(container.getByText('24 Replies, 5 Unread')).toBeInTheDocument()
    })

    it('omits the unread count if there are no unread replies', () => {
      const container = setup({replyCount: 24, unreadCount: 0})
      expect(container.getAllByText('24 Replies').length).toBe(2)
    })

    it('uses the singular tense of reply if there is only one reply', () => {
      const container = setup({replyCount: 1})
      expect(container.getAllByText('1 Reply').length).toBe(2)
    })
  })
})
