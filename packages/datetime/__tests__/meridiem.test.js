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

import { configure, hasMeridiem, useMeridiem } from '../'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import french from 'timezone/fr_FR'
import { setup, equal, epoch, ok, moonwalk } from './helpers'

setup(this)

test('hasMeridiem() true if locale defines am/pm', () => ok(hasMeridiem()))

test("hasMeridiem() false if locale doesn't define am/pm", () => {
  configure({
    tz: timezone('fr_FR', french),
    momentLocale: 'fr'
  })

  ok(!hasMeridiem())
})

test('useMeridiem() true if locale defines am/pm and uses 12-hour format', () => {
  configure({
    formats: {
      'time.formats.tiny': '%l:%M%P'
    }
  })

  ok(hasMeridiem())
  ok(useMeridiem())
})

test('useMeridiem() false if locale defines am/pm but uses 24-hour format', () => {
  configure({
    formats: {
      'time.formats.tiny': '%k:%M'
    }
  })

  ok(hasMeridiem())
  ok(!useMeridiem())
})

test("useMeridiem() false if locale doesn't define am/pm and instead uses 24-hour format", () => {
  configure({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr',
    formats: {
      'time.formats.tiny': '%-k:%M'
    }
  })

  ok(!hasMeridiem())
  ok(!useMeridiem())
})

test("useMeridiem() false if locale doesn't define am/pm but still uses 12-hour format (format will be corrected)", () => {
  configure({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr',
    formats: {
      'time.formats.tiny': '%-l:%M%P'
    }
  })

  ok(!hasMeridiem())
  ok(!useMeridiem())
})
