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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import InfiniteScroll from '../InfiniteScroll'

describe('InfiniteScroll', () => {
  let loadMore

  const defaultProps = (props = {}) => ({
    loadMore,
    hasMore: true,
    ...props,
  })

  beforeEach(() => {
    loadMore = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const mockContainer = (container, prop, value) => {
    jest.spyOn(container, prop, 'get').mockImplementation(() => value)
  }

  describe('with scroll container', () => {
    it('works if scrollContainer is passed after the creation', () => {
      const scrollContainer = document.createElement('div')
      mockContainer(scrollContainer, 'scrollHeight', 1000)
      mockContainer(scrollContainer, 'clientHeight', 400)
      mockContainer(scrollContainer, 'scrollTop', 0)

      const {rerender} = render(<InfiniteScroll {...defaultProps()} />)
      // by default, the current implementation listening for window scroll events
      // will call the loadMore function, because the window scroll values aren't mocked
      loadMore.mockClear()

      rerender(<InfiniteScroll {...defaultProps()} scrollContainer={scrollContainer} />)

      fireEvent.scroll(scrollContainer)
      expect(loadMore).not.toHaveBeenCalled()

      mockContainer(scrollContainer, 'scrollTop', 349)
      fireEvent.scroll(scrollContainer)
      expect(loadMore).not.toHaveBeenCalled()

      mockContainer(scrollContainer, 'scrollTop', 350)
      fireEvent.scroll(scrollContainer)
      expect(loadMore).toHaveBeenCalled()
    })

    it('works if scrollContainer is passed on the creation of the component', () => {
      const scrollContainer = document.createElement('div')
      mockContainer(scrollContainer, 'scrollHeight', 1000)
      mockContainer(scrollContainer, 'clientHeight', 400)
      mockContainer(scrollContainer, 'scrollTop', 0)

      render(<InfiniteScroll {...defaultProps()} scrollContainer={scrollContainer} />)

      mockContainer(scrollContainer, 'scrollTop', 350)
      fireEvent.scroll(scrollContainer)
      expect(loadMore).toHaveBeenCalled()
    })

    it('detaches events from scrollContaner if other container is passed', () => {
      const scrollContainer = document.createElement('div')
      const scrollContainer2 = document.createElement('div')

      mockContainer(scrollContainer, 'scrollHeight', 1000)
      mockContainer(scrollContainer, 'clientHeight', 400)
      mockContainer(scrollContainer, 'scrollTop', 0)
      mockContainer(scrollContainer2, 'scrollHeight', 1000)
      mockContainer(scrollContainer2, 'clientHeight', 400)
      mockContainer(scrollContainer2, 'scrollTop', 0)

      const {rerender} = render(
        <InfiniteScroll {...defaultProps()} scrollContainer={scrollContainer} />
      )
      rerender(<InfiniteScroll {...defaultProps()} scrollContainer={scrollContainer2} />)

      mockContainer(scrollContainer, 'scrollTop', 350)
      fireEvent.scroll(scrollContainer)
      expect(loadMore).not.toHaveBeenCalled()

      mockContainer(scrollContainer2, 'scrollTop', 350)
      fireEvent.scroll(scrollContainer2)
      expect(loadMore).toHaveBeenCalled()
    })

    it('attaches events to window when switching from a scrollContainer to null', () => {
      const scrollContainer = document.createElement('div')

      mockContainer(scrollContainer, 'scrollHeight', 1000)
      mockContainer(scrollContainer, 'clientHeight', 400)
      mockContainer(scrollContainer, 'scrollTop', 0)

      const windowSpy = jest.spyOn(window, 'addEventListener')

      const {rerender} = render(
        <InfiniteScroll {...defaultProps()} scrollContainer={scrollContainer} />
      )
      expect(windowSpy.mock.calls.map(c => c[0])).not.toContain('scroll')

      rerender(<InfiniteScroll {...defaultProps()} />)

      expect(windowSpy.mock.calls.map(c => c[0])).toContain('scroll')
    })
  })
})
