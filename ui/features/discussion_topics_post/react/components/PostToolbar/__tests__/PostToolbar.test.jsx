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
import fakeENV from '@canvas/test-utils/fakeENV'
import {PostToolbar} from '../PostToolbar'
import {Discussion} from '../../../../graphql/Discussion'
import {MockedProvider} from '@apollo/client/testing'
import {useTranslationStore} from '../../../hooks/useTranslationStore'
import {useTranslation} from '../../../hooks/useTranslation'

vi.mock('../../../hooks/useTranslation')
vi.mock('../../../hooks/useTranslationStore')

vi.mock('../../../utils', async () => ({
  ...(await vi.importActual('../../../utils')),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

beforeAll(() => {
  window.matchMedia = vi.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }
  })
})

beforeEach(() => {
  useTranslation.mockReturnValue({tryTranslate: vi.fn()})
})

const setup = (props, mocks = []) => {
  return render(
    <MockedProvider mocks={mocks}>
      <PostToolbar
        onReadAll={Function.prototype}
        {...props}
        discussionTopic={props?.discussion || Discussion.mock()}
      />
    </MockedProvider>,
  )
}

describe('PostToolbar', () => {
  describe('info text', () => {
    it('displays if provided', () => {
      const {queryAllByText} = setup({repliesCount: 1})
      expect(queryAllByText('1 Reply')).toHaveLength(2)
    })
    it('not displayed if replies = 0', () => {
      const {queryAllByText} = setup({repliesCount: 0})
      expect(queryAllByText('0 Reply')).toHaveLength(0)
    })
    it('correct pluralization displayed', () => {
      const {queryAllByText} = setup({repliesCount: 2})
      expect(queryAllByText('2 Replies')).toHaveLength(2)
    })
  })

  describe('publish button', () => {
    it('does not display if callback is not provided', () => {
      const {queryByText} = setup()
      expect(queryByText('Published')).toBeFalsy()
    })

    it('displays if callback is provided', () => {
      const onTogglePublishMock = vi.fn()
      const {getByText, getByTestId} = setup({
        onTogglePublish: onTogglePublishMock,
        isPublished: true,
        canUnpublish: true,
      })
      expect(getByTestId('publishToggle')).toHaveAttribute('data-action-state', 'unpublishButton')
      expect(onTogglePublishMock.mock.calls).toHaveLength(0)
      fireEvent.click(getByText('Published'))
      expect(onTogglePublishMock.mock.calls).toHaveLength(1)
    })

    it('displays as disabled if canUnpublish is false', () => {
      const onTogglePublishMock = vi.fn()
      const {getByText} = setup({
        onTogglePublish: onTogglePublishMock,
        isPublished: true,
        canUnpublish: false,
      })
      expect(getByText('Published').closest('button').hasAttribute('disabled')).toBeTruthy()
    })

    it('adds proper tracing state when it is unpublished', () => {
      const onTogglePublishMock = vi.fn()
      const {getByTestId} = setup({
        onTogglePublish: onTogglePublishMock,
        isPublished: false,
        canUnpublish: true,
      })
      expect(getByTestId('publishToggle')).toHaveAttribute('data-action-state', 'publishButton')
    })
  })

  describe('subscription button', () => {
    it('does not display if callback is not provided', () => {
      const {queryByText} = setup()
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('displays if callback is provided', () => {
      const onToggleSubscriptionMock = vi.fn()
      const {queryByText, getByText, getByTestId} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
        discussion: Discussion.mock({groupSet: null}),
      })
      expect(queryByText('Subscribed')).toBeTruthy()
      expect(getByTestId('subscribeToggle')).toHaveAttribute(
        'data-action-state',
        'unsubscribeButton',
      )
      expect(onToggleSubscriptionMock.mock.calls).toHaveLength(0)
      fireEvent.click(getByText('Subscribed'))
      expect(onToggleSubscriptionMock.mock.calls).toHaveLength(1)
    })

    it('adds proper tracing state when it is unsubscibed', () => {
      const onToggleSubscriptionMock = vi.fn()
      const {getByTestId} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: false,
        discussion: Discussion.mock({groupSet: null}),
      })
      expect(getByTestId('subscribeToggle')).toHaveAttribute('data-action-state', 'subscribeButton')
    })

    it('displays if user does not have teacher, designer, ta', () => {
      window.ENV.current_user_roles = ['student']
      const onToggleSubscriptionMock = vi.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
        discussion: Discussion.mock({groupSet: null}),
      })
      expect(queryByText('Subscribed')).toBeTruthy()
    })

    it('does not display if user has teacher', () => {
      window.ENV.current_user_roles = ['teacher']
      const onToggleSubscriptionMock = vi.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
      })
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('does not display if user has designer', () => {
      window.ENV.current_user_roles = ['designer']
      const onToggleSubscriptionMock = vi.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
      })
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('does not display if user has ta', () => {
      window.ENV.current_user_roles = ['ta']
      const onToggleSubscriptionMock = vi.fn()
      const {queryByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        isSubscribed: true,
      })
      expect(queryByText('Subscribed')).toBeFalsy()
    })

    it('makes the button disabled if cannot subscribe', () => {
      window.ENV.current_user_roles = ['student']
      const onToggleSubscriptionMock = vi.fn()
      const {queryAllByText} = setup({
        onToggleSubscription: onToggleSubscriptionMock,
        discussion: Discussion.mock({
          subscriptionDisabledForUser: true,
          groupSet: null,
        }),
        isSubscribed: false,
      })
      const buttonElement = queryAllByText('Reply to subscribe')[0].closest('button')
      expect(buttonElement.disabled).toBe(true)
    })
  })

  describe('menu options', () => {
    describe('mark all as read', () => {
      it('calls provided callback when clicked', () => {
        const onReadAllMock = vi.fn()
        const {getByTestId, getByText} = setup({onReadAll: onReadAllMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onReadAllMock.mock.calls).toHaveLength(0)
        // This attribute is used for user tracking
        expect(getByTestId('discussion-thread-menuitem-read-all')).toBeDefined()
        fireEvent.click(getByText('Mark All as Read'))
        expect(onReadAllMock.mock.calls).toHaveLength(1)
      })
    })

    describe('mark all as unread', () => {
      it('calls provided callback when clicked', () => {
        const onUnreadAllMock = vi.fn()
        const {getByTestId, getByText} = setup({onUnreadAll: onUnreadAllMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onUnreadAllMock.mock.calls).toHaveLength(0)
        // This attribute is used for user tracking
        expect(getByTestId('discussion-thread-menuitem-unread-all')).toBeDefined()
        fireEvent.click(getByText('Mark All as Unread'))
        expect(onUnreadAllMock.mock.calls).toHaveLength(1)
      })
    })

    describe('edit', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Edit')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onEditMock = vi.fn()
        const {getByTestId, getByText} = setup({onEdit: onEditMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onEditMock.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Edit'))
        expect(onEditMock.mock.calls).toHaveLength(1)
      })
    })

    describe('delete', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Delete')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onDeleteMock = vi.fn()
        const {getByTestId, getByText} = setup({onDelete: onDeleteMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onDeleteMock.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Delete'))
        expect(onDeleteMock.mock.calls).toHaveLength(1)
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
            onCloseForComments: vi.fn(),
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(queryByText('Close for Comments')).toBeTruthy()
          expect(queryByText('Open for Comments')).toBeFalsy()
        })

        it('calls provided callback when clicked', () => {
          const onToggleCommentsMock = vi.fn()
          const {getByTestId, getByText} = setup({
            onCloseForComments: onToggleCommentsMock,
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(onToggleCommentsMock.mock.calls).toHaveLength(0)
          fireEvent.click(getByText('Close for Comments'))
          expect(onToggleCommentsMock.mock.calls).toHaveLength(1)
        })
      })

      describe('comments are currently disabled', () => {
        it('renders correct display text', () => {
          const {queryByText, getByTestId} = setup({
            onOpenForComments: vi.fn(),
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(queryByText('Open for Comments')).toBeTruthy()
          expect(queryByText('Close for Comments')).toBeFalsy()
        })

        it('calls provided callback when clicked', () => {
          const onToggleCommentsMock = vi.fn()
          const {getByTestId, getByText} = setup({
            onOpenForComments: onToggleCommentsMock,
          })
          fireEvent.click(getByTestId('discussion-post-menu-trigger'))
          expect(onToggleCommentsMock.mock.calls).toHaveLength(0)
          fireEvent.click(getByText('Open for Comments'))
          expect(onToggleCommentsMock.mock.calls).toHaveLength(1)
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
        const onSendMock = vi.fn()
        const {getByTestId, getByText} = setup({onSend: onSendMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onSendMock.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Send To...'))
        expect(onSendMock.mock.calls).toHaveLength(1)
      })
    })

    describe('copy to', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Copy To...')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onCopyMock = vi.fn()
        const {getByTestId, getByText} = setup({onCopy: onCopyMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onCopyMock.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Copy To...'))
        expect(onCopyMock.mock.calls).toHaveLength(1)
      })
    })

    describe('speedgrader', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Open in SpeedGrader')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onOpenSpeedgraderMock = vi.fn()
        const {getByTestId, getByText} = setup({onOpenSpeedgrader: onOpenSpeedgraderMock})
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onOpenSpeedgraderMock.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Open in SpeedGrader'))
        expect(onOpenSpeedgraderMock.mock.calls).toHaveLength(1)
      })
    })

    describe('rubric', () => {
      it('does not render if the callback is not provided', () => {
        const {queryByText, getByTestId} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(queryByText('Show Rubric')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const onDisplayRubricMock = vi.fn()
        const {getByTestId, getByText} = setup({
          onDisplayRubric: onDisplayRubricMock,
          showRubric: true,
        })
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))
        expect(onDisplayRubricMock.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Show Rubric'))
        expect(onDisplayRubricMock.mock.calls).toHaveLength(1)
      })
    })

    describe('share to commons', () => {
      beforeAll(() => {
        fakeENV.setup({
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
        })
      })

      afterAll(() => {
        fakeENV.teardown()
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

    describe('translate', () => {
      const tryTranslate = vi.fn()
      const clearEntry = vi.fn()

      it('displays Hide Translation when translation exists', () => {
        useTranslation.mockReturnValue({tryTranslate})
        window.ENV.ai_translation_improvements = true
        window.ENV.discussion_translation_available = true
        useTranslationStore.mockImplementation(selector =>
          selector({
            entries: {topic: {translatedMessage: 'Translated text'}},
            translateAll: false,
            clearEntry,
          }),
        )

        const {getByTestId, queryByText, getByText} = setup()
        fireEvent.click(getByTestId('discussion-post-menu-trigger'))

        expect(queryByText('Translate Text')).toBeFalsy()
        expect(queryByText('Hide Translation')).toBeInTheDocument()

        fireEvent.click(getByText('Hide Translation'))
        expect(clearEntry).toHaveBeenCalledWith('topic')
      })
    })
  })
})
