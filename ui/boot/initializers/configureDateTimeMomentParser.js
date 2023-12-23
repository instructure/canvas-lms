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

import {useScope as useI18nScope} from '@canvas/i18n'
import {loadI18nFormats} from '@canvas/datetime/moment-parser'

const I18n = useI18nScope('instructure')

const dateFormat = key => () => I18n.lookup(`date.formats.${key}`)

const eventFormat =
  ({date, time}) =>
  () =>
    I18n.t('#time.event', '%{date} at %{time}', {
      date: I18n.lookup(`date.formats.${date}`),
      time: I18n.lookup(`time.formats.${time}`),
    })

const timeFormat = key => () => I18n.lookup(`time.formats.${key}`)

const joinFormats = (separator, formats) => () =>
  formats.map(key => I18n.lookup(key)).join(separator)

export function prepareFormats() {
  // examples are from en_US. order is significant since if an input matches
  // multiple formats, the format earlier in the list will be preferred
  return [
    timeFormat('default'), // %a, %d %b %Y %H:%M:%S %z
    dateFormat('full_with_weekday'), // %a %b %-d, %Y %-l:%M%P
    dateFormat('full'), // %b %-d, %Y %-l:%M%P
    dateFormat('date_at_time'), // %b %-d at %l:%M%P
    dateFormat('long_with_weekday'), // %A, %B %-d
    dateFormat('medium_with_weekday'), // %a %b %-d, %Y
    dateFormat('short_with_weekday'), // %a, %b %-d
    timeFormat('long'), // %B %d, %Y %H:%M
    dateFormat('long'), // %B %-d, %Y
    eventFormat({date: 'medium', time: 'tiny'}),
    eventFormat({date: 'medium', time: 'tiny_on_the_hour'}),
    eventFormat({date: 'short', time: 'tiny'}),
    eventFormat({date: 'short', time: 'tiny_on_the_hour'}),
    joinFormats(' ', ['date.formats.medium', 'time.formats.tiny']),
    joinFormats(' ', ['date.formats.medium', 'time.formats.tiny_on_the_hour']),
    dateFormat('medium'), // %b %-d, %Y
    timeFormat('short'), // %d %b %H:%M
    joinFormats(' ', ['date.formats.short', 'time.formats.tiny']),
    joinFormats(' ', ['date.formats.short', 'time.formats.tiny_on_the_hour']),
    dateFormat('short'), // %b %-d
    dateFormat('default'), // %Y-%m-%d
    timeFormat('tiny'), // %l:%M%P
    timeFormat('tiny_on_the_hour'), // %l%P
    dateFormat('weekday'), // %A
    dateFormat('short_weekday'), // %a
  ]
}

export function up() {
  loadI18nFormats(prepareFormats())
}

export function down() {
  loadI18nFormats([])
}
