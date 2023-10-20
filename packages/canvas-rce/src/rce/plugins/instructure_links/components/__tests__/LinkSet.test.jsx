/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import LinkSet from '../LinkSet'
import RCEGlobals from '../../../../RCEGlobals'

function renderComponent(props) {
  return render(
    <LinkSet
      fetchInitialPage={() => {}}
      fetchNextPage={() => {}}
      onLinkClick={() => {}}
      contextType="course"
      contextId="1"
      suppressRenderEmpty={false}
      type="assignments"
      collection={{links: [], hasMore: false, isLoading: false}}
      {...props}
    />
  )
}

describe('RCE "Links" Plugin > LinkSet', () => {
  it('renders empty notice', () => {
    const {getByText} = renderComponent()
    expect(getByText('No assignments created yet.')).toBeInTheDocument()
  })

  it('does not render empty notice if suppressed', () => {
    const {queryByText} = renderComponent({suppressRenderEmpty: true})
    expect(queryByText('No assignments created yet.')).toBeNull()
  })

  it('renders a collection of assignments', () => {
    const {getByText, getAllByTestId} = renderComponent({
      collection: {
        hasMore: false,
        isLoading: false,
        links: [
          {href: 'url1', title: 'link1'},
          {href: 'url2', title: 'link2'},
        ],
      },
    })

    expect(getAllByTestId('instructure_links-Link')).toHaveLength(2)
    expect(getByText('link1')).toBeInTheDocument()
    expect(getByText('link2')).toBeInTheDocument()
  })

  it('renders load more button if there is more', () => {
    const {getByText} = renderComponent({
      collection: {
        hasMore: true,
        isLoading: false,
        links: [
          {href: 'url1', title: 'link1'},
          {href: 'url2', title: 'link2'},
        ],
      },
    })

    expect(getByText('Load More')).toBeInTheDocument()
  })

  it('fetches initial data when mounted', () => {
    const fetchInitialPage = jest.fn()
    renderComponent({
      collection: {
        hasMore: true,
        isLoading: false,
        links: [],
      },
      fetchInitialPage,
    })

    expect(fetchInitialPage).toHaveBeenCalled()
  })

  it('fetches more when the load more button is clicked', () => {
    const fetchNextPage = jest.fn()
    const {getByText} = renderComponent({
      collection: {
        hasMore: true,
        isLoading: false,
        links: [
          {href: 'url1', title: 'link1'},
          {href: 'url2', title: 'link2'},
        ],
      },
      fetchNextPage,
    })

    const loadMoreBtn = getByText('Load More')
    loadMoreBtn.click()
    expect(fetchNextPage).toHaveBeenCalled()
  })

  it('shows an error message if the fetch failed', () => {
    const fetchNextPage = jest.fn()
    const {getByText} = renderComponent({
      collection: {
        hasMore: true,
        isLoading: false,
        links: [
          {href: 'url1', title: 'link1'},
          {href: 'url2', title: 'link2'},
        ],
        lastError: {},
      },
      fetchNextPage,
    })

    expect(getByText('Loading failed...')).toBeInTheDocument()
  })

  it('shows spinner during initial load', () => {
    const fetchInitialPage = jest.fn()
    const {getByText} = renderComponent({
      collection: {
        hasMore: true,
        isLoading: true,
        links: [],
        lastError: {},
      },
      fetchInitialPage,
    })

    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('shows spinner while loading more', () => {
    const fetchNextPage = jest.fn()
    const {getByText} = renderComponent({
      collection: {
        hasMore: true,
        isLoading: true,
        links: [
          {href: 'url1', title: 'link1'},
          {href: 'url2', title: 'link2'},
        ],
        lastError: {},
      },
      fetchNextPage,
    })

    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('adds a SR indicator to the selected link', async () => {
    const {findByTestId} = renderComponent({
      collection: {
        hasMore: false,
        isLoading: false,
        links: [
          {href: 'url1', title: 'link1'},
          {href: 'url2', title: 'link2'},
        ],
        lastError: {},
      },
      selectedLink: {href: 'url2', title: 'link2'},
    })

    expect(await findByTestId('selected-link-indicator')).toBeInTheDocument()
  })
})
