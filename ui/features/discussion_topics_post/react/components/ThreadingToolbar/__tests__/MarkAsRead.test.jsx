/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {responsiveQuerySizes} from '../../../utils'
import {MarkAsRead} from '../MarkAsRead'

jest.mock('../../../utils')

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

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = props => {
  return render(
    <MarkAsRead onClick={Function.prototype} isRead={false} isSplitScreenView={false} {...props} />
  )
}

describe('MarkAsRead', () => {
  it('renders text for desktop view', () => {
    const {getAllByText} = setup()
    expect(getAllByText('Mark as Read')).toBeTruthy()
  })

  it('renders unread text for desktop view', () => {
    const {getAllByText} = setup({isRead: true})
    expect(getAllByText('Mark as Unread')).toBeTruthy()
  })

  it('does not render text for split screen view', () => {
    const {queryByText} = setup({isSplitScreenView: true})
    expect(queryByText('Mark as Read')).toBeFalsy()
  })

  it('calls provided callback when clicked', () => {
    const onClickMock = jest.fn()
    const {getAllByText} = setup({onClick: onClickMock})
    expect(onClickMock.mock.calls.length).toBe(0)
    fireEvent.click(getAllByText('Mark as Read')[0])
    expect(onClickMock.mock.calls.length).toBe(1)
  })

  describe('Mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1024px'},
      }))
    })

    it('does not render text', () => {
      const {queryByText} = setup()
      expect(queryByText('Mark as Read')).toBeFalsy()
    })
  })
})
