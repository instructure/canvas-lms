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

import {parse, format} from '@canvas/datetime'
import fr_FR from 'timezone/fr_FR'
import zh_CN from 'timezone/zh_CN'
import en_US from 'timezone/en_US'
import MockDate from 'mockdate'
import I18nStubber from '../../../../spec/coffeescripts/helpers/I18nStubber'
import {up as configureDateTime, down as resetDateTime} from '../configureDateTime'
import {
  up as configureDateTimeMomentParser,
  down as resetDateTimeMomentParser,
} from '../configureDateTimeMomentParser'

const equal = (a, b, _message) => expect(a).toEqual(b)

let TIMEZONE, BIGEASY_LOCALE, MOMENT_LOCALE, __PRELOADED_TIMEZONE_DATA__

beforeAll(() => {
  if (!window.ENV) {
    window.ENV = {}
  }

  __PRELOADED_TIMEZONE_DATA__ = window.__PRELOADED_TIMEZONE_DATA__
  TIMEZONE = window.ENV.TIMEZONE
  BIGEASY_LOCALE = window.ENV.BIGEASY_LOCALE
  MOMENT_LOCALE = window.ENV.MOMENT_LOCALE
})

afterAll(() => {
  window.__PRELOADED_TIMEZONE_DATA__ = __PRELOADED_TIMEZONE_DATA__
  window.ENV.TIMEZONE = TIMEZONE
  window.ENV.BIGEASY_LOCALE = BIGEASY_LOCALE
  window.ENV.MOMENT_LOCALE = MOMENT_LOCALE
})

describe('english tz', () => {
  beforeAll(() => {
    MockDate.set('2015-02-01', 'UTC')

    I18nStubber.pushFrame()
    I18nStubber.setLocale('en_US')
    I18nStubber.stub('en_US', {
      'date.formats.date_at_time': '%b %-d at %l:%M%P',
      'date.formats.default': '%Y-%m-%d',
      'date.formats.full': '%b %-d, %Y %-l:%M%P',
      'date.formats.full_with_weekday': '%a %b %-d, %Y %-l:%M%P',
      'date.formats.long': '%B %-d, %Y',
      'date.formats.long_with_weekday': '%A, %B %-d',
      'date.formats.medium': '%b %-d, %Y',
      'date.formats.medium_month': '%b %Y',
      'date.formats.medium_with_weekday': '%a %b %-d, %Y',
      'date.formats.short': '%b %-d',
      'date.formats.short_month': '%b',
      'date.formats.short_weekday': '%a',
      'date.formats.short_with_weekday': '%a, %b %-d',
      'date.formats.weekday': '%A',
      'time.formats.default': '%a, %d %b %Y %H:%M:%S %z',
      'time.formats.long': '%B %d, %Y %H:%M',
      'time.formats.short': '%d %b %H:%M',
      'time.formats.tiny': '%l:%M%P',
      'time.formats.tiny_on_the_hour': '%l%P',
    })

    window.__PRELOADED_TIMEZONE_DATA__ = {en_US}
    window.ENV.BIGEASY_LOCALE = 'en_US'
    window.ENV.MOMENT_LOCALE = 'en'

    configureDateTime()
    configureDateTimeMomentParser()
  })

  afterAll(() => {
    resetDateTimeMomentParser()
    resetDateTime()
    MockDate.reset()
    I18nStubber.clear()
  })

  test('parses english dates', () => {
    const engDates = [
      '08/03/2015',
      '8/3/2015',
      'August 3, 2015',
      'Aug 3, 2015',
      '3 Aug 2015',
      '2015-08-03',
      '2015 08 03',
      'August 3, 2015',
      'Monday, August 3',
      'Mon Aug 3, 2015',
      'Mon, Aug 3',
      'Aug 3',
    ]

    engDates.forEach(date => {
      const d = parse(date)
      equal(format(d, '%d'), '03', `this works: ${date}`)
    })
  })

  test('parses english times', () => {
    const engTimes = ['6:06 PM', '6:06:22 PM', '6:06pm', '6pm']

    engTimes.forEach(time => {
      const d = parse(time)
      equal(format(d, '%H'), '18', `this works: ${time}`)
    })
  })

  test('parses english date times', () => {
    const engDateTimes = [
      '2015-08-03 18:06:22',
      'August 3, 2015 6:06 PM',
      'Aug 3, 2015 6:06 PM',
      'Aug 3, 2015 6pm',
      'Monday, August 3, 2015 6:06 PM',
      'Mon, Aug 3, 2015 6:06 PM',
      'Aug 3 at 6:06pm',
      'Aug 3, 2015 6:06pm',
      'Mon Aug 3, 2015 6:06pm',
    ]

    engDateTimes.forEach(dateTime => {
      const d = parse(dateTime)
      equal(format(d, '%d %H'), '03 18', `this works: ${dateTime}`)
    })
  })

  test('parses 24hr times even if the locale lacks them', () => {
    const d = parse('18:06')
    equal(format(d, '%H:%M'), '18:06')
  })
})

describe('french tz', () => {
  beforeAll(() => {
    MockDate.set('2015-02-01', 'UTC')

    I18nStubber.pushFrame()
    I18nStubber.setLocale('fr_FR')
    I18nStubber.stub('fr_FR', {
      'date.formats.date_at_time': '%-d %b à %k:%M',
      'date.formats.default': '%d/%m/%Y',
      'date.formats.full': '%b %-d, %Y %-k:%M',
      'date.formats.full_with_weekday': '%a %-d %b, %Y %-k:%M',
      'date.formats.long': 'le %-d %B %Y',
      'date.formats.long_with_weekday': '%A, %-d %B',
      'date.formats.medium': '%-d %b %Y',
      'date.formats.medium_month': '%b %Y',
      'date.formats.medium_with_weekday': '%a %-d %b %Y',
      'date.formats.short': '%-d %b',
      'date.formats.short_month': '%b',
      'date.formats.short_weekday': '%a',
      'date.formats.short_with_weekday': '%a, %-d %b',
      'date.formats.weekday': '%A',
      'time.formats.default': '%a, %d %b %Y %H:%M:%S %z',
      'time.formats.long': ' %d %B, %Y %H:%M',
      'time.formats.short': '%d %b %H:%M',
      'time.formats.tiny': '%k:%M',
      'time.formats.tiny_on_the_hour': '%k:%M',
    })

    window.__PRELOADED_TIMEZONE_DATA__ = {fr_FR}
    window.ENV.BIGEASY_LOCALE = 'fr_FR'
    window.ENV.MOMENT_LOCALE = 'fr'

    configureDateTime()
    configureDateTimeMomentParser()
  })

  afterAll(() => {
    resetDateTimeMomentParser()
    resetDateTime()
    MockDate.reset()
    I18nStubber.clear()
  })

  const frenchDates = [
    '03/08/2015',
    '3/8/2015',
    '3 août 2015',
    '2015-08-03',
    'le 3 août 2015',
    'lundi, 3 août',
    'lun. 3 août 2015',
    '3 août',
    'lun., 3 août',
    '3 août 2015',
    '3 août',
  ]

  for (const date of frenchDates) {
    test(`parses french date "${date}"`, () => {
      equal(format(parse(date), '%d'), '03')
    })
  }

  const frenchTimes = ['18:06', '18:06:22']

  for (const time of frenchTimes) {
    test(`parses french time "${time}"`, () => {
      equal(format(parse(time), '%H'), '18')
    })
  }

  const frenchDateTimes = [
    '2015-08-03 18:06:22',
    '3 août 2015 18:06',
    'lundi 3 août 2015 18:06',
    'lun. 3 août 2015 18:06',
    '3 août à 18:06',
    'août 3, 2015 18:06',
    'lun. 3 août, 2015 18:06',
  ]

  for (const dateTime of frenchDateTimes) {
    test(`parses french date time "${dateTime}"`, () => {
      equal(format(parse(dateTime), '%d %H'), '03 18')
    })
  }
})

describe('chinese tz', () => {
  beforeAll(() => {
    MockDate.set('2015-02-01', 'UTC')

    I18nStubber.pushFrame()
    I18nStubber.setLocale('zh_CN')
    I18nStubber.stub('zh_CN', {
      'date.formats.date_at_time': '%b %-d 于 %H:%M',
      'date.formats.default': '%Y-%m-%d',
      'date.formats.full': '%b %-d, %Y %-l:%M%P',
      'date.formats.full_with_weekday': '%a %b %-d, %Y %-l:%M%P',
      'date.formats.long': '%Y %B %-d',
      'date.formats.long_with_weekday': '%A, %B %-d',
      'date.formats.medium': '%Y %b %-d',
      'date.formats.medium_month': '%Y %b',
      'date.formats.medium_with_weekday': '%a %Y %b %-d',
      'date.formats.short': '%b %-d',
      'date.formats.short_month': '%b',
      'date.formats.short_weekday': '%a',
      'date.formats.short_with_weekday': '%a, %b %-d',
      'date.formats.weekday': '%A',
      'time.formats.default': '%a, %Y %b %d  %H:%M:%S %z',
      'time.formats.long': '%Y %B %d %H:%M',
      'time.formats.short': '%b %d %H:%M',
      'time.formats.tiny': '%H:%M',
      'time.formats.tiny_on_the_hour': '%k:%M',
    })

    window.__PRELOADED_TIMEZONE_DATA__ = {zh_CN}
    window.ENV.BIGEASY_LOCALE = 'zh_CN'
    window.ENV.MOMENT_LOCALE = 'zh-cn'

    configureDateTime()
    configureDateTimeMomentParser()
  })

  afterAll(() => {
    resetDateTimeMomentParser()
    resetDateTime()
    MockDate.reset()
    I18nStubber.clear()
  })

  test('parses chinese dates', () => {
    const chineseDates = [
      '2015-08-03',
      '2015年8月3日',
      '2015 八月 3',
      '2015 8月 3',
      '星期一, 八月 3',
      '一 2015 8月 3',
      '一, 8月 3',
      '8月 3',
    ]

    chineseDates.forEach(date => {
      expect(format(parse(date), '%d')).toEqual('03')
    })
  })

  test('parses chinese date AM times', () => {
    const chineseDateTimes = [
      '2015-08-03 06:06:22',
      '2015年8月3日6点06分',
      '2015年8月3日星期一6点06分',
      '8月 3日 于 6:06',
      '20158月3日, 6:06',
      '一 20158月3日, 6:06', // this is incorrectly parsing as "Fri, 20 Mar 1908 06:06:00 GMT"
    ]

    chineseDateTimes.forEach(dateTime => {
      equal(format(parse(dateTime), '%d %H'), '03 06')
    })
  })

  test('parses chinese date PM times', () => {
    const chineseDateTimes = [
      '2015-08-03 18:06:22',
      '2015年8月3日晚上6点06分',
      // '2015年8月3日星期一晚上6点06分', // parsing as "Mon, 03 Aug 2015 06:06:00 GMT"
      '8月 3日, 于 18:06',
      // '2015 8月 3日, 6:06下午',      // doesn't recognize 下午 as implying PM
      // '一 2015 8月 3日, 6:06下午'
    ]

    chineseDateTimes.forEach(dateTime => {
      equal(format(parse(dateTime), '%d %H'), '03 18')
    })
  })
})
