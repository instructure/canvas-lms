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

import React, {useRef} from 'react'
import {render} from '@testing-library/react'

import {LoadMoreButton, LoadingIndicator, LoadingStatus, useIncrementalLoading} from '..'

/*
 * The following conditions specify how these components must be used, not
 * necessarily how they will behave by default upon using them. Minimal wiring
 * is required to ensure the intended experience for users.
 */
describe('RCE > Common > Incremental Loading', () => {
  let $container
  let component
  let loaderOptions

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    loaderOptions = {
      hasMore: null,
      isLoading: false,
      onLoadInitial: jest.fn(),
      onLoadMore: jest.fn(),
      records: [],
      contextType: 'course',
      sortBy: {
        sort: 'alphabetical',
        order: 'asc',
      },
      searchString: '',
    }
  })

  afterEach(() => {
    component.unmount()
    $container.remove()
  })

  function SpecComponent() {
    const {records} = loaderOptions
    const lastItemRef = useRef(null)

    const loader = useIncrementalLoading({...loaderOptions, lastItemRef})

    return (
      <div>
        <ul>
          {records.map((record, index) => {
            const ref = index === records.length - 1 ? lastItemRef : null
            return (
              <li id={`listitem-${record.id}`} key={record.id} ref={ref}>
                {record.label}
              </li>
            )
          })}
        </ul>

        {loader.isLoading && <LoadingIndicator />}

        {loader.hasMore && !loader.isLoading && <LoadMoreButton loader={loader} />}

        <span id="loading-status">
          <LoadingStatus loader={loader} />
        </span>
      </div>
    )
  }

  function renderComponent() {
    component = render(<SpecComponent />, {container: $container})
  }

  function rerenderComponent() {
    component.rerender(<SpecComponent />)
  }

  function buildRecords(count) {
    const records = []
    for (let i = loaderOptions.records.length; i < loaderOptions.records.length + count; i++) {
      records.push({id: i + 1, label: `Record ${i + 1}`})
    }
    return records
  }

  function completeLoad({recordCount = 5, hasMore = true} = {}) {
    loaderOptions.hasMore = hasMore
    loaderOptions.isLoading = false
    loaderOptions.records.push(...buildRecords(recordCount))
    renderComponent()
  }

  function startLoadingMore() {
    loaderOptions.isLoading = true
    renderComponent()
  }

  describe('initial records query', () => {
    it('is executed upon mounting', () => {
      renderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(1)
    })

    it('is executed when sortBy changes', () => {
      renderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(1)
      loaderOptions.sortBy.sort = 'date_added'
      rerenderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(2)
    })

    it('is executed when contextType changes', () => {
      renderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(1)
      loaderOptions.contextType = 'user'
      rerenderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(2)
    })

    it('is executed when searchString changes', () => {
      renderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(1)
      loaderOptions.searchString = 'Waldo'
      rerenderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(2)
    })

    it('is not executed if nothing changes', () => {
      renderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(1)

      rerenderComponent()
      expect(loaderOptions.onLoadInitial).toHaveBeenCalledTimes(1)
    })
  })

  describe('Loading Status', () => {
    beforeEach(renderComponent)

    function getLoadingStatus() {
      return $container.querySelector('#loading-status').textContent.trim()
    }

    it('has no status during the initial load', () => {
      expect(getLoadingStatus()).toEqual('')
    })

    describe('after the initial load resolves', () => {
      it('displays the count of records loaded', () => {
        completeLoad()
        expect(getLoadingStatus()).toEqual('5 items loaded')
      })
    })

    describe('after a subsequent load resolves', () => {
      it('displays the count of only the records just loaded', () => {
        completeLoad()
        startLoadingMore()
        completeLoad({recordCount: 7, hasMore: false})
        expect(getLoadingStatus()).toEqual('7 items loaded')
      })
    })
  })

  describe('"Load More" button', () => {
    beforeEach(renderComponent)

    function getLoadMoreButton() {
      return $container.querySelector('button')
    }

    it('is not displayed during the initial load', () => {
      expect(getLoadMoreButton()).not.toBeInTheDocument()
    })

    describe('after the initial load resolves', () => {
      beforeEach(completeLoad)

      it('is displayed when there are more records to load', () => {
        completeLoad()
        expect(getLoadMoreButton()).toBeInTheDocument()
      })

      it('is not displayed when there are no more records to load', () => {
        completeLoad({hasMore: false})
        expect(getLoadMoreButton()).not.toBeInTheDocument()
      })
    })

    describe('when clicked', () => {
      it('loads more records', () => {
        completeLoad()
        getLoadMoreButton().click()
        expect(loaderOptions.onLoadMore).toHaveBeenCalledTimes(1)
      })
    })
  })
})
