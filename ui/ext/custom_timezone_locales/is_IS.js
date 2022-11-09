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
  name: 'is_IS',
  day: {
    abbrev: ['Sun', 'Mán', 'Þri', 'Mið', 'Fim', 'Fös', 'Lau'],
    full: [
      'Sunnudagur',
      'Mánudagur',
      'Þriðjudagur',
      'Miðvikudagur',
      'Fimmtudagur',
      'Föstudagur',
      'Laugardagur',
    ],
  },
  month: {
    abbrev: ['Jan', 'Feb', 'Mar', 'Apr', 'Maí', 'Jún', 'Júl', 'Ágú', 'Sep', 'Okt', 'Nóv', 'Des'],
    full: [
      'Janúar',
      'Febrúar',
      'Mars',
      'Apríl',
      'Maí',
      'Júní',
      'Júlí',
      'Ágúst',
      'September',
      'Október',
      'Nóvember',
      'Desember',
    ],
  },
  meridiem: ['', ''],
  date: '%Y-%m-%d',
  time24: '%T',
  dateTime: '%a %d %b %Y %T %Z',
  time12: '',
  full: '%b %-d, %Y %-l:%M%P',
}
