/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import * as DeepLinking from '@canvas/deep-linking/DeepLinking'
import * as Alerts from '@canvas/alerts/react/FlashAlert'
import {
  handleAssignmentIndexDeepLinking,
  alertUserModuleCreatedKey,
  alertIfDeepLinkingCreatedModule,
} from '../deepLinkingHelper'

// EVAL-3907 - remove or rewrite to remove spies on imports
describe.skip('handleAssignmentIndexDeepLinking', () => {
  const fakeEvent: {data: {moduleCreated?: boolean; placement?: string}} = {data: {}}

  beforeEach(() => {
    jest.spyOn(window.sessionStorage, 'setItem')
    jest.spyOn(DeepLinking, 'reloadPage')
  })

  afterEach(() => {
    jest.restoreAllMocks()
    window.sessionStorage.clear()
  })

  describe('the tool returned content that created a module', () => {
    beforeEach(() => {
      fakeEvent.data.moduleCreated = true
    })

    describe('the tool is installed at the course_assignments_menu placement', () => {
      beforeEach(() => {
        fakeEvent.data.placement = 'course_assignments_menu'
      })

      it('tells the page that it needs to alert the user a module was created', () => {
        handleAssignmentIndexDeepLinking(fakeEvent)

        expect(window.sessionStorage.setItem).toHaveBeenCalledWith(
          alertUserModuleCreatedKey,
          true.toString()
        )
        expect(DeepLinking.reloadPage).toHaveBeenCalledTimes(1)
      })
    })

    describe('the tool is installed somewhere else', () => {
      beforeEach(() => {
        fakeEvent.data.placement = 'foobarbaz'
      })

      it("tells the page that the user doesn't need to be alerted about module creation", () => {
        handleAssignmentIndexDeepLinking(fakeEvent)

        expect(window.sessionStorage.setItem).toHaveBeenCalledWith(
          alertUserModuleCreatedKey,
          false.toString()
        )
        expect(DeepLinking.reloadPage).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe("the tool returned content that didn't create a module", () => {
    beforeEach(() => {
      fakeEvent.data.moduleCreated = false
    })

    it('stores false in the moduleCreated sessionStorage key', () => {
      handleAssignmentIndexDeepLinking(fakeEvent)

      expect(window.sessionStorage.setItem).toHaveBeenCalledWith(
        alertUserModuleCreatedKey,
        false.toString()
      )
      expect(DeepLinking.reloadPage).toHaveBeenCalledTimes(1)
    })
  })
})

// EVAL-3907 - remove or rewrite to remove spies on imports
describe.skip('alertIfDeepLinkingCreatedModule', () => {
  beforeEach(() => {
    jest.spyOn(window.sessionStorage, 'getItem')
    jest.spyOn(window.sessionStorage, 'removeItem')
    jest.spyOn(Alerts, 'showFlashAlert').mockImplementation(() => {})
  })

  afterEach(() => {
    window.sessionStorage.clear()
  })

  describe('the user should be alerted that a module was created', () => {
    beforeEach(() => {
      window.sessionStorage.setItem(alertUserModuleCreatedKey, true.toString())
    })

    it('tries to alert the user that a module was created', () => {
      alertIfDeepLinkingCreatedModule()

      expect(Alerts.showFlashAlert).toHaveBeenCalledTimes(1)
      expect(window.sessionStorage.getItem(alertUserModuleCreatedKey)).toBeNull()
    })
  })

  describe("the user doesn't need to be told that a module was created", () => {
    beforeEach(() => {
      window.sessionStorage.setItem(alertUserModuleCreatedKey, false.toString())
    })

    it('does not alert the user', () => {
      alertIfDeepLinkingCreatedModule()

      expect(Alerts.showFlashAlert).not.toHaveBeenCalled()
      expect(window.sessionStorage.getItem(alertUserModuleCreatedKey)).toBeNull()
    })
  })
})
