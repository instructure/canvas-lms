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

const defaultRequiredProps = {
  id: '1',
  onMarkAllAsUnread: jest.fn(),
  onToggleUnread: jest.fn()
}

const createProps = overrides => {
  return {
    ...defaultRequiredProps,
    goToParent: jest.fn(),
    goToTopic: jest.fn(),
    onEdit: jest.fn(),
    onDelete: jest.fn(),
    openInSpeedGrader: jest.fn(),
    ...overrides
  }
}

describe('ThreadActions', () => {
  it('renders all the expected buttons', () => {
    const props = createProps()
    const {getByTestId, queryByText} = render(<ThreadActions {...props} />)

    const menu = getByTestId('thread-actions-menu')
    expect(menu).toBeInTheDocument()
    fireEvent.click(menu)

    expect(getByTestId('markAllAsRead')).toBeInTheDocument()
    expect(getByTestId('markAsUnread')).toBeInTheDocument()
    expect(getByTestId('toTopic')).toBeInTheDocument()
    expect(getByTestId('edit')).toBeInTheDocument()
    expect(getByTestId('delete')).toBeInTheDocument()
    expect(getByTestId('inSpeedGrader')).toBeInTheDocument()

    expect(queryByText('Mark All as Read')).toBeTruthy()
    expect(queryByText('Go To Topic')).toBeTruthy()
    expect(queryByText('Edit')).toBeTruthy()
    expect(queryByText('Delete')).toBeTruthy()
    expect(queryByText('Open in SpeedGrader')).toBeTruthy()
  })

  it('does not display if callback is not provided', () => {
    const {getByTestId, queryByText} = render(<ThreadActions {...defaultRequiredProps} />)
    const menu = getByTestId('thread-actions-menu')

    expect(menu).toBeInTheDocument()
    fireEvent.click(menu)

    expect(queryByText('Mark All as Read')).toBeTruthy()
    expect(queryByText('Go To Topic')).toBeFalsy()
    expect(queryByText('Edit')).toBeFalsy()
    expect(queryByText('Delete')).toBeFalsy()
    expect(queryByText('Open in SpeedGrader')).toBeFalsy()
  })

  describe('menu options', () => {
    describe('mark all as read', () => {
      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = render(<ThreadActions {...props} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onMarkAllAsUnread.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Mark All as Read'))
        expect(props.onMarkAllAsUnread.mock.calls.length).toBe(1)
      })
    })

    describe('mark as read/unread', () => {
      it('should render Mark as Unread button when read', () => {
        const props = createProps()
        const {getByTestId} = render(<ThreadActions {...props} />)

        const menu = getByTestId('thread-actions-menu')
        expect(menu).toBeInTheDocument()
        fireEvent.click(menu)

        const markAsUnread = getByTestId('markAsUnread')

        expect(markAsUnread).toBeInTheDocument()

        fireEvent.click(markAsUnread)

        expect(props.onToggleUnread.mock.calls.length).toBe(1)
        expect(props.onToggleUnread.mock.calls[0][0]).toBe('markAsUnread')
      })

      it('should render Mark as Read button when unread', () => {
        const props = createProps({onToggleUnread: jest.fn()})
        const {getByTestId} = render(<ThreadActions isUnread {...props} />)

        const menu = getByTestId('thread-actions-menu')
        expect(menu).toBeInTheDocument()
        fireEvent.click(menu)

        const markAsRead = getByTestId('markAsRead')

        expect(markAsRead).toBeInTheDocument()

        fireEvent.click(markAsRead)

        expect(props.onToggleUnread.mock.calls.length).toBe(1)
        expect(props.onToggleUnread.mock.calls[0][0]).toBe('markAsRead')
      })
    })

    describe('edit', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = render(<ThreadActions {...defaultRequiredProps} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Edit')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = render(<ThreadActions {...props} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onEdit.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Edit'))
        expect(props.onEdit.mock.calls.length).toBe(1)
      })
    })

    describe('delete', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = render(<ThreadActions {...defaultRequiredProps} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Delete')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = render(<ThreadActions {...props} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.onDelete.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Delete'))
        expect(props.onDelete.mock.calls.length).toBe(1)
      })
    })

    describe('SpeedGrader', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = render(<ThreadActions {...defaultRequiredProps} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Open in SpeedGrader')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = render(<ThreadActions {...props} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.openInSpeedGrader.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Open in SpeedGrader'))
        expect(props.openInSpeedGrader.mock.calls.length).toBe(1)
      })
    })

    describe('Go to topic', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = render(<ThreadActions {...defaultRequiredProps} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Go To Topic')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = render(<ThreadActions {...props} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.goToTopic.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Go To Topic'))
        expect(props.goToTopic.mock.calls.length).toBe(1)
      })
    })

    describe('Go to Parent', () => {
      it('does not render if the callback is not provided', () => {
        const {getByTestId, queryByText} = render(<ThreadActions {...defaultRequiredProps} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(queryByText('Go To Parent')).toBeFalsy()
      })

      it('calls provided callback when clicked', () => {
        const props = createProps()
        const {getByTestId, getByText} = render(<ThreadActions {...props} />)

        fireEvent.click(getByTestId('thread-actions-menu'))
        expect(props.goToParent.mock.calls.length).toBe(0)
        fireEvent.click(getByText('Go To Parent'))
        expect(props.goToParent.mock.calls.length).toBe(1)
      })
    })
  })
})
