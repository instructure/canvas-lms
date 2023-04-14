/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import $ from 'jquery'

if (!('INST' in window)) window.INST = {}

class Client {
  // Is truthy if PandaPub is enabled.
  //
  enabled = INST.pandaPubSettings

  constructor() {
    this.subscribe = this.subscribe.bind(this)
    this.on = this.on.bind(this)
    this.authExtension = this.authExtension.bind(this)
    this.faye = null
    this.tokens = {}
  }

  // Subscribe to a channel with a token. Returns an object
  // which can receive a .cancel() call in order to unsubscribe.
  // That object is also a Deferred, to find out when the subscription
  // is successful or failed.
  //
  subscribe = (channel, token, cb) => {
    const fullChannel = `/${INST.pandaPubSettings.application_id}${channel}`

    this.tokens[fullChannel] = token

    const dfd = new $.Deferred()
    dfd.cancel = function () {}

    this.client(faye => {
      const subscription = faye.subscribe(fullChannel, message => cb(message))

      subscription.then(dfd.resolve, dfd.reject)
      return (dfd.cancel = () => subscription.cancel())
    })

    return dfd
  }

  // Subscribe to transport-level events, transport:down or
  // transport:up. See http://faye.jcoglan.com/browser/transport.html
  on = (event, cb) => this.client(faye => faye.on(event, cb))

  // @api private
  authExtension = () => {
    return {
      outgoing: (message, cb) => {
        if (message.channel === '/meta/subscribe') {
          if (message.subscription in this.tokens) {
            ;(message.ext || (message.ext = {})).auth = {
              token: this.tokens[message.subscription],
            }
          }
        }
        return cb(message)
      },
    }
  }

  // Creates or returns the internal Faye client, loading it first
  // if necessary.
  //
  // @api private
  client(cb) {
    if (this.faye) cb(this.faye)

    if (!this.faye) {
      $.getScript(`${INST.pandaPubSettings.push_url}/client.js`, () => {
        this.faye = new window.Faye.Client(INST.pandaPubSettings.push_url)
        this.faye.addExtension(this.authExtension())
        cb(this.faye)
      })
    }
  }
}

// We return a singleton instance of our client.
export default new Client()
