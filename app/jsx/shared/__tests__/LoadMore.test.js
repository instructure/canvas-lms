/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import { shallow } from 'enzyme'
import React from 'react'
import LoadMore from '../load-more'

describe('LoadMore', () => {
  const defaultProps = {
    hasMore: false,
    loadMore() { },
    isLoading: false
  }

  it('renders the load more component', () => {
    expect(shallow(<LoadMore {...defaultProps} />)).toHaveLength(1)
  })

  it('function is called on load more link click', () => {
    const mockLoadMore = jest.fn()
    const wrapper = shallow(<LoadMore {...defaultProps} hasMore loadMore={mockLoadMore} />)
    wrapper.find('.Button--link').simulate('click')
    expect(mockLoadMore).toBeCalled()
  })
})
