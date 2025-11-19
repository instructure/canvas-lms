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

import axios from '@canvas/axios'
import {loadRollups, exportCSV, saveLearningMasteryGradebookSettings} from '../apiClient'
import {
  DEFAULT_STUDENTS_PER_PAGE,
  SortOrder,
  SortBy,
  DisplayFilter,
  SecondaryInfoDisplay,
  NameDisplayFormat,
} from '../utils/constants'

jest.mock('@canvas/axios')
const mockedAxios = axios as jest.Mocked<typeof axios>

describe('apiClient', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockedAxios.get.mockResolvedValue({data: {}, status: 200})
    mockedAxios.put.mockResolvedValue({data: {}, status: 200})
  })

  describe('loadRollups', () => {
    it('calls the correct endpoint with default parameters', async () => {
      await loadRollups('123', [])

      expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/courses/123/outcome_rollups', {
        params: {
          rating_percents: true,
          per_page: DEFAULT_STUDENTS_PER_PAGE,
          exclude: [],
          include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
          sort_by: SortBy.SortableName,
          sort_order: SortOrder.ASC,
          page: 1,
        },
      })
    })

    it('calls the correct endpoint with custom parameters', async () => {
      await loadRollups('456', ['filter1', 'filter2'], true, 2, 50, SortOrder.DESC, 'custom_sort')

      expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/courses/456/outcome_rollups', {
        params: {
          rating_percents: true,
          per_page: 50,
          exclude: ['filter1', 'filter2'],
          include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
          sort_by: 'custom_sort',
          sort_order: SortOrder.DESC,
          page: 2,
          add_defaults: true,
        },
      })
    })

    it('does not include add_defaults when needDefaults is false', async () => {
      await loadRollups('123', [], false)

      const callArgs = mockedAxios.get.mock.calls[0][1]
      expect(callArgs?.params).not.toHaveProperty('add_defaults')
    })

    it('accepts numeric courseId', async () => {
      await loadRollups(789, [])

      expect(mockedAxios.get).toHaveBeenCalledWith(
        '/api/v1/courses/789/outcome_rollups',
        expect.any(Object),
      )
    })
  })

  describe('exportCSV', () => {
    it('calls the correct endpoint with parameters', async () => {
      await exportCSV('123', ['filter1'])

      expect(mockedAxios.get).toHaveBeenCalledWith('/courses/123/outcome_rollups.csv', {
        params: {
          exclude: ['filter1'],
        },
      })
    })

    it('accepts numeric courseId', async () => {
      await exportCSV(456, [])

      expect(mockedAxios.get).toHaveBeenCalledWith('/courses/456/outcome_rollups.csv', {
        params: {
          exclude: [],
        },
      })
    })
  })

  describe('saveLearningMasteryGradebookSettings', () => {
    it('calls the correct endpoint with proper request body', async () => {
      const settings = {
        secondaryInfoDisplay: SecondaryInfoDisplay.SIS_ID,
        displayFilters: [
          DisplayFilter.SHOW_STUDENT_AVATARS,
          DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
        ],
        nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        studentsPerPage: 15,
      }

      await saveLearningMasteryGradebookSettings('123', settings)

      expect(mockedAxios.put).toHaveBeenCalledWith(
        '/api/v1/courses/123/learning_mastery_gradebook_settings',
        {
          learning_mastery_gradebook_settings: {
            secondary_info_display: 'sis_id',
            show_student_avatars: true,
            show_students_with_no_results: true,
            name_display_format: 'first_last',
            students_per_page: 15,
          },
        },
      )
    })

    it('handles settings without display filters', async () => {
      const settings = {
        secondaryInfoDisplay: SecondaryInfoDisplay.NONE,
        displayFilters: [],
        nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        studentsPerPage: 30,
      }

      await saveLearningMasteryGradebookSettings('456', settings)

      expect(mockedAxios.put).toHaveBeenCalledWith(
        '/api/v1/courses/456/learning_mastery_gradebook_settings',
        {
          learning_mastery_gradebook_settings: {
            secondary_info_display: 'none',
            show_student_avatars: false,
            show_students_with_no_results: false,
            name_display_format: 'first_last',
            students_per_page: 30,
          },
        },
      )
    })

    it('accepts numeric courseId', async () => {
      const settings = {
        secondaryInfoDisplay: SecondaryInfoDisplay.SIS_ID,
        displayFilters: [],
        nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        studentsPerPage: 50,
      }

      await saveLearningMasteryGradebookSettings(789, settings)

      expect(mockedAxios.put).toHaveBeenCalledWith(
        '/api/v1/courses/789/learning_mastery_gradebook_settings',
        {
          learning_mastery_gradebook_settings: {
            secondary_info_display: 'sis_id',
            show_student_avatars: false,
            show_students_with_no_results: false,
            name_display_format: 'first_last',
            students_per_page: 50,
          },
        },
      )
    })

    it('correctly maps display filters to boolean flags', async () => {
      const settings = {
        secondaryInfoDisplay: SecondaryInfoDisplay.NONE,
        displayFilters: [DisplayFilter.SHOW_STUDENT_AVATARS],
        nameDisplayFormat: NameDisplayFormat.FIRST_LAST,
        studentsPerPage: DEFAULT_STUDENTS_PER_PAGE,
      }

      await saveLearningMasteryGradebookSettings('123', settings)

      expect(mockedAxios.put).toHaveBeenCalledWith(
        '/api/v1/courses/123/learning_mastery_gradebook_settings',
        {
          learning_mastery_gradebook_settings: {
            secondary_info_display: 'none',
            show_student_avatars: true,
            show_students_with_no_results: false,
            name_display_format: 'first_last',
            students_per_page: 15,
          },
        },
      )
    })

    it('includes name_display_format in the request body when set to LAST_FIRST', async () => {
      const settings = {
        secondaryInfoDisplay: SecondaryInfoDisplay.NONE,
        displayFilters: [],
        nameDisplayFormat: NameDisplayFormat.LAST_FIRST,
        studentsPerPage: DEFAULT_STUDENTS_PER_PAGE,
      }

      await saveLearningMasteryGradebookSettings('123', settings)

      expect(mockedAxios.put).toHaveBeenCalledWith(
        '/api/v1/courses/123/learning_mastery_gradebook_settings',
        {
          learning_mastery_gradebook_settings: {
            secondary_info_display: 'none',
            show_student_avatars: false,
            show_students_with_no_results: false,
            name_display_format: 'last_first',
            students_per_page: 15,
          },
        },
      )
    })
  })
})
