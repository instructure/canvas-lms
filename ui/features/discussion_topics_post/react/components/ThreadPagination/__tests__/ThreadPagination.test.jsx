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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {ThreadPagination, NAV_BAR_HEIGHT} from '../ThreadPagination'
import fakeENV from '@canvas/test-utils/fakeENV'



const defaultProps = overrides => ({
  setPage: jest.fn(),
  selectedPage: 1,
  totalPages: 10,
  ...overrides,
})

describe('ThreadPagination', () => {
  it('Uses the setPage callback with the correct argument', () => {
    const props = defaultProps()
    const {getByText} = render(<ThreadPagination {...props} />)

    fireEvent.click(getByText('2'))
    expect(props.setPage).toHaveBeenCalledWith(1)

    fireEvent.click(getByText('3'))
    expect(props.setPage).toHaveBeenCalledWith(2)

    fireEvent.click(getByText('10'))
    expect(props.setPage).toHaveBeenCalledWith(9)
  })

  describe('adjust style is nav bar is present', () => {
    const expectedNavBarHeightPx = `${NAV_BAR_HEIGHT}px`
    const expectedZeroHeightPx = '0px'

    const setEmbedQueryParam = (paramValue = 'true') => {
      const url = new URL(window.location.href)
      url.searchParams.set('embed', paramValue)
      window.history.pushState({}, '', url)
    }

    const deleteEmbedParam = () => {
      const url = new URL(window.location.href)
      url.searchParams.delete('embed')
      window.history.pushState({}, '', url)
    }

    const renderPaginationSection = () => {
      const {container} = render(<ThreadPagination {...defaultProps()} />)
      return container.querySelector('.discussion-pagination-section')
    }

    afterEach(() => {
      fakeENV.teardown()
    })

    describe('when ENV.SEQUENCE is enabled and NOT in embed mode', () => {
      beforeEach(() => {
        fakeENV.setup({SEQUENCE: true})
        deleteEmbedParam()
      })

      it('should adjust paddingBottom based on the NAV_BAR_HEIGHT', () => {
        expect(renderPaginationSection().style.paddingBottom).toBe(expectedNavBarHeightPx)
      })

      it('should adjust paddingBottom if embed flag is not true', () => {
        setEmbedQueryParam('false')
        expect(renderPaginationSection().style.paddingBottom).toBe(expectedNavBarHeightPx)
      })
    })

    describe('when ENV.SEQUENCE is enabled and in embed mode', () => {
      beforeEach(() => {
        fakeENV.setup({SEQUENCE: true})
        setEmbedQueryParam()
      })

      it('should not adjust paddingBottom', () => {
        expect(renderPaginationSection().style.paddingBottom).toBe(expectedZeroHeightPx)
      })
    })

    describe('when ENV.SEQUENCE is NOT enabled and NOT in embed mode', () => {
      beforeEach(() => {
        fakeENV.setup({SEQUENCE: false})
        deleteEmbedParam()
      })

      it('should not adjust paddingBottom', () => {
        expect(renderPaginationSection().style.paddingBottom).toBe(expectedZeroHeightPx)
      })
    })

    describe('when ENV.SEQUENCE is NOT enabled and in embed mode', () => {
      beforeEach(() => {
        fakeENV.setup({SEQUENCE: false})
        setEmbedQueryParam()
      })

      it('should not adjust paddingBottom', () => {
        expect(renderPaginationSection().style.paddingBottom).toBe(expectedZeroHeightPx)
      })
    })
  })
})
