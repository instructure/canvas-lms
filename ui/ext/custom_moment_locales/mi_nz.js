/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

// Custom moment.js locale for maori
// see baseWebpackConfig.js for how this is pulled in
import moment from 'moment'

export default moment.defineLocale('mi-nz', {
  months:
    'Kohi-tāte_Hui-tanguru_Poutū-te-rangi_Paenga-whāwhā_Haratua_Pipiri_Hōngoingoi_Here-turi-kōkā_Mahuru_Whiringa-ā-nuku_Whiringa-ā-rangi_Hakihea'.split(
      '_'
    ),
  monthsShort: ['Hān', 'Pēp', 'Māe', 'Āpe', 'Mei', 'Hun', 'Hūr', 'Āku', 'Hep', 'Oke', 'Noe', 'Tīh'],
  // regexes taken from moment 2.22.2's moment/locale/mi.js
  // and modified to include unicode characters from our customized monthsShort
  monthsRegex: /(?:['a-z\u0101\u014D\u016B]+\-?){1,3}/i,
  monthsStrictRegex: /(?:['a-z\u0101\u014D\u016B]+\-?){1,3}/i,
  monthsShortRegex: /(?:['a-z\u0101\u014D\u016B\u0113\u012B]+\-?){1,3}/i,
  monthsShortStrictRegex: /(?:['a-z\u0101\u014D\u016B]+\-?){1,2}/i,
  weekdays: 'Rātapu_Mane_Tūrei_Wenerei_Tāite_Paraire_Hātarei'.split('_'),
  weekdaysShort: 'Ta_Ma_Tū_We_Tāi_Pa_Hā'.split('_'),
  weekdaysMin: 'Ta_Ma_Tū_We_Tāi_Pa_Hā'.split('_'),
  longDateFormat: {
    LT: 'HH:mm',
    LTS: 'HH:mm:ss',
    L: 'DD/MM/YYYY',
    LL: 'D MMMM YYYY',
    LLL: 'D MMMM YYYY [i] HH:mm',
    LLLL: 'dddd, D MMMM YYYY [i] HH:mm',
  },
  calendar: {
    sameDay: '[i teie mahana, i] LT',
    nextDay: '[apopo i] LT',
    nextWeek: 'dddd [i] LT',
    lastDay: '[inanahi i] LT',
    lastWeek: 'dddd [whakamutunga i] LT',
    sameElse: 'L',
  },
  relativeTime: {
    future: 'i roto i %s',
    past: '%s i mua',
    s: 'te hēkona ruarua',
    m: 'he meneti',
    mm: '%d meneti',
    h: 'te haora',
    hh: '%d haora',
    d: 'he ra',
    dd: '%d ra',
    M: 'he marama',
    MM: '%d marama',
    y: 'he tau',
    yy: '%d tau',
  },
  ordinalParse: /\d{1,2}º/,
  ordinal: '%dº',
})
