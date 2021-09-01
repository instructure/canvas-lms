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
import detroit from 'timezone/America/Detroit'
import french from 'timezone/fr_FR'
import { setup, I18nStubber, equal, epoch, ok, moonwalk, preload } from './helpers'

setup(this)

test('hasMeridian() true if locale defines am/pm', () => ok(tz.hasMeridian()))

test("hasMeridian() false if locale doesn't define am/pm", () => {
  configure({
    tz: timezone('fr_FR', french),
    momentLocale: 'fr'
  })

  ok(!tz.hasMeridian())
})

test('useMeridian() true if locale defines am/pm and uses 12-hour format', () => {
  I18nStubber.stub('en', {'time.formats.tiny': '%l:%M%P'})
  ok(tz.hasMeridian())
  ok(tz.useMeridian())
})

test('useMeridian() false if locale defines am/pm but uses 24-hour format', () => {
  I18nStubber.stub('en', {'time.formats.tiny': '%k:%M'})
  ok(tz.hasMeridian())
  ok(!tz.useMeridian())
})

test("useMeridian() false if locale doesn't define am/pm and instead uses 24-hour format", () => {
  configure({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr'
  })

  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {'time.formats.tiny': '%-k:%M'})
  ok(!tz.hasMeridian())
  ok(!tz.useMeridian())
})

test("useMeridian() false if locale doesn't define am/pm but still uses 12-hour format (format will be corrected)", () => {
  configure({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr'
  })

  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {'time.formats.tiny': '%-l:%M%P'})
  ok(!tz.hasMeridian())
  ok(!tz.useMeridian())
})

test('isMidnight() is false when no argument given.', () => ok(!tz.isMidnight()))

test('isMidnight() is false when invalid date is given.', () => {
  const date = new Date('invalid date')
  ok(!tz.isMidnight(date))
})

test('isMidnight() is true when date given is at midnight.', () => ok(tz.isMidnight(epoch)))

test("isMidnight() is false when date given isn't at midnight.", () => ok(!tz.isMidnight(moonwalk)))

test('isMidnight() is false when date is midnight in a different zone.', () => {
  configure({ tz: timezone(detroit, 'America/Detroit') })

  ok(!tz.isMidnight(epoch))
})

test('changeToTheSecondBeforeMidnight() returns null when no argument given.', () =>
  equal(tz.changeToTheSecondBeforeMidnight(), null))

test('changeToTheSecondBeforeMidnight() returns null when invalid date is given.', () => {
  const date = new Date('invalid date')
  equal(tz.changeToTheSecondBeforeMidnight(date), null)
})

test('changeToTheSecondBeforeMidnight() returns fancy midnight when a valid date is given.', () => {
  const fancyMidnight = tz.changeToTheSecondBeforeMidnight(epoch)
  equal(fancyMidnight.toGMTString(), 'Thu, 01 Jan 1970 23:59:59 GMT')
})
