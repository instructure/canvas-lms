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

import formatMessage from 'format-message'
import generateId from 'format-message-generate-id/underscored_crc32'

// Create a namespace specifically for canvas-media translations
const canvasMediaFormatter = formatMessage.namespace()

// Configure format-message with Canvas defaults
// This is called automatically on first use to prevent "missing translation" warnings
let isConfigured = false

function configure() {
  if (isConfigured) return

  isConfigured = true
  canvasMediaFormatter.setup({
    locale: (typeof ENV !== 'undefined' && ENV?.LOCALE) || 'en',
    translations: {},
    generateId,
    missingTranslation: 'ignore',
  })
}

// Auto-configure when imported
configure()

// Add a helper to load translations for a specific locale
canvasMediaFormatter.addLocale = translations => {
  const locale = Object.keys(translations)[0]
  const currentConfig = canvasMediaFormatter.setup()

  canvasMediaFormatter.setup({
    ...currentConfig,
    locale,
    translations: {
      ...currentConfig.translations,
      ...translations,
    },
  })
}

export default canvasMediaFormatter
