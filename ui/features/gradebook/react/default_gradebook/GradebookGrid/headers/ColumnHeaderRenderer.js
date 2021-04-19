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

import AssignmentColumnHeaderRenderer from './AssignmentColumnHeaderRenderer'
import AssignmentGroupColumnHeaderRenderer from './AssignmentGroupColumnHeaderRenderer'
import CustomColumnHeaderRenderer from './CustomColumnHeaderRenderer'
import StudentColumnHeaderRenderer from './StudentColumnHeaderRenderer'
import TotalGradeColumnHeaderRenderer from './TotalGradeColumnHeaderRenderer'
import TotalGradeOverrideColumnHeaderRenderer from './TotalGradeOverrideColumnHeaderRenderer'

export default class ColumnHeaderRenderer {
  constructor(gradebook) {
    this.gradebook = gradebook
    this.factories = {
      assignment: new AssignmentColumnHeaderRenderer(gradebook),
      assignment_group: new AssignmentGroupColumnHeaderRenderer(gradebook),
      custom_column: new CustomColumnHeaderRenderer(gradebook),
      student: new StudentColumnHeaderRenderer(gradebook),
      total_grade: new TotalGradeColumnHeaderRenderer(gradebook),
      total_grade_override: new TotalGradeOverrideColumnHeaderRenderer(gradebook)
    }
  }

  renderColumnHeader(column, $container, gridSupport) {
    if (this.factories[column.type]) {
      const options = {
        ref: header => {
          this.gradebook.setHeaderComponentRef(column.id, header)
        }
      }
      // The container to render into needs to be slick-column-name because
      // overwriting slick-column-name can cause slick-resizable-handle to be
      // ordered as the first child. This causes issues because React expects
      // to unmount the component at the first child.
      const $nameNode = $container.querySelector('.slick-column-name')
      this.factories[column.type].render(column, $nameNode, gridSupport, options)
    }
  }

  destroyColumnHeader(column, $container, gridSupport) {
    if (this.factories[column.type]) {
      this.gradebook.removeHeaderComponentRef(column.id)
      const $nameNode = $container.querySelector('.slick-column-name')
      this.factories[column.type].destroy(column, $nameNode, gridSupport)
    }
  }
}
