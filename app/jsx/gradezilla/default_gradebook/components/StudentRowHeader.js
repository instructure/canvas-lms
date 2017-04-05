/*
 * Copyright (C) 2017 Instructure, Inc.
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

import RowStudentNameTemplate from 'jst/gradezilla/row_student_name';
import I18n from 'i18n!gradebook';
import 'jst/_avatar';

function getPrimaryDisplayInfo (student, displayAs) {
  return {
    first_last: { displayName: student.name, anonymous: false},
    last_first: { displayName: student.sortable_name, anonymous: false},
    anonymous: { displayName: '', anonymous: true}
  }[displayAs];
}

function getSecondaryDisplayInfo (student, opts) {
  return {
    sis_id: { secondaryInfo: student.sis_user_id, sectionNames: null },
    login_id: { secondaryInfo: student.login_id, sectionNames: null },
    section: { secondaryInfo: null, sectionNames: opts.sectionNames },
    none: {}
  }[opts.selectedSecondaryInfo];
}

function getEnrollmentLabel (student) {
  if (student.isConcluded) {
    return I18n.t('concluded');
  } else if (student.isInactive) {
    return I18n.t('inactive');
  }
  return null;
}

class StudentRowHeader {
  constructor (student, opts) {
    this.student = student;
    this.opts = opts;
    this.render = this.render.bind(this);
  }

  render () {
    const student = this.student;
    const opts = this.opts;
    const url = `${student.enrollments[0].grades.html_url}#tab-assignments`;
    const { displayName, anonymous } = getPrimaryDisplayInfo(student, opts.selectedPrimaryInfo);
    const { secondaryInfo, sectionNames } = getSecondaryDisplayInfo(student, opts);

    return RowStudentNameTemplate({
      student_id: student.id,
      course_id: opts.courseId,
      avatar_url: student.avatar_url,
      display_name: displayName,
      enrollment_status: getEnrollmentLabel(student),
      alreadyEscaped: true,
      sectionNames,
      secondaryInfo,
      url,
      anonymous
    });
  }
}

export default StudentRowHeader;
