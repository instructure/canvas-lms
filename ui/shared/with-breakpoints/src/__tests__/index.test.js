/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import WithBreakpoints from '../index'

const testWidthQuery = (query, width) => {
  const minWidth = query.match(/min-width: ([0-9]+)px/)?.[1]
  const maxWidth = query.match(/max-width: ([0-9]+)px/)?.[1]
  if (minWidth && width > parseFloat(minWidth)) {
    return true
  }
  if (maxWidth && width < parseFloat(maxWidth)) {
    return true
  }
  return false
}

describe('WithBreakpoints', () => {
  const renderer = jest.fn(() => <div>Hello, world!</div>)
  const Wrapped = WithBreakpoints(renderer)

  let matchMedia
  const mockWindowWidth = width => {
    if (window.matchMedia && !window.matchMedia._mocked) {
      throw new Error('cannot mock when window.mediaQuery is defined')
    }
    matchMedia = query => ({
      matches: testWidthQuery(query, width),
      addListener: Function.prototype,
      removeListener: Function.prototype,
    })
    window.matchMedia = matchMedia
  }

  afterEach(() => {
    renderer.mockClear()
    if (matchMedia) {
      delete window.matchMedia
    }
  })

  describe('without matchMedia defined', () => {
    it('renders inner component', () => {
      const {getByText} = render(<Wrapped />)
      expect(getByText('Hello, world!')).not.toBeNull()
    })

    it('does not include any breakpoints', () => {
      render(<Wrapped />)
      const breakpoints = renderer.mock.calls[0][0].breakpoints
      expect(Object.keys(breakpoints)).toEqual([])
    })
  })

  describe('with matchMedia defined', () => {
    it('renders inner component', () => {
      mockWindowWidth(1)
      const {getByText} = render(<Wrapped />)
      expect(getByText('Hello, world!')).not.toBeNull()
    })

    it('calls inner component once', () => {
      mockWindowWidth(1)
      render(<Wrapped />)
      expect(renderer).toHaveBeenCalledTimes(1)
    })

    describe('breakpoints prop', () => {
      it('includes breakpoints prop', () => {
        mockWindowWidth(1)
        render(<Wrapped />)
        expect(renderer.mock.calls[0][0]).toMatchObject({breakpoints: expect.any(Object)})
      })

      it('includes correct breakpoints for small screen', () => {
        mockWindowWidth(1)
        render(<Wrapped />)
        const breakpoints = renderer.mock.calls[0][0].breakpoints
        expect(Object.keys(breakpoints)).toEqual(['mobileOnly'])
      })

      it('includes miniTablet breakpoint for miniTablet screen', () => {
        mockWindowWidth(550)
        render(<Wrapped />)
        const breakpoints = renderer.mock.calls[0][0].breakpoints
        expect(Object.keys(breakpoints)).toEqual(['miniTablet', 'mobileOnly'])
      })

      it('includes tablet breakpoints for tablet screen', () => {
        mockWindowWidth(800)
        render(<Wrapped />)
        const breakpoints = renderer.mock.calls[0][0].breakpoints
        expect(Object.keys(breakpoints)).toEqual(['miniTablet', 'tablet', 'desktopOnly'])
      })

      it('includes desktop breakpoints for desktop screen', () => {
        mockWindowWidth(1000)
        render(<Wrapped />)
        const breakpoints = renderer.mock.calls[0][0].breakpoints
        expect(Object.keys(breakpoints)).toEqual(['miniTablet', 'tablet', 'desktop', 'desktopOnly'])
      })

      it('includes desktopNavOpen breakpoints for large desktop screen', () => {
        mockWindowWidth(2000)
        render(<Wrapped />)
        const breakpoints = renderer.mock.calls[0][0].breakpoints
        expect(Object.keys(breakpoints)).toEqual([
          'miniTablet',
          'tablet',
          'desktop',
          'desktopNavOpen',
          'desktopOnly',
        ])
      })
    })
  })
})
