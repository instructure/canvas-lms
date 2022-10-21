//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

let activeLocale = 'en-US'

export const setLocale = locale => {
  const locale_map = {zh_Hant: 'zh-Hant'}
  activeLocale = locale_map[locale] || locale
}

export default {
  strings(x, y) {
    // if you change these settings, also match the settings in best_unicode_collation_key
    // and Canvas::ICU.collator
    return x.localeCompare(y, activeLocale, {
      sensitivity: 'variant',
      ignorePunctuation: false,
      numeric: true,
    })
  },

  by(f) {
    return (x, y) => this.strings(f(x), f(y))
  },

  byKey(key) {
    return this.by(x => x[key])
  },

  byGet(key) {
    return this.by(x => x.get(key))
  },
}
