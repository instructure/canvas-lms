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
import {useScope as createI18nScope} from '@canvas/i18n'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'
import '@canvas/rails-flash-notifications'
import {
  postMessageExternalContentReady,
  postMessageExternalContentCancel,
} from '@canvas/external-tools/messages'
import {captureException} from '@sentry/react'

const I18n = createI18nScope('content_migrations')

export default function processMigrationContentItem(event) {
  if (
    event.origin !== ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN ||
    event.data.subject !== 'LtiDeepLinkingResponse'
  ) {
    return
  }

  try {
    const result = processSingleContentItem(event)
    if (result === undefined || result === null) {
      if (!event.data.msg && !event.data.errormsg) {
        $.flashWarning(I18n.t('No content was selected'))
      }
      postMessageExternalContentCancel(window)
      return
    }
    if (result.type !== 'file') {
      throw new Error(`Expected type "file" but received "${result.type}"`)
    }

    const contentItems = [{text: result.text, url: result.url}]
    postMessageExternalContentReady(window, {contentItems})
  } catch (error) {
    $.flashError(I18n.t('Error retrieving content'))
    postMessageExternalContentCancel(window)

    console.error(error)
    captureException(error)
  }
}
