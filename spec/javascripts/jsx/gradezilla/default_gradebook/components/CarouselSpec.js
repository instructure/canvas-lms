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

import React from 'react';
import { mount } from 'enzyme';
import Carousel from 'jsx/gradezilla/default_gradebook/components/Carousel';

function mountComponent (props) {
  const defaultProps = {
    children: 'Book Report',
    disabled: false,
    displayLeftArrow: false,
    displayRightArrow: false,
    leftArrowDescription: 'Previous',
    onLeftArrowClick () {},
    onRightArrowClick () {},
    rightArrowDescription: 'Next'
  };

  const tbody = document.createElement('div');
  tbody.id = 'carousel-tbody';
  document.body.appendChild(tbody);

  return mount(<Carousel {...defaultProps} {...props} />, { attachTo: tbody });
}

QUnit.module('Carousel', {
  teardown () {
    this.wrapper.detach();
    document.getElementById('carousel-tbody').remove();
  }
});

test('renders children', function () {
  this.wrapper = mountComponent();
  strictEqual(this.wrapper.text(), 'Book Report');
});

test('does not render left arrow when displayLeftArrow is false', function () {
  this.wrapper = mountComponent();
  strictEqual(this.wrapper.find('.left-arrow-button-container button').length, 0);
});

test('renders left arrow when displayLeftArrow is true', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true });
  strictEqual(this.wrapper.find('.left-arrow-button-container button').length, 1);
});

test('does not render right arrow when displayRightArrow is false', function () {
  this.wrapper = mountComponent();
  strictEqual(this.wrapper.find('.right-arrow-button-container button').length, 0);
});

test('renders right arrow when displayRightArrow is true', function () {
  this.wrapper = mountComponent({ displayRightArrow: true });
  strictEqual(this.wrapper.find('.right-arrow-button-container button').length, 1);
});

test('calls onLeftArrowClick when left arrow is clicked', function () {
  const onLeftArrowClick = this.stub();
  this.wrapper = mountComponent({ displayLeftArrow: true, onLeftArrowClick });
  this.wrapper.find('.left-arrow-button-container button').simulate('click');
  strictEqual(onLeftArrowClick.callCount, 1);
});

test('calls onRightArrowClick when right arrow is clicked', function () {
  const onRightArrowClick = this.stub();
  this.wrapper = mountComponent({ displayRightArrow: true, onRightArrowClick });
  this.wrapper.find('.right-arrow-button-container button').simulate('click');
  strictEqual(onRightArrowClick.callCount, 1);
});

test('focuses right arrow on right arrow click when both arrows are displayed', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, displayRightArrow: true });
  const rightArrow = this.wrapper.instance().rightArrow;
  this.wrapper.find('.right-arrow-button-container button').simulate('click');
  strictEqual(rightArrow.focused, true);
});

test('focuses left arrow on left arrow click when both arrows are displayed', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, displayRightArrow: true });
  const leftArrow = this.wrapper.instance().leftArrow;
  this.wrapper.find('.left-arrow-button-container button').simulate('click');
  strictEqual(leftArrow.focused, true);
});

test('focuses left arrow when transitioning from displaying both arrows to only the left arrow', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, displayRightArrow: true });
  const instance = this.wrapper.instance();
  const leftArrow = instance.leftArrow;
  this.wrapper.setProps({ displayRightArrow: false });
  strictEqual(leftArrow.focused, true);
});

test('focuses right arrow when transitioning from displaying both arrows to only the right arrow', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, displayRightArrow: true });
  const instance = this.wrapper.instance();
  const rightArrow = instance.rightArrow;
  this.wrapper.setProps({ displayLeftArrow: false });
  strictEqual(rightArrow.focused, true);
});

test('left button is not disabled', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, disabled: false });
  strictEqual(this.wrapper.find('Button').prop('disabled'), false);
});

test('right button is not disabled', function () {
  this.wrapper = mountComponent({ displayRightArrow: true, disabled: false });
  strictEqual(this.wrapper.find('Button').prop('disabled'), false);
});

test('left button can be disabled', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, disabled: true });
  strictEqual(this.wrapper.find('Button').prop('disabled'), true);
});

test('right button is not disabled', function () {
  this.wrapper = mountComponent({ displayRightArrow: true, disabled: true });
  strictEqual(this.wrapper.find('Button').prop('disabled'), true );
});

test('adds a VO description for the left arrow button', function () {
  this.wrapper = mountComponent({ displayLeftArrow: true, leftArrowDescription: 'Previous record' });
  strictEqual(this.wrapper.find('IconArrowOpenLeftLine').prop('title'), 'Previous record');
});

test('adds a VO description for the right arrow button', function () {
  this.wrapper = mountComponent({ displayRightArrow: true, rightArrowDescription: 'Next record' });
  strictEqual(this.wrapper.find('IconArrowOpenRightLine').prop('title'), 'Next record');
});
