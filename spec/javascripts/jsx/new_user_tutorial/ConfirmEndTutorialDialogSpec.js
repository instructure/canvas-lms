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

/* global QUnit */
define([
  'jquery',
  'react',
  'enzyme',
  'axios',
  'moxios',
  'jsx/new_user_tutorial/ConfirmEndTutorialDialog',
], ($, React, { shallow, mount }, axios, moxios, ConfirmEndTutorialDialog) => {
  let $appElement;
  QUnit.module('ConfirmEndTutorialDialog Spec', {
    setup () {
      $appElement = $('<div id="application"></div>').appendTo($('#fixtures'));
      moxios.install();
    },
    teardown () {
      $('#fixtures').empty();
      moxios.uninstall();
    }
  });

  const getDefaultProps = () => ({
    isOpen: true,
    handleRequestClose () {}
  });

  test('handleOkayButtonClick calls the proper api endpoint and data', () => {
    const spy = sinon.spy(axios, 'put');
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    wrapper.instance().handleOkayButtonClick();
    ok(spy.calledWith('/api/v1/users/self/features/flags/new_user_tutorial_on_off', { state: 'off'}));
    spy.restore();
  });

  test('handleOkayButtonClick calls onSuccessFunc after calling the api', (assert) => {
    const done = assert.async();
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    const spy = sinon.spy();
    const fakeEvent = {};
    wrapper.instance().handleOkayButtonClick(fakeEvent, spy);
    moxios.wait(() => {
      const request = moxios.requests.mostRecent();
      request.respondWith({ status: 200}).then(() => {
        ok(spy.called);
        done();
      });
    });
  });
});
