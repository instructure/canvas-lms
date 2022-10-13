//
// Copyright (C) 2018 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import * as FinalGradeOverrideApi from '@canvas/grading/FinalGradeOverrideApi'
import ScreenreaderGradebookRoute from '../../routes/screenreader_gradebook_route'

QUnit.module('ScreenreaderGradebookRoute', suiteHooks => {
  let server

  suiteHooks.beforeEach(() => {
    server = sinon.createFakeServer()
  })

  suiteHooks.afterEach(() => {
    server.restore()
  })

  QUnit.module('model', contextHooks => {
    let originalENV
    let route

    contextHooks.beforeEach(() => {
      originalENV = window.ENV
      window.ENV.GRADEBOOK_OPTIONS = {
        custom_columns_url: 'custom_columns',
        enrollments_url: 'enrollments',
        final_grade_overrides_url: 'final_grade_overrides',
        sections_url: 'sections',
        outcome_links_url: 'outcome_links',
        outcome_rollups_url: 'outcome_rollups',
      }
      route = ScreenreaderGradebookRoute.create()
    })

    contextHooks.afterEach(() => {
      window.ENV = originalENV
    })

    QUnit.module('final_grade_overrides', hooks => {
      hooks.beforeEach(() => {
        window.ENV.GRADEBOOK_OPTIONS.final_grade_override_enabled = true
      })

      test('sets isLoaded to false while records are loading', () => {
        const model = route.model()
        strictEqual(model.final_grade_overrides.isLoaded, false)
      })

      test('sets isLoaded to true after records are loaded', async () => {
        const apiStub = sinon
          .stub(FinalGradeOverrideApi, 'getFinalGradeOverrides')
          .returns(Promise.resolve({status: 200}))
        const model = await route.model()
        strictEqual(model.final_grade_overrides.isLoaded, true)
        apiStub.restore()
      })

      test('sets content after records are loaded', async () => {
        const overrideData = {
          23: {
            courseGrade: {
              percentage: 91.1,
            },
            gradingPeriodGrades: {},
          },
        }
        const apiStub = sinon
          .stub(FinalGradeOverrideApi, 'getFinalGradeOverrides')
          .returns(Promise.resolve({finalGradeOverrides: overrideData}))
        const model = await route.model()
        deepEqual(model.final_grade_overrides.content, {finalGradeOverrides: overrideData})
        apiStub.restore()
      })
    })
  })
})
