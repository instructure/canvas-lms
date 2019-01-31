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

import $ from 'jquery'
import I18n from 'i18n!gradebook'
import 'jquery.instructure_misc_helpers' // $.toSentence

function getSecondaryDisplayInfo(student, secondaryInfo, options) {
  if (options.shouldShowSections() && secondaryInfo === 'section') {
    const sectionNames = student.sections.map(sectionId => options.getSection(sectionId).name)
    return $.toSentence(sectionNames.sort())
  }
  return {
    login_id: student.login_id,
    sis_id: student.sis_user_id,
    integration_id: student.integration_id
  }[secondaryInfo]
}

function getEnrollmentLabel(student) {
  if (student.isConcluded) {
    return I18n.t('concluded')
  }
  if (student.isInactive) {
    return I18n.t('inactive')
  }

  return null
}

// xsslint safeString.property enrollmentLabel secondaryInfo studentId courseId url displayName
function render(options) {
  let enrollmentStatus = ''
  let secondaryInfo = ''

  if (options.enrollmentLabel) {
    const title = I18n.t('This user is currently not able to access the course')
    // xsslint safeString.identifier title
    enrollmentStatus = `&nbsp;<span title="${title}" class="label">${
      options.enrollmentLabel
    }</span>`
  }

  if (options.secondaryInfo) {
    secondaryInfo = `<div class="secondary-info">${options.secondaryInfo}</div>`
  }

  // xsslint safeString.identifier enrollmentStatus secondaryInfo
  return `
    <div class="student-name">
      <a
        class="student-grades-link student_context_card_trigger"
        data-student_id="${options.studentId}"
        data-course_id="${options.courseId}"
        href="${options.url}"
      >${options.displayName}</a>
      ${enrollmentStatus}
    </div>
    ${secondaryInfo}
  `
}

export default class StudentCellFormatter {
  constructor(gradebook) {
    this.options = {
      courseId: gradebook.options.context_id,
      getSection(sectionId) {
        return gradebook.sections[sectionId]
      },
      getSelectedPrimaryInfo() {
        return gradebook.getSelectedPrimaryInfo()
      },
      getSelectedSecondaryInfo() {
        return gradebook.getSelectedSecondaryInfo()
      },
      shouldShowSections() {
        return gradebook.showSections()
      }
    }
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
      url: `${student.enrollments[0].grades.html_url}#tab-assignments`
    }

    return render(options)
  }
}
