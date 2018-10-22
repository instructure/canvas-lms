/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import sinon from 'sinon'
import localeConfig from 'json-loader!yaml-loader!../../../config/locales/locales.yml'
import tz from 'timezone_core'
import DatetimeField from 'compiled/widget/DatetimeField'
import $ from 'jquery'
import I18n from 'i18nObj'
import 'translations/_core'
import 'translations/_core_en'

import bigeasyLocales from 'timezone/locales'
import bigeasyLocale_cy_GB from 'custom_timezone_locales/cy_GB'
import bigeasyLocale_de_DE from 'custom_timezone_locales/de_DE'
import bigeasyLocale_fr_FR from 'custom_timezone_locales/fr_FR'
import bigeasyLocale_fr_CA from 'custom_timezone_locales/fr_CA'
import bigeasyLocale_he_IL from 'custom_timezone_locales/he_IL'
import bigeasyLocale_pl_PL from 'custom_timezone_locales/pl_PL'
import bigeasyLocale_is_IS from 'custom_timezone_locales/is_IS'
import bigeasyLocale_ar_SA from 'custom_timezone_locales/ar_SA'
import bigeasyLocale_da_DK from 'custom_timezone_locales/da_DK'
import bigeasyLocale_fa_IR from 'custom_timezone_locales/fa_IR'
import bigeasyLocale_ht_HT from 'custom_timezone_locales/ht_HT'
import bigeasyLocale_hy_AM from 'custom_timezone_locales/hy_AM'
import bigeasyLocale_mi_NZ from 'custom_timezone_locales/mi_NZ'
import bigeasyLocale_nn_NO from 'custom_timezone_locales/nn_NO'
import bigeasyLocale_tr_TR from 'custom_timezone_locales/tr_TR'
import bigeasyLocale_uk_UA from 'custom_timezone_locales/uk_UA'
import bigeasyLocale_el_GR from 'custom_timezone_locales/el_GR'

import 'custom_moment_locales/de'
import 'custom_moment_locales/he'
import 'custom_moment_locales/pl'
import 'custom_moment_locales/fa'
import 'custom_moment_locales/fr'
import 'custom_moment_locales/fr_ca'
import 'custom_moment_locales/ht_ht'
import 'custom_moment_locales/mi_nz'
import 'custom_moment_locales/hy_am'

let originalLocale
let originalFallbacksMap

const bigeasyLocalesWithCustom = [
  ...bigeasyLocales,
  bigeasyLocale_cy_GB,
  bigeasyLocale_de_DE,
  bigeasyLocale_fr_FR,
  bigeasyLocale_fr_CA,
  bigeasyLocale_he_IL,
  bigeasyLocale_pl_PL,
  bigeasyLocale_is_IS,
  bigeasyLocale_ar_SA,
  bigeasyLocale_da_DK,
  bigeasyLocale_fa_IR,
  bigeasyLocale_ht_HT,
  bigeasyLocale_hy_AM,
  bigeasyLocale_mi_NZ,
  bigeasyLocale_nn_NO,
  bigeasyLocale_tr_TR,
  bigeasyLocale_uk_UA,
  bigeasyLocale_el_GR
]

const preloadedData = bigeasyLocalesWithCustom.reduce((memo, locale) => {
  memo[locale.name] = locale
  return memo
}, {})

QUnit.module('Parsing locale formatted dates', {
  setup () {
    originalLocale = I18n.locale
    sinon.stub(tz, 'preload').callsFake(name => preloadedData[name])
    originalFallbacksMap = I18n.fallbacksMap
    I18n.fallbacksMap = null
  },

  teardown () {
    I18n.locale = originalLocale
    I18n.fallbacksMap = originalFallbacksMap
    tz.preload.restore()
  }
})

const locales = Object.keys(localeConfig).map((key) => {
  const locale = localeConfig[key]
  const base = key.split('-')[0]
  return {
    key,
    moment: locale.moment_locale || key.toLowerCase(),
    bigeasy: locale.bigeasy_locale || localeConfig[base].bigeasy_locale
  }
}).filter(l => l.key)

const dates = []
const currentYear = parseInt(tz.format(new Date(), '%Y'), 10)
const otherYear = currentYear + 4
for (let i = 0; i < 12; ++i) {
  dates.push(new Date(Date.UTC(currentYear, i, 1, 23, 59)))
  dates.push(new Date(Date.UTC(currentYear, i, 28, 23, 59)))
  dates.push(new Date(Date.UTC(otherYear, i, 7, 23, 59)))
  dates.push(new Date(Date.UTC(otherYear, i, 15, 23, 59)))
}

function assertFormattedParsesToDate (formatted, date) {
  const parsed = tz.parse(formatted)
  const formattedDate = tz.format(parsed, 'date.formats.medium')
  const formattedTime = tz.format(parsed, 'time.formats.tiny')
  const formattedParsed = `${formattedDate} ${formattedTime}`
  equal(date.getTime(), parsed.getTime(), `${formatted} incorrectly parsed as ${formattedParsed}`)
}

locales.forEach((locale) => {
  test(`timezone -> moment for ${locale.key}`, () => {
    I18n.locale = locale.key
    try {
      tz.changeLocale(locale.bigeasy, locale.moment)
      dates.forEach((date) => {
        const formattedDate = $.dateString(date)
        const formattedTime = tz.format(date, 'time.formats.tiny')
        const formatted = `${formattedDate} ${formattedTime}`
        assertFormattedParsesToDate(formatted, date)
      })
    } catch (err) {
      ok(false, err.message)
    }
  })

  test(`datepicker -> moment for ${locale.key}`, () => {
    I18n.locale = locale.key
    const config = DatetimeField.prototype.datepickerDefaults()
    try {
      tz.changeLocale(locale.bigeasy, locale.moment)
      dates.forEach((date) => {
        const formattedDate = $.datepicker.formatDate(config.dateFormat, date, config)
        const formattedTime = $.timeString(date)
        const formatted = `${formattedDate} ${formattedTime}`
        assertFormattedParsesToDate(formatted, date)
      })
    } catch (err) {
      ok(false, err.message)
    }
  })

  test(`hour format matches timezone locale for ${locale.key}`, () => {
    I18n.locale = locale.key
    tz.changeLocale(locale.bigeasy, locale.moment)
    const formats = [
      'date.formats.date_at_time',
      'date.formats.full',
      'date.formats.full_with_weekday',
      'time.formats.tiny',
      'time.formats.tiny_on_the_hour'
    ]
    const invalid = key => {
      const format = I18n.lookup(key)
      // ok(/%p/i.test(format) === tz.hasMeridian(), `format: ${format}, hasMeridian: ${tz.hasMeridian()}`)
      ok(tz.hasMeridian() || !/%p/i.test(format), `format: ${format}, hasMeridian: ${tz.hasMeridian()}`)
    }
    ok(!formats.forEach(invalid))
  })
})
