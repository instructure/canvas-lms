/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {configure} from '@canvas/datetime'
import timezone from 'timezone'
import en_US from 'timezone/en_US'
import I18n from '@canvas/i18n'

export function up() {
  const tzData = window.__PRELOADED_TIMEZONE_DATA__ || {}

  let userTZ = timezone(en_US, 'en_US', 'UTC')

  // These timezones and locales should already be put on the page as <script>
  // tags from rails. this block should not create any network requests.
  if (window.ENV && ENV.TIMEZONE && tzData[ENV.TIMEZONE]) {
    userTZ = userTZ(tzData[ENV.TIMEZONE], ENV.TIMEZONE)
  }

  if (window.ENV && ENV.BIGEASY_LOCALE && tzData[ENV.BIGEASY_LOCALE]) {
    userTZ = userTZ(tzData[ENV.BIGEASY_LOCALE], ENV.BIGEASY_LOCALE)
  }

  configure({
    tz: userTZ,
    tzData,
    momentLocale: (window.ENV && ENV.MOMENT_LOCALE) || 'en',
    formats: getI18nFormats(),
  })
}

export function down() {
  configure({})
}

export function getI18nFormats() {
  return {
    'date.formats.date_at_time': I18n.lookup('date.formats.date_at_time'),
    'date.formats.default': I18n.lookup('date.formats.default'),
    'date.formats.full': I18n.lookup('date.formats.full'),
    'date.formats.full_with_weekday': I18n.lookup('date.formats.full_with_weekday'),
    'date.formats.long': I18n.lookup('date.formats.long'),
    'date.formats.long_with_weekday': I18n.lookup('date.formats.long_with_weekday'),
    'date.formats.medium': I18n.lookup('date.formats.medium'),
    'date.formats.medium_month': I18n.lookup('date.formats.medium_month'),
    'date.formats.medium_with_weekday': I18n.lookup('date.formats.medium_with_weekday'),
    'date.formats.short': I18n.lookup('date.formats.short'),
    'date.formats.short_month': I18n.lookup('date.formats.short_month'),
    'date.formats.short_weekday': I18n.lookup('date.formats.short_weekday'),
    'date.formats.short_with_weekday': I18n.lookup('date.formats.short_with_weekday'),
    'date.formats.weekday': I18n.lookup('date.formats.weekday'),
    'time.formats.default': I18n.lookup('time.formats.default'),
    'time.formats.long': I18n.lookup('time.formats.long'),
    'time.formats.short': I18n.lookup('time.formats.short'),
    'time.formats.tiny': I18n.lookup('time.formats.tiny'),
    'time.formats.tiny_on_the_hour': I18n.lookup('time.formats.tiny_on_the_hour'),
  }
}
