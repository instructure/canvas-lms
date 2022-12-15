/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
 * Transforms `externalContentReady` postMessages from child windows
 * into the custom jQuery `externalContentReady` event that the rest
 * of the Canvas frontend is expecting.
 *
 * This prevents errors when the external_content_success code that gets
 * rendered in a child window after an LTI tool redirects back to Canvas
 * tries to reference stuff on its parent Window, and suddenly that window
 * may or may not be cross-origin.
 *
 * In an ideal world, all consumers of this jQuery event are taught to instead
 * consume the postMessage, and then this can be removed.
 */
export function up() {
  window.addEventListener('message', event => {
    if (
      event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
      event.data?.subject === 'externalContentReady'
    ) {
      const e = $.Event('externalContentReady')
      e.contentItems = event.data.contentItems
      e.service_id = event.data.service_id
      e.service = event.data.service

      $(window).trigger('externalContentReady', e)
    }

    if (
      event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
      event.data?.subject === 'externalContentCancel'
    ) {
      $(window).trigger('externalContentCancel')
    }
  })
}
