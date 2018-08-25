/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import createStore from 'jsx/account_course_user_search/store/createStore'
import $ from 'jquery'
import ajaxJSON from 'jquery.ajaxJSON'
import sinon from 'sinon'

QUnit.module('account course user search createStore', hooks => {
  let store
  let testXhr

  hooks.beforeEach(() => {
    store = createStore({ getUrl: () => 'store-url' })
    sinon.stub(ajaxJSON, 'abortRequest')
  })

  hooks.afterEach(() => {
    $.ajax.restore()
    ajaxJSON.abortRequest.restore()
  })

  test('load aborts previous load request', () => {
    testXhr = { then: () => {} }
    sinon.stub($, 'ajax').returns(testXhr)
    store.load({})
    store.load({})
    ok(ajaxJSON.abortRequest.calledWith(undefined))
    ok(ajaxJSON.abortRequest.calledWith(testXhr))
  })

  test('load does not set the error flag if the request is aborted', () => {
    testXhr = { then: (success, failure) => {
      failure({}, 'abort');
    } }
    sinon.stub($, 'ajax').returns(testXhr)
    store.load({});
    ok(!store.getState()['{}'].error)
  });

  test('load sets the error flag on non-abort failures', () => {
    testXhr = { then: (success, failure) => {
      failure({}, 'error');
    } }
    sinon.stub($, 'ajax').returns(testXhr)
    store.load({});
    ok(store.getState()['{}'].error)
  });
})


