// @ts-nocheck
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

import {
  getSecondaryDisplayInfo,
  getEnrollmentLabel,
  getOptions,
  renderCell,
} from './StudentCellFormatter.utils'
import type Gradebook from '../../Gradebook'

export default class StudentCellFormatter {
  options: ReturnType<typeof getOptions>

  constructor(gradebook: Gradebook) {
    this.options = getOptions(gradebook)
  }

  render = (_row, _cell, _value, _columnDef, student /* dataContext */) => {
    if (student.isPlaceholder) {
      return ''
    }

    const primaryInfo = this.options.getSelectedPrimaryInfo()
    const secondaryInfo = this.options.getSelectedSecondaryInfo()

    const options = {
      courseId: this.options.courseId,
      displayName: primaryInfo === 'last_first' ? student.sortable_name : student.name,
      enrollmentLabel: getEnrollmentLabel(student),
      secondaryInfo: getSecondaryDisplayInfo(student, secondaryInfo, this.options),
      studentId: student.id,
      url: `${student.enrollments[0].grades.html_url}#tab-assignments`,
    }

    return renderCell(options)
  }
}
