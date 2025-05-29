/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import LoadingFutureIndicator from '../index'

it('renders load more by default', () => {
  const wrapper = shallow(<LoadingFutureIndicator />)
  expect(wrapper.find('Link')).toHaveLength(1)
  expect(wrapper.find('Link').prop('children')).toBe('Load more')
  expect(wrapper.find('Spinner')).toHaveLength(0)
  expect(wrapper.find('Text')).toHaveLength(0)
  expect(wrapper.find('ErrorAlert')).toHaveLength(0)
})

it('renders loading when indicated', () => {
  const wrapper = shallow(<LoadingFutureIndicator loadingFuture={true} />)
  expect(wrapper.find('Link')).toHaveLength(0)
  expect(wrapper.find('Spinner')).toHaveLength(1)
  expect(wrapper.find('Text')).toHaveLength(1)
  expect(wrapper.find('Text').prop('children')).toBe('Loading...')
  expect(wrapper.find('Spinner').prop('renderTitle')()).toBe('Loading...')
})

it('renders all future items loaded regardless of other props', () => {
  const wrapper = shallow(
    <LoadingFutureIndicator loadingFuture={true} allFutureItemsLoaded={true} />,
  )
  expect(wrapper.find('Link')).toHaveLength(0)
  expect(wrapper.find('Spinner')).toHaveLength(0)
  expect(wrapper.find('Text')).toHaveLength(1)
  expect(wrapper.find('Text').prop('children')).toBe('No more items to show')
  expect(wrapper.find('Text').prop('color')).toBe('secondary')
})

it('invokes the callback when the load more button is clicked', () => {
  const mockLoad = jest.fn()
  const wrapper = shallow(<LoadingFutureIndicator onLoadMore={mockLoad} />)
  wrapper.find('Link').simulate('click')
  expect(mockLoad).toHaveBeenCalledWith({loadMoreButtonClicked: true})
})

it("shows an Alert when there's a query error", () => {
  const wrapper = shallow(<LoadingFutureIndicator loadingError="uh oh" />)
  expect(wrapper.find('ErrorAlert')).toHaveLength(1)
  expect(wrapper.find('ErrorAlert').prop('error')).toBe('uh oh')
  expect(wrapper.find('ErrorAlert').prop('children')).toBe('Error loading more items')
  // The load more button still shows when there's an error, since error doesn't prevent loading more
  expect(wrapper.find('Link')).toHaveLength(1)
  expect(wrapper.find('Spinner')).toHaveLength(0)
})
