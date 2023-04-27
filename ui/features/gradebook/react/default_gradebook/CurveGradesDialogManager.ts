// @ts-nocheck
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
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'
import type {Assignment, StudentMap} from '../../../../api.d'

import AsyncComponents from './AsyncComponents'

const I18n = useI18nScope('gradebook')

const CurveGradesDialogManager = {
  createCurveGradesAction(
    assignment: Assignment,
    students: StudentMap,
    {
      isAdmin,
      contextUrl,
      submissionsLoaded,
    }: {
      isAdmin?: boolean
      contextUrl?: string
      submissionsLoaded?: boolean
    } = {}
  ) {
    const {grading_type: gradingType, points_possible: pointsPossible} = assignment
    return {
      isDisabled:
        !submissionsLoaded ||
        gradingType === 'pass_fail' ||
        pointsPossible == null ||
        pointsPossible === 0 ||
        !assignment.grades_published,

      async onSelect(onClose) {
        if (!isAdmin && assignment.inClosedGradingPeriod) {
          return $.flashError(
            I18n.t(
              'Unable to curve grades because this assignment is due in a closed ' +
                'grading period for at least one student'
            )
          )
        }

        const CurveGradesDialog = await AsyncComponents.loadCurveGradesDialog()
        const dialog = new CurveGradesDialog({assignment, students, context_url: contextUrl})
        dialog.show(onClose)
      },
    }
  },
}

export default CurveGradesDialogManager
