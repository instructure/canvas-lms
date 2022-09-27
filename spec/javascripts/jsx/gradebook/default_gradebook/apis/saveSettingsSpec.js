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

import FakeServer, {
  formBodyFromRequest,
  pathFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook', suiteHooks => {
  let gradebook
  let gradebookOptions

  suiteHooks.beforeEach(() => {
    gradebookOptions = {
      settings_update_url: '/api/v1/courses/1201/settings',
    }
  })

  QUnit.module('#saveSettings()', hooks => {
    let onSuccess
    let onFailure
    let server

    hooks.beforeEach(() => {
      server = new FakeServer()

      onSuccess = sinon.spy()
      onFailure = sinon.spy()

      server.for('/api/v1/courses/1201/settings').respond({status: 200, body: {}})

      gradebook = createGradebook(gradebookOptions)
    })

    hooks.afterEach(() => {
      server.teardown()
    })

    function saveSettings(additionalSettings = {}) {
      return gradebook.saveSettings(additionalSettings).then(onSuccess).catch(onFailure)
    }

    function getSavedSettings() {
      const request = server.receivedRequests[0]
      return formBodyFromRequest(request).gradebook_settings
    }

    test('sends a request to update course settings', async () => {
      await saveSettings()
      const request = server.receivedRequests[0]
      equal(pathFromRequest(request), '/api/v1/courses/1201/settings')
    })

    test('sends a POST request', async () => {
      await saveSettings()
      const request = server.receivedRequests[0]
      equal(request.method, 'POST')
    })

    test('converts the POST to a PUT using the _method field', async () => {
      await saveSettings()
      const request = server.receivedRequests[0]
      equal(formBodyFromRequest(request)._method, 'PUT')
    })

    QUnit.module('"Submission Status Colors" setting', () => {
      const colors = Object.freeze({
        dropped: '#FEF0E5',
        excused: '#FEF7E5',
        late: '#E5F3FC',
        missing: '#FFE8E5',
        resubmitted: '#E5F7E5',
      })

      test('can be set using an argument', async () => {
        await saveSettings({colors})
        deepEqual(getSavedSettings().colors, colors)
      })
    })

    test('includes the "Enter Grades as" settings', async () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      await saveSettings()
      equal(getSavedSettings().enter_grades_as[2301], 'percent')
    })

    QUnit.module('within the "Filter Columns by" settings', () => {
      function getFilterColumnsBySetting(key) {
        return getSavedSettings().filter_columns_by[key]
      }

      test('includes the "assignment group" setting', async () => {
        gradebook.setFilterColumnsBySetting('assignmentGroupId', '2201')
        await saveSettings()
        equal(getFilterColumnsBySetting('assignment_group_id'), '2201')
      })

      test('includes the "context module" setting', async () => {
        gradebook.setFilterColumnsBySetting('contextModuleId', '2601')
        await saveSettings()
        equal(getFilterColumnsBySetting('context_module_id'), '2601')
      })

      test('includes the "grading period" setting', async () => {
        gradebook.setFilterColumnsBySetting('gradingPeriodId', '1501')
        await saveSettings()
        equal(getFilterColumnsBySetting('grading_period_id'), '1501')
      })
    })

    QUnit.module('within the "Filter Rows by" settings', () => {
      function getFilterRowsBySetting(key) {
        return getSavedSettings().filter_rows_by[key]
      }

      test('includes the "section" setting', async () => {
        gradebook.setFilterRowsBySetting('sectionId', '2001')
        await saveSettings()
        equal(getFilterRowsBySetting('section_id'), '2001')
      })
    })

    QUnit.module('"Selected View Options Filters" setting', () => {
      test('includes the selected view options filters', async () => {
        const filters = ['assignmentGroups', 'gradingPeriods']
        gradebook.setSelectedViewOptionsFilters(filters)
        await saveSettings()
        deepEqual(getSavedSettings().selected_view_options_filters, filters)
      })

      test('can be set using an argument', async () => {
        const filters = ['assignmentGroups', 'gradingPeriods']
        await saveSettings({selectedViewOptionsFilters: filters})
        deepEqual(getSavedSettings().selected_view_options_filters, filters)
      })

      test('is amended with a blank string when empty to ensure setting is updated', async () => {
        gradebook.setSelectedViewOptionsFilters([])
        await saveSettings()
        deepEqual(getSavedSettings().selected_view_options_filters, [''])
      })
    })

    QUnit.module('"Show Concluded Enrollments" setting', () => {
      test('is set using the current setting from Gradebook', async () => {
        gradebook.getEnrollmentFilters().concluded = true
        await saveSettings()
        strictEqual(getSavedSettings().show_concluded_enrollments, 'true')
      })

      test('can be set using an argument', async () => {
        await saveSettings({showConcludedEnrollments: true})
        strictEqual(getSavedSettings().show_concluded_enrollments, 'true')
      })
    })

    QUnit.module('"Show Inactive Enrollments" setting', () => {
      test('is set using the current setting from Gradebook', async () => {
        gradebook.getEnrollmentFilters().inactive = true
        await saveSettings()
        strictEqual(getSavedSettings().show_inactive_enrollments, 'true')
      })

      test('can be set using an argument', async () => {
        await saveSettings({showInactiveEnrollments: true})
        strictEqual(getSavedSettings().show_inactive_enrollments, 'true')
      })
    })

    QUnit.module('"Show Unpublished Assignments" setting', () => {
      test('is set using the current setting from Gradebook', async () => {
        gradebook.gridDisplaySettings.showUnpublishedAssignments = true
        await saveSettings()
        strictEqual(getSavedSettings().show_unpublished_assignments, 'true')
      })

      test('can be set using an argument', async () => {
        await saveSettings({showUnpublishedAssignments: true})
        strictEqual(getSavedSettings().show_unpublished_assignments, 'true')
      })
    })

    QUnit.module('"Sort Rows by" settings', () => {
      function setSortRowsBySetting(columnId, direction, settingKey) {
        gradebook.gridDisplaySettings.sortRowsBy.columnId = columnId
        gradebook.gridDisplaySettings.sortRowsBy.settingKey = settingKey
        gradebook.gridDisplaySettings.sortRowsBy.direction = direction
      }

      QUnit.module('"column id" setting', () => {
        test('is set using the current setting from Gradebook', async () => {
          setSortRowsBySetting('total_grade', 'descending', 'grade')
          await saveSettings()
          equal(getSavedSettings().sort_rows_by_column_id, 'total_grade')
        })

        test('can be set using an argument', async () => {
          const sortRowsBy = {columnId: 'total_grade', direction: 'descending', settingKey: 'grade'}
          await saveSettings({sortRowsBy})
          equal(getSavedSettings().sort_rows_by_column_id, 'total_grade')
        })
      })

      QUnit.module('"direction" setting', () => {
        test('is set using the current setting from Gradebook', async () => {
          setSortRowsBySetting('total_grade', 'descending', 'grade')
          await saveSettings()
          equal(getSavedSettings().sort_rows_by_direction, 'descending')
        })

        test('can be set using an argument', async () => {
          const sortRowsBy = {columnId: 'total_grade', direction: 'descending', settingKey: 'grade'}
          await saveSettings({sortRowsBy})
          equal(getSavedSettings().sort_rows_by_direction, 'descending')
        })
      })

      QUnit.module('"setting key" setting', () => {
        test('is set using the current setting from Gradebook', async () => {
          setSortRowsBySetting('total_grade', 'descending', 'grade')
          await saveSettings()
          equal(getSavedSettings().sort_rows_by_setting_key, 'grade')
        })

        test('can be set using an argument', async () => {
          const sortRowsBy = {columnId: 'total_grade', direction: 'descending', settingKey: 'grade'}
          await saveSettings({sortRowsBy})
          equal(getSavedSettings().sort_rows_by_setting_key, 'grade')
        })
      })
    })

    QUnit.module('Student Column "Display as" setting', () => {
      test('is set using the current setting from Gradebook', async () => {
        gradebook.gridDisplaySettings.selectedPrimaryInfo = 'first_last'
        await saveSettings()
        equal(getSavedSettings().student_column_display_as, 'first_last')
      })

      test('can be set using an argument', async () => {
        await saveSettings({studentColumnDisplayAs: 'first_last'})
        equal(getSavedSettings().student_column_display_as, 'first_last')
      })
    })

    QUnit.module('Student Column "Secondary Info" setting', () => {
      test('is set using the current setting from Gradebook', async () => {
        gradebook.gridDisplaySettings.selectedSecondaryInfo = 'section'
        await saveSettings()
        equal(getSavedSettings().student_column_secondary_info, 'section')
      })

      test('can be set using an argument', async () => {
        await saveSettings({studentColumnSecondaryInfo: 'section'})
        equal(getSavedSettings().student_column_secondary_info, 'section')
      })
    })

    test('calls the "on success" callback when the request succeeds', async () => {
      await saveSettings()
      strictEqual(onSuccess.callCount, 1)
    })

    test('calls the "on failure" callback when the request fails', async () => {
      server.unsetResponses('/api/v1/courses/1201/settings')
      server
        .for('/api/v1/courses/1201/settings')
        .respond({status: 500, body: {error: 'Server Error'}})
      await saveSettings()
      strictEqual(onFailure.callCount, 1)
    })
  })
})
