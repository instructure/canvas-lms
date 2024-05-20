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

// =~*~=~=*!=~=~!!~=+!+!11212121+!+!+@!@=+!!@+!@=~*~=~=*!=~=~!!~=+!+!13333333333
//
// this is only meant for use by maintainers and is not actually exercised in
// the build mainly because the locale files aren't available to the runner
//
// you can use this if you're doing something substantial to tz/moment/i18n
//
// =~*~=~=*!=~=~!!~=+!+!fv....................................~=+!+!13333333333.

import CoreTranslations from '../../../../public/javascripts/translations/en.json'

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

import $ from 'jquery'
import '@canvas/datetime/jquery'
import {parse, format, hasMeridiem} from '@canvas/datetime'
import * as configureDateTime from '../configureDateTime'
import * as configureDateTimeMomentParser from '../configureDateTimeMomentParser'
// eslint-disable-next-line import/no-nodejs-modules
import fs from 'fs'
import I18n, {useTranslations} from '@canvas/i18n'
// eslint-disable-next-line import/no-nodejs-modules
import path from 'path'
import YAML from 'yaml'

import defaultTZLocaleData from 'timezone/locales'
import ar_SA from '../../../ext/custom_timezone_locales/ar_SA'
import ca_ES from '../../../ext/custom_timezone_locales/ca_ES'
import cy_GB from '../../../ext/custom_timezone_locales/cy_GB'
import da_DK from '../../../ext/custom_timezone_locales/da_DK'
import de_DE from '../../../ext/custom_timezone_locales/de_DE'
import el_GR from '../../../ext/custom_timezone_locales/el_GR'
import fa_IR from '../../../ext/custom_timezone_locales/fa_IR'
import fr_CA from '../../../ext/custom_timezone_locales/fr_CA'
import fr_FR from '../../../ext/custom_timezone_locales/fr_FR'
import he_IL from '../../../ext/custom_timezone_locales/he_IL'
import ht_HT from '../../../ext/custom_timezone_locales/ht_HT'
import hy_AM from '../../../ext/custom_timezone_locales/hy_AM'
import is_IS from '../../../ext/custom_timezone_locales/is_IS'
import mi_NZ from '../../../ext/custom_timezone_locales/mi_NZ'
import nn_NO from '../../../ext/custom_timezone_locales/nn_NO'
import pl_PL from '../../../ext/custom_timezone_locales/pl_PL'
import tr_TR from '../../../ext/custom_timezone_locales/tr_TR'
import uk_UA from '../../../ext/custom_timezone_locales/uk_UA'

const tzLocales = [
  ...defaultTZLocaleData,
  ar_SA,
  ca_ES,
  cy_GB,
  da_DK,
  de_DE,
  el_GR,
  fa_IR,
  fr_CA,
  fr_FR,
  he_IL,
  ht_HT,
  hy_AM,
  is_IS,
  mi_NZ,
  nn_NO,
  pl_PL,
  tr_TR,
  uk_UA,
]

useTranslations(CoreTranslations)

const locales = loadAvailableLocales()
const tzLocaleData = tzLocales.reduce((acc, locale) => {
  acc[locale.name] = locale
  return acc
}, {})

const dates = createDateSamples()

for (const locale of locales) {
  // eslint-disable-next-line jest/valid-describe
  describe(locale.key, () => {
    beforeAll(() => {
      I18n.locale = locale.key

      window.ENV = window.ENV || {}
      window.ENV.BIGEASY_LOCALE = locale.bigeasy
      window.ENV.MOMENT_LOCALE = locale.moment
      window.__PRELOADED_TIMEZONE_DATA__ = {
        [locale.bigeasy]: tzLocaleData[locale.bigeasy],
      }

      configureDateTimeMomentParser.up()
      configureDateTime.up()
    })

    afterAll(() => {
      configureDateTimeMomentParser.down()
      configureDateTime.down()
    })

    test(`timezone -> moment`, () => {
      for (const date of dates) {
        const formattedDate = $.dateString(date)
        const formattedTime = format(date, 'time.formats.tiny')
        const formatted = `${formattedDate} ${formattedTime}`

        expect(parse(formatted).getTime()).toEqual(date.getTime())
      }
    })

    test(`hour format matches timezone locale`, () => {
      if (locale.key === 'ca') {
        this.pending("it's broken for ca, needs investigation")
      }

      const formats = [
        'date.formats.date_at_time',
        'date.formats.full',
        'date.formats.full_with_weekday',
        'time.formats.tiny',
        'time.formats.tiny_on_the_hour',
      ]

      for (const format of formats) {
        expect(hasMeridiem() || !/%p/i.test(I18n.lookup(format))).toBeTruthy()
      }
    })
  })
}

function createDateSamples() {
  const dates = []
  const currentYear = new Date().getFullYear()
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
  const manifest = YAML.parse(
    fs.readFileSync(path.resolve(__dirname, '../../../../config/locales/locales.yml'), 'utf8')
  )

  return Object.keys(manifest)
    .map(key => {
      const locale = manifest[key]
      const base = key.split('-')[0]

      return {
        key,
        moment: locale.moment_locale || key.toLowerCase(),
        bigeasy: locale.bigeasy_locale || manifest[base].bigeasy_locale,
      }
    })
    .filter(x => x.key)
}
