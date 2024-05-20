// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import htmlEscape from '@instructure/html-escape'
import {useScope as useI18nScope} from '@canvas/i18n'
import listFormatterPolyfill from '@canvas/util/listFormatter'
import type Gradebook from '../../Gradebook'

const I18n = useI18nScope('gradebook')

const listFormatter = Intl.ListFormat
  ? new Intl.ListFormat(ENV.LOCALE || navigator.language)
  : listFormatterPolyfill

export function getSecondaryDisplayInfo(
  student: {
    sections: string[]
    group_ids: string[]
    login_id: string
    sis_user_id?: string
    integration_id?: string
  },
  secondaryInfo: string,
  options
) {
  if (options.shouldShowSections() && secondaryInfo === 'section') {
    const sectionNames: string[] = (student?.sections || [])
      .filter(options.isVisibleSection)
      .map((sectionId: string) => options.getSection(sectionId).name)
    return listFormatter.format(sectionNames.sort())
  }

  if (options.shouldShowGroups() && secondaryInfo === 'group') {
    const groupNames: string[] = student.group_ids.map(
      (groupId: string) => options.getGroup(groupId).name
    )
    return listFormatter.format(groupNames.sort())
  }

  return {
    login_id: student.login_id,
    sis_id: student.sis_user_id,
    integration_id: student.integration_id,
  }[secondaryInfo]
}

export function getEnrollmentLabel(student: {isConcluded: boolean; isInactive: boolean}) {
  if (student.isConcluded) {
    return I18n.t('concluded')
  }
  if (student.isInactive) {
    return I18n.t('inactive')
  }

  return null
}

export function getOptions(gradebook: Gradebook) {
  return {
    courseId: gradebook.options.context_id,
    getSection(sectionId: string) {
      return gradebook.sections[sectionId]
    },
    getGroup(groupId: string) {
      return gradebook.studentGroups[groupId]
    },
    getSelectedPrimaryInfo() {
      return gradebook.getSelectedPrimaryInfo()
    },
    getSelectedSecondaryInfo() {
      return gradebook.getSelectedSecondaryInfo()
    },
    isVisibleSection(sectionId: string) {
      return gradebook.sections[sectionId] != null
    },
    shouldShowSections() {
      return gradebook.showSections()
    },
    shouldShowGroups() {
      return gradebook.studentGroupsEnabled
    },
  }
}

// xsslint safeString.property enrollmentLabel secondaryInfo studentId courseId url displayName
export function renderCell(options) {
  let enrollmentStatus = ''
  let secondaryInfo = ''

  if (options.enrollmentLabel) {
    const title = I18n.t('This user is currently not able to access the course')
    // xsslint safeString.identifier title
    enrollmentStatus = `&nbsp;<span title="${title}" class="label">${options.enrollmentLabel}</span>`
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
      >${htmlEscape(options.displayName)}</a>
      ${enrollmentStatus}
    </div>
    ${secondaryInfo}
  `
}
