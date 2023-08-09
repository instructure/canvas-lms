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
import MediaPanel from '../index'

function getPanelProps(contextType, mediaprops) {
  return {
    contextType,
    fetchInitialMedia: () => {},
    fetchNextMedia: () => {},
    onMediaEmbed: () => {},
    media: {
      [contextType]: {
        files: [],
        bookmark: null,
        isLoading: false,
        hasMore: false,
        ...mediaprops,
      },
    },
    sortBy: {sort: 'alphabetical', order: 'asc'},
    searchString: 'whereami',
  }
}

function renderComponent(props) {
  return render(
    <MediaPanel
      {...getPanelProps('course', {bookmark: 'http://next.docs'})}
      fetchInitialMedia={() => {}}
      fetchNextMedia={() => {}}
      onMediaEmbed={() => {}}
      {...props}
    />
  )
}

function makeFiles(override) {
  return {
    files: [1, 2].map(i => {
      return {
        id: i,
        filename: `file${i}.mp4`,
        title: `file${i}.mp4`,
        content_type: 'video/mp4',
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

describe('RCE "Media" Plugin > MediaPanel', () => {
  it('renders empty notice', () => {
    const {getByText} = renderComponent(getPanelProps('course', {}))
    expect(getByText('No results.')).toBeInTheDocument()
  })

  it('renders loading spinner', () => {
    const {getByText} = renderComponent(getPanelProps('course', {isLoading: true}))
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('renders media files', () => {
    const {getByText, getAllByTestId} = renderComponent(getPanelProps('course', makeFiles()))

    expect(getAllByTestId('instructure_links-Link')).toHaveLength(2)
    expect(getByText('file1')).toBeInTheDocument()
    expect(getByText('file2')).toBeInTheDocument()
  })

  describe('when there is a pending media file', () => {
    let filesObj

    beforeEach(() => {
      filesObj = makeFiles()
      filesObj.files.push({
        id: 3,
        filename: `3.mp4`,
        title: `3.mp4`,
        content_type: 'video/mp4',
        display_name: `pending file`,
        href: `http://the.net/3`,
        date: `2019-05-25T13:03:00Z`,
        media_entry_id: 'maybe',
      })
    })

    it('shows a "pending" message for the file', () => {
      const {getByText} = renderComponent(getPanelProps('course', filesObj))
      expect(getByText('pending file').parentElement.parentElement.outerHTML).toContain(
        'Media file is processing. Please try again later.'
      )
    })
  })

  it('renders load more button if there is more', () => {
    const {getByText} = renderComponent(
      getPanelProps('course', makeFiles({hasMore: true, bookmark: 'next.docs'}))
    )

    expect(getByText('Load More')).toBeInTheDocument()
  })

  it('fetches initial data when mounted', () => {
    const fetchInitialMedia = jest.fn()
    renderComponent({
      fetchInitialMedia,
    })

    expect(fetchInitialMedia).toHaveBeenCalled()
  })

  it('fetches more when the load more button is clicked', () => {
    const fetchNextMedia = jest.fn()
    const {getByText} = renderComponent({
      ...getPanelProps('course', makeFiles({hasMore: true, bookmark: 'more.docs'})),
      fetchNextMedia,
    })

    const loadMoreBtn = getByText('Load More')
    loadMoreBtn.click()
    expect(fetchNextMedia).toHaveBeenCalled()
  })

  it('shows an error message if the fetch failed', () => {
    const fetchNextMedia = jest.fn()
    const {getByText} = renderComponent({
      ...getPanelProps('course', makeFiles({error: 'whoops'})),
      fetchNextMedia,
    })

    expect(getByText('Loading failed.')).toBeInTheDocument()
  })

  it('shows spinner during initial load', () => {
    const fetchInitialMedia = jest.fn()
    const {getByText} = renderComponent({
      ...getPanelProps('course', makeFiles({files: [], isLoading: true})),
      fetchInitialMedia,
    })

    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('shows spinner while loading more', () => {
    const {getByText} = renderComponent(
      getPanelProps('course', makeFiles({isLoading: true, hasMore: true}))
    )

    expect(getByText('Loading')).toBeInTheDocument()
  })
})
