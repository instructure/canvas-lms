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

define([
  'jquery',
  'compiled/shared/CurveGradesDialog',
  'i18n!gradebook',
  'compiled/jquery.rails_flash_notifications'
], ($, CurveGradesDialog, I18n) => {
  const CurveGradesDialogManager = {
    createCurveGradesAction (assignment, students, {isAdmin, contextUrl, submissionsLoaded} = {}) {
      const { grading_type: gradingType, points_possible: pointsPossible } = assignment;
      return {
        isDisabled: !submissionsLoaded || gradingType === 'pass_fail' || pointsPossible == null || pointsPossible === 0,

        onSelect () { // eslint-disable-line consistent-return
          if (!isAdmin && assignment.inClosedGradingPeriod) {
            return $.flashError(I18n.t('Unable to curve grades because this assignment is due in a closed ' +
              'grading period for at least one student'));
          }
          const dialog = new CurveGradesDialog({assignment, students, context_url: contextUrl});
          dialog.show();
        }
      };
    }
  }
  return CurveGradesDialogManager
});
