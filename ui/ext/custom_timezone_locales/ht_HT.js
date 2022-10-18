/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

module.exports = {
  name: 'ht_HT',
  day: {
    abbrev: ['dim', 'len', 'mad', 'mèk', 'jed', 'van', 'sam'],
    full: ['dimanch', 'lendi', 'madi', 'mèkredi', 'jedi', 'vandredi', 'samdi'],
  },
  month: {
    abbrev: ['jan', 'fev', 'mas', 'avr', 'me', 'jen', 'jiy', 'out', 'sep', 'okt', 'nov', 'des'],
    full: [
      'janvye',
      'fevriye',
      'mas',
      'avril',
      'me',
      'jen',
      'jiyè',
      'out',
      'septanm',
      'oktòb',
      'novanm',
      'desanm',
    ],
  },
  meridiem: ['', ''],
  date: '%d-%m-%Y',
  time24: '%R',
  dateTime: '%a, %d %b %Y %H:%M:%S %z',
  time12: '',
  full: '%b %-d, %Y %H:%M',
}
