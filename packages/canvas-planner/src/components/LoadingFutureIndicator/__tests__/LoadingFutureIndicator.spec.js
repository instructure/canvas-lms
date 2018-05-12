/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react';
import {shallow} from 'enzyme';
import LoadingFutureIndicator from '../index';

it('renders load more by default', () => {
  const wrapper = shallow(<LoadingFutureIndicator />);
  expect(wrapper).toMatchSnapshot();
});

it('renders loading when indicated', () => {
  const wrapper = shallow(<LoadingFutureIndicator loadingFuture />);
  expect(wrapper).toMatchSnapshot();
});

it('renders all future items loaded regardless of other props', () => {
  const wrapper = shallow(<LoadingFutureIndicator loadingFuture allFutureItemsLoaded />);
  expect(wrapper).toMatchSnapshot();
});

it('invokes the callback when the load more button is clicked', () => {
  const mockLoad = jest.fn();
  const wrapper = shallow(<LoadingFutureIndicator onLoadMore={mockLoad} />);
  wrapper.find('Button').simulate('click');
  expect(mockLoad).toHaveBeenCalledWith({loadMoreButtonClicked: true});
});

it('shows an Alert when there\'s a query error', () => {
  const wrapper = shallow(<LoadingFutureIndicator loadingError={"uh oh"}/>);
  expect(wrapper).toMatchSnapshot();
});
