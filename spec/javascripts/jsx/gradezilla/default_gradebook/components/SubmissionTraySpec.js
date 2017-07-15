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
import SubmissionTray from 'jsx/gradezilla/default_gradebook/components/SubmissionTray';

QUnit.module('SubmissionTray', {
  mountComponent (props) {
    const defaultProps = {
      onRequestClose () {},
      onClose () {},
      showContentComingSoon: false,
      isOpen: true
    };
    return mount(<SubmissionTray {...defaultProps} {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows "Content Coming Soon" content if showContentComingSoon is true', function () {
  const server = sinon.fakeServer.create({ respondImmediately: true });
  server.respondWith('GET', /^\/images\/.*\.svg$/, [
    200, { 'Content-Type': 'img/svg+xml' }, '{}'
  ]);
  this.wrapper = this.mountComponent({ showContentComingSoon: true });
  ok(document.querySelector('.ComingSoonContent__Container'));
  server.restore();
});

test('does not show "Content Coming Soon" content if showContentComingSoon is false', function () {
  this.wrapper = this.mountComponent();
  notOk(document.querySelector('.ComingSoonContent__Container'));
});
