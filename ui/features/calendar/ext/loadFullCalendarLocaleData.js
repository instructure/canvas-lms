/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export default function loadFullCalendarLocaleData(locale) {
  // get it from node_modules/fullcalendar/dist/locale/
  const FULLCALENDAR_LOCALES = [
    'ar',
    'ar-ma',
    'ar-sa',
    'ar-tn',
    'bg',
    'ca',
    'cs',
    'da',
    'de',
    'de-at',
    'el',
    'en-au',
    'en-ca',
    'en-gb',
    'es',
    'fa',
    'fi',
    'fr',
    'fr-ca',
    'he',
    'hi',
    'hr',
    'hu',
    'id',
    'is',
    'it',
    'ja',
    'ko',
    'lt',
    'lv',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt-br',
    'ro',
    'ru',
    'sk',
    'sl',
    'sr',
    'sr-cyrl',
    'sv',
    'th',
    'tr',
    'uk',
    'vi',
    'zh-cn',
    'zh-tw',
  ]

  if (locale === 'ga') {
    return import('../../../ext/custom_fullcalendar_locales/ga')
  } else if (!FULLCALENDAR_LOCALES.includes(locale)) {
    return Promise.resolve()
  }

  return import(`fullcalendar/dist/locale/${locale}.js`).then(() => {
    // fullcalendar's locale bundle configures moment's locales too and overrides
    // ours..
    //
    // Since such a workaround did not exist prior to introducing the Catalan
    // language support, I'm assuming it's not affecting other languages. If that
    // turns out not to be the case, though, either extend this or revisit the
    // whole approach (e.g. import fullcalendar's locales earlier in the build)
    if (locale === 'ca') {
      return import('../../../ext/custom_moment_locales/ca').then(
        ({default: reconfigureMomentCALocale}) => {
          reconfigureMomentCALocale()
        }
      )
    }
  })
}
