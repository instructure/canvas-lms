/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
  name: 'ga_IE',
  day: {
    abbrev: ['Domh', 'Luan', 'Máirt', 'Céad', 'Déar', 'Aoine', 'Sath'],
    full: [
      'Dé Domhnaigh',
      'Dé Luain',
      'Dé Máirt',
      'Dé Céadaoin',
      'Déardaoin',
      'Dé hAoine',
      'Dé Sathairn',
    ],
  },
  month: {
    abbrev: [
      'Ean',
      'Feabh',
      'Márt',
      'Aib',
      'Beal',
      'Meith',
      'Iúil',
      'Lún',
      'M.F.',
      'D.F.',
      'Samh',
      'Noll',
    ],
    full: [
      'Eanáir',
      'Feabhra',
      'Márta',
      'Aibreán',
      'Bealtaine',
      'Meitheamh',
      'Iúil',
      'Lúnasa',
      'Meán Fómhair',
      'Deireadh Fómhair',
      'Samhain',
      'Nollaig',
    ],
  },
  meridiem: ['', ''],
  date: '%d/%m/%y',
  time24: '%T',
  dateTime: '%d %b %Y %T',
  time12: '',
  full: '%a %d %b %Y %T %Z',
}
