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

import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import {responsiveQuerySizes} from '../../../utils'
import {ThreadingToolbar} from '../ThreadingToolbar'

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
      <ThreadingToolbar searchTerm="" filter="unread" isIsolatedView={true}>
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(queryByText('Go to Reply')).toBeNull()
  })

  describe('when rootEntryId is present', () => {
    it('calls the onOpenIsolatedView callback with the isolated entry id', async () => {
      window.ENV.isolated_view = true
      const onOpenIsolatedView = jest.fn()
      const container = render(
        <ThreadingToolbar
          discussionEntry={DiscussionEntry.mock({
            id: '1',
            _id: '1',
            rootEntryId: '2',
            isolatedEntryId: '3',
            parentId: '3',
          })}
          searchTerm="neato"
          onOpenIsolatedView={onOpenIsolatedView}
        />
      )

      fireEvent.click(container.getByText('Go to Reply'))
      await waitFor(() =>
        expect(onOpenIsolatedView).toHaveBeenCalledWith('3', '3', false, '1', '1')
      )
    })
  })

  describe('when rootEntryId is not present', () => {
    it('calls the onOpenIsolatedView callback with the entry id', async () => {
      window.ENV.isolated_view = true
      const onOpenIsolatedView = jest.fn()
      const container = render(
        <ThreadingToolbar
          discussionEntry={DiscussionEntry.mock({
            _id: '1',
            rootEntryId: null,
            isolatedEntryId: null,
            parentId: null,
          })}
          searchTerm="neato"
          onOpenIsolatedView={onOpenIsolatedView}
        />
      )

      fireEvent.click(container.getByText('Go to Reply'))
      await waitFor(() =>
        expect(onOpenIsolatedView).toHaveBeenCalledWith('1', null, false, null, '1')
      )
    })
  })

  it('calls the onOpenIsolatedView callback with its own id if it is a root entry', async () => {
    window.ENV.isolated_view = true
    const onOpenIsolatedView = jest.fn()
    const container = render(
      <ThreadingToolbar
        discussionEntry={DiscussionEntry.mock({
          id: '1',
          _id: '1',
          isolatedEntryId: null,
          rootEntryId: null,
        })}
        searchTerm="neato"
        onOpenIsolatedView={onOpenIsolatedView}
      />
    )

    fireEvent.click(container.getByText('Go to Reply'))
    await waitFor(() =>
      expect(onOpenIsolatedView).toHaveBeenCalledWith('1', null, false, null, '1')
    )
  })

  describe('Mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1024px'},
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
