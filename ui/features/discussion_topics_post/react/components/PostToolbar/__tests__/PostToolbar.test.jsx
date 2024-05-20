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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {PostToolbar} from '../PostToolbar'
import {Discussion} from '../../../../graphql/Discussion'

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

const setup = props => {
  return render(
    <PostToolbar
      onReadAll={Function.prototype}
      {...props}
      discussionTopic={props?.discussion || Discussion.mock()}
    />
  )
}

describe('PostToolbar', () => {
  describe('info text', () => {
    it('displays if provided', () => {
      const {queryAllByText} = setup({repliesCount: 1})
      expect(queryAllByText('1 Reply').length).toBe(2)
    })
    it('not displayed if replies = 0', () => {
      const {queryAllByText} = setup({repliesCount: 0})
      expect(queryAllByText('0 Reply').length).toBe(0)
    })
    it('correct pluralization displayed', () => {
      const {queryAllByText} = setup({repliesCount: 2})
      expect(queryAllByText('2 Replies').length).toBe(2)
    })
  })

  describe('publish button', () => {
    it('does not display if callback is not provided', () => {
      const {queryByText} = setup()
      expect(queryByText('Published')).toBeFalsy()
    })

    it('displays if callback is provided', () => {
      const onTogglePublishMock = jest.fn()
      const {getByText} = setup({
        onTogglePublish: onTogglePublishMock,
        isPublished: true,
        canUnpublish: true,
      })
      expect(onTogglePublishMock.mock.calls.length).toBe(0)
      fireEvent.click(getByText('Published'))
      expect(onTogglePublishMock.mock.calls.length).toBe(1)
    })

    it('displays as disabled if canUnpublish is false', () => {
      const onTogglePublishMock = jest.fn()
      const {getByText} = setup({
        onTogglePublish: onTogglePublishMock,
        isPublished: true,
        canUnpublish: false,
      })
      expect(getByText('Published').closest('button').hasAttribute('disabled')).toBeTruthy()
    })
  })

  describe('subscription button', () => {
    it('does not display if callback is not provided', () => {
      const {queryByText} = setup()
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('displays if callback is provided', () => {
      const onToggleSubscriptionMock = jest.fn()
      const {queryByText, getByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
        discussion: Discussion.mock({groupSet: null}),
      })
      expect(queryByText('Subscribed')).toBeTruthy()
      expect(onToggleSubscriptionMock.mock.calls.length).toBe(0)
      fireEvent.click(getByText('Subscribed'))
      expect(onToggleSubscriptionMock.mock.calls.length).toBe(1)
    })

    it('displays if user does not have teacher, designer, ta', () => {
      window.ENV.current_user_roles = ['student']
      const onToggleSubscriptionMock = jest.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
        discussion: Discussion.mock({groupSet: null}),
      })
      expect(queryByText('Subscribed')).toBeTruthy()
    })

    it('does not display if user has teacher', () => {
      window.ENV.current_user_roles = ['teacher']
      const onToggleSubscriptionMock = jest.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
      })
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('does not display if user has designer', () => {
      window.ENV.current_user_roles = ['designer']
      const onToggleSubscriptionMock = jest.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
      })
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('does not display if user has ta', () => {
      window.ENV.current_user_roles = ['ta']
      const onToggleSubscriptionMock = jest.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
      })
      expect(queryByText('Subscribed')).toBeFalsy()
    })
  })

  describe('menu options', () => {
    describe('mark all as read', () => {
      it('calls provided callback when clicked', () => {
        const onReadAllMock = jest.fn()
        const {getByTestId, getByText} = setup({onReadAll: onReadAllMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onReadAllMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Mark All as Read'))
        expect(onReadAllMock.mock.calls.length).toBe(1)
      })
    })

    describe('mark all as unread', () => {
      it('calls provided callback when clicked', () => {
        const onUnreadAllMock = jest.fn()
        const {getByTestId, getByText} = setup({onUnreadAll: onUnreadAllMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onUnreadAllMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Mark All as Unread'))
        expect(onUnreadAllMock.mock.calls.length).toBe(1)
      })
    })

    describe('edit', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Edit')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onEditMock = jest.fn()
        const {getByTestId, getByText} = setup({onEdit: onEditMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onEditMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Edit'))
        expect(onEditMock.mock.calls.length).toBe(1)
      })
    })

    describe('delete', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Delete')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onDeleteMock = jest.fn()
        const {getByTestId, getByText} = setup({onDelete: onDeleteMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onDeleteMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Delete'))
        expect(onDeleteMock.mock.calls.length).toBe(1)
      })
    })

    describe('toggle comments', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Close for Comments')).toBeFalsy()
        expect(queryByText('Open for Comments')).toBeFalsy()
      })

      describe('comments are currently enabled', () => {
        it('renders correct display text', () => {
          const {queryByText, getByTestId} = setup({
            onCloseForComments: jest.fn(),
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(queryByText('Close for Comments')).toBeTruthy()
          expect(queryByText('Open for Comments')).toBeFalsy()
        })

        it('calls provided callback when clicked', () => {
          const onToggleCommentsMock = jest.fn()
          const {getByTestId, getByText} = setup({
            onCloseForComments: onToggleCommentsMock,
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(onToggleCommentsMock.mock.calls.length).toBe(0)
          fireEvent.click(getByText('Close for Comments'))
          expect(onToggleCommentsMock.mock.calls.length).toBe(1)
        })
      })

      describe('comments are currently disabled', () => {
        it('renders correct display text', () => {
          const {queryByText, getByTestId} = setup({
            onOpenForComments: jest.fn(),
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(queryByText('Open for Comments')).toBeTruthy()
          expect(queryByText('Close for Comments')).toBeFalsy()
        })

        it('calls provided callback when clicked', () => {
          const onToggleCommentsMock = jest.fn()
          const {getByTestId, getByText} = setup({
            onOpenForComments: onToggleCommentsMock,
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(onToggleCommentsMock.mock.calls.length).toBe(0)
          fireEvent.click(getByText('Open for Comments'))
          expect(onToggleCommentsMock.mock.calls.length).toBe(1)
        })
      })
    })

    describe('send to', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Sent To...')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onSendMock = jest.fn()
        const {getByTestId, getByText} = setup({onSend: onSendMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onSendMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Send To...'))
        expect(onSendMock.mock.calls.length).toBe(1)
      })
    })

    describe('copy to', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Copy To...')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onCopyMock = jest.fn()
        const {getByTestId, getByText} = setup({onCopy: onCopyMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onCopyMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Copy To...'))
        expect(onCopyMock.mock.calls.length).toBe(1)
      })
    })

    describe('speedgrader', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Open in Speedgrader')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onOpenSpeedgraderMock = jest.fn()
        const {getByTestId, getByText} = setup({onOpenSpeedgrader: onOpenSpeedgraderMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onOpenSpeedgraderMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Open in Speedgrader'))
        expect(onOpenSpeedgraderMock.mock.calls.length).toBe(1)
      })
    })

    describe('rubric', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Show Rubric')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onDisplayRubricMock = jest.fn()
        const {getByTestId, getByText} = setup({
          onDisplayRubric: onDisplayRubricMock,
          showRubric: true,
        })
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onDisplayRubricMock.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Show Rubric'))
        expect(onDisplayRubricMock.mock.calls.length).toBe(1)
      })
    })

    describe('share to commons', () => {
      beforeAll(() => {
        window.ENV = {
          discussion_topic_menu_tools: [
            {
              base_url: 'example.com',
              canvas_icon_class: 'icon-commons',
              id: '1',
              title: 'Share to Commons',
            },
            {
              base_url: 'example.com',
              canvas_icon_class: 'icon-example',
              id: '2',
              title: 'Share to Example',
            },
          ],
        }
      })

      it('does not render if cannot manage content', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Share to Commons')).toBeFalsy()
      })

      it('render if can manage content', () => {
        const {getByTestId, getByText} = setup({canManageContent: true, discussionTopicId: '1'})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(getByText('Share to Commons')).toBeTruthy()
      })

      it('render multiple LTI if can manage content', () => {
        const {getByTestId, getByText} = setup({canManageContent: true, discussionTopicId: '1'})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(getByText('Share to Commons')).toBeTruthy()
        expect(getByText('Share to Example')).toBeTruthy()
      })
    })
  })
})
