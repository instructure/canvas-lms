/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import SearchMessage, {LAST_PAGE_UNKNOWN_MARKER} from '../SearchMessage'
import {render} from '@testing-library/react'

function defaultProps() {
  return {
    collection: {
      loading: false,
      data: [1, 2, 3],
      links: {
        current: {url: 'abc', page: '5'},
        last: {url: 'abc10', page: '10'},
      },
    },
    setPage: jest.fn(),
    noneFoundMessage: 'None found!',
  }
}

describe('SearchMessage::', () => {
  let flashElements

  beforeEach(() => {
    flashElements = document.createElement('div')
    flashElements.setAttribute('id', 'flash_screenreader_holder')
    flashElements.setAttribute('role', 'alert')
    document.body.appendChild(flashElements)
  })

  afterEach(() => {
    document.body.removeChild(flashElements)
    flashElements = undefined
  })

  it('shows a spinner while loading', () => {
    const props = defaultProps()
    props.collection.loading = true
    const {getByTestId} = render(<SearchMessage {...props} />)
    expect(getByTestId('loading-spinner')).toBeInTheDocument()
  })

  describe('Pagination', () => {
    const textContents = elts => elts.map(elt => elt.textContent)
    const hasUnknownMarker = elts => textContents(elts).includes(LAST_PAGE_UNKNOWN_MARKER)

    it('can handle a lot of pages', () => {
      const props = defaultProps()
      props.collection.links.last.page = '1000'
      const {queryAllByTestId} = render(<SearchMessage {...props} />)
      expect(textContents(queryAllByTestId('page-button'))).toEqual([
        '1',
        '4',
        '5',
        '6',
        '7',
        '8',
        '1,000',
      ])
    })

    it('renders the "last unknown" marker only if the last page is unknown', () => {
      const props = defaultProps()
      const {queryAllByTestId, rerender} = render(<SearchMessage {...props} />)
      expect(hasUnknownMarker(queryAllByTestId('page-button'))).toBe(false)
      delete props.collection.links.last
      rerender(<SearchMessage {...props} />)
      expect(hasUnknownMarker(queryAllByTestId('page-button'))).toBe(true)
    })

    it('honors the knownLastPage prop correctly', () => {
      const props = defaultProps()
      delete props.collection.links.last
      const {queryAllByTestId, rerender} = render(<SearchMessage {...props} />)
      expect(hasUnknownMarker(queryAllByTestId('page-button'))).toBe(true)
      rerender(<SearchMessage {...props} knownLastPage="15" />)
      expect(textContents(queryAllByTestId('page-button'))).toEqual([
        '1',
        '4',
        '5',
        '6',
        '7',
        '8',
        '15',
      ])
    })
  })
})
