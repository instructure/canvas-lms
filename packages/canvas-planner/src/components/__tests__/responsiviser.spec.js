/*
 * Copyright (C) 2108 - present Instructure, Inc.
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
import {string} from 'prop-types';
import { mount } from 'enzyme';
import responsiviser from '../responsiviser';

jest.useFakeTimers();

const defaultWindowWidth = window.innerWidth;
let mockMatchMedia = false;
let handleWindowResize = null;

function resizeWindow(newWidth) {
  window.innerWidth = newWidth;
  window.dispatchEvent(new Event('resize'));
  jest.runAllTimers();
}
function mockMediaQueryList(mediaQuery) {
  this.mediaQuery = mediaQuery;
  this.matches = window.innerWidth <= 768;

  this.onWindowResize = (event) => {
    this.matches = window.innerWidth <= 768;
  };
  handleWindowResize = this.onWindowResize;
  window.addEventListener('resize', this.onWindowResize);
}
function mockUpWindow () {
  if ('matchMedia' in window) return;
  mockMatchMedia = true;
  window.matchMedia = function(mediaQuery) {
    return new mockMediaQueryList(mediaQuery);
  };
  window.innerWidth = 1024;
}
function resetWindow () {
  window.innerWidth = defaultWindowWidth;
  if(mockMatchMedia) {
    window.removeEventListener('resize', handleWindowResize);
    delete window.matchMedia;
  }
}

class SomeComponent extends React.Component {
  static propTypes = { responsiveSize: string }
  static defaultProps = { responsiveSize: 'large' }
  render () {
    return <div data-sz={this.props.responsiveSize}>hello world</div>;
  }
}

beforeAll(() => {
  mockUpWindow();
});
afterAll(() => {
  resetWindow();
});
afterEach(() => {
  jest.restoreAllMocks();
});


it('renders large', () => {
  const ResponsiveComponent = responsiviser()(SomeComponent);
  const wrapper = mount(<ResponsiveComponent/>);
  expect(responsiviser.mqwatcher.interestedParties).toHaveLength(1);
  expect(wrapper).toMatchSnapshot();
  wrapper.unmount();
  expect(responsiviser.mqwatcher.interestedParties).toHaveLength(0);
});

it('renders medium', () => {
  const ResponsiveComponent = responsiviser()(SomeComponent);
  const wrapper = mount(<ResponsiveComponent/>);
  expect(wrapper).toMatchSnapshot();   // large
  resizeWindow(700);
  expect(wrapper).toMatchSnapshot();  // medium
  wrapper.unmount();
});
