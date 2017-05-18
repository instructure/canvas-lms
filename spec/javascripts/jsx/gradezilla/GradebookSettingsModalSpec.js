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
import GradebookSettingsModal from 'jsx/gradezilla/GradebookSettingsModal';
import $ from 'jquery';

QUnit.module('GradebookSettingsModal', {
  mountComponent (props = { onClose: () => {} }) {
    this.wrapper = mount(
      <GradebookSettingsModal {...props} />
    );
    this.component = this.wrapper.get(0)
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('modal is initially closed', function () {
  this.mountComponent();
  equal(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('calling open causes the modal to be rendered', function () {
  this.mountComponent();
  this.component.open();
  equal(this.wrapper.find('Modal').prop('isOpen'), true);
});

test('calling close closes the modal', function () {
  this.mountComponent();

  this.component.open();
  equal(this.wrapper.find('Modal').prop('isOpen'), true);

  this.component.close();
  equal(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('clicking cancel closes the modal', function () {
  this.mountComponent();

  this.component.open();
  equal(this.wrapper.find('Modal').prop('isOpen'), true);

  $('#gradebook-settings-cancel-button').click();
  equal(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('onClose is passed to modal onExit', function () {
  const onCloseStub = this.stub();
  this.wrapper = mount(<GradebookSettingsModal onClose={onCloseStub} />);
  equal(this.wrapper.find('Modal').prop('onExited'), onCloseStub);
});
