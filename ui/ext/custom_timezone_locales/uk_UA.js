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
  name: 'uk_UA',
  day: {
    abbrev: ['нд', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб'],
    full: ['неділя', 'понеділок', 'вівторок', 'середа', 'четвер', "п'ятниця", 'субота'],
  },
  month: {
    abbrev: [
      'січ',
      'лют',
      'бер',
      'квіт',
      'трав',
      'черв',
      'лип',
      'серп',
      'вер',
      'жовт',
      'лист:',
      'груд',
    ],
    full: [
      'січень',
      'лютий',
      'березень',
      'квітень',
      'травень',
      'червень',
      'липень',
      'серпень',
      'вересень',
      'жовтень',
      'листопад',
      'грудень',
    ],
  },
  meridiem: ['', ''],
  date: '%d.%m.%y',
  time24: '%T',
  dateTime: '%a, %d-%b-%Y %X %z',
  full: '%A, %-d %Om %Y %X %z',
  time12: '',
}
