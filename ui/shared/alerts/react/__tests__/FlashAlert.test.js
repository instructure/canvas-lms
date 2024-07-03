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

import {destroyContainer, showFlashAlert, showFlashError, showFlashSuccess} from '../FlashAlert'
import sinon from 'sinon'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

const ok = x => expect(x).toBeTruthy()
const strictEqual = (x, y) => expect(x).toStrictEqual(y)
const notStrictEqual = (x, y) => expect(x).not.toBe(y)

injectGlobalAlertContainers()

let clock
const ids = ['flash_screenreader_holder', 'flashalert_message_holder', 'flash-messages']

describe('FlashAlert', () => {
  beforeEach(() => {
    clock = sinon.useFakeTimers()

    for (let i = 0; i < ids.length; i++) {
      const el = document.createElement('div')
      el.setAttribute('role', 'alert')
      el.id = ids[i]
      document.body.appendChild(el)
    }
  })

  afterEach(() => {
    // ensure the automatic close timeout (10000ms) has elapsed
    // add 500ms for the animation
    // add 10ms for cushion
    clock.tick(10510)
    clock.restore()

    // remove the screenreader alert holder or railsFlashNotificationsHelperSpec can fail
    const sralertholder = document.getElementById('flash_screenreader_holder')
    if (sralertholder) {
      sralertholder.parentElement.removeChild(sralertholder)
    }

    for (let i = 0; i < ids.length; i++) {
      const el = document.getElementById(ids[i])
      el?.remove()
    }
  })

  function callShowFlashAlert(props = {}, disableToastTimeouts = false) {
    if (disableToastTimeouts) {
      ENV.flashAlertTimeout = 86400000
    }

    const defaultProps = {
      message: 'Example Message',
    }
    showFlashAlert({...defaultProps, ...props})
  }

  describe('.showFlashAlert', () => {
    it.skip('closes after 11 seconds, respecting timeout if ENV.flashAlertTimeout is not set', () => {
      callShowFlashAlert()
      clock.tick(11000)
      strictEqual(document.querySelector('#flashalert_message_holder').innerHTML, '')
    })

    it('does not close after 11 seconds if ENV.flashAlertTimeout is set', () => {
      callShowFlashAlert({}, true)
      clock.tick(11000)
      notStrictEqual(document.querySelector('#flashalert_message_holder').innerHTML, '')
    })

    it('has no effect when the container element has been removed', () => {
      callShowFlashAlert()
      destroyContainer()
      clock.tick(11000)
      ok('no error was thrown')
    })

    // passes in Jest, fails in QUnit
    it.skip('applies the "clickthrough-container" class to the container element', () => {
      callShowFlashAlert()
      ok(
        document
          .getElementById('flashalert_message_holder')
          .classList.contains('clickthrough-container')
      )
      clock.tick(11000)
    })
  })

  describe('.showFlashError', () => {
    // passes in Jest, fails in QUnit
    it.skip('renders an alert with a default message', () => {
      showFlashError()()
      clock.tick(600)
      const expectedText = 'An error occurred making a network request'
      ok(document.querySelector('#flashalert_message_holder').innerText.includes(expectedText))
      clock.tick(500) // tick to close the alert with timeout
    })
  })

  describe('.showFlashSuccess', () => {
    // passes in Jest, fails in QUnit
    it.skip('renders an alert with a given message', () => {
      const expectedText = 'hello world'
      showFlashSuccess(expectedText)()
      clock.tick(600)
      ok(document.querySelector('#flashalert_message_holder').innerText.includes(expectedText))
      clock.tick(500) // tick to close the alert with timeout
    })

    // passes in Jest, fails in QUnit
    it.skip('renders an alert without "Details"', () => {
      showFlashSuccess('yay!')({body: 'a body'})
      clock.tick(600)
      strictEqual(
        document.querySelector('#flashalert_message_holder').innerText.includes('Details'),
        false
      )
      clock.tick(500) // tick to close the alert with timeout
    })
  })
})
