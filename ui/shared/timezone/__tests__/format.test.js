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

import tz, { configure } from '../'
import timezone from 'timezone/index'
import french from 'timezone/fr_FR'
import AmericaDenver from 'timezone/America/Denver'
import AmericaChicago from 'timezone/America/Chicago'
import { setup, I18nStubber, moonwalk, epoch, equal } from './helpers'

setup(this)

test('format() should format relative to UTC by default', () =>
  equal(tz.format(moonwalk, '%F %T%:z'), '1969-07-21 02:56:00+00:00'))

test('format() should format in en_US by default', () =>
  equal(tz.format(moonwalk, '%c'), 'Mon 21 Jul 1969 02:56:00 AM UTC'))

test('format() should parse the value if necessary', () =>
  equal(tz.format('1969-07-21 02:56', '%F %T%:z'), '1969-07-21 02:56:00+00:00'))

test('format() should return null if the parse fails', () =>
  equal(tz.format('bogus', '%F %T%:z'), null))

test('format() should return null if the format string is unrecognized', () =>
  equal(tz.format(moonwalk, 'bogus'), null))

test('format() should preserve 12-hour+am/pm if the locale does define am/pm', () => {
  const time = tz.parse('1969-07-21 15:00:00')
  equal(tz.format(time, '%-l%P'), '3pm')
  equal(tz.format(time, '%I%P'), '03pm')
  equal(tz.format(time, '%r'), '03:00:00 PM')
})

test("format() should promote 12-hour+am/pm into 24-hour if the locale doesn't define am/pm", () => {
  configure({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr',
  })

  const time = tz.parse('1969-07-21 15:00:00')

  equal(tz.format(time, '%-l%P'), '15')
  equal(tz.format(time, '%I%P'), '15')
  equal(tz.format(time, '%r'), '15:00:00')
})

test("format() should use a specific timezone when asked", () => {
  configure({
    tz: timezone,
    tzData: {
      'America/Denver': AmericaDenver,
      'America/Chicago': AmericaChicago,
    }
  })

  const time = tz.parse('1969-07-21 15:00:00')
  equal(tz.format(time, '%-l%P', 'America/Denver'), '9am')
  equal(tz.format(time, '%-l%P', 'America/Chicago'), '10am')
})

test('format() should recognize date.formats.*', () => {
  I18nStubber.stub('en', {'date.formats.short': '%b %-d'})
  equal(tz.format(moonwalk, 'date.formats.short'), 'Jul 21')
})

test('format() should recognize time.formats.*', () => {
  I18nStubber.stub('en', {'time.formats.tiny': '%-l:%M%P'})
  equal(tz.format(epoch, 'time.formats.tiny'), '12:00am')
})

test('format() should localize when given a localization key', () => {
  configure({
    tz: timezone('fr_FR', french),
    momentLocale: 'fr'
  })

  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {'date.formats.full': '%-d %b %Y %-l:%M%P'})
  equal(tz.format(moonwalk, 'date.formats.full'), '21 juil. 1969 2:56')
})

test('format() should automatically convert %l to %-l when given a localization key', () => {
  I18nStubber.stub('en', {'time.formats.tiny': '%l:%M%P'})
  equal(tz.format(moonwalk, 'time.formats.tiny'), '2:56am')
})

test('format() should automatically convert %k to %-k when given a localization key', () => {
  I18nStubber.stub('en', {'time.formats.tiny': '%k:%M'})
  equal(tz.format(moonwalk, 'time.formats.tiny'), '2:56')
})

test('format() should automatically convert %e to %-e when given a localization key', () => {
  I18nStubber.stub('en', {'date.formats.short': '%b %e'})
  equal(tz.format(epoch, 'date.formats.short'), 'Jan 1')
})
