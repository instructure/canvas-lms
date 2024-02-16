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
  name: 'id_ID',
  day: {
    abbrev: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'],
    full: ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'],
  },
  month: {
    abbrev: ['Jan', 'Peb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'],
    full: [
      'Januari',
      'Pebruari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ],
  },
  meridiem: ['', ''],
  date: '%d/%m/%y',
  time24: '%T',
  dateTime: '%a %d %b %Y %r %Z',
  time12: '',
  full: '%a %b %e %H:%M:%S %Z %Y',
}
