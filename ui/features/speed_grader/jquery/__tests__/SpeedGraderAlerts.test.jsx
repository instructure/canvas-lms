/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import fakeENV from '@canvas/test-utils/fakeENV'
import $ from 'jquery'
import SpeedGraderAlerts from '../../react/SpeedGraderAlerts'
import '@canvas/rails-flash-notifications'

describe('SpeedGraderAlerts', () => {
  let $flashMessage

  beforeEach(() => {
    $flashMessage = $('<div>').appendTo(document.body)
    $.flashMessage = jest.fn(message => {
      $flashMessage.text(message)
      return $flashMessage
    })
  })

  afterEach(() => {
    $flashMessage.remove()
    fakeENV.teardown()
  })

  describe('showStudentGroupChangeAlert', () => {
    it('shows an alert when student is not in selected group', () => {
      SpeedGraderAlerts.showStudentGroupChangeAlert({
        selectedStudentGroup: {name: 'Group 1'},
        reasonForChange: 'student_not_in_selected_group',
      })

      expect($flashMessage.text()).toContain(
        'The group "Group 1" was selected because the student you requested is not in the previously-selected group',
      )
    })

    it('shows an alert when no students are in group', () => {
      SpeedGraderAlerts.showStudentGroupChangeAlert({
        selectedStudentGroup: {name: 'Group 1'},
        reasonForChange: 'no_students_in_group',
      })

      expect($flashMessage.text()).toContain(
        'The group "Group 1" was selected because the previously-selected group contains no students',
      )
    })

    it('shows an alert when no group was previously selected', () => {
      SpeedGraderAlerts.showStudentGroupChangeAlert({
        selectedStudentGroup: {name: 'Group 1'},
        reasonForChange: 'no_group_selected',
      })

      expect($flashMessage.text()).toContain(
        'The group "Group 1" was automatically selected because no group was previously chosen',
      )
    })
  })
})
