/*
 * Copyright (C) 2026 - present Instructure, Inc.
 *
 * This file is part of Canvas Studio.
 *
 * Canvas Studio is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas Studio is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import formatMessage from 'format-message'

const asrSupportedLanguages = [
  {
    id: 'ar',
    get label() {
      return formatMessage('Arabic')
    },
  },
  {
    id: 'zh',
    get label() {
      return formatMessage('Chinese')
    },
  },
  {
    id: 'cs',
    get label() {
      return formatMessage('Czech')
    },
  },
  {
    id: 'da',
    get label() {
      return formatMessage('Danish')
    },
  },
  {
    id: 'nl',
    get label() {
      return formatMessage('Dutch')
    },
  },
  {
    id: 'en',
    get label() {
      return formatMessage('English')
    },
  },
  {
    id: 'fr',
    get label() {
      return formatMessage('French')
    },
  },
  {
    id: 'de',
    get label() {
      return formatMessage('German')
    },
  },
  {
    id: 'it',
    get label() {
      return formatMessage('Italian')
    },
  },
  {
    id: 'ja',
    get label() {
      return formatMessage('Japanese')
    },
  },
  {
    id: 'ko',
    get label() {
      return formatMessage('Korean')
    },
  },
  {
    id: 'lv',
    get label() {
      return formatMessage('Latvian')
    },
  },
  {
    id: 'lt',
    get label() {
      return formatMessage('Lithuanian')
    },
  },
  {
    id: 'no',
    get label() {
      return formatMessage('Norwegian')
    },
  },
  {
    id: 'pl',
    get label() {
      return formatMessage('Polish')
    },
  },
  {
    id: 'pt',
    get label() {
      return formatMessage('Portuguese')
    },
  },
  {
    id: 'ru',
    get label() {
      return formatMessage('Russian')
    },
  },
  {
    id: 'es',
    get label() {
      return formatMessage('Spanish')
    },
  },
  {
    id: 'sv',
    get label() {
      return formatMessage('Swedish')
    },
  },
  {
    id: 'tr',
    get label() {
      return formatMessage('Turkish')
    },
  },
]

function sortedAsrLanguageList(userLocale: string) {
  const ul = userLocale.replace('_', '-')
  const langlist = asrSupportedLanguages.sort((a, b) => {
    if (a.id === ul) {
      return -1
    }
    if (b.id === ul) {
      return 1
    }
    return a.label.localeCompare(b.label, ul)
  })
  return langlist
}

function asrLanguageForLocale(locale: string) {
  return asrSupportedLanguages.find(lang => lang.id === locale)?.label || locale
}

export {sortedAsrLanguageList, asrLanguageForLocale}
