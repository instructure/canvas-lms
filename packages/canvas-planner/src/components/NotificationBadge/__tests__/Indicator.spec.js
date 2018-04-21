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
import { shallow, mount } from 'enzyme';
import Indicator from '../Indicator';

it('renders screenreader content with the title', () => {
  const wrapper = mount(<Indicator title="a title" variant="primary" />);
  expect(wrapper.find('ScreenReaderContent').text()).toBe('a title');
});

it('renders a badge with the specified variant', () => {
  const wrapper = shallow(<Indicator title="foo" variant="danger" />);
  expect(wrapper.find('Badge').prop('variant')).toBe('danger');
});

// enzyme makes this nigh impossible to test. calling ref methods doesn't work.
// it('provides a ref to the container')
