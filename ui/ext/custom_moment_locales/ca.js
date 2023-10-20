/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from '@canvas/i18n'
import moment from 'moment'

const lookupInCA = phrase => I18n.lookup(phrase, {locale: 'ca'})

// some lists in ca.yml start with a blank item, we don't want it here:
const withoutLeadingBlank = (x, i) => (i === 0 ? x && x.length : true)

const apply = () => {
  // keep track of it to restore it later because defineLocale() appears to also
  // activate it...
  const origLocale = moment.locale()

  const monthsRegex =
    /^(Gen|Feb|Març|Abr|Maig|Juny|Jul|Ag|Set|Oct|Nov|Des|de Gen|de Febr|de Març|d[’']Abr|de Maig|de Juny|de Jul|d[’']Ag|de Set|d[’']Oct|de Nov|de Des)/i

  const monthsParse = [
    /^(de Gen|Gen)/i,
    /^(de Febr|Febr)/i,
    /^(de Març|Març)/i,
    /^(d’Abr|d'Abr|Abr)/i,
    /^(de Maig|Maig)/i,
    /^(de Juny|Juny)/i,
    /^(de Jul|Jul)/i,
    /^(d’Ag|d'Ag|Ag)/i,
    /^(de Set|Set)/i,
    /^(d’Oct|d'Oct|Oct)/i,
    /^(de Nov|Nov)/i,
    /^(de Des|Des)/i,
  ]

  // uses 'node_modules/moment/locale/ca.js' as a reference
  moment.defineLocale('ca', {
    months: {
      standalone: lookupInCA('date.month_names').filter(withoutLeadingBlank),
      format: [
        'de Gener',
        'de Febrer',
        'de Març',
        "d'Abril",
        'de Maig',
        'de Juny',
        'de Juliol',
        "d'Agost",
        'de Setembre',
        "d'Octubre",
        'de Novembre',
        'de Desembre',
      ],
      isFormat: /D[oD]?(\s)+MMMM/,
    },
    monthsShort: [
      'Gen',
      'Febr',
      'Març',
      'Abr',
      'Maig',
      'Juny',
      'Juli',
      'Ag',
      'Set',
      'Oct',
      'Nov',
      'Des',
    ],
    monthsRegex,
    monthsShortRegex: monthsRegex,
    monthsStrictRegex: monthsRegex,
    monthsShortStrictRegex: monthsRegex,
    monthsParse,
    longMonthsParse: monthsParse,
    shortMonthsParse: monthsParse,
    weekdays: lookupInCA('date.day_names'),
    weekdaysShort: lookupInCA('date.abbr_day_names'),
    weekdaysMin: lookupInCA('date.datepicker.column_headings'),
    weekdaysParseExact: true,
    longDateFormat: {
      LT: 'H:mm',
      LTS: 'H:mm:ss',
      L: 'DD/MM/YYYY',
      LL: 'D MMMM [de] YYYY',
      ll: 'D MMM YYYY',
      LLL: 'D MMMM [de] YYYY [a les] H:mm',
      lll: 'D MMM YYYY, H:mm',
      LLLL: 'dddd D MMMM [de] YYYY [a les] H:mm',
      llll: 'ddd D MMM YYYY, H:mm',
    },
    calendar: {
      sameDay() {
        return '[avui a ' + (this.hours() !== 1 ? 'les' : 'la') + '] LT'
      },
      nextDay() {
        return '[demà a ' + (this.hours() !== 1 ? 'les' : 'la') + '] LT'
      },
      nextWeek() {
        return 'dddd [a ' + (this.hours() !== 1 ? 'les' : 'la') + '] LT'
      },
      lastDay() {
        return '[ahir a ' + (this.hours() !== 1 ? 'les' : 'la') + '] LT'
      },
      lastWeek() {
        return '[el] dddd [passat a ' + (this.hours() !== 1 ? 'les' : 'la') + '] LT'
      },
      sameElse: 'L',
    },
    relativeTime: {
      future: "d'aquí %s",
      past: 'fa %s',
      s: 'uns segons',
      ss: '%d segons',
      m: 'un minut',
      mm: '%d minuts',
      h: 'una hora',
      hh: '%d hores',
      d: 'un dia',
      dd: '%d dies',
      M: 'un mes',
      MM: '%d mesos',
      y: 'un any',
      yy: '%d anys',
    },
    dayOfMonthOrdinalParse: /\d{1,2}(r|n|t|è|a)/,
    ordinal(number, period) {
      let output =
        number === 1 ? 'r' : number === 2 ? 'n' : number === 3 ? 'r' : number === 4 ? 't' : 'è'

      if (period === 'w' || period === 'W') {
        output = 'a'
      }
      return number + output
    },
    week: {
      dow: 1, // Monday is the first day of the week.
      doy: 4, // The week that contains Jan 4th is the first week of the year.
    },
  })

  moment.locale(origLocale)
}

const applyWhenTranslationsAreAvailable = () => {
  const trigger = ({detail}) => {
    if (detail === 'capabilities') {
      apply()
      window.removeEventListener('canvasReadyStateChange', trigger)
    }
  }

  window.addEventListener('canvasReadyStateChange', trigger)
}

applyWhenTranslationsAreAvailable()

export default applyWhenTranslationsAreAvailable
