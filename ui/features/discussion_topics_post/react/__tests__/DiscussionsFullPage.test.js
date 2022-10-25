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
import {
  createDiscussionEntryMock,
  deleteDiscussionEntryMock,
  getDiscussionQueryMock,
  getAnonymousDiscussionQueryMock,
  getDiscussionSubentriesQueryMock,
  subscribeToDiscussionTopicMock,
  updateDiscussionEntryMock,
  updateDiscussionEntryParticipantMock,
} from '../../graphql/Mocks'
import DiscussionTopicManager from '../DiscussionTopicManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'

jest.useFakeTimers()
jest.mock('@canvas/rce/RichContentEditor')
jest.mock('../utils', () => ({
  ...jest.requireActual('../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1000'}}),
  resolveAuthorRoles: () => [],
}))

describe('DiscussionFullPage', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    window.ENV = {
      per_page: 20,
      isolated_view_initial_page_size: 5,
      current_page: 0,
      discussion_topic_id: '1',
      manual_mark_as_read: false,
      current_user: {
        id: 'PLACEHOLDER',
        display_name: 'Omar Soto-Fortuño',
        avatar_image_url: 'www.avatar.com',
      },
      course_id: '1',
    }

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    window.INST = {
      editorButtons: [],
    }
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  const setup = mocks => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <DiscussionTopicManager discussionTopicId="1" />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  it('should render', () => {
    const {container} = setup(getDiscussionQueryMock())
    expect(container).toBeTruthy()
  })

  it('should render split screen view if enabled', () => {
    const {container} = setup(getDiscussionQueryMock())
    expect(container).toBeTruthy()
  })

  it('should render isolated view if enabled', () => {
    const {container} = setup(getDiscussionQueryMock())
    expect(container).toBeTruthy()
  })

  it('should render isolated view if both isolated view and split screen view are enabled', () => {
    const {container} = setup(getDiscussionQueryMock())
    expect(container).toBeTruthy()
  })

  describe('discussion entries', () => {
    it('should render', async () => {
      const mocks = [
        ...getDiscussionQueryMock(),
        ...getDiscussionSubentriesQueryMock({
          first: 20,
        }),
      ]
      const container = setup(mocks)
      expect(await container.findByText('This is the parent reply')).toBeInTheDocument()
      expect(container.queryByText('This is the child reply asc')).toBeNull()

      const expandButton = container.getByTestId('expand-button')
      fireEvent.click(expandButton)

      expect(await container.findByText('This is the child reply asc')).toBeInTheDocument()
    })

    it('should allow deleting entries', async () => {
      window.confirm = jest.fn(() => true)
      const mocks = [...getDiscussionQueryMock(), ...deleteDiscussionEntryMock()]
      const container = setup(mocks)

      const actionsButton = await container.findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)

      const deleteButton = container.getByText('Delete')
      fireEvent.click(deleteButton)
      expect(await container.findByText('Deleted by Hank Mccoy')).toBeInTheDocument()
    })

    it('toggles an entries read state when the Mark as Read/Unread is clicked', async () => {
      const mocks = [
        ...getDiscussionQueryMock(),
        ...updateDiscussionEntryParticipantMock({read: false, forcedReadState: true}),
        ...updateDiscussionEntryParticipantMock({read: true, forcedReadState: true}),
      ]
      const container = setup(mocks)
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

    it('toggles an entries rating state when the like button is clicked', async () => {
      const mocks = [
        ...getDiscussionQueryMock(),
        ...updateDiscussionEntryParticipantMock({rating: 'liked'}),
        ...updateDiscussionEntryParticipantMock({rating: 'not_liked'}),
      ]
      const container = setup(mocks)
      const likeButton = await container.findByTestId('like-button')

      expect(container.queryByText('Like count: 1')).toBeNull()
      fireEvent.click(likeButton)
      await waitFor(() => expect(container.queryByText('Like count: 1')).toBeTruthy())

      fireEvent.click(likeButton)
      await waitFor(() => expect(container.queryByText('Like count: 1')).toBeNull())
    })

    it('updates discussion entry', async () => {
      const mocks = [...getDiscussionQueryMock(), ...updateDiscussionEntryMock()]
      const container = setup(mocks)
      expect(await container.findByText('This is the parent reply')).toBeInTheDocument()

      const actionsButton = await container.findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)
      fireEvent.click(container.getByTestId('edit'))

      await waitFor(() => {
        expect(tinymce.editors[0]).toBeDefined()
      })

      document.querySelectorAll('textarea')[0].value = ''

      const submitButton = container.getAllByTestId('DiscussionEdit-submit')[0]
      fireEvent.click(submitButton)

      await waitFor(() =>
        expect(container.queryByText('This is the parent reply')).not.toBeInTheDocument()
      )
    })
  })

  describe('searchFilter', () => {
    it('filters by unread', async () => {
      const mocks = [
        ...getDiscussionQueryMock(),
        ...getDiscussionQueryMock({filter: 'unread', rootEntries: false}),
      ]
      const container = setup(mocks)
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(container.queryByText('This is an Unread Reply')).toBeNull()

      const simpleSelect = container.getByLabelText('Filter by')
      fireEvent.click(simpleSelect)
      const unread = container.getByText('Unread')
      fireEvent.click(unread)

      expect(await container.findByText('This is an Unread Reply')).toBeInTheDocument()
    })

    it('sorts discussion entries by asc', async () => {
      const mocks = [...getDiscussionQueryMock(), ...getDiscussionQueryMock({sort: 'asc'})]
      const container = setup(mocks)
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(container.queryByText('This is a Reply asc')).toBeNull()

      const button = container.getByTestId('sortButton')
      button.click()

      expect(await container.findByText('This is a Reply asc')).toBeInTheDocument()
    })

    it('hides discussion topic when unread is selected', async () => {
      const mocks = [
        ...getDiscussionQueryMock(),
        ...getDiscussionQueryMock({filter: 'unread', rootEntries: false}),
      ]
      const container = setup(mocks)
      expect(await container.findByTestId('discussion-topic-container')).toBeInTheDocument()

      const simpleSelect = container.getByLabelText('Filter by')
      fireEvent.click(simpleSelect)
      const unread = container.getByText('Unread')
      fireEvent.click(unread)

      await waitFor(() =>
        expect(container.queryByTestId('discussion-topic-container')).not.toBeInTheDocument()
      )
    })

    it('does not hide discussion topic when single character search term is present', async () => {
      const mocks = [...getDiscussionQueryMock(), ...getDiscussionQueryMock({searchTerm: 'a'})]
      const container = setup(mocks)
      expect(await container.findByTestId('discussion-topic-container')).toBeInTheDocument()
      fireEvent.change(container.getByLabelText('Search entries or author'), {
        target: {value: 'a'},
      })
      expect(await container.findByTestId('discussion-topic-container')).toBeInTheDocument()
    })
  })

  describe('discussion topic', () => {
    it('should render', async () => {
      const container = setup(getDiscussionQueryMock())
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
    })

    it('allows subscribing to the topic', async () => {
      const mocks = [
        ...getDiscussionQueryMock({isGroup: false}),
        ...subscribeToDiscussionTopicMock({subscribed: true}),
      ]
      mocks[0].result.data.legacyNode.subscribed = false
      const container = setup(mocks)
      const subscribeButton = await container.findByText('Unsubscribed')
      fireEvent.click(subscribeButton)
      expect(await container.findByText('Subscribed')).toBeInTheDocument()
    })

    it('allows unsubscribing to the topic', async () => {
      const mocks = [
        ...getDiscussionQueryMock({isGroup: false}),
        ...subscribeToDiscussionTopicMock({subscribed: false}),
      ]
      const container = setup(mocks)
      const subscribeButton = await container.findByText('Subscribed')
      fireEvent.click(subscribeButton)
      expect(await container.findByText('Unsubscribed')).toBeInTheDocument()
    })

    it('renders a readonly publish button if canUnpublish is false', async () => {
      const container = setup(getDiscussionQueryMock())
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(await container.findByText('Published')).toBeInTheDocument()
      expect(
        container.getByText('Published').closest('button').hasAttribute('disabled')
      ).toBeTruthy()
    })

    it('renders the dates properly', async () => {
      const container = setup(getDiscussionQueryMock())
      expect(await container.findByText('Nov 23, 2020 6:40pm')).toBeInTheDocument()
      expect(await container.findByText('Last reply Apr 5, 2021 7:41pm')).toBeInTheDocument()
    })
  })

  describe('AvailableForUser', () => {
    describe('Topic is unavailable', () => {
      it('should show locked discussion topic', async () => {
        const mocks = getDiscussionQueryMock()
        mocks[0].result.data.legacyNode.availableForUser = false
        const container = setup(mocks)
        expect(await container.findByTestId('locked-discussion')).toBeInTheDocument()
      })

      it('should show available discussion topic alert', async () => {
        const mocks = getDiscussionQueryMock()
        mocks[0].result.data.legacyNode.availableForUser = false
        const container = setup(mocks)
        expect(await container.findByTestId('locked-for-user')).toBeInTheDocument()
      })

      it('should not show root replies', async () => {
        const mocks = getDiscussionQueryMock()
        mocks[0].result.data.legacyNode.availableForUser = false
        const container = setup(mocks)
        expect(container.queryByTestId('discussion-root-entry-container')).toBeNull()
      })
    })

    describe('Topic is available', () => {
      it('should not show locked discussion topic', async () => {
        const mocks = getDiscussionQueryMock()
        const container = setup(mocks)
        expect(container.queryByTestId('locked-discussion')).toBeNull()
      })

      it('should not show available discussion topic alert', () => {
        const mocks = getDiscussionQueryMock()
        const container = setup(mocks)
        expect(container.queryByTestId('locked-for-user')).toBeNull()
      })

      it('should show root replies', async () => {
        const mocks = getDiscussionQueryMock()
        const container = setup(mocks)
        expect(await container.findByTestId('discussion-root-entry-container')).toBeInTheDocument()
      })
    })
  })

  describe('error handling', () => {
    it('should render generic error page when DISCUSSION_QUERY returns errors', async () => {
      const container = setup(getDiscussionQueryMock({shouldError: true}))
      expect(await container.findAllByText('Sorry, Something Broke')).toBeTruthy()
    })

    it('should render generic error page when DISCUSSION_QUERY returns null', async () => {
      const mocks = getDiscussionQueryMock()
      mocks[0].result.data.legacyNode = null
      const container = setup(mocks)
      expect(await container.findAllByText('Sorry, Something Broke')).toBeTruthy()
    })
  })

  it('should be able to post a reply to the topic', async () => {
    // For some reason when we add a reply to a discussion topic we end up performing
    // 2 additional discussion queries. Until we address that issue we need to specify
    // these queries in our mocks we provide to MockedProvider
    const mocks = [...getDiscussionQueryMock(), ...createDiscussionEntryMock()]
    const container = setup(mocks)

    const replyButton = await container.findByTestId('discussion-topic-reply')
    fireEvent.click(replyButton)

    await waitFor(() => {
      expect(tinymce.editors[0]).toBeDefined()
    })

    const rce = await container.findByTestId('DiscussionEdit-container')
    expect(rce.style.display).toBe('')

    document.querySelectorAll('textarea')[0].value = 'This is a reply'

    expect(container.queryAllByText('This is a reply')).toBeTruthy()

    const doReplyButton = await container.findByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    await waitFor(() =>
      expect(container.queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument()
    )

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })

  describe('partially anonymous discussion', () => {
    beforeAll(() => {
      window.ENV.discussion_anonymity_enabled = true
    })

    afterAll(() => {
      window.ENV.discussion_anonymity_enabled = false
    })

    it('should be able to post an anonymous reply to the topic', async () => {
      const mocks = [
        ...getAnonymousDiscussionQueryMock(),
        ...createDiscussionEntryMock({isAnonymousAuthor: true}),
      ]
      const container = setup(mocks)

      const replyButton = await container.findByTestId('discussion-topic-reply')
      fireEvent.click(replyButton)

      await waitFor(() => {
        expect(tinymce.editors[0]).toBeDefined()
      })

      const rce = await container.findByTestId('DiscussionEdit-container')
      expect(rce.style.display).toBe('')

      document.querySelectorAll('textarea')[0].value = 'This is a reply'

      expect(container.queryAllByText('This is a reply')).toBeTruthy()

      const doReplyButton = await container.findByTestId('DiscussionEdit-submit')
      fireEvent.click(doReplyButton)

      await waitFor(() =>
        expect(container.queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument()
      )

      await waitFor(() =>
        expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
      )
    })
  })

  it('should be able to post a reply to an entry', async () => {
    const mocks = [
      ...getDiscussionQueryMock(),
      ...createDiscussionEntryMock({replyFromEntryId: '1', includeReplyPreview: false}),
    ]
    const container = setup(mocks)

    const replyButton = await container.findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)

    await waitFor(() => {
      expect(tinymce.editors[0]).toBeDefined()
    })

    const rce = await container.findByTestId('DiscussionEdit-container')
    expect(rce.style.display).toBe('')

    const doReplyButton = await container.findByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    await waitFor(() =>
      expect(container.queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument()
    )

    // expect the highlight to exist for a while
    jest.advanceTimersByTime(3000)
    // expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()

    // expect the highlight to disappear
    jest.advanceTimersByTime(3000)
    await waitFor(() => expect(container.queryByTestId('isHighlighted')).toBeNull())

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
    )
  })

  it('should show reply preview when replying to an entry', async () => {
    const mocks = [
      ...getDiscussionQueryMock(),
      ...createDiscussionEntryMock({replyFromEntryId: '1', includeReplyPreview: true}),
    ]
    const container = setup(mocks)

    const kebabMenu = await container.findByTestId('thread-actions-menu')
    fireEvent.click(kebabMenu)

    const quoteReplyMenuItem = await container.findByText('Quote Reply')
    fireEvent.click(quoteReplyMenuItem)

    await waitFor(() => {
      expect(tinymce.editors[0]).toBeDefined()
    })

    const rce = await container.findByTestId('DiscussionEdit-container')
    expect(rce.style.display).toBe('')

    expect(await container.findByTestId('reply-preview')).toBeTruthy()

    const doReplyButton = await container.findByTestId('DiscussionEdit-submit')
    fireEvent.click(doReplyButton)

    await waitFor(() =>
      expect(container.queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument()
    )

    // expect the highlight to exist for a while
    jest.advanceTimersByTime(3000)
    // expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()

    // expect the highlight to disappear
    jest.advanceTimersByTime(3000)
    await waitFor(() => expect(container.queryByTestId('isHighlighted')).toBeNull())

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
      window.ENV.course_id = '1'
      const container = setup(getDiscussionQueryMock())
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(container.queryAllByTestId('pill-container')).toBeTruthy()
      expect(container.queryAllByTestId('pill-Teacher')).toBeTruthy()
      expect(container.queryAllByTestId('pill-TA')).toBeTruthy()
    })

    it('should not render Teacher and Ta if no course is given', async () => {
      window.ENV.course_id = null
      const container = setup(getDiscussionQueryMock({courseID: null}))
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(container.queryAllByTestId('pill-container')).toEqual([])
      expect(container.queryAllByTestId('pill-Teacher')).toEqual([])
      expect(container.queryAllByTestId('pill-TA')).toEqual([])
    })
  })

  describe('group menu button', () => {
    it('should find "Super Group" group name', async () => {
      const container = setup(getDiscussionQueryMock())
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(container.queryByText('Super Group')).toBeFalsy()
      const groupsMenuButton = await container.findByTestId('groups-menu-btn')
      fireEvent.click(groupsMenuButton)
      await waitFor(() => expect(container.queryByText('Super Group')).toBeTruthy())
    })

    it('should show groups menu when discussion has no child topics but has sibling topics', async () => {
      // defaultTopic has a root topic which has a child topic named Super Group
      // we are only removing the child topic from defaultTopic itself, not its root topic
      const mocks = getDiscussionQueryMock()
      mocks[0].result.data.legacyNode.childTopics = null

      const container = setup(mocks)
      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      expect(container.queryByText('Super Group')).toBeFalsy()
      const groupsMenuButton = await container.findByTestId('groups-menu-btn')
      fireEvent.click(groupsMenuButton)
      await waitFor(() => expect(container.queryByText('Super Group')).toBeTruthy())
    })
  })

  describe('highlighting', () => {
    it('should allow highlighting the discussion topic multiple times', async () => {
      const container = setup(getDiscussionQueryMock())

      expect(container.queryByTestId('isHighlighted')).toBeNull()

      fireEvent.click(await container.findByTestId('thread-actions-menu'))
      fireEvent.click(await container.findByTestId('toTopic'))
      expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()

      // expect the highlight to disappear
      jest.advanceTimersByTime(6000)
      await waitFor(() => expect(container.queryByTestId('isHighlighted')).toBeNull())

      // should be able to highlight the topic multiple times
      fireEvent.click(await container.findByTestId('thread-actions-menu'))
      fireEvent.click(await container.findByTestId('toTopic'))
      expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()
    })

    it('should highlight the deep linked discussion entry', async () => {
      window.ENV.discussions_deep_link = {
        entry_id: '1',
        root_entry_id: null,
      }
      const container = setup(getDiscussionQueryMock())

      // expect the highlight to exist for a while
      jest.advanceTimersByTime(3000)
      expect(await container.findByTestId('isHighlighted')).toBeInTheDocument()

      // expect the highlight to disappear
      jest.advanceTimersByTime(3000)
      await waitFor(() => expect(container.queryByTestId('isHighlighted')).toBeNull())
    })
  })

  describe('reply with ascending sort order', () => {
    beforeEach(() => {
      window.ENV.per_page = 1
    })

    afterEach(() => {
      jest.mock('../utils/constants', () => ({
        ...jest.requireActual('../utils/constants'),
        HIGHLIGHT_TIMEOUT: 0,
      }))
    })

    it('should change to last page when sort order is asc', async () => {
      const mocks = [
        ...getDiscussionQueryMock({perPage: 1}),
        ...getDiscussionQueryMock({perPage: 1, sort: 'asc'}),
        ...createDiscussionEntryMock(),
      ]
      const container = setup(mocks)

      expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
      const button = container.getByTestId('sortButton')
      fireEvent.click(button)

      const replyButton = await container.findByTestId('discussion-topic-reply')
      fireEvent.click(replyButton)

      await waitFor(() => {
        expect(tinymce.editors[0]).toBeDefined()
      })

      const rce = await container.findByTestId('DiscussionEdit-container')
      expect(rce.style.display).toBe('')

      document.querySelectorAll('textarea')[0].value = 'This is a reply'

      expect(container.queryAllByText('This is a reply')).toBeTruthy()

      const doReplyButton = await container.findByTestId('DiscussionEdit-submit')
      fireEvent.click(doReplyButton)

      await waitFor(() =>
        expect(container.queryByTestId('DiscussionEdit-container')).not.toBeInTheDocument()
      )

      await waitFor(() =>
        expect(setOnSuccess).toHaveBeenCalledWith('The discussion entry was successfully created.')
      )
    })
  })
})
