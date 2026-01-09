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
import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {useGradebookSettings} from '../useGradebookSettings'
import * as apiClient from '../../apiClient'
import {
  DEFAULT_GRADEBOOK_SETTINGS,
  DisplayFilter,
  SecondaryInfoDisplay,
  NameDisplayFormat,
  ScoreDisplayFormat,
  OutcomeArrangement,
} from '@canvas/outcomes/react/utils/constants'

vi.mock('../../apiClient')

describe('useGradebookSettings', () => {
  const courseId = '123'

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('loads settings successfully', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
      show_outcomes_with_no_results: true,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.secondaryInfoDisplay).toBe(SecondaryInfoDisplay.SIS_ID)
    expect(result.current.settings.displayFilters).toEqual([
      DisplayFilter.SHOW_STUDENT_AVATARS,
      DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
      DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS,
    ])
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('sets default settings on error', async () => {
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockRejectedValue(new Error('fail'))
    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()
    expect(result.current.settings).toEqual(DEFAULT_GRADEBOOK_SETTINGS)
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeTruthy()
  })

  it('sets default settings if response is missing settings', async () => {
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {},
    })
    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()
    expect(result.current.settings).toEqual(DEFAULT_GRADEBOOK_SETTINGS)
    expect(result.current.isLoading).toBe(false)
  })

  it('sets display filters to default if they are missing in the response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: false,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })
    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()
    expect(result.current.settings.secondaryInfoDisplay).toBe(mockSettings.secondary_info_display)
    expect(result.current.settings.displayFilters).toEqual([
      DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
      DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS,
    ])
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets display filters to default if both filters are missing in the response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })
    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()
    expect(result.current.settings.secondaryInfoDisplay).toBe(mockSettings.secondary_info_display)
    expect(result.current.settings.displayFilters).toEqual(
      DEFAULT_GRADEBOOK_SETTINGS.displayFilters,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets secondaryInfoDisplay to default if it is missing in the response', async () => {
    const mockSettings = {
      show_student_avatars: true,
      show_students_with_no_results: true,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })
    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()
    expect(result.current.settings.secondaryInfoDisplay).toBe(
      DEFAULT_GRADEBOOK_SETTINGS.secondaryInfoDisplay,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets nameDisplayFormat from API response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
      name_display_format: NameDisplayFormat.LAST_FIRST,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.nameDisplayFormat).toBe(NameDisplayFormat.LAST_FIRST)
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets nameDisplayFormat to default when missing in the response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.nameDisplayFormat).toBe(
      DEFAULT_GRADEBOOK_SETTINGS.nameDisplayFormat,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets scoreDisplayFormat from API response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
      score_display_format: ScoreDisplayFormat.ICON_AND_POINTS,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.scoreDisplayFormat).toBe(ScoreDisplayFormat.ICON_AND_POINTS)
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets scoreDisplayFormat to default when missing in the response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.scoreDisplayFormat).toBe(
      DEFAULT_GRADEBOOK_SETTINGS.scoreDisplayFormat,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets outcomeArrangement from API response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
      outcome_arrangement: OutcomeArrangement.CUSTOM,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.outcomeArrangement).toBe(OutcomeArrangement.CUSTOM)
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets outcomeArrangement to default when missing in the response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
    }
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.outcomeArrangement).toBe(
      DEFAULT_GRADEBOOK_SETTINGS.outcomeArrangement,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('loads show_unpublished_assignments setting from API response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
      show_outcomes_with_no_results: false,
      show_unpublished_assignments: true,
    }
    jest.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.displayFilters).toContain(
      DisplayFilter.SHOW_UNPUBLISHED_ASSIGNMENTS,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('does not include show_unpublished_assignments when false in API response', async () => {
    const mockSettings = {
      secondary_info_display: SecondaryInfoDisplay.SIS_ID,
      show_student_avatars: true,
      show_students_with_no_results: true,
      show_unpublished_assignments: false,
    }
    jest.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {learning_mastery_gradebook_settings: mockSettings},
    })

    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()

    expect(result.current.settings.displayFilters).not.toContain(
      DisplayFilter.SHOW_UNPUBLISHED_ASSIGNMENTS,
    )
    expect(result.current.error).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('updateSettings updates settings', async () => {
    vi.spyOn(apiClient, 'loadLearningMasteryGradebookSettings').mockResolvedValue({
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
      data: {
        learning_mastery_gradebook_settings: {
          secondary_info_display: SecondaryInfoDisplay.SIS_ID,
          show_student_avatars: false,
          show_students_with_no_results: false,
        },
      },
    })
    const {result, waitForNextUpdate} = renderHook(() => useGradebookSettings(courseId))
    await waitForNextUpdate()
    act(() => {
      result.current.updateSettings({
        secondaryInfoDisplay: SecondaryInfoDisplay.INTEGRATION_ID,
        displayFilters: [DisplayFilter.SHOW_STUDENT_AVATARS],
        nameDisplayFormat: NameDisplayFormat.LAST_FIRST,
        studentsPerPage: 15,
        scoreDisplayFormat: ScoreDisplayFormat.ICON_AND_LABEL,
        outcomeArrangement: OutcomeArrangement.UPLOAD_ORDER,
      })
    })
    expect(result.current.settings.secondaryInfoDisplay).toBe(SecondaryInfoDisplay.INTEGRATION_ID)
    expect(result.current.settings.displayFilters).toEqual([DisplayFilter.SHOW_STUDENT_AVATARS])
    expect(result.current.settings.nameDisplayFormat).toBe(NameDisplayFormat.LAST_FIRST)
    expect(result.current.settings.studentsPerPage).toBe(15)
    expect(result.current.settings.scoreDisplayFormat).toBe(ScoreDisplayFormat.ICON_AND_LABEL)
    expect(result.current.settings.outcomeArrangement).toBe(OutcomeArrangement.UPLOAD_ORDER)
  })
})
