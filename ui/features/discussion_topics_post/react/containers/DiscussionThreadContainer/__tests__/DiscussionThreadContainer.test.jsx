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
import {AnonymousUser} from '../../../../graphql/AnonymousUser'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {DiscussionEntryPermissions} from '../../../../graphql/DiscussionEntryPermissions'
import {DiscussionPermissions} from '../../../../graphql/DiscussionPermissions'
import {DiscussionThreadContainer} from '../DiscussionThreadContainer'
import {fireEvent, render} from '@testing-library/react'
import {getSpeedGraderUrl} from '../../../utils'
import {MockedProvider} from '@apollo/client/testing'
import React from 'react'
import {
  updateDiscussionEntryParticipantMock,
  updateDiscussionThreadReadStateMock,
} from '../../../../graphql/Mocks'
import {User} from '../../../../graphql/User'
import {waitFor} from '@testing-library/dom'

jest.mock('@canvas/util/globalUtils')

describe('DiscussionThreadContainer', () => {
  const onFailureStub = jest.fn()
  const onSuccessStub = jest.fn()
  const openMock = jest.fn()

  beforeAll(() => {
    window.ENV = {
      course_id: '1',
      SPEEDGRADER_URL_TEMPLATE: '/courses/1/gradebook/speed_grader?assignment_id=1&:student_id',
      discussions_reporting: false,
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

    window.open = openMock
  })

  afterEach(() => {
    onFailureStub.mockClear()
    onSuccessStub.mockClear()
    openMock.mockClear()
    window.ENV.discussions_reporting = false
    jest.clearAllMocks()
  })

  const defaultProps = ({
    discussionEntryOverrides = {},
    discussionOverrides = {},
    propOverrides = {},
  } = {}) => ({
    discussionTopic: Discussion.mock(discussionOverrides),
    discussionEntry: DiscussionEntry.mock(discussionEntryOverrides),
    ...propOverrides,
  })

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider
          value={{setOnFailure: onFailureStub, setOnSuccess: onSuccessStub}}
        >
          <DiscussionThreadContainer {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('renders an attachment if it exists', async () => {
    const container = setup(defaultProps())
    expect(await container.findByText('288777.jpeg')).toBeInTheDocument()
  })

  it('should not render reply button if reply permission is false', () => {
    const {container} = setup(
      defaultProps({
        discussionEntryOverrides: {permissions: DiscussionEntryPermissions.mock({reply: false})},
      }),
    )
    expect(container.querySelector('svg[name="IconDiscussionReply2"]')).not.toBeInTheDocument()
  })

  it('should render reply button if reply permission is true', () => {
    const {container} = setup(defaultProps())
    expect(container.querySelector('svg[name="IconDiscussionReply2"]')).toBeInTheDocument()
  })

  it('should not render quote button if reply permission is false', () => {
    const {queryAllByText, getByTestId} = setup(
      defaultProps({
        discussionEntryOverrides: {permissions: DiscussionEntryPermissions.mock({reply: false})},
      }),
    )
    fireEvent.click(getByTestId('thread-actions-menu'))
    expect(queryAllByText('Quote Reply')).toHaveLength(0)
  })

  it('should render quote button if reply permission is true', () => {
    const {getByTestId, getByText} = setup(defaultProps())
    fireEvent.click(getByTestId('thread-actions-menu'))

    expect(getByText('Quote Reply')).toBeInTheDocument()
  })

  describe('delete permission', () => {
    it('removed when false', async () => {
      const props = defaultProps()
      props.discussionEntry.permissions.delete = false
      const {getByTestId, queryAllByText} = setup(props)
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryAllByText('Delete')).toHaveLength(0)
    })

    it('present when true', async () => {
      const {getByTestId, getByText} = setup(defaultProps())
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(getByText('Delete')).toBeInTheDocument()
    })
  })

  describe('Roles', () => {
    it('does not display author role if not the author', async () => {
      const {queryByTestId} = setup(defaultProps())
      expect(queryByTestId('pill-Author')).not.toBeInTheDocument()
    })

    it('displays author role if the post is from the author', async () => {
      const props = defaultProps({
        discussionOverrides: {author: User.mock({_id: '3', displayName: 'Charles Xavier'})},
        discussionEntryOverrides: {author: User.mock({_id: '3', displayName: 'Charles Xavier'})},
      })
      const {queryByTestId} = setup(props)

      expect(queryByTestId('pill-Author')).toBeInTheDocument()
    })
  })

  describe('read state', () => {
    it('indicates the update to the user', async () => {
      const {getByTestId} = setup(
        defaultProps(),
        updateDiscussionEntryParticipantMock({
          read: false,
          forcedReadState: true,
        }),
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('markAsUnread'))

      await waitFor(() => {
        expect(onSuccessStub.mock.calls).toHaveLength(1)
        expect(onFailureStub.mock.calls).toHaveLength(0)
      })
    })

    it('Should render Mark Thread as Unread and Read', () => {
      const setHighlightEntryId = jest.fn()
      const {getByTestId, getAllByText} = setup(
        defaultProps({
          propOverrides: {setHighlightEntryId},
          discussionOverrides: {discussionType: 'threaded'},
        }),
        updateDiscussionThreadReadStateMock({
          discussionEntryId: 'DiscussionEntry-default-mock',
          read: false,
        }),
      )

      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(getAllByText('Mark Thread as Unread')).toHaveLength(1)
      expect(getAllByText('Mark Thread as Read')).toHaveLength(1)

      fireEvent.click(getAllByText('Mark Thread as Unread')[0])
      expect(setHighlightEntryId.mock.calls).toHaveLength(1)
      expect(setHighlightEntryId).toHaveBeenCalledWith('DiscussionEntry-default-mock')
    })

    it('Should not render Mark Thread as Unread and Read', () => {
      const {getByTestId, queryByTestId} = setup(
        defaultProps({
          discussionOverrides: {discussionType: 'not_threaded'},
        }),
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(queryByTestId('markThreadAsRead')).toBeNull()
      expect(queryByTestId('markThreadAsUnRead')).toBeNull()
    })

    describe('error handling', () => {
      it('indicates the failure to the user', async () => {
        const {getByTestId} = setup(
          defaultProps(),
          updateDiscussionEntryParticipantMock({
            read: false,
            forcedReadState: true,
            shouldError: true,
          }),
        )

        fireEvent.click(getByTestId('thread-actions-menu'))
        fireEvent.click(getByTestId('markAsUnread'))

        await waitFor(() => {
          expect(onSuccessStub.mock.calls).toHaveLength(0)
          expect(onFailureStub.mock.calls).toHaveLength(1)
        })
      })
    })
  })

  describe('ratings', () => {
    it('indicates the update to the user', async () => {
      const {getByTestId} = setup(
        defaultProps(),
        updateDiscussionEntryParticipantMock({
          rating: 'liked',
        }),
      )

      fireEvent.click(getByTestId('like-button'))

      await waitFor(() => {
        expect(onSuccessStub.mock.calls).toHaveLength(1)
        expect(onFailureStub.mock.calls).toHaveLength(0)
      })
    })

    describe('error handling', () => {
      it('indicates the failure to the user', async () => {
        const {getByTestId} = setup(
          defaultProps(),
          updateDiscussionEntryParticipantMock({
            rating: 'liked',
            shouldError: true,
          }),
        )

        fireEvent.click(getByTestId('like-button'))

        await waitFor(() => {
          expect(onSuccessStub.mock.calls).toHaveLength(0)
          expect(onFailureStub.mock.calls).toHaveLength(1)
        })
      })
    })
  })

  describe('SpeedGrader', () => {
    it('Should be able to open SpeedGrader when speedGrader permission is true', async () => {
      const {getByTestId} = setup(defaultProps())

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('inSpeedGrader'))

      await waitFor(() => {
        expect(openMock).toHaveBeenCalledWith(
          getSpeedGraderUrl('2', 'DiscussionEntry-default-mock'),
          `_blank`,
        )
      })
    })

    it('Should not be able to open SpeedGrader if is speedGrader permission is false', () => {
      const {getByTestId, queryByTestId} = setup(
        defaultProps({
          discussionOverrides: {permissions: DiscussionPermissions.mock({speedGrader: false})},
        }),
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(queryByTestId('inSpeedGrader')).toBeNull()
    })
  })

  describe('Go to Buttons', () => {
    it('Should call scrollTo when go to topic is pressed', async () => {
      const goToTopic = jest.fn()
      const {getByTestId} = setup(defaultProps({propOverrides: {goToTopic}}))

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('toTopic'))

      await waitFor(() => {
        expect(goToTopic.mock.calls).toHaveLength(1)
      })
    })

    it('Should call props.setHighlightEntryId when go to parent is pressed', async () => {
      const setHighlightEntryId = jest.fn()
      const parentId = '1'
      const {getByTestId} = setup(
        defaultProps({propOverrides: {setHighlightEntryId, parentId, depth: 2}}),
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('toParent'))

      await waitFor(() => {
        expect(setHighlightEntryId.mock.calls).toHaveLength(1)
      })
    })
  })

  describe('Unread Badge', () => {
    describe('should find unread badge', () => {
      it('root is unread and child reply is unread', () => {
        const container = setup(
          defaultProps({
            discussionEntryOverrides: {entryParticipant: {read: false, rating: false}},
          }),
        )
        expect(container.getByTestId('is-unread')).toBeInTheDocument()
      })

      it('root is unread and child is read', () => {
        const container = setup(
          defaultProps({
            discussionEntryOverrides: {
              entryParticipant: {read: false, rating: false},
              rootEntryParticipantCounts: {
                unreadCount: 0,
                repliesCount: 1,
                __typename: 'DiscussionEntryCounts',
              },
            },
          }),
        )
        expect(container.getByTestId('is-unread')).toBeInTheDocument()
      })
    })

    describe('should not find unread badge', () => {
      it('root is read and child reply is read', () => {
        const container = setup(
          defaultProps({
            discussionEntryOverrides: {
              entryParticipant: {read: true, rating: false},
              rootEntryParticipantCounts: {
                unreadCount: 0,
                repliesCount: 1,
                __typename: 'DiscussionEntryCounts',
              },
            },
          }),
        )
        expect(container.queryByTestId('is-unread')).not.toBeInTheDocument()
      })
    })
  })

  describe('Expand-Button', () => {
    it('should render expand when nested replies are present', () => {
      const {getByTestId} = setup(defaultProps())
      expect(getByTestId('expand-button')).toBeInTheDocument()
    })

    it('pluralizes reply message correctly when there is only a single reply', () => {
      const {getAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {
            rootEntryParticipantCounts: {
              unreadCount: 1,
              repliesCount: 1,
              __typename: 'DiscussionEntryCounts',
            },
          },
        }),
      )
      expect(getAllByText('1 Reply, 1 Unread')).toHaveLength(2)
    })

    it('pluralizes replies message correctly when there are multiple replies', () => {
      const {getAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {rootEntryParticipantCounts: {unreadCount: 1, repliesCount: 2}},
        }),
      )
      expect(getAllByText('2 Replies, 1 Unread')).toBeTruthy()
    })

    it('does not display unread count if it is 0', () => {
      const {queryAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {rootEntryParticipantCounts: {unreadCount: 0, repliesCount: 2}},
        }),
      )
      expect(queryAllByText('2 Replies, 0 Unread')).toHaveLength(0)
      expect(queryAllByText('2 Replies')).toHaveLength(2)
    })
  })

  describe('Report Reply', () => {
    it('does not show Report', () => {
      const {getByTestId, queryByText} = setup(defaultProps())

      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Report')).toBeNull()
    })

    describe('when feature flag and setting is enabled', () => {
      beforeEach(() => {
        window.ENV.discussions_reporting = true
      })

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
          }),
        )

        fireEvent.click(getByTestId('thread-actions-menu'))

        expect(queryByText('Reported')).toBeTruthy()
      })

      it('can Report', async () => {
        const {getByTestId, getByText} = setup(
          defaultProps(),
          updateDiscussionEntryParticipantMock({
            reportType: 'other',
          }),
        )

        fireEvent.click(getByTestId('thread-actions-menu'))
        fireEvent.click(getByText('Report'))
        fireEvent.click(getByText('Other'))
        fireEvent.click(getByTestId('report-reply-submit-button'))

        await waitFor(() => {
          expect(onSuccessStub).toHaveBeenCalledWith('You have reported this reply.', false)
        })
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
})
