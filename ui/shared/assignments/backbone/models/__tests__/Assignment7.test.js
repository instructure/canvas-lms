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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Assignment', () => {
  describe('#quizzesRespondusEnabled', () => {
    let assignment

    beforeEach(() => {
      assignment = new Assignment()
      fakeENV.setup({current_user_roles: []})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('returns false if the assignment is not RLDB enabled', () => {
      fakeENV.setup({current_user_roles: ['student']})
      assignment.set('require_lockdown_browser', false)
      assignment.set('is_quiz_lti_assignment', true)
      expect(assignment.quizzesRespondusEnabled()).toBe(false)
    })

    it('returns false if the assignment is not a N.Q assignment', () => {
      fakeENV.setup({current_user_roles: ['student']})
      assignment.set('require_lockdown_browser', true)
      assignment.set('is_quiz_lti_assignment', false)
      expect(assignment.quizzesRespondusEnabled()).toBe(false)
    })

    it('returns false if the user is not a student', () => {
      fakeENV.setup({current_user_roles: ['teacher']})
      assignment.set('require_lockdown_browser', true)
      assignment.set('is_quiz_lti_assignment', true)
      expect(assignment.quizzesRespondusEnabled()).toBe(false)
    })

    it('returns true if the assignment is a RLDB enabled N.Q', () => {
      fakeENV.setup({current_user_roles: ['student']})
      assignment.set('require_lockdown_browser', true)
      assignment.set('is_quiz_lti_assignment', true)
      expect(assignment.quizzesRespondusEnabled()).toBe(true)
    })
  })

  describe('#externalToolTagAttributes', () => {
    const externalData = {
      key1: 'val1',
    }
    const customParams = {
      root_account_id: '$Canvas.rootAccount.id',
      referer: 'LTI test tool example',
    }
    let assignment

    beforeEach(() => {
      assignment = new Assignment({
        name: 'Sample Assignment',
        external_tool_tag_attributes: {
          content_id: 999,
          content_type: 'context_external_tool',
          custom_params: customParams,
          new_tab: '0',
          url: 'http://lti13testtool.docker/launch',
          external_data: externalData,
        },
      })
      fakeENV.setup({current_user_roles: []})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it("returns url from assignment's external tool attributes", () => {
      const url = assignment.externalToolUrl()
      expect(url).toBe('http://lti13testtool.docker/launch')
    })

    it("returns external data from assignment's external tool attributes", () => {
      const data = assignment.externalToolData()
      expect(data.key1).toBe('val1')
      expect(assignment.externalToolDataStringified()).toBe(JSON.stringify(externalData))
    })

    it("returns custom params from assignment's external tool attributes", () => {
      expect(assignment.externalToolCustomParams()).toBe(customParams)
    })

    it("returns custom params stringified from assignment's external tool attributes", () => {
      const data = assignment.externalToolCustomParamsStringified()
      expect(data).toBe(JSON.stringify(customParams))
    })

    it("returns new tab from assignment's external tool attributes", () => {
      expect(assignment.externalToolNewTab()).toBe('0')
    })
  })
})
