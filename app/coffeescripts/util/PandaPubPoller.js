//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import pandapub from '../PandaPub'
import $ from 'jquery'

// This class handles the common logic of "use PandaPub when available,
// otherwise poll".

export default class PandaPubPoller {
  // Create a new PandaPubPoller.
  //
  // @pollInterval (ms) - How long to poll when pandapub is disabled
  // @rarePollInterval (ms) - How long to poll when pandapub is enabled
  // @pollCB - The function to call when we should poll. Normally this will
  //   wrap your normal poll method. It is passed another function that should
  //   be called when the poll is complete.

  constructor (pollInterval, rarePollInterval, pollCB) {
    this.pollInterval = pollInterval
    this.rarePollInterval = rarePollInterval
    this.pollCB = pollCB
    this.running = false
    this.lastUpdate = null

    // make sure our timer doesn't fire again as leaving the page
    // workaround for https://code.google.com/p/chromium/issues/detail?id=263981
    $(window).on('beforeunload', () => {
      if (this.timeout) this.stopTimeout()
    })
  }

  // Configures the PandaPub channel and token.

  setToken = (channel, token) => {
    this.channel = channel
    this.token = token
    if (pandapub.enabled && this.running) this.subscribe()
  }

  // Set the function to call when data is received via the streaming
  // channel.

  setOnData = (streamingCB) => {
    this.streamingCB = streamingCB
  }

  // Starts polling/streaming.

  start = () => {
    this.lastUpdate = Date.now()
    this.running = true
    this.startTimeout()
    if (pandapub.enabled) this.subscribe()
  }

  // Stop polling/streaming.

  stop = () => {
    this.stopTimeout()
    if (pandapub.enabled) this.unsubscribe()
    this.running = false
  }

  isRunning = () => this.running

  // Start the timeout that schedules the periodic polling consideration.
  //
  // @api private

  startTimeout = () => this.timeout = setTimeout(this.considerPoll, this.pollInterval)


  // Stop the timeout
  //
  // @api private

  stopTimeout = () => clearTimeout(this.timeout)

  // Triggers a poll based on time passed since last data received, and
  // whether pandapub is enabled
  //
  // @api private

  considerPoll = () => {
    let interval = this.pollInterval

    if (pandapub.enabled) {
      interval = this.rarePollInterval
    }

    if (Date.now() - this.lastUpdate >= interval) {
      return this.pollCB(this.pollDone)
    } else {
      return this.startTimeout()
    }
  }

  // Fired when a poll completes
  //
  // @api private

  pollDone = () => {
    this.lastUpdate = Date.now()
    this.startTimeout()
  }

  subscribe = () => {
    // TODO: make this smart so you can update credentials periodically
    if (this.subscription) return

    // don't attempt to subscribe until we get a channel and a token
    if (!this.channel || !this.token) return

    this.subscription = pandapub.subscribe(this.channel, this.token, (message) => {
      this.lastUpdate = Date.now()
      this.streamingCB(message)
    })
  }

  unsubscribe = () => {
    if (this.subscription) this.subscription.cancel()
  }
}
