/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import I18n from 'i18n!speed_grader'
import 'compiled/jquery.rails_flash_notifications'

function showStudentGroupChangeAlert({selectedStudentGroup = null, reasonForChange = null} = {}) {
  const groupName = selectedStudentGroup?.name
  let groupText
  if (reasonForChange === 'student_not_in_selected_group') {
    groupText = I18n.t(
      `The group "%{groupName}" was selected because the student you requested is not in the previously-selected group. You can change the selected group in the Gradebook.`,
      {groupName}
    )
  } else if (reasonForChange === 'no_students_in_group') {
    groupText = I18n.t(
      `The group "%{groupName}" was selected because the previously-selected group contains no students. You can change the selected group in the Gradebook.`,
      {groupName}
    )
  } else if (reasonForChange === 'no_group_selected') {
    groupText = I18n.t(
      `The group "%{groupName}" was automatically selected because no group was previously chosen. You can change the selected group in the Gradebook.`,
      {groupName}
    )
  } else if (reasonForChange === 'student_in_no_groups') {
    groupText = I18n.t(
      `The selected group was cleared because the student you requested is not part of any groups. You can select a group in the Gradebook.`
    )
  }

  if (groupText != null) {
    $.flashMessage(groupText, 10000)
  }
}

const speedGraderAlerts = {showStudentGroupChangeAlert}

export default speedGraderAlerts
