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

import AssignmentCellFormatter from './AssignmentCellFormatter'
import AssignmentGroupCellFormatter from './AssignmentGroupCellFormatter'
import CustomColumnCellFormatter from './CustomColumnCellFormatter'
import StudentCellFormatter from './StudentCellFormatter'
import TotalGradeCellFormatter from './TotalGradeCellFormatter'
import TotalGradeOverrideCellFormatter from './TotalGradeOverrideCellFormatter'

class CellFormatterFactory {
  constructor(gradebook) {
    this.formatters = {
      assignment: new AssignmentCellFormatter(gradebook),
      assignment_group: new AssignmentGroupCellFormatter(),
      custom_column: new CustomColumnCellFormatter(),
      student: new StudentCellFormatter(gradebook),
      total_grade: new TotalGradeCellFormatter(gradebook),
      total_grade_override: new TotalGradeOverrideCellFormatter(gradebook)
    }
  }

  getFormatter(column) {
    return (this.formatters[column.type] || {}).render
  }
}

export default CellFormatterFactory
