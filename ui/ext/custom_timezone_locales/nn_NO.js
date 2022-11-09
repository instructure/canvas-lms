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
  name: 'nn_NO',
  day: {
    abbrev: ['sø.', 'må.', 'ty.', 'on.', 'to.', 'fr.', 'la.'],
    full: ['sundag', 'måndag', 'tysdag', 'onsdag', 'torsdag', 'fredag', 'laurdag'],
  },
  month: {
    abbrev: [
      'jan.',
      'feb.',
      'mars',
      'april',
      'mai',
      'juni',
      'juli',
      'aug.',
      'sep.',
      'okt.',
      'nov.',
      'des.',
    ],
    full: [
      'januar',
      'februar',
      'mars',
      'april',
      'mai',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'desember',
    ],
  },
  meridiem: ['', ''],
  date: '%Y-%m-%d',
  time24: 'kl. %H.%M %z',
  dateTime: '%b %-d at %l:%M%P',
  time12: '',
  full: '%b %-d, %Y %-l:%M%P',
}
