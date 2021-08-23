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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import {Discussion} from '../../graphql/Discussion'
import DiscussionTopicManager from '../DiscussionTopicManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {graphql} from 'msw'
import {handlers} from '../../graphql/mswHandlers'
import {mswClient} from '../../../../shared/msw/mswClient'
import {mswServer} from '../../../../shared/msw/mswServer'
import React from 'react'
import {responsiveQuerySizes} from '../utils'

jest.mock('@canvas/rce/RichContentEditor')
jest.mock('../utils/constants', () => ({
  ...jest.requireActual('../utils/constants'),
  HIGHLIGHT_TIMEOUT: 0
}))
jest.mock('../utils')

describe('DiscussionFullPage', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.ENV = {
      discussion_topic_id: '1',
      manual_mark_as_read: false,
      current_user: {
        id: 'PLACEHOLDER',
        display_name: 'Omar Soto-Fortuño',
        avatar_image_url: 'www.avatar.com'
      },
      course_id: '1'
    }

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    window.INST = {
      editorButtons: []
    }
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    mswClient.cache.reset()
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {maxWidth: '1000'}
    }))
  })

  afterEach(() => {
    server.resetHandlers()
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = () => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <DiscussionTopicManager discussionTopicId="1" />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  it('should render', () => {
    const {container} = setup()
    expect(container).toBeTruthy()
  })

  describe('discussion entries', () => {
    it.skip('should render', async () => {
      const container = setup()
      expect(await container.findByText('This is the parent reply')).toBeInTheDocument()
      expect(container.queryByText('This is the child reply')).toBeNull()

      const expandButton = container.getByTestId('expand-button')
      fireEvent.click(expandButton)

      expect(await container.findByText('This is the child reply')).toBeInTheDocument()
    })

    it.skip('should allow deleting entries', async () => {
      window.confirm = jest.fn(() => true)
      const container = setup()

      const actionsButton = await container.findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)

      const deleteButton = container.getByText('Delete')
      fireEvent.click(deleteButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(await container.findByText('Deleted by Hank Mccoy')).toBeInTheDocument()
    })

    it.skip('toggles an entries read state when the Mark as Read/Unread is clicked', async () => {
      const container = setup()
      const actionsButton = await container.findByTestId('thread-actions-menu')

      expect(container.queryByTestId('is-unread')).toBeNull()
      fireEvent.click(actionsButton)
      fireEvent.click(container.getByTestId('markAsUnread'))
      const unreadBadge = await container.findByTestId('is-unread')
      expect(unreadBadge).toBeInTheDocument()
      expect(unreadBadge.getAttribute('data-isforcedread')).toBe('true')

      fireEvent.click(actionsButton)
      fireEvent.click(container.getByTestId('markAsRead'))
      await waitFor(() => expect(container.queryByTestId('is-unread')).not.toBeInTheDocument())
    })

    it.skip('toggles an entries rating state when the like button is clicked', async () => {
      const container = setup()
      const likeButton = await container.findByTestId('like-button')

      expect(container.queryByText('Like count: 1')).toBeNull()
      fireEvent.click(likeButton)
      await waitFor(() => expect(container.queryByText('Like count: 1')).toBeTruthy())

      fireEvent.click(likeButton)
      await waitFor(() => expect(container.queryByText('Like count: 1')).toBeNull())
    })

    it('updates discussion entry', async () => {
      const {getByTestId, queryByText, findByTestId, getAllByTestId} = setup()
      await waitFor(() => expect(queryByText('This is the parent reply')).toBeInTheDocument())

      const actionsButton = await findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)
      fireEvent.click(getByTestId('edit'))

      await waitFor(() => {
        expect(tinymce.editors[0]).toBeDefined()
      })

      document.querySelectorAll('textarea')[0].value = ''

      const submitButton = getAllByTestId('DiscussionEdit-submit')[0]
      fireEvent.click(submitButton)

      await waitFor(() => expect(queryByText('This is the parent reply')).not.toBeInTheDocument())
    })
  })

  describe('searchFilter', () => {
    it('filters by unread', async () => {
      const container = setup()
      await waitFor(() =>
        expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
      )

      await waitFor(() => expect(container.queryByText('This is an Unread Reply')).toBeNull())

      const simpleSelect = await container.getByLabelText('Filter by')
      await fireEvent.click(simpleSelect)
      const unread = await container.getByText('Unread')
      await fireEvent.click(unread)

      await waitFor(() =>
        expect(container.queryByText('This is an Unread Reply')).toBeInTheDocument()
      )
    })

    it('sorts dEntry by asc', async () => {
      const container = setup()
      await waitFor(() =>
        expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
      )

      await waitFor(() => expect(container.queryByText('This is a Reply asc')).toBeNull())

      const button = await container.getByTestId('sortButton')
      await button.click()

      await waitFor(() => expect(container.queryByText('This is a Reply asc')).toBeInTheDocument())
    })

    it('hides discussion topic when search term is present', async () => {
      const container = setup()
      expect(await container.findByTestId('discussion-topic-container')).toBeTruthy()
      fireEvent.change(await container.getByLabelText('Search entries or author'), {
        target: {value: 'aa'}
      })
      await waitFor(() => expect(container.queryByTestId('discussion-topic-container')).toBeNull())
    })

    it('hides discussion topic when unread is selected', async () => {
      const {findByTestId, getByLabelText, getByText, queryByTestId} = setup()
      expect(await findByTestId('discussion-topic-container')).toBeTruthy()

      const simpleSelect = await getByLabelText('Filter by')
      await fireEvent.click(simpleSelect)
      const unread = await getByText('Unread')
      await fireEvent.click(unread)

      await waitFor(() => expect(queryByTestId('discussion-topic-container')).toBeNull())
    })

    it('does not hide discussion topic when single character search term is present', async () => {
      const container = setup()
      expect(await container.findByTestId('discussion-topic-container')).toBeTruthy()
      fireEvent.change(await container.getByLabelText('Search entries or author'), {
        target: {value: 'a'}
      })
      await waitFor(() =>
        expect(container.queryByTestId('discussion-topic-container')).toBeTruthy()
      )
    })
  })

  describe('discussion topic', () => {
    it('should render', async () => {
      const container = setup()

      await waitFor(() => expect(container.getAllByText('Hank Mccoy')).toBeTruthy())
      expect(await container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
    })

    it.skip('toggles a topics subscribed state when subscribed is clicked', async () => {
      const container = setup()
      await waitFor(() =>
        expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
      )
      const actionsButton = container.getByText('Subscribed')
      fireEvent.click(actionsButton)
      expect(await container.findByText('Unsubscribed')).toBeInTheDocument()
      fireEvent.click(actionsButton)
      expect(await container.findByText('Subscribed')).toBeInTheDocument()
    })

    it.skip('renders a readonly publish button if canUnpublish is false', async () => {
      const container = setup()
      await waitFor(() =>
        expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
      )
      expect(await container.findByText('Published')).toBeInTheDocument()
      expect(
        await container.getByText('Published').closest('button').hasAttribute('disabled')
      ).toBeTruthy()
    })
  })

  describe('error handling', () => {
    it.skip('should render generic error page when DISCUSSION_QUERY returns errors', async () => {
      server.use(
        graphql.query('GetDiscussionQuery', (req, res, ctx) => {
          return res.once(
            ctx.errors([
              {
                message: 'generic error'
              }
            ])
          )
        })
      )

      const container = setup()
      await waitFor(() => expect(container.getAllByText('Sorry, Something Broke')).toBeTruthy())
    })

    it('should render generic error page when DISCUSSION_QUERY returns null', async () => {
      server.use(
        graphql.query('GetDiscussionQuery', (req, res, ctx) => {
          return res.once(ctx.data({legacyNode: null}))
        })
      )

      const container = setup()
      await waitFor(() => expect(container.getAllByText('Sorry, Something Broke')).toBeTruthy())
    })

    it('renders the dates properly', async () => {
      const container = setup()
      expect(await container.findByText('Nov 23, 2020 6:40pm')).toBeInTheDocument()
      expect(await container.findByText('Last reply Apr 5 7:41pm')).toBeInTheDocument()
    })
  })

  it('should be able to post a reply to the topic', async () => {
    const {queryByTestId, findByTestId, queryAllByText} = setup()

    const replyButton = await findByTestId('discussion-topic-reply')
    fireEvent.click(replyButton)

    await waitFor(() => {
      expect(tinymce.editors[0]).toBeDefined()
    })

    const rce = await findByTestId('DiscussionEdit-container')
    expect(rce.style.display).toBe('')

    document.querySelectorAll('textarea')[0].value = 'This is a reply'

    expect(queryAllByText('This is a reply')).toBeTruthy()

    const doReplyButton = await findByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    await waitFor(() => expect(queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument())

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })

  it('should be able to post a reply to an entry', async () => {
    const {findByTestId, queryByTestId} = setup()

    const replyButton = await findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)

    await waitFor(() => {
      expect(tinymce.editors[0]).toBeDefined()
    })

    const rce = await findByTestId('DiscussionEdit-container')
    expect(rce.style.display).toBe('')

    const doReplyButton = await findByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    await waitFor(() => expect(queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument())

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })

  describe('discussion role pills', () => {
    let oldCourseID
    beforeEach(() => {
      oldCourseID = window.ENV.course_id
    })

    afterEach(() => {
      window.ENV.course_id = oldCourseID
    })

    it('should render Teacher and Ta pills', async () => {
      window.ENV.course_id = 1
      const container = setup()
      await waitFor(() => expect(container.queryAllByTestId('pill-container')).toBeTruthy())
      await waitFor(() => expect(container.queryAllByTestId('pill-Teacher')).toBeTruthy())
      await waitFor(() => expect(container.queryAllByTestId('pill-TA')).toBeTruthy())
    })

    it('should not render Teacher and Ta if no course is given', async () => {
      window.ENV.course_id = null
      const container = setup()
      const pillContainer = container.queryAllByTestId('pill-container')
      const teacherPill = container.queryAllByTestId('pill-Teacher')
      const taPill = container.queryAllByTestId('pill-TA')
      expect(pillContainer).toEqual([])
      expect(teacherPill).toEqual([])
      expect(taPill).toEqual([])
    })
  })

  describe('group menu button', () => {
    it('should find "Super Group" group name', async () => {
      const container = setup()
      expect(await container.queryByText('Super Group')).toBeFalsy()
      const groupsMenuButton = await container.findByTestId('groups-menu-btn')
      fireEvent.click(groupsMenuButton)
      await waitFor(() => expect(container.queryByText('Super Group')).toBeTruthy())
    })

    it('should show groups menu when discussion has no child topics but has sibling topics', async () => {
      // defaultTopic has a root topic which has a child topic named Super Group
      // we are only removing the child topic from defaultTopic itself, not its root topic
      server.use(
        graphql.query('GetDiscussionQuery', (req, res, ctx) => {
          return res.once(ctx.data({legacyNode: Discussion.mock({childTopics: null})}))
        })
      )

      const container = setup()
      expect(await container.queryByText('Super Group')).toBeFalsy()
      const groupsMenuButton = await container.findByTestId('groups-menu-btn')
      fireEvent.click(groupsMenuButton)
      await waitFor(() => expect(container.queryByText('Super Group')).toBeTruthy())
    })
  })

  describe('highlighting', () => {
    it('should allow highlighting the discussion topic multiple times', async () => {
      const container = setup()

      expect(container.queryByTestId('isHighlighted')).toBeNull()

      fireEvent.click(await container.findByTestId('thread-actions-menu'))
      fireEvent.click(await container.findByTestId('toTopic'))
      expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()

      // expect the highlight to disapear
      await waitFor(() => expect(container.queryByTestId('isHighlighted')).toBeNull())

      // should be able to highlight the topic multiple times
      fireEvent.click(await container.findByTestId('thread-actions-menu'))
      fireEvent.click(await container.findByTestId('toTopic'))
      expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()
    })
  })
})
