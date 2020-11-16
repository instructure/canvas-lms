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

import {render} from '@testing-library/react'
import React from 'react'
import {MessageListHolder} from '../MessageListHolder'

describe('MessageListHolder', () => {
  it('renders the provided conversations', () => {
    const props = {
      conversations: [
        {
          id: 1,
          workflowState: 'unread',
          conversation: {
            subject: 'This is the subject line',
            participants: [{name: 'Bob Barker'}, {name: 'Sally Ford'}, {name: 'Russel Franks'}],
            conversationMessages: [
              {
                author: {name: 'Bob Barker'},
                participants: [{name: 'Bob Barker'}, {name: 'Sally Ford'}, {name: 'Russel Franks'}],
                created_at: 'November 5, 2020 at 2:25pm',
                body: 'This is the body text for the message.'
              },
              {
                author: {name: 'Sally Ford'},
                participants: [{name: 'Sally Ford'}, {name: 'Bob Barker'}, {name: 'Russel Franks'}],
                created_at: 'November 4, 2020 at 2:25pm',
                body: 'This is the body text for the message.'
              }
            ]
          }
        },
        {
          id: 2,
          workflowState: 'read',
          conversation: {
            subject: 'This is a different subject line',
            participants: [{name: 'Todd Martin'}, {name: 'Jim Thompson'}],
            conversationMessages: [
              {
                author: {name: 'Todd Martin'},
                participants: [{name: 'Todd Martin'}, {name: 'Jim Thompson'}],
                created_at: 'November 3, 2020 at 8:58am',
                body:
                  'This conversation has a much longer body which should be too long to completely display.'
              }
            ]
          }
        },
        {
          id: 3,
          workflowState: 'unread',
          conversation: {
            subject: 'This is a different subject line',
            participants: [{name: 'Todd Martin'}, {name: 'Jim Thompson'}],
            conversationMessages: [
              {
                author: {name: 'Todd Martin'},
                participants: [{name: 'Todd Martin'}, {name: 'Jim Thompson'}],
                created_at: 'November 3, 2020 at 8:58am',
                body:
                  'This conversation has a much longer body which should be too long to completely display.'
              }
            ]
          }
        }
      ]
    }

    const {getAllByTestId} = render(<MessageListHolder {...props} />)
    const conversations = getAllByTestId('conversation')
    expect(conversations.length).toBe(3)
  })
})
