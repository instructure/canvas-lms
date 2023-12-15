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
  it('renders "Go to Reply" button when filter is set to unread', () => {
    const {getByText} = render(
      <ThreadingToolbar searchTerm="" filter="unread">
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(getByText('Go to Reply')).toBeTruthy()
  })

  it('should not render go to reply button when isSplitView prop is true', () => {
    const {queryByText} = render(
      <ThreadingToolbar searchTerm="" filter="unread" isSplitView={true}>
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(queryByText('Go to Reply')).toBeNull()
  })

  it('renders "Go to Reply" button when search term is not ""', () => {
    const {getByText} = render(
      <ThreadingToolbar searchTerm="asdf">
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(getByText('Go to Reply')).toBeTruthy()
  })

  describe('when rootEntryId is present', () => {
    it('calls the onOpenSplitView callback with the parent entry id', async () => {
      const onOpenSplitView = jest.fn()
      const container = render(
        <ThreadingToolbar
          discussionEntry={DiscussionEntry.mock({
            id: '1',
            _id: '1',
            rootEntryId: '2',
            parentId: '3',
          })}
          searchTerm="neato"
          onOpenSplitView={onOpenSplitView}
        />
      )

      fireEvent.click(container.getByText('Go to Reply'))
      await waitFor(() => expect(onOpenSplitView).toHaveBeenCalledWith('3', false, '1', '1'))
    })
  })

  describe('when rootEntryId is not present', () => {
    it('calls the onOpenSplitView callback with the entry id', async () => {
      const onOpenSplitView = jest.fn()
      const container = render(
        <ThreadingToolbar
          discussionEntry={DiscussionEntry.mock({
            _id: '1',
            rootEntryId: null,
            parentId: null,
          })}
          searchTerm="neato"
          onOpenSplitView={onOpenSplitView}
        />
      )

      fireEvent.click(container.getByText('Go to Reply'))
      await waitFor(() => expect(onOpenSplitView).toHaveBeenCalledWith('1', false, null, '1'))
    })
  })

  it('calls the onOpenSplitView callback with its own id if it is a root entry', async () => {
    const onOpenSplitView = jest.fn()
    const container = render(
      <ThreadingToolbar
        discussionEntry={DiscussionEntry.mock({
          id: '1',
          _id: '1',
          rootEntryId: null,
        })}
        searchTerm="neato"
        onOpenSplitView={onOpenSplitView}
      />
    )

    fireEvent.click(container.getByText('Go to Reply'))
    await waitFor(() => expect(onOpenSplitView).toHaveBeenCalledWith('1', false, null, '1'))
  })

  it('renders provided children', () => {
    const {getByText} = render(
      <ThreadingToolbar filter="all" searchTerm="" isSplitView={false}>
        <>First</>
        <>Second</>
      </ThreadingToolbar>
    )

    expect(getByText('First')).toBeTruthy()
    expect(getByText('Second')).toBeTruthy()
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
