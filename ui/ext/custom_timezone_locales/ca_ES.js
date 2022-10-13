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
  name: 'ca_ES',
  day: {
    abbrev: ['Dg.', 'Dl.', 'Dt.', 'Dc.', 'Dj.', 'Dv.', 'Ds.'],
    full: ['Diumenge', 'Dilluns', 'Dimarts', 'Dimecres', 'Dijous', 'Divendres', 'Dissabte'],
  },
  month: {
    abbrev: [
      'Gen.',
      'Febr.',
      'Març',
      'Abr.',
      'Maig',
      'Juny',
      'Jul.',
      'Ag.',
      'Set.',
      'Oct.',
      'Nov.',
      'Des.',
    ],
    full: [
      'Gener',
      'Febrer',
      'Març',
      'Abril',
      'Maig',
      'Juny',
      'Juliol',
      'Agost',
      'Setembre',
      'Octubre',
      'Novembre',
      'Desembre',
    ],
  },
  meridiem: ['', ''],
  date: '%d/%m/%Y', // date.formats.default
  time24: '%T',
  dateTime: '%-d de %b a les %l:%M%P', // date.formats.date_at_time
  time12: '',
  full: '%-d de %b, %Y %-l:%M%P', // date.formats.full
}
