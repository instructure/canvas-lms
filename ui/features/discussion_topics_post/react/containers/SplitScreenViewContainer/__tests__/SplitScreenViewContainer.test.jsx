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
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {getDiscussionSubentriesQueryMock} from '../../../../graphql/Mocks'
import {SplitScreenViewContainer} from '../SplitScreenViewContainer'
import {MockedProvider} from '@apollo/react-testing'
import {PageInfo} from '../../../../graphql/PageInfo'
import React from 'react'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.mock('@canvas/rce/react/CanvasRce')
jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

describe('SplitScreenViewContainer', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const onOpenSplitScreenView = jest.fn()
  const goToTopic = jest.fn()
  const onClose = jest.fn()

  const per_page = 20
  const split_screen_view_initial_page_size = 5

  beforeAll(() => {
    window.ENV = {
      per_page,
      split_screen_view_initial_page_size,
      discussion_topic_id: 'Discussion-default-mock',
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
    jest.clearAllMocks()
  })

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <SplitScreenViewContainer {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  const defaultProps = overrides => ({
    discussionTopic: Discussion.mock(),
    discussionEntryId: 'DiscussionEntry-default-mock',
    open: true,
    onClose,
    onOpenSplitScreenView,
    goToTopic,
    setHighlightEntryId: jest.fn(),
    ...overrides,
    isTrayFinishedOpening: true,
  })

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render a back button', async () => {
    const mocks = getDiscussionSubentriesQueryMock({
      last: split_screen_view_initial_page_size,
      includeRelativeEntry: false,
    })
    mocks[0].result.data.legacyNode.parentId = '77'
    const {findByTestId} = setup(defaultProps(), mocks)

    const backButton = await findByTestId('back-button')
    expect(backButton).toBeInTheDocument()

    fireEvent.click(backButton)

    expect(onOpenSplitScreenView).toHaveBeenCalledWith('77', false)
  })

  it('should go to root reply when clicking Go To Parent', async () => {
    const {findAllByTestId, findByText} = setup(
      defaultProps(),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const threadActionsMenus = await findAllByTestId('thread-actions-menu')
    expect(threadActionsMenus[1]).toBeInTheDocument()
    fireEvent.click(threadActionsMenus[1])

    const goToParentButton = await findByText('Go To Parent')
    expect(goToParentButton).toBeInTheDocument()
    fireEvent.click(goToParentButton)

    expect(onOpenSplitScreenView).toHaveBeenCalledWith('DiscussionEntry-default-mock', false)
  })

  it('calls the goToTopic callback when clicking Go To Topic (from parent)', async () => {
    const {findAllByTestId, findByText} = setup(
      defaultProps(),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const threadActionsMenus = await findAllByTestId('thread-actions-menu')
    expect(threadActionsMenus[0]).toBeInTheDocument()
    fireEvent.click(threadActionsMenus[0])

    const goToTopicButton = await findByText('Go To Topic')
    expect(goToTopicButton).toBeInTheDocument()
    fireEvent.click(goToTopicButton, {clientY: 100})

    expect(goToTopic).toHaveBeenCalled()
  })

  it('calls the goToTopic callback when clicking Go To Topic (from child)', async () => {
    const {findAllByTestId, findByText} = setup(
      defaultProps(),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const threadActionsMenus = await findAllByTestId('thread-actions-menu')
    expect(threadActionsMenus[1]).toBeInTheDocument()
    fireEvent.click(threadActionsMenus[1])

    const goToTopicButton = await findByText('Go To Topic')
    expect(goToTopicButton).toBeInTheDocument()
    fireEvent.click(goToTopicButton, {clientY: 100})

    expect(goToTopic).toHaveBeenCalled()
  })

  describe('when a ui-dialog is clicked', () => {
    const modalTestId = 'test-modal'

    beforeEach(() => {
      const elem = document.createElement('div')
      elem.classList.add('ui-dialog')
      elem.setAttribute('data-testid', modalTestId)
      document.body.prepend(elem)
    })

    it('does not call "onClose"', async () => {
      const {findAllByTestId, findByTestId} = setup(
        defaultProps(),
        getDiscussionSubentriesQueryMock({
          last: split_screen_view_initial_page_size,
          includeRelativeEntry: false,
        })
      )

      const threadActionsMenus = await findAllByTestId('thread-actions-menu')
      expect(threadActionsMenus[1]).toBeInTheDocument()
      fireEvent.click(threadActionsMenus[1])

      const modal = await findByTestId(modalTestId)
      expect(modal).toBeInTheDocument()
      fireEvent.click(modal, {clientY: 100})

      expect(onClose).not.toHaveBeenCalled()
    })
  })

  it('should not render a back button', async () => {
    const {findByText, queryByTestId} = setup(
      defaultProps(),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )
    expect(await findByText('This is the parent reply')).toBeInTheDocument()
    expect(queryByTestId('back-button')).toBeNull()
  })

  it('allows fetching older discussion entries', async () => {
    const mocks = [
      ...getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      }),
      ...getDiscussionSubentriesQueryMock({
        last: per_page,
        before: 'MQ',
        includeRelativeEntry: false,
      }),
    ]
    mocks[1].result.data.legacyNode = DiscussionEntry.mock({
      discussionSubentriesConnection: {
        nodes: [
          DiscussionEntry.mock({
            id: '1337',
            _id: '1337',
            message: '<p>Get riggity riggity wrecked son</p>',
          }),
        ],
        pageInfo: PageInfo.mock({hasPreviousPage: false}),
        __typename: 'DiscussionSubentriesConnection',
      },
    })
    const {findByText, queryByText} = setup(defaultProps(), mocks)

    const showOlderRepliesButton = await findByText('Show older replies')
    expect(showOlderRepliesButton).toBeInTheDocument()
    expect(queryByText('Get riggity riggity wrecked son')).toBe(null)

    fireEvent.click(showOlderRepliesButton)

    await waitFor(() => expect(queryByText('Show older replies')).toBeNull())

    expect(await findByText('Get riggity riggity wrecked son')).toBeInTheDocument()
  })

  it('allows fetching newer discussion entries', async () => {
    const mocks = [
      ...getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: true,
        relativeEntryId: '10',
      }),
      ...getDiscussionSubentriesQueryMock({
        first: 0,
        includeRelativeEntry: false,
        beforeRelativeEntry: false,
        relativeEntryId: '10',
      }),
      ...getDiscussionSubentriesQueryMock({
        first: per_page,
        after: 'MjA',
        includeRelativeEntry: false,
        beforeRelativeEntry: false,
        relativeEntryId: '10',
      }),
    ]
    mocks[2].result.data.legacyNode = DiscussionEntry.mock({
      discussionSubentriesConnection: {
        nodes: [
          DiscussionEntry.mock({
            id: '1337',
            _id: '1337',
            message: '<p>Get riggity riggity wrecked son</p>',
          }),
        ],
        pageInfo: PageInfo.mock({hasNextPage: false}),
        __typename: 'DiscussionSubentriesConnection',
      },
    })
    const {findByText, queryByText} = setup(defaultProps({relativeEntryId: '10'}), mocks)

    const showNewerRepliesButton = await findByText('Show newer replies')
    expect(showNewerRepliesButton).toBeInTheDocument()
    expect(queryByText('Get riggity riggity wrecked son')).toBe(null)

    fireEvent.click(showNewerRepliesButton)

    await waitFor(() => expect(queryByText('Show newer replies')).toBeNull())

    expect(await findByText('Get riggity riggity wrecked son')).toBeInTheDocument()
  })

  it('should not show "Show older replies" button initially if hasPreviousPage is false', async () => {
    const mocks = getDiscussionSubentriesQueryMock({
      last: split_screen_view_initial_page_size,
      includeRelativeEntry: false,
    })
    mocks[0].result.data.legacyNode.discussionSubentriesConnection.pageInfo = PageInfo.mock({
      hasPreviousPage: false,
    })

    const {findByText, queryByText} = setup(defaultProps(), mocks)

    expect(await findByText('This is the parent reply')).toBeInTheDocument()
    expect(queryByText('Show older replies')).not.toBeInTheDocument()
  })

  it('should call query with relative id params', async () => {
    const mocks = [
      ...getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: true,
        relativeEntryId: '10',
      }),
      ...getDiscussionSubentriesQueryMock({
        first: 0,
        includeRelativeEntry: false,
        beforeRelativeEntry: false,
        relativeEntryId: '10',
      }),
    ]
    const {findByText} = setup(defaultProps({relativeEntryId: '10'}), mocks)

    expect(await findByText('This is the search result child reply')).toBeInTheDocument()
  })

  it('show newer button should be visible when relativeEntryId is present', async () => {
    const mocks = [
      ...getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: true,
        relativeEntryId: '10',
      }),
      ...getDiscussionSubentriesQueryMock({
        first: 0,
        includeRelativeEntry: false,
        beforeRelativeEntry: false,
        relativeEntryId: '10',
      }),
    ]
    const {queryByText} = setup(defaultProps({relativeEntryId: '10'}), mocks)
    await waitFor(() => expect(queryByText('Show newer replies')).toBeInTheDocument())
  })

  it('show newer button should not be visible when reativeEntryId is not present', async () => {
    const {queryByText} = setup(
      defaultProps({relativeEntryId: null}),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )
    await waitFor(() => expect(queryByText('Show newer replies')).toBeNull())
  })

  it('calls the onOpenSplitScreenView callback when clicking View Replies', async () => {
    const {findByText} = setup(
      defaultProps(),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const viewRepliesButton = await findByText('View Replies')
    fireEvent.click(viewRepliesButton)

    expect(onOpenSplitScreenView).toHaveBeenCalledWith('104', false)
  })

  it('calls the onOpenSplitScreenView callback when clicking reply', async () => {
    const {findAllByText} = setup(
      defaultProps(),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const replyButton = await findAllByText('Reply')
    fireEvent.click(replyButton[1])

    expect(onOpenSplitScreenView).toHaveBeenCalledWith('104', true)
  })

  describe('replying', () => {
    describe('RCE is open', () => {
      const props = defaultProps({RCEOpen: true})

      it('should not display children', () => {
        const {queryByTestId} = setup(
          props,
          getDiscussionSubentriesQueryMock({
            last: split_screen_view_initial_page_size,
            includeRelativeEntry: false,
          })
        )
        expect(queryByTestId('split-screen-view-children')).toBeFalsy()
      })
    })

    describe('RCE is closed', () => {
      const props = defaultProps({RCEOpen: false})

      it('should display children', async () => {
        const {findByTestId} = setup(
          props,
          getDiscussionSubentriesQueryMock({
            last: split_screen_view_initial_page_size,
            includeRelativeEntry: false,
          })
        )
        expect(await findByTestId('split-screen-view-children')).toBeTruthy()
      })
    })
  })

  it('disables the reply and enables the expand buttons if the RCE is open', async () => {
    const setRCEOpen = jest.fn()
    const {findByTestId} = setup(
      defaultProps({RCEOpen: true, setRCEOpen}),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    expect(await findByTestId('DiscussionEdit-container')).toBeInTheDocument()
    const reply = await findByTestId('threading-toolbar-reply')
    expect(reply.hasAttribute('aria-disabled')).toBe(true)
    expect(await findByTestId('expand-button')).toBeEnabled()
  })

  it('disables the expand and enables the reply buttons if the RCE is closed', async () => {
    const setRCEOpen = jest.fn()
    const {findAllByTestId, queryByTestId} = setup(
      defaultProps({RCEOpen: false, setRCEOpen}),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const replyButtons = await findAllByTestId('threading-toolbar-reply')
    expect(replyButtons[0]).toBeEnabled()
    const expandButtons = await findAllByTestId('expand-button')
    expect(expandButtons[0].hasAttribute('aria-disabled')).toBe(true)
    expect(queryByTestId('DiscussionEdit-container')).toBe(null)
  })

  it('calls the setRCEOpen callback with false when clicking the expand button', async () => {
    const setRCEOpen = jest.fn()
    const {findByTestId} = setup(
      defaultProps({RCEOpen: true, setRCEOpen}),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    fireEvent.click(await findByTestId('expand-button'))
    expect(setRCEOpen).toHaveBeenCalledWith(false)
  })

  it('calls the setRCEOpen callback with true when clicking the reply button', async () => {
    const setRCEOpen = jest.fn()
    const {findAllByTestId} = setup(
      defaultProps({RCEOpen: false, setRCEOpen}),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    const replyButtons = await findAllByTestId('threading-toolbar-reply')
    fireEvent.click(replyButtons[0])
    expect(setRCEOpen).toHaveBeenCalledWith(true)
  })

  it('highlights an entry', async () => {
    const {findByTestId} = setup(
      defaultProps({highlightEntryId: '104'}),
      getDiscussionSubentriesQueryMock({
        last: split_screen_view_initial_page_size,
        includeRelativeEntry: false,
      })
    )

    expect(await findByTestId('isHighlighted')).toBeInTheDocument()
  })

  describe('graphql error', () => {
    it('should render generic error page when DISCUSSION_SUBENTRIES_QUERY returns errors', async () => {
      const container = setup(
        defaultProps({highlightEntryId: '104'}),
        getDiscussionSubentriesQueryMock({
          last: split_screen_view_initial_page_size,
          includeRelativeEntry: false,
          shouldError: true,
        })
      )
      await waitFor(() => expect(container.getAllByText('Sorry, Something Broke')).toBeTruthy())
    })
  })
})
