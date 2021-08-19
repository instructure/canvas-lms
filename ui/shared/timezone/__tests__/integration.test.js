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
import timezone from 'timezone'
import french from 'timezone/fr_FR'
import chinese from 'timezone/zh_CN'
import en_US from 'timezone/en_US'
import MockDate from 'mockdate'
import { I18nStubber, equal, epoch, ok, moonwalk } from './helpers'
import {
  up as configureDateTimeMomentParser,
  down as resetDateTimeMomentParser
} from '../../../../ui/boot/initializers/configureDateTimeMomentParser'

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
      'time.formats.tiny_on_the_hour': '%l%P'
    })

    configure({
      tz: timezone('en_US', en_US),
      momentLocale: 'en',
    })

    configureDateTimeMomentParser()
  })

  afterAll(() => {
    resetDateTimeMomentParser()
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
      'Aug 3'
    ]

    engDates.forEach(date => {
      const d = tz.parse(date)
      equal(tz.format(d, '%d'), '03', `this works: ${date}`)
    })
  })

  test('parses english times', () => {
    const engTimes = ['6:06 PM', '6:06:22 PM', '6:06pm', '6pm']

    engTimes.forEach(time => {
      const d = tz.parse(time)
      equal(tz.format(d, '%H'), '18', `this works: ${time}`)
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
      'Mon Aug 3, 2015 6:06pm'
    ]

    engDateTimes.forEach(dateTime => {
      const d = tz.parse(dateTime)
      equal(tz.format(d, '%d %H'), '03 18', `this works: ${dateTime}`)
    })
  })

  test('parses 24hr times even if the locale lacks them', () => {
    const d = tz.parse('18:06')
    equal(tz.format(d, '%H:%M'), '18:06')
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
      'time.formats.tiny_on_the_hour': '%k:%M'
    })

    configure({
      tz: timezone('fr_FR', french),
      momentLocale: 'fr'
    })

    configureDateTimeMomentParser()
  })

  afterAll(() => {
    resetDateTimeMomentParser()
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
    '3 août'
  ]

  for (const date of frenchDates) {
    test(`parses french date "${date}"`, () => {
      equal(tz.format(tz.parse(date), '%d'), '03')
    })
  }

  const frenchTimes = ['18:06', '18:06:22']

  for (const time of frenchTimes) {
    test(`parses french time "${time}"`, () => {
      equal(tz.format(tz.parse(time), '%H'), '18')
    })
  }

  const frenchDateTimes = [
    '2015-08-03 18:06:22',
    '3 août 2015 18:06',
    'lundi 3 août 2015 18:06',
    'lun. 3 août 2015 18:06',
    '3 août à 18:06',
    'août 3, 2015 18:06',
    'lun. 3 août, 2015 18:06'
  ]

  for (const dateTime of frenchDateTimes) {
    test(`parses french date time "${dateTime}"`, () => {
      equal(tz.format(tz.parse(dateTime), '%d %H'), '03 18')
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
      'time.formats.tiny_on_the_hour': '%k:%M'
    })

    configure({
      tz: timezone(chinese, 'zh_CN'),
      momentLocale: 'zh-cn'
    })

    configureDateTimeMomentParser()
  })

  afterAll(() => {
    resetDateTimeMomentParser()
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
      '8月 3'
    ]

    chineseDates.forEach(date => {
      expect(tz.format(tz.parse(date), '%d')).toEqual('03')
    })
  })

  test('parses chinese date AM times', () => {
    const chineseDateTimes = [
      '2015-08-03 06:06:22',
      '2015年8月3日6点06分',
      '2015年8月3日星期一6点06分',
      '8月 3日 于 6:06',
      '20158月3日, 6:06',
      '一 20158月3日, 6:06' // this is incorrectly parsing as "Fri, 20 Mar 1908 06:06:00 GMT"
    ]

    chineseDateTimes.forEach(dateTime => {
      equal(tz.format(tz.parse(dateTime), '%d %H'), '03 06')
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
      equal(tz.format(tz.parse(dateTime), '%d %H'), '03 18')
    })
  })
})
