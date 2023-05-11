// @ts-nocheck
/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import type GradeOverride from '../GradeOverride'

type Attr = {
  enteredAs: string | null
  enteredValue: string
  grade: GradeOverride | null
  valid: boolean | null
}

export default class GradeOverrideInfo {
  _attr: Attr

  constructor(attr = {}) {
    this._attr = {
      enteredAs: null,
      enteredValue: '',
      grade: null,
      valid: null,
      ...attr,
    }
  }

  get enteredAs() {
    return this._attr.enteredAs
  }

  get enteredValue() {
    return this._attr.enteredValue
  }

  get grade() {
    return this._attr.grade
  }

  get valid() {
    return this._attr.valid
  }

  equals(gradeOverrideInfo) {
    return this.grade?.equals(gradeOverrideInfo.grade)
  }
}
