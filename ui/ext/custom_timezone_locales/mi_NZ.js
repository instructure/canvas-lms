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
  name: 'mi_NZ',
  day: {
    abbrev: ['Ta', 'Ma', 'Tū', 'We', 'Tāi', 'Pa', 'Hā'],
    full: ['Rātapu', 'Mane', 'Tūrei', 'Wenerei', 'Tāite', 'Paraire', 'Hātarei'],
  },
  month: {
    abbrev: ['Hān', 'Pēp', 'Māe', 'Āpe', 'Mei', 'Hun', 'Hūr', 'Āku', 'Hep', 'Oke', 'Noe', 'Tīh'],
    full: [
      'Kohi-tātea',
      'Hui-tanguru',
      'Poutū-te-rangi',
      'Paenga-whāwhā',
      'Haratua',
      'Pipiri',
      'Hōngoingoi',
      'Here-turi-kōkā',
      'Mahuru',
      'Whiringa-ā-nuku',
      'Whiringa-ā-rangi',
      'Hakihea',
    ],
  },
  meridiem: ['ahau', 'pm'],
  date: '%d/%m/%y',
  time24: '%T',
  dateTime: 'Te %A, te %d o %B, %Y %T %Z',
  time12: '',
  full: 'Te %A, te %d o %B, %Y %T %Z',
}
