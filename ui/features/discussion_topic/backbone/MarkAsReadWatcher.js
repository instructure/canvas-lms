//
// Copyright (C) 2012 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import _, {extend, throttle} from 'lodash'

// An entry needs to be in the viewport for 2 consecutive secods for it to be marked as read
// if you are scrolling quickly down the page and it comes in and out of the viewport in less
// than 2 seconds, it will not count as being read
const MS_UNTIL_READ = 2000
const CHECK_THROTTLE = 1000
const $window = $(window)

// #
// Watches an EntryView position to determine whether or not to mark it
// as read
class MarkAsReadWatcher {
  static unread = []

  // #
  // @param {EntryView} view
  constructor(view) {
    this.view = view
    MarkAsReadWatcher.unread.push(this)
    this.view.model.bind('change:collapsedView', (model, collapsedView) => {
      this.ignore = collapsedView
      if (collapsedView) {
        return this.clearTimer()
      }
    })
  }

  createTimer() {
    return this.timer || (this.timer = setTimeout(this.markAsRead, MS_UNTIL_READ))
  }

  clearTimer() {
    clearTimeout(this.timer)
    return delete this.timer
  }

  markAsRead = () => {
    this.view.model.markAsRead()
    MarkAsReadWatcher.unread = _(MarkAsReadWatcher.unread).without(this)
    return MarkAsReadWatcher.trigger('markAsRead', this.view.model)
  }

  static init() {
    $window.bind('scroll resize', this.checkForVisibleEntries)
    return this.checkForVisibleEntries()
  }

  static checkForVisibleEntries = throttle(() => {
    const topOfViewport = $window.scrollTop()
    const bottomOfViewport = topOfViewport + $window.height()
    MarkAsReadWatcher.unread.forEach(entry => {
      if (entry.ignore || entry.view.model.get('forced_read_state')) return
      const topOfElement = entry.view.$el.offset().top
      const inView =
        topOfElement < bottomOfViewport && topOfElement + entry.view.$el.height() > topOfViewport
      entry[inView ? 'createTimer' : 'clearTimer']()
    })
  }, CHECK_THROTTLE)
}

export default extend(MarkAsReadWatcher, Backbone.Events)
