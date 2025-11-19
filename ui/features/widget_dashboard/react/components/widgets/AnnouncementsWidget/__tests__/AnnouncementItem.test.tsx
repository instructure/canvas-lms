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

import React from 'react'
import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import userEvent from '@testing-library/user-event'
import AnnouncementItem from '../AnnouncementItem'
import type {Announcement} from '../../../../types'

const mockAnnouncement: Announcement = {
  id: '1',
  title:
    'This is an Extremely Long Announcement Title That Should Be Truncated Because It Is Way Too Long',
  message: '<p>Test message</p>',
  posted_at: '2025-01-15T10:00:00Z',
  html_url: '/courses/1/discussion_topics/1',
  context_code: 'course_1',
  isRead: false,
  author: {
    _id: 'user1',
    name: 'Test Teacher',
    avatarUrl: 'https://example.com/avatar.jpg',
  },
  course: {
    id: '1',
    name: 'Test Course',
    courseCode: 'CS 101',
  },
}

const server = setupServer()

const setup = (announcement: Announcement = mockAnnouncement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <AnnouncementItem announcementItem={announcement} filter="unread" />
    </QueryClientProvider>,
  )
}

describe('AnnouncementItem', () => {
  beforeAll(() =>
    server.listen({
      onUnhandledRequest: 'bypass',
    }),
  )
  afterEach(() => {
    server.resetHandlers()
  })
  afterAll(() => server.close())

  it('renders avatar without squishing when title is long', () => {
    server.use(
      graphql.mutation('UpdateDiscussionReadState', () => {
        return HttpResponse.json({
          data: {
            updateDiscussionReadState: {
              discussionTopic: {
                _id: '1',
              },
            },
          },
        })
      }),
    )

    const {container} = setup()

    const announcementItem = screen.getByTestId('announcement-item-1')
    expect(announcementItem).toBeInTheDocument()

    const avatarImage = container.querySelector('img[src="https://example.com/avatar.jpg"]')
    expect(avatarImage).toBeInTheDocument()

    const avatarSpan = avatarImage?.closest('[name="Test Teacher"]')
    expect(avatarSpan).toBeInTheDocument()
    expect(avatarSpan).toHaveAttribute('shape', 'circle')

    expect(screen.getByText(/Sent by Test Teacher/)).toBeInTheDocument()
  })

  it('removes announcements cache when Read more link is clicked on unread announcement', async () => {
    const user = userEvent.setup()
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          gcTime: 0,
        },
      },
    })

    const removeQueriesSpy = jest.spyOn(queryClient, 'removeQueries')

    render(
      <QueryClientProvider client={queryClient}>
        <AnnouncementItem announcementItem={mockAnnouncement} filter="unread" />
      </QueryClientProvider>,
    )

    const readMoreLink = screen.getByText('Read more')
    await user.click(readMoreLink)

    expect(removeQueriesSpy).toHaveBeenCalledWith({
      predicate: expect.any(Function),
    })

    const call = removeQueriesSpy.mock.calls[0]?.[0]
    expect(call).toBeDefined()
    const predicate = call?.predicate
    expect(predicate).toBeDefined()

    const mockQuery = {
      queryKey: ['announcementsPaginated', 'user123'],
    } as any
    expect(predicate!(mockQuery)).toBe(true)

    removeQueriesSpy.mockRestore()
  })

  it('does not remove cache when Read more link is clicked on read announcement', async () => {
    const user = userEvent.setup()
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          gcTime: 0,
        },
      },
    })

    const removeQueriesSpy = jest.spyOn(queryClient, 'removeQueries')

    const readAnnouncement = {...mockAnnouncement, isRead: true}

    render(
      <QueryClientProvider client={queryClient}>
        <AnnouncementItem announcementItem={readAnnouncement} filter="all" />
      </QueryClientProvider>,
    )

    const readMoreLink = screen.getByText('Read more')
    await user.click(readMoreLink)

    expect(removeQueriesSpy).not.toHaveBeenCalled()

    removeQueriesSpy.mockRestore()
  })
})
