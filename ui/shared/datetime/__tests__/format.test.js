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

import timezone from 'timezone/index'
import french from 'timezone/fr_FR'
import AmericaDenver from 'timezone/America/Denver'
import AmericaChicago from 'timezone/America/Chicago'
import * as tz from '..'
import {configure} from '..'
import {moonwalk, epoch} from './helpers'

describe('format::', () => {
  const oldENV = window.ENV

  beforeEach(() => {
    window.ENV = {LOCALE: 'en'}
  })

  afterEach(() => {
    window.ENV = oldENV
  })

  it('formats relative to UTC by default', () => {
    expect(tz.format(moonwalk, '%F %T%:z')).toBe('1969-07-21 02:56:00+00:00')
  })

  it('formats in en_US by default', () => {
    expect(tz.format(moonwalk, '%c')).toBe('Mon 21 Jul 1969 02:56:00 AM UTC')
  })

  it('parses the value if necessary', () => {
    expect(tz.format('1969-07-21 02:56', '%F %T%:z')).toBe('1969-07-21 02:56:00+00:00')
  })

  it('returns null if the parse fails', () => {
    expect(tz.format('bogus', '%F %T%:z')).toBe(null)
  })

  it('returns null if the format string is unrecognized', () => {
    expect(tz.format(moonwalk, 'bogus')).toBe(null)
  })

  it('preserves 12-hour+am/pm if the locale does define am/pm', () => {
    const time = tz.parse('1969-07-21 15:00:00')
    expect(tz.format(time, '%-l%P')).toBe('3pm')
    expect(tz.format(time, '%I%P')).toBe('03pm')
    expect(tz.format(time, '%r')).toBe('03:00:00 PM')
  })

  it("promotes 12-hour+am/pm into 24-hour if the locale doesn't define am/pm", () => {
    configure({
      tz: timezone(french, 'fr_FR'),
      momentLocale: 'fr',
    })
    window.ENV.LOCALE = 'fr'

    const time = tz.parse('1969-07-21 15:00:00')

    expect(tz.format(time, '%-l%P')).toBe('15')
    expect(tz.format(time, '%I%P')).toBe('15')
    expect(tz.format(time, '%r')).toBe('15:00:00')
  })

  it('uses a specific timezone when asked', () => {
    configure({
      tz: timezone,
      tzData: {
        'America/Denver': AmericaDenver,
        'America/Chicago': AmericaChicago,
      },
    })

    const time = tz.parse('1969-07-21 15:00:00')
    expect(tz.format(time, '%-l%P', 'America/Denver')).toBe('9am')
    expect(tz.format(time, '%-l%P', 'America/Chicago')).toBe('10am')
  })

  it('recognizes date.formats.*', () => {
    configure({
      formats: {
        'date.formats.short': '%b %-d',
      },
    })

    expect(tz.format(moonwalk, 'date.formats.short')).toBe('Jul 21')
  })

  it('recognizes time.formats.*', () => {
    configure({
      formats: {
        'time.formats.tiny': '%-l:%M%P',
      },
    })

    expect(tz.format(epoch, 'time.formats.tiny')).toBe('12:00am')
  })

  it('localizes when given a localization key', () => {
    configure({
      tz: timezone('fr_FR', french),
      momentLocale: 'fr',
      formats: {
        'date.formats.full': '%-d %b %Y %-l:%M%P',
      },
    })
    window.ENV.LOCALE = 'fr'

    expect(tz.format(moonwalk, 'date.formats.full')).toBe('21 juil. 1969 2:56')
  })

  it('automatically converts %l to %-l when given a localization key', () => {
    configure({
      formats: {
        'time.formats.tiny': '%l:%M%P',
      },
    })

    expect(tz.format(moonwalk, 'time.formats.tiny')).toBe('2:56am')
  })

  it('automatically converts %k to %-k when given a localization key', () => {
    configure({
      formats: {
        'time.formats.tiny': '%k:%M',
      },
    })

    expect(tz.format(moonwalk, 'time.formats.tiny')).toBe('2:56')
  })

  it('automatically converts %e to %-e when given a localization key', () => {
    configure({
      formats: {
        'date.formats.short': '%b %e',
      },
    })

    expect(tz.format(epoch, 'date.formats.short')).toBe('Jan 1')
  })
})
