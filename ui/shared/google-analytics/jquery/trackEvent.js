/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

/**
 * Tracks an event using the given parameters.
 *
 * The trackEvent method takes four arguments:
 *
 *  category - required string used to group events
 *  action - required string used to define event type, eg. click, download
 *  label - optional label to attach to event, eg. buy
 *  value - optional numerical value to attach to event, eg. price
 *
 * see: https://developers.google.com/analytics/devguides/collection/analyticsjs/events
 */
export function trackEvent(category, action, label, value) {
  if (window.ga) {
    ;(window.requestIdleCallback || window.setTimeout)(() => {
      // don't ever block anything else going on
      window.ga('send', 'event', category, action, label, value)
    })
  }
}

// we put it on the jQuery object just for backwards compatibility,
// don't use this, use `import {trackEvent} from 'jquery.google-analytics'` instead
$.trackEvent = trackEvent
