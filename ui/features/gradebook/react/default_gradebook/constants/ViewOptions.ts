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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook_constants')

export const filterLabels = {
  assignmentGroups: I18n.t('Assignment Groups'),
  gradingPeriods: I18n.t('Grading Periods'),
  modules: I18n.t('Modules'),
  sections: I18n.t('Sections'),
  studentGroups: I18n.t('Student Groups'),
}

export default {
  filterLabels,
}
