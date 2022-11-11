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

import {getLocaleList} from '../getTranslations'

// keys = "qualified" locales old canvas sent, values = corresponding standard
// locales that canvas now sends. old locales absent from this mapping (e.g.
// pt-BR) didn't change.
const mapping = {
  fa: 'fa-IR',
  uk: 'uk-UA',
  'zh-CN': 'zh-Hans',
  'zh-HK': 'zh-Hant',
}

export default function normalizeLocale(locale) {
  const recognized = getLocaleList()
  if (!locale) {
    // default to english
    return 'en'
  } else if (recognized.indexOf(locale) >= 0) {
    // pass through recognized locales
    return locale
  } else if (mapping[locale]) {
    // translate recognized old-style locale to standard style
    return mapping[locale]
  } else if (locale.match('-x-')) {
    // reduce unrecognized custom locales to their base locale
    locale = locale.split('-x-')[0]
    return normalizeLocale(locale)
  } else if (recognized.indexOf(locale.split('-')[0]) >= 0) {
    return locale.split('-')[0]
  } else {
    // default to english for unrecognized locales
    return 'en'
  }
}
