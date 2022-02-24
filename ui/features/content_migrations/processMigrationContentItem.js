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
import I18n from 'i18n!content_migrations'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'
import '@canvas/rails-flash-notifications'

export default function processMigrationContentItem(event) {
  if (
    event.origin !== ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN ||
    event.data.messageType !== 'LtiDeepLinkingResponse'
  ) {
    return
  }

  processSingleContentItem(event)
    .then(result => {
      if (result.type !== 'file') {
        throw new Error(`Expected type "file" but received "${result.type}"`)
      }

      $(window).trigger('externalContentReady', {
        contentItems: [
          {
            text: result.text,
            url: result.url
          }
        ]
      })
    })
    .catch(error => {
      $.flashError(I18n.t('Error retrieving content'))
      $(window).trigger('externalContentCancel')
      console.error(error)
    })
}
