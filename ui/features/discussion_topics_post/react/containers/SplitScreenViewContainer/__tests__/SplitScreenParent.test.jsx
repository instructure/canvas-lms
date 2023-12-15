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
import {fireEvent, render} from '@testing-library/react'
import {SplitScreenParent} from '../SplitScreenParent'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {updateDiscussionEntryParticipantMock} from '../../../../graphql/Mocks'
import {waitFor} from '@testing-library/dom'
import {AnonymousUser} from '../../../../graphql/AnonymousUser'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

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

describe('SplitScreenParent', () => {
  const onFailureStub = jest.fn()
  const onSuccessStub = jest.fn()

  const defaultProps = ({discussionEntryOverrides = {}, overrides = {}} = {}) => ({
    discussionTopic: Discussion.mock(),
    discussionEntry: DiscussionEntry.mock(discussionEntryOverrides),
    onToggleUnread: jest.fn(),
    ...overrides,
  })

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider
          value={{setOnFailure: onFailureStub, setOnSuccess: onSuccessStub}}
        >
          <SplitScreenParent {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  afterEach(() => {
    onFailureStub.mockClear()
    onSuccessStub.mockClear()
  })

  it('should render the reply preview', () => {
    const quotedEntry = {
      quotedEntry: {
        createdAt: '2021-08-10T12:10:38-06:00',
        previewMessage:
          'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.',
        author: {
          shortName: 'Albus Dumbledore',
        },
        editor: {
          shortName: 'Albus Dumbledore',
        },
        deleted: false,
      },
    }
    const container = setup(
      defaultProps({
        discussionEntryOverrides: {...quotedEntry},
      })
    )
    expect(container.getByTestId('reply-preview')).toBeInTheDocument()
  })

  describe('thread actions menu', () => {
    it('allows toggling the unread state of an entry', () => {
      const onToggleUnread = jest.fn()
      const {getByTestId} = setup(defaultProps({overrides: {onToggleUnread}}))

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('markAsUnread'))

      expect(onToggleUnread).toHaveBeenCalled()
    })

    it('only shows the delete option if you have permission', () => {
      const props = defaultProps({overrides: {onDelete: jest.fn()}})
      props.discussionEntry.permissions.delete = false
      const {getByTestId, queryByTestId} = setup(props)

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(queryByTestId('delete')).toBeNull()
    })

    it('allows deleting an entry', () => {
      const onDelete = jest.fn()
      const {getByTestId} = setup(defaultProps({overrides: {onDelete}}))

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('delete'))

      expect(onDelete).toHaveBeenCalled()
    })

    it('only shows the speed grader option if you have permission', () => {
      const props = defaultProps({overrides: {onOpenInSpeedGrader: jest.fn()}})
      props.discussionTopic.permissions.speedGrader = false
      const {getByTestId, queryByTestId} = setup(props)

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(queryByTestId('inSpeedGrader')).toBeNull()
    })

    it('allows opening an entry in speedgrader', () => {
      const onOpenInSpeedGrader = jest.fn()
      const {getByTestId} = setup(defaultProps({overrides: {onOpenInSpeedGrader}}))

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByTestId('inSpeedGrader'))

      expect(onOpenInSpeedGrader).toHaveBeenCalled()
    })
  })

  describe('Expand-Button', () => {
    it('should render expand when nested replies are present', () => {
      const {getByTestId} = setup(defaultProps())
      expect(getByTestId('expand-button')).toBeTruthy()
    })

    it('displays unread and replyCount', async () => {
      const {queryAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {rootEntryParticipantCounts: {unreadCount: 1, repliesCount: 2}},
        })
      )
      expect(queryAllByText('2 Replies, 1 Unread').length).toBe(2)
    })

    it('does not display unread count if it is 0', async () => {
      const {queryAllByText} = setup(
        defaultProps({
          discussionEntryOverrides: {rootEntryParticipantCounts: {unreadCount: 0, repliesCount: 2}},
        })
      )
      expect(queryAllByText('2 Replies, 0 Unread').length).toBe(0)
      expect(queryAllByText('2 Replies').length).toBe(2)
    })
  })

  it('should render correct deeply nested alert at depth 4', () => {
    window.ENV = {
      should_show_deeply_nested_alert: true,
    }
    const {queryByText} = setup(
      defaultProps({
        discussionEntryOverrides: {
          parentId: '77',
          depth: 4,
        },
        overrides: {RCEOpen: true},
      })
    )

    expect(
      queryByText(
        'Deeply nested replies are no longer supported. Your reply will appear on the first page of this thread.'
      )
    ).toBeTruthy()
  })

  it('should render correct deeply nested alert at depth 3', () => {
    window.ENV = {
      should_show_deeply_nested_alert: true,
    }
    const {queryByText} = setup(
      defaultProps({
        discussionEntryOverrides: {
          parentId: '77',
          depth: 3,
        },
        overrides: {RCEOpen: true},
      })
    )

    expect(
      queryByText(
        'Deeply nested replies are no longer supported. Your reply will appear on on the page you are currently on.'
      )
    ).toBeTruthy()
  })

  it('should not render deeply nested alert', () => {
    window.ENV = {
      should_show_deeply_nested_alert: false,
    }
    const {queryByText} = setup(defaultProps())

    expect(
      queryByText(
        'Deeply nested replies are no longer supported. Your reply will appear on the first page of this thread.'
      )
    ).toBeFalsy()
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
          reportType: 'other',
        })
      )

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(queryByText('Report'))
      fireEvent.click(queryByText('Other'))
      fireEvent.click(getByTestId('report-reply-submit-button'))

      await waitFor(() => {
        expect(onSuccessStub).toHaveBeenCalledWith('You have reported this reply.', false)
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
