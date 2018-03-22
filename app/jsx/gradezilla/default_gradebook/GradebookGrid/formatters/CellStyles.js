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

/* eslint-disable import/prefer-default-export */
export function classNamesForAssignmentCell (assignment, submissionData) {
  const classNames = [];

  if (submissionData) {
    // Exclusive Classes (only one of these can be used at a time)
    if (submissionData.dropped) {
      classNames.push('dropped');
    } else if (submissionData.excused) {
      classNames.push('excused');
    } else if (submissionData.resubmitted) {
      classNames.push('resubmitted');
    } else if (submissionData.missing) {
      classNames.push('missing');
    } else if (submissionData.late) {
      classNames.push('late');
    }
  }

  if (String(assignment.submissionTypes) === 'not_graded') {
    classNames.push('ungraded');
  }

  if (assignment.muted) {
    classNames.push('muted');
  }

  return classNames;
}
