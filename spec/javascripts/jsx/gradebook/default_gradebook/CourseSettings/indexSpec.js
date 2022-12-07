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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook CourseSettings', suiteHooks => {
  let gradebook
  let gradebookOptions

  suiteHooks.beforeEach(() => {
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

  QUnit.module('#allowFinalGradeOverride', () => {
    test('is true when final grade overrides are allowed for the course', () => {
      gradebookOptions.course_settings.allow_final_grade_override = true
      buildGradebook()
      strictEqual(gradebook.courseSettings.allowFinalGradeOverride, true)
    })

    test('is false when final grade overrides are not allowed for the course', () => {
      gradebookOptions.course_settings.allow_final_grade_override = false
      buildGradebook()
      strictEqual(gradebook.courseSettings.allowFinalGradeOverride, false)
    })
  })

  QUnit.module('#setAllowFinalGradeOverride()', () => {
    test('optionally enables "allow final grade override"', () => {
      buildGradebook()
      gradebook.courseSettings.setAllowFinalGradeOverride(true)
      strictEqual(gradebook.courseSettings.allowFinalGradeOverride, true)
    })

    test('optionally disables "allow final grade override"', () => {
      gradebookOptions.course_settings.allow_final_grade_override = true
      buildGradebook()
      gradebook.courseSettings.setAllowFinalGradeOverride(false)
      strictEqual(gradebook.courseSettings.allowFinalGradeOverride, false)
    })
  })

  QUnit.module('#handleUpdated()', hooks => {
    hooks.beforeEach(() => {
      buildGradebook()
      sinon.stub(gradebook, 'updateColumns')
    })

    QUnit.module('when "allow final grade override" becomes enabled', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.courseSettings.setAllowFinalGradeOverride(false)
        gradebook.courseSettings.handleUpdated(
          {
            allowFinalGradeOverride: true,
          },
          () => {}
        )
      })

      test('updates columns in the Gradebook grid', () => {
        strictEqual(gradebook.updateColumns.callCount, 1)
      })
    })

    QUnit.module('when "allow final grade override" becomes disabled', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.courseSettings.setAllowFinalGradeOverride(true)
        gradebook.courseSettings.handleUpdated(
          {
            allowFinalGradeOverride: false,
          },
          () => {}
        )
      })

      test('updates columns in the Gradebook grid', () => {
        strictEqual(gradebook.updateColumns.callCount, 1)
      })
    })
  })
})
