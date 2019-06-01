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

import I18n from 'i18n!external_toolsdeepLinking'
import $ from 'jquery'

export function handleContentItem(result, contentView, callback) {
  contentView.trigger('ready', {contentItems: [legacyContentItem(result)]})
  callback()
}

export function handleDeepLinkingError(e, contentView, reloadTool) {
  $.flashError(I18n.t('Error retrieving content'))
  console.error(e)
  reloadTool(contentView.model.id)
}

function legacyContentItem(ltiAdvantageContentItem) {
  const types = {
    ltiResourceLink: 'LtiLinkItem',
    file: 'FileItem'
  }
  const {type, title, text, icon, url} = ltiAdvantageContentItem
  const legacyType = types[type]

  if (!legacyType) {
    throw `Unknown type: ${type}`
  }

  return {
    '@type': legacyType,
    title,
    text,
    url,
    thumbnail: {
      '@id': icon
    }
  }
}
