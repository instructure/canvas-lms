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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {ThreadActions} from '../ThreadActions'
import {MockedProvider} from '@apollo/client/testing'
import {useTranslationStore} from '../../../hooks/useTranslationStore'

const tryTranslate = vi.fn()
const clearEntry = vi.fn()
const setModalOpen = vi.fn()

vi.mock('../../../hooks/useTranslation', () => ({
  useTranslation: () => ({
    tryTranslate,
  }),
}))

vi.mock('../../../hooks/useTranslationStore')

const defaultRequiredProps = {
  id: '1',
  entry: {
    id: '1',
  },
  onMarkAllAsUnread: vi.fn(),
  onToggleUnread: vi.fn(),
}

const defaultMocks = []

const createProps = overrides => {
  return {
    ...defaultRequiredProps,
    goToParent: vi.fn(),
    goToTopic: vi.fn(),
    goToQuotedReply: vi.fn(),
    onEdit: vi.fn(),
    onDelete: vi.fn(),
    onOpenInSpeedGrader: vi.fn(),
    onMarkAllAsRead: vi.fn(),
    onMarkThreadAsRead: vi.fn(),
    onReport: vi.fn(),
    permalinkId: '1',
    ...overrides,
  }
}

const setup = (props, mocks = defaultMocks) =>
  render(
    <MockedProvider mocks={mocks}>
      <ThreadActions {...props} />
    </MockedProvider>,
  )

describe('ThreadActions', () => {
  it('renders all the expected buttons', () => {
    window.ENV.FEATURES.discussion_permalink = true
    const props = createProps()
    const {getByTestId, queryByText} = setup(props)

    const menu = getByTestId('thread-actions-menu')
    expect(menu).toBeInTheDocument()
    fireEvent.click(menu)

    expect(getByTestId('markAllAsRead')).toBeInTheDocument()
    expect(getByTestId('markAsUnread')).toBeInTheDocument()
    expect(getByTestId('toTopic')).toBeInTheDocument()
    expect(getByTestId('toQuotedReply')).toBeInTheDocument()
    expect(getByTestId('edit')).toBeInTheDocument()
    expect(getByTestId('delete')).toBeInTheDocument()
    expect(getByTestId('inSpeedGrader')).toBeInTheDocument()
    expect(getByTestId('report')).toBeInTheDocument()
    expect(getByTestId('copyLink')).toBeInTheDocument()

    expect(queryByText('Mark All as Read')).toBeTruthy()
    expect(queryByText('Go To Topic')).toBeTruthy()
    expect(queryByText('Go To Quoted Reply')).toBeTruthy()
    expect(queryByText('Edit')).toBeTruthy()
    expect(queryByText('Delete')).toBeTruthy()
    expect(queryByText('Open in SpeedGrader')).toBeTruthy()
    expect(queryByText('Report')).toBeTruthy()
    expect(queryByText('Copy Link')).toBeTruthy()
  })

  it('does not display if callback is not provided', () => {
    window.ENV.FEATURES.discussion_permalink = true
    const {getByTestId, queryByText} = setup(defaultRequiredProps)
    const menu = getByTestId('thread-actions-menu')

    expect(menu).toBeInTheDocument()
    fireEvent.click(menu)

    expect(queryByText('Mark All as Read')).toBeFalsy()
    expect(queryByText('Go To Topic')).toBeFalsy()
    expect(queryByText('Go To Quoted Reply')).toBeFalsy()
    expect(queryByText('Edit')).toBeFalsy()
    expect(queryByText('Delete')).toBeFalsy()
    expect(queryByText('Open in SpeedGrader')).toBeFalsy()
    expect(queryByText('Report')).toBeFalsy()
    expect(queryByText('Copy Link')).toBeFalsy()
  })

  it('should not render when is search', () => {
    const {queryByTestId} = setup({...defaultRequiredProps, isSearch: true})
    const menu = queryByTestId('thread-actions-menu')
    expect(menu).toBeNull()
  })

  describe('menu options', () => {
    describe('mark all as read', () => {
      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onMarkAllAsRead.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Mark All as Read'))
        expect(props.onMarkAllAsRead.mock.calls).toHaveLength(1)
      })
    })

    describe('mark all as unread', () => {
      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onMarkAllAsUnread.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Mark All as Unread'))
        expect(props.onMarkAllAsUnread.mock.calls).toHaveLength(1)
      })
    })

    describe('mark thread as read', () => {
      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onMarkThreadAsRead.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Mark Thread as Read'))
        expect(props.onMarkThreadAsRead.mock.calls).toHaveLength(1)
      })
    })

    describe('mark thread as unread', () => {
      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onMarkThreadAsRead.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Mark Thread as Unread'))
        expect(props.onMarkThreadAsRead.mock.calls).toHaveLength(1)
      })
    })

    describe('mark as read/unread', () => {
      it('should render Mark as Unread button when read', () => {
        const props = createProps()
        const {getByTestId} = setup(props)

        const menu = getByTestId('thread-actions-menu')
        expect(menu).toBeInTheDocument()
        fireEvent.click(menu)

        const markAsUnread = getByTestId('markAsUnread')

        expect(markAsUnread).toBeInTheDocument()

        fireEvent.click(markAsUnread)

        expect(props.onToggleUnread.mock.calls).toHaveLength(1)
        expect(props.onToggleUnread.mock.calls[0][0]).toBe('markAsUnread')
      })

      it('should render Mark as Read button when unread', () => {
        const props = createProps({onToggleUnread: vi.fn()})
        const {getByTestId} = setup({...props, isUnread: true})

        const menu = getByTestId('thread-actions-menu')
        expect(menu).toBeInTheDocument()
        fireEvent.click(menu)

        const markAsRead = getByTestId('markAsRead')

        expect(markAsRead).toBeInTheDocument()

        fireEvent.click(markAsRead)

        expect(props.onToggleUnread.mock.calls).toHaveLength(1)
        expect(props.onToggleUnread.mock.calls[0][0]).toBe('markAsRead')
      })
    })

    describe('edit', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = setup({...defaultRequiredProps})

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Edit')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onEdit.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Edit'))
        expect(props.onEdit.mock.calls).toHaveLength(1)
      })
    })

    describe('delete', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = setup({...defaultRequiredProps})

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Delete')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onDelete.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Delete'))
        expect(props.onDelete.mock.calls).toHaveLength(1)
      })
    })

    describe('SpeedGrader', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = setup({...defaultRequiredProps})

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Open in SpeedGrader')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onOpenInSpeedGrader.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Open in SpeedGrader'))
        expect(props.onOpenInSpeedGrader.mock.calls).toHaveLength(1)
      })
    })

    describe('Go to topic', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = setup({...defaultRequiredProps})

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Go To Topic')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.goToTopic.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Go To Topic'))
        expect(props.goToTopic.mock.calls).toHaveLength(1)
      })
    })

    describe('Go to Parent', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = setup({...defaultRequiredProps})

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Go To Parent')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = setup(props)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.goToParent.mock.calls).toHaveLength(0)
        fireEvent.click(getByText('Go To Parent'))
        expect(props.goToParent.mock.calls).toHaveLength(1)
      })
    })
  })

  describe('Report', () => {
    it('calls provided callback when clicked', () => {
      const props = createProps()
      const {getByTestId, getByText} = setup(props)

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(props.onReport.mock.calls).toHaveLength(0)
      fireEvent.click(getByText('Report'))
      expect(props.onReport.mock.calls).toHaveLength(1)
    })

    it('shows Reported if isReported', () => {
      const props = createProps()
      const {getByTestId, getByText} = setup({...props, isReported: true})

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(getByText('Reported')).toBeTruthy()
    })

    it('cannot click if isReported', () => {
      const props = createProps()
      const {getByTestId, getByText} = setup({...props, isReported: true})

      fireEvent.click(getByTestId('thread-actions-menu'))
      expect(props.onReport.mock.calls).toHaveLength(0)
      fireEvent.click(getByText('Reported'))
      expect(props.onReport.mock.calls).toHaveLength(0)
    })
  })

  it('does not display copy link if ff if off', () => {
    window.ENV.FEATURES.discussion_permalink = false
    const props = createProps()
    const {getByTestId, queryByText} = setup(props)

    const menu = getByTestId('thread-actions-menu')
    expect(menu).toBeInTheDocument()
    fireEvent.click(menu)

    expect(queryByText('Copy Link')).toBeFalsy()
  })

  describe('Translate text button', () => {
    beforeAll(() => {
      window.ENV.discussion_translation_available = true
      window.ENV.ai_translation_improvements = true
    })

    afterAll(() => {
      delete window.ENV.ai_translation_improvements
    })

    beforeEach(() => {
      useTranslationStore.mockImplementation(selector =>
        selector({entries: {}, translateAll: false, clearEntry, setModalOpen}),
      )
    })

    it('does not display if the feature flag is off', () => {
      window.ENV.ai_translation_improvements = false
      const props = createProps()
      const {getByTestId, queryByText} = setup(props)
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Translate Text')).toBeFalsy()

      window.ENV.ai_translation_improvements = true
      window.ENV.discussion_translation_available = true
    })

    it('displays if the feature flag is on', () => {
      const props = createProps()
      const {getByTestId, queryByText} = setup(props)
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Translate Text')).toBeInTheDocument()
    })

    it('calls the onTranslate callback when clicked', () => {
      const props = createProps()
      const {getByTestId, getByText} = setup(props)

      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByText('Translate Text'))

      expect(tryTranslate).toHaveBeenCalledWith('1', undefined)
    })

    it('displays only Hide Translation when translation exists', () => {
      useTranslationStore.mockImplementation(selector =>
        selector({
          entries: {1: {translatedMessage: 'Translated text'}},
          translateAll: false,
          clearEntry,
          setModalOpen,
        }),
      )

      const props = createProps()
      const {getByTestId, queryByText} = setup(props)
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Translate Text')).toBeFalsy()
      expect(queryByText('Change Language')).toBeFalsy()
      expect(queryByText('Hide Translation')).toBeInTheDocument()
    })

    it('calls clearEntry when Hide Translation is clicked', () => {
      useTranslationStore.mockImplementation(selector =>
        selector({
          entries: {1: {translatedMessage: 'Translated text'}},
          translateAll: false,
          clearEntry,
          setModalOpen,
        }),
      )

      const props = createProps()
      const {getByTestId, getByText} = setup(props)
      fireEvent.click(getByTestId('thread-actions-menu'))
      fireEvent.click(getByText('Hide Translation'))

      expect(clearEntry).toHaveBeenCalledWith('1')
    })

    it('does not display translation options when translateAll is active', () => {
      useTranslationStore.mockImplementation(selector =>
        selector({entries: {}, translateAll: true, clearEntry, setModalOpen}),
      )

      const props = createProps()
      const {getByTestId, queryByText} = setup(props)
      fireEvent.click(getByTestId('thread-actions-menu'))

      expect(queryByText('Translate Text')).toBeFalsy()
      expect(queryByText('Change Language')).toBeFalsy()
      expect(queryByText('Hide Translation')).toBeFalsy()
    })
  })
})
