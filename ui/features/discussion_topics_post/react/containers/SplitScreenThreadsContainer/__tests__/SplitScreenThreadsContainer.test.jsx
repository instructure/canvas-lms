/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {AnonymousUser} from '../../../../graphql/AnonymousUser'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {SplitScreenThreadsContainer} from '../SplitScreenThreadsContainer'
import {MockedProvider} from '@apollo/react-testing'
import {PageInfo} from '../../../../graphql/PageInfo'
import React from 'react'
import {updateDiscussionEntryParticipantMock} from '../../../../graphql/Mocks'

jest.mock('../../../utils/constants', () => ({
  ...jest.requireActual('../../../utils/constants'),
  AUTO_MARK_AS_READ_DELAY: 0,
}))

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

describe('SplitScreenThreadsContainer', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    window.ENV = {
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
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  const defaultProps = ({
    discussionEntryOverrides = {},
    discussionOverrides = {},
    overrides = {},
  } = {}) => ({
    discussionTopic: Discussion.mock(discussionOverrides),
    discussionEntry: DiscussionEntry.mock({
      discussionSubentriesConnection: {
        nodes: [
          DiscussionEntry.mock({
            _id: '50',
            id: '50',
            read: false,
            message: '<p>This is the child reply</P>',
            ...discussionEntryOverrides,
          }),
        ],
        pageInfo: PageInfo.mock(),
        __typename: 'DiscussionSubentriesConnection',
      },
    }),
    ...overrides,
  })

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <SplitScreenThreadsContainer {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  it('should render', () => {
    const container = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render sub-entries in the correct order', async () => {
    const container = setup(defaultProps())
    expect(await container.findByText('This is the child reply')).toBeInTheDocument()
  })

  it('does not render the pagination component if there is only 1 page', () => {
    const props = defaultProps()
    props.discussionTopic.entriesTotalPages = 1
    const {queryByTestId} = setup(props)
    expect(queryByTestId('pagination')).toBeNull()
  })

  describe('Spinners', () => {
    it('show newer spinner when fetchingMoreNewerReplies is true', async () => {
      const container = setup(
        defaultProps({
          overrides: {hasMoreNewerReplies: true, fetchingMoreNewerReplies: true},
        })
      )
      await waitFor(() => expect(container.queryByTestId('new-reply-spinner')).toBeTruthy())
    })

    it('hide newer button spinner when fetchingMoreNewerReplies is false', async () => {
      const container = setup(
        defaultProps({overrides: {hasMoreNewerReplies: true, fetchingMoreNewerReplies: false}})
      )
      await waitFor(() => expect(container.queryByTestId('new-reply-spinner')).toBeNull())
    })

    it('show older button spinner when fetchingMoreOlderReplies is true', async () => {
      const container = setup(
        defaultProps({overrides: {hasMoreOlderReplies: true, fetchingMoreOlderReplies: true}})
      )
      await waitFor(() => expect(container.queryByTestId('old-reply-spinner')).toBeTruthy())
    })

    it('hide older button spinner when fetchingMoreOlderReplies is false', async () => {
      const container = setup(
        defaultProps({overrides: {hasMoreOlderReplies: true, fetchingMoreOlderReplies: false}})
      )
      await waitFor(() => expect(container.queryByTestId('old-reply-spinner')).toBeNull())
    })
  })

  describe('show more replies buttons', () => {
    it('clicking show older replies button calls showOlderReplies()', async () => {
      const showOlderReplies = jest.fn()
      const container = setup(
        defaultProps({overrides: {hasMoreOlderReplies: true, showOlderReplies}})
      )
      const showOlderRepliesButton = await container.findByTestId('show-more-replies-button')
      fireEvent.click(showOlderRepliesButton)
      await waitFor(() => expect(showOlderReplies).toHaveBeenCalled())
    })

    it('clicking show newer replies button calls showNewerReplies()', async () => {
      const showNewerReplies = jest.fn()
      const container = setup(
        defaultProps({overrides: {hasMoreNewerReplies: true, showNewerReplies}})
      )
      const showNewerRepliesButton = await container.findByTestId('show-more-replies-button')
      fireEvent.click(showNewerRepliesButton)
      await waitFor(() => expect(showNewerReplies).toHaveBeenCalled())
    })
  })

  describe('thread actions menu', () => {
    it('allows toggling the unread state of an entry', async () => {
      const onToggleUnread = jest.fn()
      const props = defaultProps({overrides: {onToggleUnread}})
      props.discussionEntry.discussionSubentriesConnection.nodes[0].entryParticipant.read = true
      const {findAllByTestId, findByTestId} = setup(props)

      const threadActionsMenu = await findAllByTestId('thread-actions-menu')
      fireEvent.click(threadActionsMenu[0])
      const markAsRead = await findByTestId('markAsUnread')
      fireEvent.click(markAsRead)

      expect(onToggleUnread).toHaveBeenCalled()
    })

    it('only shows the delete option if you have permission', async () => {
      const props = defaultProps({overrides: {onDelete: jest.fn()}})
      props.discussionEntry.discussionSubentriesConnection.nodes[0].permissions.delete = false
      const {queryByTestId, findAllByTestId} = setup(props)

      const threadActionsMenu = await findAllByTestId('thread-actions-menu')
      fireEvent.click(threadActionsMenu[0])
      expect(queryByTestId('delete')).toBeNull()
    })

    it('allows deleting an entry', async () => {
      const onDelete = jest.fn()
      const {getByTestId, findAllByTestId} = setup(defaultProps({overrides: {onDelete}}))

      const threadActionsMenu = await findAllByTestId('thread-actions-menu')
      fireEvent.click(threadActionsMenu[0])
      fireEvent.click(getByTestId('delete'))

      expect(onDelete).toHaveBeenCalled()
    })

    it('only shows the speed grader option if you have permission', async () => {
      const props = defaultProps({overrides: {onOpenInSpeedGrader: jest.fn()}})
      props.discussionTopic.permissions.speedGrader = false
      const {queryByTestId, findAllByTestId} = setup(props)

      const threadActionsMenu = await findAllByTestId('thread-actions-menu')
      fireEvent.click(threadActionsMenu[0])
      expect(queryByTestId('inSpeedGrader')).toBeNull()
    })

    it('allows opening an entry in speedgrader', async () => {
      const onOpenInSpeedGrader = jest.fn()
      const {getByTestId, findAllByTestId} = setup(defaultProps({overrides: {onOpenInSpeedGrader}}))

      const threadActionsMenu = await findAllByTestId('thread-actions-menu')
      fireEvent.click(threadActionsMenu[0])
      fireEvent.click(getByTestId('inSpeedGrader'))

      expect(onOpenInSpeedGrader).toHaveBeenCalled()
    })
  })

  describe('Quote Reply', () => {
    it('appears in kebab menu', () => {
      const {getByTestId, queryByText} = setup(defaultProps())

      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Quote Reply')).toBeTruthy()
    })
  })

  describe('Report Reply', () => {
    it('show Report', () => {
      const {getByTestId, queryByText} = setup(defaultProps())

      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Report')).toBeTruthy()
    })

    it('show Reported', () => {
      const {getByTestId, queryByText} = setup(
        defaultProps({
          discussionEntryOverrides: {
            entryParticipant: {
              reportType: 'other',
            },
          },
        })
      )

      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Reported')).toBeTruthy()
    })

    it('can Report', async () => {
      const {getByTestId, queryByText} = setup(
        defaultProps(),
        updateDiscussionEntryParticipantMock({
          discussionEntryId: '50',
          reportType: 'other',
        })
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(queryByText('Report'))
      fireEvent.click(queryByText('Other'))
      fireEvent.click(getByTestId('report-reply-submit-button'))

      await waitFor(() => {
        expect(setOnSuccess).toHaveBeenCalledWith('You have reported this reply.', false)
      })
    })
  })

  describe('anonymous author', () => {
    beforeAll(() => {
      window.ENV.discussion_anonymity_enabled = true
    })

    afterAll(() => {
      window.ENV.discussion_anonymity_enabled = false
    })

    it('renders name', () => {
      const props = defaultProps({
        discussionEntryOverrides: {author: null, anonymousAuthor: AnonymousUser.mock()},
      })
      const container = setup(props)
      expect(container.queryByText('Sorry, Something Broke')).toBeNull()
      expect(container.getByText('Anonymous 1')).toBeInTheDocument()
    })
  })

  describe('auto read', () => {
    const intersectionObserverMock = () => ({
      observe: () => null,
      unobserve: () => null,
    })

    beforeEach(() => {
      window.IntersectionObserver = jest.fn().mockImplementation(intersectionObserverMock)
    })

    it('observer is not created when entry is already read', () => {
      const props = defaultProps()
      props.discussionEntry.discussionSubentriesConnection.nodes[0].entryParticipant.read = true
      const container = setup(props)
      expect(container).toBeTruthy()
      expect(window.IntersectionObserver).toHaveBeenCalledTimes(0)
    })

    it('observer is not created when entry is set to force unread', () => {
      const props = defaultProps()
      props.discussionEntry.discussionSubentriesConnection.nodes[0].entryParticipant.read = false
      props.discussionEntry.discussionSubentriesConnection.nodes[0].entryParticipant.forcedReadState = true
      const container = setup(props)
      expect(container).toBeTruthy()
      expect(window.IntersectionObserver).toHaveBeenCalledTimes(0)
    })

    it('observer is created for unread entries', () => {
      const props = defaultProps()
      props.discussionEntry.discussionSubentriesConnection.nodes[0].entryParticipant.read = false
      const container = setup(props)
      expect(container).toBeTruthy()
      expect(window.IntersectionObserver).toHaveBeenCalledTimes(2)
    })
  })

  it('Go To Quoted Reply should work', () => {
    const onOpenSplitScreenView = jest.fn()
    const props = defaultProps({
      discussionEntryOverrides: {
        rootEntryId: '50',
        quotedEntry: {
          ...DiscussionEntry.mock({_id: '100'}),
          previewMessage: '<p>This is the quoted reply</p>',
        },
      },
      overrides: {onOpenSplitScreenView},
    })
    const {getByTestId, queryByText} = setup(props)

    fireEvent.click(getByTestId('thread-actions-menu'))
    fireEvent.click(queryByText('Go To Quoted Reply'))

    expect(onOpenSplitScreenView).toHaveBeenCalledWith('50', false, '100')
  })
})
