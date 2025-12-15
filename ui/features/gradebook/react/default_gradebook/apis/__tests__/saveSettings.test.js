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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {createGradebook} from '../../__tests__/GradebookSpecHelper'

describe('Gradebook', () => {
  let gradebook
  let gradebookOptions

  beforeEach(() => {
    gradebookOptions = {
      settings_update_url: '/api/v1/courses/1201/settings',
    }
  })

  describe('#saveSettings()', () => {
    let onSuccess
    let onFailure
    let capturedRequest = null
    const server = setupServer()

    beforeAll(() => {
      server.listen()
    })

    beforeEach(() => {
      onSuccess = vi.fn()
      onFailure = vi.fn()
      capturedRequest = null

      server.use(
        http.post('/api/v1/courses/1201/settings', async ({request}) => {
          capturedRequest = {
            method: request.method,
            url: request.url,
            body: await request.text(),
          }
          return HttpResponse.json({})
        }),
      )

      gradebook = createGradebook(gradebookOptions)
    })

    afterEach(() => {
      server.resetHandlers()
    })

    afterAll(() => {
      server.close()
    })

    function saveSettings(additionalSettings = {}) {
      return gradebook.saveSettings(additionalSettings).then(onSuccess).catch(onFailure)
    }

    function getSavedSettings() {
      if (!capturedRequest) return {}
      const formData = new URLSearchParams(capturedRequest.body)
      const settings = {}
      const arrayKeys = new Set()

      // First pass: identify array parameters
      for (const [key] of formData.entries()) {
        if (key.includes('[]')) {
          arrayKeys.add(key)
        }
      }

      for (const [key, value] of formData.entries()) {
        if (key.startsWith('gradebook_settings[')) {
          const match = key.match(
            /gradebook_settings\[([^\]]+)\](?:\[([^\]]+)\])?(?:\[([^\]]+)\])?/,
          )
          if (match) {
            const [, first, second, third] = match
            if (arrayKeys.has(key)) {
              // Handle array parameters
              const cleanKey = first.replace('[]', '')
              settings[cleanKey] = settings[cleanKey] || []
              settings[cleanKey].push(value)
            } else if (third) {
              settings[first] = settings[first] || {}
              settings[first][second] = settings[first][second] || {}
              settings[first][second][third] = value
            } else if (second) {
              settings[first] = settings[first] || {}
              settings[first][second] = value
            } else {
              settings[first] = value
            }
          }
        }
      }
      return settings
    }

    it('sends a request to update course settings', async () => {
      await saveSettings()
      expect(capturedRequest.url).toContain('/api/v1/courses/1201/settings')
    })

    it('sends a POST request', async () => {
      await saveSettings()
      expect(capturedRequest.method).toBe('POST')
    })

    it('converts the POST to a PUT using the _method field', async () => {
      await saveSettings()
      const formData = new URLSearchParams(capturedRequest.body)
      expect(formData.get('_method')).toBe('PUT')
    })

    describe('"Submission Status Colors" setting', () => {
      const colors = Object.freeze({
        dropped: '#FEF0E5',
        excused: '#FEF7E5',
        late: '#E5F3FC',
        missing: '#FFE8E5',
        resubmitted: '#E5F7E5',
      })

      it('can be set using an argument', async () => {
        await saveSettings({colors})
        expect(getSavedSettings().colors).toEqual(colors)
      })
    })

    it('includes the "Enter Grades as" settings', async () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      await saveSettings()
      expect(getSavedSettings().enter_grades_as['2301']).toBe('percent')
    })

    describe('within the "Filter Columns by" settings', () => {
      function getFilterColumnsBySetting(key) {
        return getSavedSettings().filter_columns_by[key]
      }

      it('includes the "assignment group" setting', async () => {
        gradebook.setFilterColumnsBySetting('assignmentGroupId', '2201')
        await saveSettings()
        expect(getFilterColumnsBySetting('assignment_group_id')).toBe('2201')
      })

      it('includes the "context module" setting', async () => {
        gradebook.setFilterColumnsBySetting('contextModuleId', '2601')
        await saveSettings()
        expect(getFilterColumnsBySetting('context_module_id')).toBe('2601')
      })

      it('includes the "grading period" setting', async () => {
        gradebook.setFilterColumnsBySetting('gradingPeriodId', '1501')
        await saveSettings()
        expect(getFilterColumnsBySetting('grading_period_id')).toBe('1501')
      })
    })

    describe('within the "Filter Rows by" settings', () => {
      function getFilterRowsBySetting(key) {
        return getSavedSettings().filter_rows_by[key]
      }

      it('includes the "section" setting', async () => {
        gradebook.setFilterRowsBySetting('sectionId', '2001')
        await saveSettings()
        expect(getFilterRowsBySetting('section_id')).toBe('2001')
      })
    })

    describe('"Selected View Options Filters" setting', () => {
      it('includes the selected view options filters', async () => {
        const filters = ['assignmentGroups', 'gradingPeriods']
        gradebook.setSelectedViewOptionsFilters(filters)
        await saveSettings()
        expect(getSavedSettings().selected_view_options_filters).toEqual(filters)
      })

      it('can be set using an argument', async () => {
        const filters = ['assignmentGroups', 'gradingPeriods']
        await saveSettings({selectedViewOptionsFilters: filters})
        expect(getSavedSettings().selected_view_options_filters).toEqual(filters)
      })

      it('is amended with a blank string when empty to ensure setting is updated', async () => {
        gradebook.setSelectedViewOptionsFilters([])
        await saveSettings()
        expect(getSavedSettings().selected_view_options_filters).toEqual([''])
      })
    })

    describe('"Show Concluded Enrollments" setting', () => {
      it('is set using the current setting from Gradebook', async () => {
        gradebook.getEnrollmentFilters().concluded = true
        await saveSettings()
        expect(getSavedSettings().show_concluded_enrollments).toBe('true')
      })

      it('can be set using an argument', async () => {
        await saveSettings({showConcludedEnrollments: true})
        expect(getSavedSettings().show_concluded_enrollments).toBe('true')
      })
    })

    describe('"Show Inactive Enrollments" setting', () => {
      it('is set using the current setting from Gradebook', async () => {
        gradebook.getEnrollmentFilters().inactive = true
        await saveSettings()
        expect(getSavedSettings().show_inactive_enrollments).toBe('true')
      })

      it('can be set using an argument', async () => {
        await saveSettings({showInactiveEnrollments: true})
        expect(getSavedSettings().show_inactive_enrollments).toBe('true')
      })
    })

    describe('"Show Unpublished Assignments" setting', () => {
      it('is set using the current setting from Gradebook', async () => {
        gradebook.gridDisplaySettings.showUnpublishedAssignments = true
        await saveSettings()
        expect(getSavedSettings().show_unpublished_assignments).toBe('true')
      })

      it('can be set using an argument', async () => {
        await saveSettings({showUnpublishedAssignments: true})
        expect(getSavedSettings().show_unpublished_assignments).toBe('true')
      })
    })

    describe('"Sort Rows by" settings', () => {
      function setSortRowsBySetting(columnId, direction, settingKey) {
        gradebook.gridDisplaySettings.sortRowsBy.columnId = columnId
        gradebook.gridDisplaySettings.sortRowsBy.settingKey = settingKey
        gradebook.gridDisplaySettings.sortRowsBy.direction = direction
      }

      describe('"column id" setting', () => {
        it('is set using the current setting from Gradebook', async () => {
          setSortRowsBySetting('total_grade', 'descending', 'grade')
          await saveSettings()
          expect(getSavedSettings().sort_rows_by_column_id).toBe('total_grade')
        })

        it('can be set using an argument', async () => {
          const sortRowsBy = {columnId: 'total_grade', direction: 'descending', settingKey: 'grade'}
          await saveSettings({sortRowsBy})
          expect(getSavedSettings().sort_rows_by_column_id).toBe('total_grade')
        })
      })

      describe('"direction" setting', () => {
        it('is set using the current setting from Gradebook', async () => {
          setSortRowsBySetting('total_grade', 'descending', 'grade')
          await saveSettings()
          expect(getSavedSettings().sort_rows_by_direction).toBe('descending')
        })

        it('can be set using an argument', async () => {
          const sortRowsBy = {columnId: 'total_grade', direction: 'descending', settingKey: 'grade'}
          await saveSettings({sortRowsBy})
          expect(getSavedSettings().sort_rows_by_direction).toBe('descending')
        })
      })

      describe('"setting key" setting', () => {
        it('is set using the current setting from Gradebook', async () => {
          setSortRowsBySetting('total_grade', 'descending', 'grade')
          await saveSettings()
          expect(getSavedSettings().sort_rows_by_setting_key).toBe('grade')
        })

        it('can be set using an argument', async () => {
          const sortRowsBy = {columnId: 'total_grade', direction: 'descending', settingKey: 'grade'}
          await saveSettings({sortRowsBy})
          expect(getSavedSettings().sort_rows_by_setting_key).toBe('grade')
        })
      })
    })

    describe('Student Column "Display as" setting', () => {
      it('is set using the current setting from Gradebook', async () => {
        gradebook.gridDisplaySettings.selectedPrimaryInfo = 'first_last'
        await saveSettings()
        expect(getSavedSettings().student_column_display_as).toBe('first_last')
      })

      it('can be set using an argument', async () => {
        await saveSettings({studentColumnDisplayAs: 'first_last'})
        expect(getSavedSettings().student_column_display_as).toBe('first_last')
      })
    })

    describe('Student Column "Secondary Info" setting', () => {
      it('is set using the current setting from Gradebook', async () => {
        gradebook.gridDisplaySettings.selectedSecondaryInfo = 'section'
        await saveSettings()
        expect(getSavedSettings().student_column_secondary_info).toBe('section')
      })

      it('can be set using an argument', async () => {
        await saveSettings({studentColumnSecondaryInfo: 'section'})
        expect(getSavedSettings().student_column_secondary_info).toBe('section')
      })
    })

    it('calls the "on success" callback when the request succeeds', async () => {
      await saveSettings()
      expect(onSuccess).toHaveBeenCalledTimes(1)
    })

    it('calls the "on failure" callback when the request fails', async () => {
      server.use(
        http.post('/api/v1/courses/1201/settings', () => {
          return HttpResponse.json({error: 'Server Error'}, {status: 500})
        }),
      )
      await saveSettings()
      expect(onFailure).toHaveBeenCalledTimes(1)
    })
  })
})
