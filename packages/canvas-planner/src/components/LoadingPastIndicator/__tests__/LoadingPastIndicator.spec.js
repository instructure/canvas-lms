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
import LoadingPastIndicator from '../index';
import {shallow} from 'enzyme';
jest.mock( '../../../utilities/scrollUtils');
import {animateSlideDown} from '../../../utilities/scrollUtils'; // eslint-disable-line import/first

it('renders very little', () => {
  const wrapper = shallow(<LoadingPastIndicator />);
  expect(wrapper).toMatchSnapshot();
});

it('renders spinner while loading', () => {
  const wrapper = shallow(<LoadingPastIndicator loadingPast={true} />);
  expect(wrapper).toMatchSnapshot();
});

it('still renders loading even when no more items in the past', () => {
  const wrapper = shallow(<LoadingPastIndicator loadingPast={true} allPastItemsLoaded={true} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders TV when all past items loaded', () => {
  const wrapper = shallow(<LoadingPastIndicator allPastItemsLoaded={true} />);
  expect(wrapper).toMatchSnapshot();
});

it('updates only when props change', () => {
  const wrapper = shallow(<LoadingPastIndicator allPastItemsLoaded={false} loadingPast={false} />);
  let shouldUpdate = wrapper.instance().shouldComponentUpdate({allPastItemsLoaded: false, loadingPast: false});
  expect(shouldUpdate).toBe(false);
  shouldUpdate = wrapper.instance().shouldComponentUpdate({allPastItemsLoaded: true, loadingPast: false});
  expect(shouldUpdate).toBe(true);
});

it('runs the animation only when props transition to true', () => {
  const wrapper = shallow(<LoadingPastIndicator allPastItemsLoaded={false} loadingPast={false}/>);

  // we change a prop then call componentDidUpdate with the previous properties and
  // if either of these 2 props transitions from false -> true, componentDidUpdate should
  // run the animation by calling animateSlideDown. Any other change and it should not.
  wrapper.setProps({allPastItemsLoaded: false, loadingPast: true});
  wrapper.instance().componentDidUpdate({allPastItemsLoaded: false, loadingPast: false});
  expect(animateSlideDown).toHaveBeenCalledTimes(1);  // animateSlideDown was called. That's once.

  wrapper.setProps({allPastItemsLoaded: false, loadingPast: false});
  wrapper.instance().componentDidUpdate({allPastItemsLoaded: false, loadingPast: true});
  expect(animateSlideDown).toHaveBeenCalledTimes(1);  // animateSlideDown not called. Still only once.

  wrapper.setProps({allPastItemsLoaded: true, loadingPast: false});
  wrapper.instance().componentDidUpdate({allPastItemsLoaded: false, loadingPast: false});
  expect(animateSlideDown).toHaveBeenCalledTimes(2);  // allPastItemsLoaded trigger the animation. That's twice

  // no prop change. even though allPastItemsLoaded is true, animation should not run
  wrapper.instance().componentDidUpdate({allPastItemsLoaded: true, loadingPast: false});
  expect(animateSlideDown).toHaveBeenCalledTimes(2);

  wrapper.instance().componentDidUpdate({loadingError: 'whoops'});
  expect(animateSlideDown).toHaveBeenCalledTimes(3);
});

it('shows an Alert when there\'s a query error', () => {
  const wrapper = shallow(<LoadingPastIndicator loadingError={'uh oh'}/>);
  expect(wrapper).toMatchSnapshot();
});
