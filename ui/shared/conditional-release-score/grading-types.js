/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

const I18n = useI18nScope('cyoe_assignment_sidebar_grading_types')

const GradingTypes = {
  points: {
    get label() {
      return I18n.t('points')
    },
    key: 'points',
  },
  percent: {
    get label() {
      return I18n.t('percent')
    },
    key: 'percent',
  },
  letter_grade: {
    get label() {
      return I18n.t('letter grade')
    },
    key: 'letter_grade',
  },
  gpa_scale: {
    get label() {
      return I18n.t('GPA scale')
    },
    key: 'gpa_scale',
  },
  other: {
    get label() {
      return I18n.t('other')
    },
    key: 'other',
  },
}

export default GradingTypes
