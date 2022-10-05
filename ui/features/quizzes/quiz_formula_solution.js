/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import numberHelper from '@canvas/i18n/numberHelper'

export default class QuizFormulaSolution {
  constructor(result) {
    this.result = result
  }

  rawValue() {
    return numberHelper.parse(this.rawText())
  }

  rawText() {
    if (this.result === null || this.result === undefined) {
      return 'NaN'
    }
    return this.result.substring(1).trim()
  }

  isValid() {
    return !!(this._wellFormedString() && this._appropriateSolutionValue())
  }

  _wellFormedString() {
    const result = this.result
    return !!(result.match(/^=/) && result !== '= NaN' && result !== '= Infinity')
  }

  _appropriateSolutionValue() {
    const rawVal = this.rawValue()
    return !!(rawVal == 0 || rawVal)
  }
}
