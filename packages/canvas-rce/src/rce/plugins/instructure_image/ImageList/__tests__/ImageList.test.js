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
import {render} from 'react-testing-library'

import ImageList from '..'

describe('RCE "Image" Plugin > ImageList', () => {
  let props
  let component

  beforeEach(() => {
    props = {
      fetchImages: jest.fn(),
      images: {
        hasMore: false,
        isLoading: false,
        records: []
      },
      onImageEmbed: jest.fn()
    }
  })

  function renderComponent() {
    component = render(<ImageList {...props} />)
  }

  it('calls the .fetchImages prop when mounting', () => {
    renderComponent()
    expect(props.fetchImages).toHaveBeenCalledTimes(1)
  })

  describe('"Load More"', () => {
    function getLoadMoreButton() {
      return component.queryByText(/Load more/)
    }

    it('is present when more images can be loaded', () => {
      jest.useFakeTimers()
      props.images.hasMore = true
      renderComponent()
      jest.runAllTimers()
      expect(getLoadMoreButton()).not.toBeNull()
    })

    it('is not present when no more images can be loaded', () => {
      jest.useFakeTimers()
      props.images.hasMore = false
      renderComponent()
      jest.runAllTimers()
      expect(getLoadMoreButton()).toBeNull()
    })
  })
})
