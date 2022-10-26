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
  name: 'cy_GB',
  day: {
    abbrev: ['Sul', 'Llun', 'Maw', 'Mer', 'Iau', 'Gwe', 'Sad'],
    full: [
      'Dydd Sul',
      'Dydd Llun',
      'Dydd Mawrth',
      'Dydd Mercher',
      'Dydd Iau',
      'Dydd Gwener',
      'Dydd Sadwrn',
    ],
  },
  month: {
    abbrev: ['Ion', 'Chwe', 'Maw', 'Ebr', 'Mai', 'Meh', 'Gor', 'Aws', 'Med', 'Hyd', 'Tach', 'Rhag'],
    full: [
      'Ionawr',
      'Chwefror',
      'Mawrth',
      'Ebrill',
      'Mai',
      'Mehefin',
      'Gorffennaf',
      'Awst',
      'Medi',
      'Hydref',
      'Tachwedd',
      'Rhagfyr',
    ],
  },
  meridiem: ['AM', 'PM'],
  date: '%d/%m/%y',
  time24: '%T',
  dateTime: '%a %d %b %Y %T %Z',
  time12: '%l:%M:%S %P %Z',
  full: '%a %b %e %H:%M:%S %Z %Y',
}
