/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

const I18n = useI18nScope('select_content_dialog')

export default class {
  static contentPlacements = ['resource_selection']

  static contentMessageTypes = ['ContentItemSelectionRequest', 'LtiDeepLinkingRequest']

  static isContentMessage(placement: {message_type: string}, placements = {}) {
    const message_type = placement && placement.message_type

    return (
      this.contentPlacements.some(p => Object.keys(placements).includes(p)) ||
      this.contentMessageTypes.includes(message_type)
    )
  }

  static errorForUrlItem(
    item: {
      '@type'?: string
      url?: string
    },
    expectedType = 'LtiLinkItem'
  ) {
    if (item['@type'] !== expectedType) {
      return I18n.t('Error: The tool returned an invalid content type "%{contentType}"', {
        contentType: item['@type'],
      })
    }

    if (!item.url) {
      return I18n.t('Error: The tool did not return a URL to Canvas')
    }

    return I18n.t('Error embedding content from tool')
  }
}
