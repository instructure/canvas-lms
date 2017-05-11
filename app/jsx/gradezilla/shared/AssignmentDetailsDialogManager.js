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

import AssignmentDetailsDialog from 'compiled/AssignmentDetailsDialog'


  function prepareStudents (students, assignmentId) {
    return students.map((student) => {
      const processedStudent = {};

      if (student.submission) {
        processedStudent[`assignment_${assignmentId}`] = {
          score: student.submission.score
        }
      }

      return processedStudent;
    });
  }

  function getAssignmentDetailsDialogOptions (assignment, students) {
    return {
      assignment,
      students: prepareStudents(students, assignment.id)
    };
  }

  class AssignmentDetailsDialogManager {
    constructor (assignment, students, submissionsLoaded = false) {
      this.assignment = assignment;
      this.students = students;
      this.submissionsLoaded = submissionsLoaded;

      this.showDialog = this.showDialog.bind(this);
    }

    showDialog () {
      const opts = getAssignmentDetailsDialogOptions(this.assignment, this.students);
      AssignmentDetailsDialog.show(opts);
    }

    isDialogEnabled () {
      return this.submissionsLoaded;
    }
  }

export default AssignmentDetailsDialogManager
