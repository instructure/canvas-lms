/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from './i18nObj'

const numberFormat = {
  _format(
    n: number,
    options: {
      precision?: number
      strip_insignificant_zeros?: boolean
    }
  ) {
    if (typeof n !== 'number' || Number.isNaN(Number(n))) {
      return n
    }
    return I18n.n(n, options)
  },

  outcomeScore(n: number) {
    return numberFormat._format(n, {precision: 2, strip_insignificant_zeros: true})
  },
}

export default numberFormat
