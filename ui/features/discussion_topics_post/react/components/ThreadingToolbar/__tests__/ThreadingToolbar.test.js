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

import {render} from '@testing-library/react'
import React from 'react'
import {ThreadingToolbar} from '../ThreadingToolbar'
import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn()
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'}
  }))
})

describe('PostToolbar', () => {
  it('renders provided children', () => {
    const {getByText} = render(
      <ThreadingToolbar>
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(getByText('First')).toBeTruthy()
    expect(getByText('Second')).toBeTruthy()
  })

  it('renders "Go to Reply" button when search term is not ""', () => {
    window.ENV.isolated_view = true
    const {getByText} = render(
      <ThreadingToolbar searchTerm="asdf">
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(getByText('Go to Reply')).toBeTruthy()
  })

  it('renders "Go to Reply" button when filter is set to unread', () => {
    window.ENV.isolated_view = true
    const {getByText} = render(
      <ThreadingToolbar searchTerm="" filter="unread">
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(getByText('Go to Reply')).toBeTruthy()
  })

  it('should not render go to reply button when isIsolatedView prop is true', () => {
    window.ENV.isolated_view = true
    const {queryByText} = render(
      <ThreadingToolbar searchTerm="" filter="unread" isIsolatedView>
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(queryByText('Go to Reply')).toBeNull()
  })

  describe('Mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1024px'}
      }))
    })

    it('should render mobile children', () => {
      const {queryAllByTestId} = render(
        <ThreadingToolbar>
          <>First</>
          <>Second</>
        </ThreadingToolbar>
      )

      expect(queryAllByTestId('mobile-thread-tool')).toBeTruthy()
    })
  })
})
