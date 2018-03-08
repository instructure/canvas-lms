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

export default class ColumnHeaderRenderer {
  constructor (gradebook) {
    this.gradebook = gradebook;
    this.factories = {
      assignment: new AssignmentColumnHeaderRenderer(gradebook),
      assignment_group: new AssignmentGroupColumnHeaderRenderer(gradebook),
      custom_column: new CustomColumnHeaderRenderer(gradebook),
      student: new StudentColumnHeaderRenderer(gradebook),
      total_grade: new TotalGradeColumnHeaderRenderer(gradebook)
    };
  }

  renderColumnHeader (column, $container, gridSupport) {
    if (this.factories[column.type]) {
      const options = {
        ref: (header) => {
          this.gradebook.setHeaderComponentRef(column.id, header);
        }
      };
      this.factories[column.type].render(column, $container, gridSupport, options);
    }
  }

  destroyColumnHeader (column, $container, gridSupport) {
    if (this.factories[column.type]) {
      this.gradebook.removeHeaderComponentRef(column.id);
      this.factories[column.type].destroy(column, $container, gridSupport);
    }
  }
}
