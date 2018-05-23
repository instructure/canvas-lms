/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react';
import {shallow} from 'enzyme';
import {GradesDisplay} from '../index';

it('renders some course grades', () => {
  const mockCourses = [
    {id: '1', shortName: 'Ticket to Ride 101', color: 'blue', href: '/courses/1',
      score: null, grade: null, hasGradingPeriods: true},
    {id: '2', shortName: 'Ingenious 101', color: 'green', href: '/courses/2',
      score: 42.34, grade: 'D', hasGradingPeriods: false},
    {id: '3', shortName: 'Settlers of Catan 201', color: 'red', href: '/courses/3',
      score: 'blahblah', grade: null, hasGradingPeriods: false},
  ];
  const wrapper = shallow(<GradesDisplay courses={mockCourses} />);
  expect(wrapper).toMatchSnapshot();
});

it('does not render caveat if no courses have grading periods', () => {
  const mockCourses = [
    {id: '1', shortName: 'Ticket to Ride 101', color: 'blue', href: '/courses/1',
      score: null, grade: null, hasGradingPeriods: false},
  ];
  const wrapper = shallow(<GradesDisplay courses={mockCourses} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders a loading spinner when loading', () => {
  const mockCourses = [
    {id: '1', shortName: 'Ticket to Ride 101', color: 'blue', href: '/courses/1',
      score: null, grade: null, hasGradingPeriods: true},
    {id: '2', shortName: 'Ingenious 101', color: 'green', href: '/courses/2',
      score: 42.34, grade: 'D', hasGradingPeriods: false},
  ];
  const wrapper = shallow(<GradesDisplay loading courses={mockCourses} />);
  expect(wrapper).toMatchSnapshot();
});

it('renders an ErrorAlert if there is an error loading grades', () => {
  const mockCourses = [
    {id: '1', shortName: 'Ticket to Ride 101', color: 'blue', href: '/courses/1'},
  ];
  const wrapper = shallow(<GradesDisplay courses={mockCourses} loadingError="There was an error" />);
  expect(wrapper).toMatchSnapshot();
});
