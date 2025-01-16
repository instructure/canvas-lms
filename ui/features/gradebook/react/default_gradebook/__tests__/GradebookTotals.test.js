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

import $ from 'jquery'
import 'jquery-migrate'
import UserSettings from '@canvas/user-settings'
import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook Totals', () => {
  let gradebook
  let mockAjaxJSON

  beforeEach(() => {
    mockAjaxJSON = jest.fn()
    $.ajaxJSON = mockAjaxJSON

    // Mock jQuery dialog
    $.fn.dialog = jest.fn().mockImplementation(function () {
      return this
    })
    $.fn.data = jest.fn()

    gradebook = createGradebook({
      show_total_grade_as_points: true,
      setting_update_url: 'http://settingUpdateUrl',
    })

    gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: jest.fn(),
      },
    }

    gradebook.gradebookGrid.invalidate = jest.fn()
  })

  afterEach(() => {
    UserSettings.contextRemove('warned_about_totals_display')
    gradebook.destroy()
    jest.clearAllMocks()
  })

  describe('#switchTotalDisplay', () => {
    it('sets the warning preference when dontWarnAgain is true', () => {
      expect(UserSettings.contextGet('warned_about_totals_display')).toBeFalsy()
      gradebook.switchTotalDisplay({dontWarnAgain: true})
      expect(UserSettings.contextGet('warned_about_totals_display')).toBe(true)
    })

    it('allows toggling show_total_grade_as_points option', () => {
      const originalValue = gradebook.options.show_total_grade_as_points
      gradebook.options.show_total_grade_as_points = !originalValue
      expect(gradebook.options.show_total_grade_as_points).not.toBe(originalValue)
    })

    it('disables Show Total Grade as Points when previously enabled', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      expect(gradebook.options.show_total_grade_as_points).toBe(false)
    })

    it('enables Show Total Grade as Points when previously disabled', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      expect(gradebook.options.show_total_grade_as_points).toBe(true)
    })

    it('updates user preferences via API', () => {
      $.ajaxJSON = jest.fn().mockImplementation((url, method, data) => {
        return $.Deferred().resolve().promise()
      })

      gradebook.switchTotalDisplay({dontWarnAgain: false})
      expect($.ajaxJSON).toHaveBeenCalledWith('http://settingUpdateUrl', 'PUT', {
        show_total_grade_as_points: false,
      })
    })

    it('invalidates the grid to trigger re-render', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      expect(gradebook.gradebookGrid.invalidate).toHaveBeenCalled()
    })

    it('updates column headers', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalled()
    })

    describe('with total grade override column', () => {
      it('updates both total grade column headers when override is enabled', () => {
        gradebook.courseSettings.setAllowFinalGradeOverride(true)
        gradebook.switchTotalDisplay({dontWarnAgain: false})
        expect(
          gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders,
        ).toHaveBeenCalledWith(['total_grade', 'total_grade_override'])
      })

      it('updates only total grade column header when override is disabled', () => {
        gradebook.courseSettings.setAllowFinalGradeOverride(false)
        gradebook.switchTotalDisplay({dontWarnAgain: false})
        expect(
          gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders,
        ).toHaveBeenCalledWith(['total_grade'])
      })
    })
  })

  describe('#togglePointsOrPercentTotals', () => {
    beforeEach(() => {
      jest.spyOn(gradebook, 'switchTotalDisplay')
    })

    it('immediately toggles display when warnings are ignored', () => {
      UserSettings.contextSet('warned_about_totals_display', true)
      gradebook.togglePointsOrPercentTotals()
      expect(gradebook.switchTotalDisplay).toHaveBeenCalled()
    })

    it('invokes callback when warnings are ignored', () => {
      const callback = jest.fn()
      UserSettings.contextSet('warned_about_totals_display', true)
      gradebook.togglePointsOrPercentTotals(callback)
      expect(callback).toHaveBeenCalled()
    })

    it('returns warning dialog when warnings are not ignored', () => {
      UserSettings.contextSet('warned_about_totals_display', false)
      const dialog = gradebook.togglePointsOrPercentTotals()
      expect(dialog).toBeTruthy()
      expect(dialog.constructor.name).toBe('GradeDisplayWarningDialog')
    })

    it('sets switchTotalDisplay as dialog save function', () => {
      UserSettings.contextSet('warned_about_totals_display', false)
      const dialog = gradebook.togglePointsOrPercentTotals()
      expect(dialog.options.save).toBe(gradebook.switchTotalDisplay)
    })

    it('sets callback as dialog onClose function', () => {
      const callback = jest.fn()
      UserSettings.contextSet('warned_about_totals_display', false)
      const dialog = gradebook.togglePointsOrPercentTotals(callback)
      expect(dialog.options.onClose).toBe(callback)
    })
  })
})
