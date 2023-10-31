/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

require('moment/locale/ja')
const moment = require('moment')

const data = moment.localeData('ja')

data._longDateFormat = {
  LT: 'HH:mm',
  LTS: 'HH:mm:ss',
  L: 'YYYY/MM/DD',
  LL: 'YYYY年M月D日',
  LLL: 'YYYY年M月D日 HH,mm',
  LLLL: 'YYYY年M月D日 dddd HH:mm',
  l: 'YYYY/MM/DD',
  ll: 'YYYY年M月D日',
  lll: 'YYYY年M月D日 HH:mm',
  llll: 'YYYY年M月D日(ddd) HH:mm',
}
