/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('permissions_templates_8')

export const GROUP_PERMISSION_DESCRIPTIONS = {
  manage_courses: contextType => {
    return contextType === 'Course'
      ? I18n.t('conclude / delete / publish / reset')
      : I18n.t('add / manage / conclude / delete / publish / reset')
  },
  manage_files: () => I18n.t('add / delete / edit'),
  manage_groups: () => I18n.t('add / delete / manage'),
  manage_lti: () => I18n.t('add / delete / edit'),
  manage_sections: () => I18n.t('add / delete / edit'),
  manage_wiki: () => I18n.t('create / delete / update'),
  manage_assignments_and_quizzes: () => I18n.t('add / delete / edit'),
  manage_course_content: () => I18n.t('add / delete / edit'),
  manage_course_student_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_teacher_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_ta_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_observer_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_designer_enrollments: () => I18n.t('add / remove in courses'),
  manage_course_templates: () => I18n.t('create / delete / edit'),
}
