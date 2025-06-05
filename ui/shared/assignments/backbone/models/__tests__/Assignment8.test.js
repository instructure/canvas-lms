/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
  describe('#suppressAssignment', () => {
    let assignment
    beforeEach(() => {
      assignment = new Assignment()
      fakeENV.setup({current_user_roles: []})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('called with params', () => {
      expect(assignment.suppressAssignment()).toBe(undefined)
      assignment.suppressAssignment(true)
      expect(assignment.suppressAssignment()).toBe(true)
    })

    it('called without params', () => {
      expect(assignment.suppressAssignment()).toBe(undefined)
    })
  })
})
