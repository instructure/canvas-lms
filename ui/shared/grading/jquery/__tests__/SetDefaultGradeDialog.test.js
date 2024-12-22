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
import '@testing-library/jest-dom'
import SetDefaultGradeDialog from '../SetDefaultGradeDialog'

describe('SetDefaultGradeDialog', () => {
  let assignment
  let dialog
  let $dialog
  let root

  beforeEach(() => {
    assignment = {
      grading_type: 'points',
      id: '2',
      name: 'an Assignment',
      points_possible: 10,
    }

    // Set up DOM elements
    document.body.innerHTML = `
      <div>
        <input type="checkbox" name="overwrite_existing_grades" />
        <div id="default_grade_with_checkpoints_mount_point"></div>
        <div id="default_grade_with_checkpoints_info_mount_point"></div>
      </div>
    `

    // Mock jQuery UI dialog
    $.fn.dialog = function (options) {
      if (typeof options === 'string') {
        if (options === 'close') {
          this.remove()
        }
        return this
      }
      $dialog = this
      return this
    }

    $.fn.fixDialogButtons = function () {
      // Mock the button setup
      const submitButton = document.createElement('button')
      submitButton.setAttribute('role', 'button')
      submitButton.textContent = 'Set Default Grade'
      this.append(submitButton)
      return this
    }

    // Mock jQuery form functions
    $.fn.getFormData = function () {
      const data = {}
      this.find('input').each(function () {
        data[this.name] = this.value
      })
      return data
    }

    $.fn.disableWhileLoading = function (_dfd) {
      return this
    }

    $.Deferred = function () {
      return {
        resolve: () => {},
        promise: () => ({}),
      }
    }

    $.when = function (...args) {
      return {
        then: callback => {
          // jQuery.when wraps responses in an array
          const wrappedResponses = args.map(response => [response])
          callback.apply(null, wrappedResponses)
          return {
            then: () => {},
          }
        },
      }
    }

    $.flashError = jest.fn()
    $.publish = jest.fn()
    $.ajaxJSON = jest.fn()
  })

  afterEach(() => {
    if (dialog?.$dialog) {
      dialog.$dialog.dialog('close')
    }
    if (root) {
      root.unmount()
      root = null
    }
    document.body.innerHTML = ''
  })

  const getDialog = () => $dialog[0]

  describe('gradeIsExcused', () => {
    beforeEach(() => {
      dialog = new SetDefaultGradeDialog({assignment})
      dialog.show()
    })

    it('returns true if grade is EX', () => {
      expect(dialog.gradeIsExcused('EX')).toBe(true)
      expect(dialog.gradeIsExcused('ex')).toBe(true)
      expect(dialog.gradeIsExcused('eX')).toBe(true)
      expect(dialog.gradeIsExcused('Ex')).toBe(true)
    })

    it('returns false if grade is not EX', () => {
      expect(dialog.gradeIsExcused('14')).toBe(false)
      expect(dialog.gradeIsExcused('F')).toBe(false)
      expect(dialog.gradeIsExcused('excused')).toBe(false)
    })
  })

  describe('show', () => {
    it('displays correct text for points grading type', () => {
      dialog = new SetDefaultGradeDialog({assignment})
      dialog.show()
      expect(getDialog().querySelector('#default_grade_description').textContent).toContain(
        'same grade',
      )
    })

    it('displays correct text for percent grading type', () => {
      const percentAssignment = {...assignment, grading_type: 'percent'}
      dialog = new SetDefaultGradeDialog({assignment: percentAssignment})
      dialog.show()
      expect(getDialog().querySelector('#default_grade_description').textContent).toContain(
        'same percent grade',
      )
    })
  })
})
