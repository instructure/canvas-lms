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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('external_toolsdeepLinking')

export function handleContentItem(result, contentView, callback) {
  contentView.trigger('ready', {contentItems: [legacyContentItem(result)]})
  callback()
}

export function handleDeepLinkingError(e, contentView, reloadTool) {
  $.flashError(I18n.t('Error retrieving content'))
  // eslint-disable-next-line no-console
  console.error(e)
  captureException(e)
  reloadTool(contentView.model.id)
}

function legacyContentItem(ltiAdvantageContentItem) {
  const types = {
    ltiResourceLink: 'LtiLinkItem',
    file: 'FileItem',
  }
  const {type, title, text, icon, url, lookup_uuid} = ltiAdvantageContentItem
  const legacyType = types[type]

  if (!legacyType) {
    throw new Error(`Unknown type: ${type}`)
  }

  const contentItem = {
    '@type': legacyType,
    title,
    text,
    url,
    thumbnail: {
      '@id': icon,
    },
  }

  if (type === 'ltiResourceLink' && lookup_uuid) {
    contentItem.lookup_uuid = lookup_uuid
  }

  return contentItem
}
