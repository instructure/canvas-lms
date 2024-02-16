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
import 'jquery-migrate'
import SpeedGraderAlerts from 'ui/features/speed_grader/react/SpeedGraderAlerts'

QUnit.module('SpeedGraderAlerts', hooks => {
  QUnit.module('showStudentGroupChangeAlert', () => {
    let flashStub
    let selectedStudentGroup
    let reasonForChange
    let showAlert

    hooks.beforeEach(() => {
      flashStub = sandbox.stub($, 'flashMessage')
      selectedStudentGroup = {name: 'Some Group or Other'}
      reasonForChange = null

      showAlert = SpeedGraderAlerts.showStudentGroupChangeAlert
    })

    hooks.afterEach(() => {
      flashStub.restore()
    })

    QUnit.module('when reasonForChange = student_not_in_selected_group', changeHooks => {
      changeHooks.beforeEach(() => {
        reasonForChange = 'student_not_in_selected_group'
      })

      test('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        strictEqual(flashStub.callCount, 1)
      })

      test('displays a message indicating the selected student was not in the previous group', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(
          flashStub.firstCall.args[0].includes(
            'the student you requested is not in the previously-selected group'
          )
        )
      })

      test('includes the newly-selected group name in the message', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(flashStub.firstCall.args[0].includes('Some Group or Other'))
      })
    })

    QUnit.module('when reasonForChange = no_students_in_group', changeHooks => {
      changeHooks.beforeEach(() => {
        reasonForChange = 'no_students_in_group'
      })

      test('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        strictEqual(flashStub.callCount, 1)
      })

      test('displays a message indicating no students were in the previously-selected group', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(
          flashStub.firstCall.args[0].includes('the previously-selected group contains no students')
        )
      })

      test('includes the newly-selected group name in the message', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(flashStub.firstCall.args[0].includes('Some Group or Other'))
      })
    })

    QUnit.module('when reasonForChange = no_group_selected', changeHooks => {
      changeHooks.beforeEach(() => {
        reasonForChange = 'no_group_selected'
      })

      test('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        strictEqual(flashStub.callCount, 1)
      })

      test('displays a message indicating no group had been selected', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(flashStub.firstCall.args[0].includes('no group was previously chosen'))
      })

      test('includes the newly-selected group name in the message', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(flashStub.firstCall.args[0].includes('Some Group or Other'))
      })
    })

    QUnit.module('when reasonForChange = student_in_no_groups', changeHooks => {
      changeHooks.beforeEach(() => {
        reasonForChange = 'student_in_no_groups'
      })

      test('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        strictEqual(flashStub.callCount, 1)
      })

      test('displays a message indicating the selected student was not in the previous group', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        ok(
          flashStub.firstCall.args[0].includes(
            'the student you requested is not part of any groups'
          )
        )
      })
    })

    test('displays no alert when reasonForChange is set to an unrecognized value', () => {
      showAlert({selectedStudentGroup, reasonForChange: 'i_have_no_idea'})
      strictEqual(flashStub.callCount, 0)
    })

    test('displays no alert when reasonForChange is not set', () => {
      showAlert({selectedStudentGroup})
      strictEqual(flashStub.callCount, 0)
    })
  })
})
