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
import DocumentsPanel from '../DocumentsPanel'

function getDocumentProps(contextType, docprops) {
  return {
    documents: {
      [contextType]: {
        files: [],
        bookmark: null,
        isLoading: false,
        hasMore: false,
        ...docprops,
      },
    },
    contextType,
  }
}

function renderComponent(props, renderer = render) {
  return renderer(
    <DocumentsPanel
      {...getDocumentProps('course', {bookmark: 'http://next.docs'})}
      sortBy={{sort: 'alphabetical', order: 'asc'}}
      searchString="Waldo"
      fetchInitialDocs={() => {}}
      fetchNextDocs={() => {}}
      onLinkClick={() => {}}
      contextType="course"
      {...props}
    />
  )
}

function makeDocuments(override) {
  return {
    files: [1, 2].map(i => {
      return {
        id: i,
        filename: `file${i}.txt`,
        content_type: 'text/plain',
        display_name: `file${i}`,
        href: `http://the.net/${i}`,
        date: `2019-05-25T13:0${i}:00Z`,
      }
    }),
    bookmark: null,
    hasMore: false,
    isLoading: false,
    ...override,
  }
}

describe('RCE "Documents" Plugin > DocumentsPanel', () => {
  it('renders empty notice', () => {
    const {getByText} = renderComponent(getDocumentProps('course', {}))
    expect(getByText('No results.')).toBeInTheDocument()
  })

  it('renders loading spinner', () => {
    const {getByText} = renderComponent(getDocumentProps('course', {isLoading: true}))
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('renders documents', () => {
    const {getByText, getAllByTestId} = renderComponent(getDocumentProps('course', makeDocuments()))

    expect(getAllByTestId('instructure_links-Link')).toHaveLength(2)
    expect(getByText('file1')).toBeInTheDocument()
    expect(getByText('file2')).toBeInTheDocument()
  })

  it('renders load more button if there is more', () => {
    const {getByText} = renderComponent(
      getDocumentProps('course', makeDocuments({hasMore: true, bookmark: 'next.docs'}))
    )

    expect(getByText('Load More')).toBeInTheDocument()
  })

  it('fetches initial data when mounted', () => {
    const fetchInitialDocs = jest.fn()
    renderComponent({
      fetchInitialDocs,
    })

    expect(fetchInitialDocs).toHaveBeenCalledTimes(1)
    expect(fetchInitialDocs).toHaveBeenCalledWith()
  })

  it('fetches more when the load more button is clicked', () => {
    const fetchNextDocs = jest.fn()
    const {getByText} = renderComponent({
      ...getDocumentProps('course', makeDocuments({hasMore: true, bookmark: 'more.docs'})),
      fetchNextDocs,
    })

    const loadMoreBtn = getByText('Load More')
    loadMoreBtn.click()
    expect(fetchNextDocs).toHaveBeenCalledWith()
  })

  it('shows an error message if the fetch failed', () => {
    const fetchNextDocs = jest.fn()
    const {getByText} = renderComponent({
      ...getDocumentProps('course', makeDocuments({error: 'whoops'})),
      fetchNextDocs,
    })

    expect(getByText('Loading failed.')).toBeInTheDocument()
  })

  it('shows spinner during initial load', () => {
    const fetchInitialDocs = jest.fn()
    const {getByText} = renderComponent({
      ...getDocumentProps('course', makeDocuments({files: [], isLoading: true})),
      fetchInitialDocs,
    })

    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('shows spinner while loading more', () => {
    const {getByText} = renderComponent(
      getDocumentProps('course', makeDocuments({isLoading: true, hasMore: true}))
    )

    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('refetches initial docs when sorting changes', () => {
    const fetchInitialDocs = jest.fn()
    const {rerender} = renderComponent({
      fetchInitialDocs,
    })
    expect(fetchInitialDocs).toHaveBeenCalledTimes(1)

    renderComponent({fetchInitialDocs}, rerender)
    expect(fetchInitialDocs).toHaveBeenCalledTimes(1)

    renderComponent({fetchInitialDocs, sortBy: {sort: 'date_added', order: 'desc'}}, rerender)
    expect(fetchInitialDocs).toHaveBeenCalledTimes(2)
  })
})
