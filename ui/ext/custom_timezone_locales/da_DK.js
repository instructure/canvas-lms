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
  name: 'da_DK',
  day: {
    abbrev: ['søn', 'man', 'tir', 'ons', 'tor', 'fre', 'lør'],
    full: ['søndag', 'mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag'],
  },
  month: {
    abbrev: ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'],
    full: [
      'januar',
      'februar',
      'marts',
      'april',
      'maj',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'december',
    ],
  },
  meridiem: ['', ''],
  date: '%Y-%m-%d',
  time24: '%H:%M:%S',
  dateTime: '%a %e %b %Y %H:%M:%S',
  time12: '',
  full: '%a %b %e %H:%M:%S %Z %Y',
}
