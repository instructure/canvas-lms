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

class AssignmentRowCellPropFactory {
  constructor (assignment, gradebook) {
    this.assignment = assignment;
    this.gradebook = gradebook;
  }

  isTrayOpenForThisCell = (student) => {
    const { open, studentId, assignmentId } = this.gradebook.getSubmissionTrayState();
    return open && studentId === student.id && assignmentId === this.assignment.id;
  }

  getProps (student) {
    return {
      isSubmissionTrayOpen: this.isTrayOpenForThisCell(student),
      onToggleSubmissionTrayOpen: this.gradebook.toggleSubmissionTrayOpen
    };
  }
}

export default AssignmentRowCellPropFactory;
