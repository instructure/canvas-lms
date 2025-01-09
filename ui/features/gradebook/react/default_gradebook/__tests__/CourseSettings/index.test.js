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

import {createGradebook} from '../GradebookSpecHelper'

describe('Gradebook CourseSettings', () => {
  let gradebook
  let gradebookOptions

  beforeEach(() => {
    gradebookOptions = {
      course_settings: {
        allow_final_grade_override: false,
      },

      final_grade_override_enabled: true,
    }
  })

  function buildGradebook() {
    gradebook = createGradebook(gradebookOptions)
  }

  describe('#allowFinalGradeOverride', () => {
    it('is true when final grade overrides are allowed for the course', () => {
      gradebookOptions.course_settings.allow_final_grade_override = true
      buildGradebook()
      expect(gradebook.courseSettings.allowFinalGradeOverride).toBe(true)
    })

    it('is false when final grade overrides are not allowed for the course', () => {
      gradebookOptions.course_settings.allow_final_grade_override = false
      buildGradebook()
      expect(gradebook.courseSettings.allowFinalGradeOverride).toBe(false)
    })
  })

  describe('#setAllowFinalGradeOverride()', () => {
    it('optionally enables "allow final grade override"', () => {
      buildGradebook()
      gradebook.courseSettings.setAllowFinalGradeOverride(true)
      expect(gradebook.courseSettings.allowFinalGradeOverride).toBe(true)
    })

    it('optionally disables "allow final grade override"', () => {
      gradebookOptions.course_settings.allow_final_grade_override = true
      buildGradebook()
      gradebook.courseSettings.setAllowFinalGradeOverride(false)
      expect(gradebook.courseSettings.allowFinalGradeOverride).toBe(false)
    })
  })

  describe('#handleUpdated()', () => {
    beforeEach(() => {
      buildGradebook()
      jest.spyOn(gradebook, 'updateColumns')
    })

    describe('when "allow final grade override" becomes enabled', () => {
      beforeEach(() => {
        gradebook.courseSettings.setAllowFinalGradeOverride(false)
        gradebook.courseSettings.handleUpdated(
          {
            allowFinalGradeOverride: true,
          },
          () => {},
        )
      })

      it('updates columns in the Gradebook grid', () => {
        expect(gradebook.updateColumns).toHaveBeenCalledTimes(1)
      })
    })

    describe('when "allow final grade override" becomes disabled', () => {
      beforeEach(() => {
        gradebook.courseSettings.setAllowFinalGradeOverride(true)
        gradebook.courseSettings.handleUpdated(
          {
            allowFinalGradeOverride: false,
          },
          () => {},
        )
      })

      it('updates columns in the Gradebook grid', () => {
        expect(gradebook.updateColumns).toHaveBeenCalledTimes(1)
      })
    })
  })
})
