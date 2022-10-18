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
  name: 'he_IL',
  day: {
    abbrev: ["א'", "ב'", "ג'", "ד'", "ה'", "ו'", "ש'"],
    full: ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'],
  },
  month: {
    abbrev: [
      'ינו׳',
      'פבר׳',
      'מרץ',
      'אפר׳',
      'מאי',
      'יונ',
      'יול',
      'אוג׳',
      'ספט׳',
      'אוק׳',
      'נוב׳',
      'דצמ׳',
    ],
    full: [
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר',
    ],
  },
  meridiem: ['AM', 'PM'],
  date: '%d/%m/%y',
  time24: '%H:%M:%S',
  dateTime: '%Z %H:%M:%S %Y %b %d %a',
  time12: '%I:%M:%S %P',
  full: '%a %b %e %H:%M:%S %Z %Y',
}
