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
import { shallow, mount, ReactWrapper } from 'enzyme';
import StatusesModal from 'jsx/gradezilla/default_gradebook/components/StatusesModal';

QUnit.module('StatusesModal', {
  setup () {
    this.wrapper = shallow(<StatusesModal onClose={() => {}} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('modal is initially closed', function () {
  strictEqual(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('modal has a label of "Statuses"', function () {
  equal(this.wrapper.find('Modal').prop('label'), 'Statuses');
});

test('modal has a close button label of "Close"', function () {
  equal(this.wrapper.find('Modal').prop('closeButtonLabel'), 'Close');
});

test('modal has an onRequestClose function', function () {
  equal(typeof this.wrapper.find('Modal').prop('onRequestClose'), 'function');
});

test('modal has an onExited function', function () {
  equal(typeof this.wrapper.find('Modal').prop('onRequestClose'), 'function');
});

test('modal has a "Statuses" header', function () {
  equal(this.wrapper.find('Heading').children().text(), 'Statuses');
});

test('modal has a "Done" button', function () {
  equal(this.wrapper.find('Button').children().text(), 'Done');
});

test('modal contains late status', function () {
  ok(this.wrapper.find('li').children().contains('Late'));
});

test('modal contains missing status', function () {
  ok(this.wrapper.find('li').children().contains('Missing'));
});

test('modal contains resubmitted status', function () {
  ok(this.wrapper.find('li').children().contains('Resubmitted'));
});

test('modal contains dropped status', function () {
  ok(this.wrapper.find('li').children().contains('Dropped'));
});

test('modal contains excused status', function () {
  ok(this.wrapper.find('li').children().contains('Excused'));
});

test('modal opens', function () {
  const wrapper = mount(<StatusesModal onClose={() => {}} />);
  wrapper.get(0).open();
  strictEqual(wrapper.find('Modal').prop('isOpen'), true);
  wrapper.unmount();
});

test('modal closes', function () {
  const wrapper = mount(<StatusesModal onClose={() => {}} />);
  wrapper.get(0).open();
  wrapper.get(0).close();
  strictEqual(wrapper.find('Modal').prop('isOpen'), false);
  wrapper.unmount();
});

test('clicking done closes modal', function () {
  const wrapper = mount(<StatusesModal onClose={() => {}} />);
  const component = wrapper.instance();
  component.open();
  const doneButton = new ReactWrapper(component.doneButton, component.doneButton);
  doneButton.simulate('click');
  strictEqual(wrapper.find('Modal').prop('isOpen'), false);
});

test('clicking the close button closes modal', function () {
  const wrapper = mount(<StatusesModal onClose={() => {}} />);
  const component = wrapper.instance();
  component.open();
  const closeButton = new ReactWrapper(component.closeButton, component.closeButton);
  closeButton.simulate('click');
  strictEqual(wrapper.find('Modal').prop('isOpen'), false);
});

test('on close prop is passed to Modal onExit', function () {
  const onCloseStub = this.stub();
  const wrapper = mount(<StatusesModal onClose={onCloseStub} />);
  equal(wrapper.find('Modal').prop('onExited'), onCloseStub);
});
