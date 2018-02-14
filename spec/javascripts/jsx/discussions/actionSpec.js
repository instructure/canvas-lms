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
import $ from 'jquery';
import 'compiled/jquery.rails_flash_notifications'
import actions from 'jsx/discussions/actions'
import * as apiClient from 'jsx/discussions/apiClient'

let sandbox = null

const mockApiClient = (method, res) => {
  sandbox = sinon.sandbox.create()
  sandbox.stub(apiClient, method).returns(res)
}

const mockSuccess = (method, data = {}) => mockApiClient(method, Promise.resolve(data))
const mockFail = (method, err = new Error('Request Failed')) => mockApiClient(method, Promise.reject(err))

QUnit.module('Discussion toggleSubscriptionState actions', {
  setup () {
    this.dispatchSpy = sinon.spy()
    this.getState = () => ({foo: 'bar'})
  },

  teardown () {
    if (sandbox) sandbox.restore()
    sandbox = null
  }
})

test('does not call the API if the discussion has a subscription_hold', function() {
  const discussion = { subscription_hold: 'test hold' }
  actions.toggleSubscriptionState(discussion)(this.dispatchSpy, this.getState)
  equal(this.dispatchSpy.callCount, 0)
})

test('calls unsubscribeFromTopic if the discussion is currently subscribed', function() {
  const discussion = { id: 1, subscribed: true }
  mockSuccess('unsubscribeFromTopic', {})
  actions.toggleSubscriptionState(discussion)(this.dispatchSpy, this.getState)
  equal(apiClient.unsubscribeFromTopic.callCount, 1)
  deepEqual(apiClient.unsubscribeFromTopic.firstCall.args, [this.getState(), discussion])
})

test('calls subscribeToTopic if the discussion is currently unsubscribed', function() {
  const discussion = { id: 1, subscribed: false }
  mockSuccess('subscribeToTopic', {})
  actions.toggleSubscriptionState(discussion)(this.dispatchSpy, this.getState)
  equal(apiClient.subscribeToTopic.callCount, 1)
  deepEqual(apiClient.subscribeToTopic.firstCall.args, [this.getState(), discussion])
})

test('dispatches toggleSubscribeSuccess with unsubscription status if currently subscribed', function(assert) {
  const done = assert.async()
  const discussion = { id: 1, subscribed: true }
  mockSuccess('unsubscribeFromTopic', {})
  actions.toggleSubscriptionState(discussion)(this.dispatchSpy, this.getState)

  setTimeout(() => {
    const expectedArgs = [{
      payload: { id: 1, subscribed: false },
      type: "TOGGLE_SUBSCRIBE_SUCCESS"
    }]
    deepEqual(this.dispatchSpy.secondCall.args, expectedArgs)
    done()
  })
})

test('dispatches toggleSubscribeSuccess with subscription status if currently unsubscribed', function(assert) {
  const done = assert.async()
  const discussion = { id: 1, subscribed: false }
  mockSuccess('subscribeToTopic', {})
  actions.toggleSubscriptionState(discussion)(this.dispatchSpy, this.getState)

  setTimeout(() => {
    const expectedArgs = [{
      payload: { id: 1, subscribed: true },
      type: "TOGGLE_SUBSCRIBE_SUCCESS"
    }]
    deepEqual(this.dispatchSpy.secondCall.args, expectedArgs)
    done()
  })
})

test('dispatches toggleSubscribeFail in an error occures on the API call', function(assert) {
  const done = assert.async()
  const flashStub = sinon.spy($, 'screenReaderFlashMessageExclusive')
  const discussion = { id: 1, subscribed: false }

  mockFail('subscribeToTopic', "test error message")
  actions.toggleSubscriptionState(discussion)(this.dispatchSpy, this.getState)

  setTimeout(() => {
    const expectedArgs = [{
      payload: { message: 'Subscribe failed', err: "test error message" },
      type: "TOGGLE_SUBSCRIBE_FAIL"
    }]
    deepEqual(this.dispatchSpy.secondCall.args, expectedArgs)
    deepEqual(flashStub.firstCall.args, ["Subscribe failed"]);
    flashStub.restore()
    done()
  })
})
