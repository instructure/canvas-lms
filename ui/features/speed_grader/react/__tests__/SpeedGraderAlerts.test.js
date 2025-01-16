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
import SpeedGraderAlerts from '../SpeedGraderAlerts'

describe('SpeedGraderAlerts', () => {
  describe('showStudentGroupChangeAlert', () => {
    let flashStub
    let selectedStudentGroup
    let reasonForChange
    let showAlert

    beforeEach(() => {
      flashStub = jest.spyOn($, 'flashMessage').mockImplementation(() => {})
      selectedStudentGroup = {name: 'Some Group or Other'}
      reasonForChange = null

      showAlert = SpeedGraderAlerts.showStudentGroupChangeAlert
    })

    afterEach(() => {
      flashStub.mockRestore()
    })

    describe('when reasonForChange = student_not_in_selected_group', () => {
      beforeEach(() => {
        reasonForChange = 'student_not_in_selected_group'
      })

      it('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub).toHaveBeenCalledTimes(1)
      })

      it('displays a message indicating the selected student was not in the previous group', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(
          /the student you requested is not in the previously-selected group/i,
        )
      })

      it('includes the newly-selected group name in the message', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(/Some Group or Other/i)
      })
    })

    describe('when reasonForChange = no_students_in_group', () => {
      beforeEach(() => {
        reasonForChange = 'no_students_in_group'
      })

      it('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub).toHaveBeenCalledTimes(1)
      })

      it('displays a message indicating no students were in the previously-selected group', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(
          /the previously-selected group contains no students/i,
        )
      })

      it('includes the newly-selected group name in the message', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(/Some Group or Other/i)
      })
    })

    describe('when reasonForChange = no_group_selected', () => {
      beforeEach(() => {
        reasonForChange = 'no_group_selected'
      })

      it('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub).toHaveBeenCalledTimes(1)
      })

      it('displays a message indicating no group had been selected', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(/no group was previously chosen/i)
      })

      it('includes the newly-selected group name in the message', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(/Some Group or Other/i)
      })
    })

    describe('when reasonForChange = student_in_no_groups', () => {
      beforeEach(() => {
        reasonForChange = 'student_in_no_groups'
      })

      it('displays a flash alert', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub).toHaveBeenCalledTimes(1)
      })

      it('displays a message indicating the selected student was not in the previous group', () => {
        showAlert({selectedStudentGroup, reasonForChange})
        expect(flashStub.mock.calls[0][0]).toMatch(
          /the student you requested is not part of any groups/i,
        )
      })
    })

    it('displays no alert when reasonForChange is set to an unrecognized value', () => {
      showAlert({selectedStudentGroup, reasonForChange: 'i_have_no_idea'})
      expect(flashStub).not.toHaveBeenCalled()
    })

    it('displays no alert when reasonForChange is not set', () => {
      showAlert({selectedStudentGroup})
      expect(flashStub).not.toHaveBeenCalled()
    })
  })
})
