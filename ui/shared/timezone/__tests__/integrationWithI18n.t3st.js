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

//
// this is only meant for use by maintainers and is not actually exercised in
// the build mainly because the locale files aren't available to the runner
//
// use this only if you're doing something substantial to tz/moment/i18n
//

import 'translations/_core'
import 'translations/_core_en'

import tz, { configure } from '../'
import timezone from 'timezone'
import $ from '@canvas/datetime'
import I18n from '@canvas/i18n'
import {
  up as configureDateTimeMomentParser,
  down as resetDateTimeMomentParser
} from '../../../boot/initializers/configureDateTimeMomentParser'
import tzLocales from './bigeasyLocales'
import fs from 'fs'
import path from 'path'
import YAML from 'yaml'

import '../../../ext/custom_moment_locales/ca'
import '../../../ext/custom_moment_locales/de'
import '../../../ext/custom_moment_locales/he'
import '../../../ext/custom_moment_locales/pl'
import '../../../ext/custom_moment_locales/fa'
import '../../../ext/custom_moment_locales/fr'
import '../../../ext/custom_moment_locales/fr_ca'
import '../../../ext/custom_moment_locales/ht_ht'
import '../../../ext/custom_moment_locales/mi_nz'
import '../../../ext/custom_moment_locales/hy_am'
import '../../../ext/custom_moment_locales/sl'

const locales = loadAvailableLocales()
const tzLocaleData = tzLocales.reduce((acc, locale) => {
  acc[locale.name] = locale
  return acc
}, {})

describe('english tz', () => {
  const dates = createDateSamples()

  beforeEach(configureDateTimeMomentParser)

  afterEach(resetDateTimeMomentParser)

  for (const locale of locales) {
    test(`timezone -> moment for ${locale.key}`, () => {
      I18n.locale = locale.key

      configure({
        tz: timezone(locale.bigeasy, tzLocaleData[locale.bigeasy]),
        momentLocale: locale.moment
      })

      for (const date of dates) {
        const formattedDate = $.dateString(date)
        const formattedTime = tz.format(date, 'time.formats.tiny')
        const formatted = `${formattedDate} ${formattedTime}`

        expect(
          tz.parse(formatted).getTime()
        ).toEqual(
          date.getTime()
        )
      }
    })

    test(`hour format matches timezone locale for ${locale.key}`, () => {
      if (locale.key === 'ca') {
        pending("it's broken for ca, needs investigation")
      }

      I18n.locale = locale.key

      configure({
        tz: timezone(locale.bigeasy, tzLocaleData[locale.bigeasy]),
        momentLocale: locale.moment
      })

      const formats = [
        'date.formats.date_at_time',
        'date.formats.full',
        'date.formats.full_with_weekday',
        'time.formats.tiny',
        'time.formats.tiny_on_the_hour'
      ]

      for (const format of formats) {
        // expect(tz.hasMeridian()).toEqual(/%p/i.test(I18n.lookup(format)))
        expect(tz.hasMeridian() || !/%p/i.test(I18n.lookup(format))).toBeTruthy()
      }
      // const invalid = key => {
      //   const format = I18n.lookup(key)
      //   // ok(/%p/i.test(format) === tz.hasMeridian(), `format: ${format}, hasMeridian: ${tz.hasMeridian()}`)
      //   ok(
      //     tz.hasMeridian() || !/%p/i.test(format),
      //     `format: ${format}, hasMeridian: ${tz.hasMeridian()}`
      //   )
      // }
      // ok(!formats.forEach(invalid))
    })
  }
})

function createDateSamples() {
  const dates = []
  const currentYear = (new Date()).getFullYear()
  const otherYear = currentYear + 4

  for (let i = 0; i < 12; ++i) {
    dates.push(new Date(Date.UTC(currentYear, i, 1, 23, 59)))
    dates.push(new Date(Date.UTC(currentYear, i, 28, 23, 59)))
    dates.push(new Date(Date.UTC(otherYear, i, 7, 23, 59)))
    dates.push(new Date(Date.UTC(otherYear, i, 15, 23, 59)))
  }

  return dates
}

function loadAvailableLocales() {
  const manifest = (
    YAML.parse(
      fs.readFileSync(
        path.resolve(__dirname, '../../../../config/locales/locales.yml'),
        'utf8'
      )
    )
  )

  return Object.keys(manifest).map(key => {
    const locale = manifest[key]
    const base = key.split('-')[0]

    return {
      key,
      moment: locale.moment_locale || key.toLowerCase(),
      bigeasy: locale.bigeasy_locale || manifest[base].bigeasy_locale
    }
  }).filter(x => x.key)
}
