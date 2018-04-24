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
import StickyButton from '../index';
import {shallow} from 'enzyme';
import IconArrowUpSolid from 'instructure-icons/lib/Solid/IconArrowUpSolid';
import IconArrowDownLine from 'instructure-icons/lib/Line/IconArrowDownLine';


it('renders', () => {
  const wrapper = shallow(<StickyButton>I am a Sticky Button</StickyButton>);
  expect(wrapper).toMatchSnapshot();
});

it('calls the onClick prop when clicked', () => {
  const fakeOnClick = jest.fn();
  const wrapper = shallow(
    <StickyButton onClick={fakeOnClick}>
      Click me
    </StickyButton>
  );

  wrapper.find('button').simulate('click');
  expect(fakeOnClick).toHaveBeenCalled();
});

it('does not call the onClick prop when disabled', () => {
  const fakeOnClick = jest.fn();
  const wrapper = shallow(
    <StickyButton onClick={fakeOnClick} disabled>
      Disabled button
    </StickyButton>
  );

  wrapper.find('button').simulate('click', {
    preventDefault() {},
    stopPropagation() {}
  });
  expect(fakeOnClick).not.toHaveBeenCalled();
});

it('renders the correct up icon', () => {
  const wrapper = shallow(
    <StickyButton direction="up">
      Click me
    </StickyButton>
  );
  expect(wrapper.find(IconArrowUpSolid)).toHaveLength(1);
});

it('renders the correct down icon', () => {
  const wrapper = shallow(
    <StickyButton direction="down">
      Click me
    </StickyButton>
  );
  expect(wrapper.find(IconArrowDownLine)).toHaveLength(1);
});

it('adds aria-hidden when specified', () => {
  const wrapper = shallow(
    <StickyButton hidden>
      Click me
    </StickyButton>
  );

  expect(wrapper).toMatchSnapshot();
});
