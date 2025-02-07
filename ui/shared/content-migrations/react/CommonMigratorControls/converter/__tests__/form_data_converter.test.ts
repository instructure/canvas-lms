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

import type {submitMigrationFormData} from '../../types'
import {convertFormDataToMigrationCreateRequest} from '../form_data_converter'

describe('convertFormDataToMigrationCreateRequest', () => {
  const dates = {
    old_start_date: '2023-01-01',
    new_start_date: '2024-01-01',
    old_end_date: '2023-12-31',
    new_end_date: '2024-12-31',
  }
  const attachmentDetails = {
    name: 'file.zip',
    no_redirect: false,
    size: 1024,
  }
  const commonFields = {
    selective_import: true,
    settings: {key: 'value'},
    pre_attachment: {...attachmentDetails},
  }
  const baseFormData: submitMigrationFormData = {
    date_shift_options: {
      day_substitutions: [{from: 0, to: 1, id: 1}],
      ...dates,
    },
    adjust_dates: {enabled: true, operation: 'shift_dates'},
    errored: false,
    ...commonFields,
  }
  const courseId = '1'
  const chosenMigrator = 'course_copy_importer'

  describe('when adjust dates is shift_dates', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      adjust_dates: {enabled: true, operation: 'shift_dates'},
    }

    it('should set shift_dates true', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options.shift_dates).toBeTruthy()
      expect(result.date_shift_options.remove_dates).toBeUndefined()
    })
  })

  describe('when adjust dates is remove_dates', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      adjust_dates: {enabled: true, operation: 'remove_dates'},
    }

    it('should set remove_dates true', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options.remove_dates).toBeTruthy()
      expect(result.date_shift_options.shift_dates).toBeUndefined()
    })
  })

  describe('when adjust dates is disabled', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      adjust_dates: {enabled: false, operation: 'remove_dates'},
    }

    it('should set shift_dates and remove_dates to undefined', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options.remove_dates).toBeUndefined()
      expect(result.date_shift_options.shift_dates).toBeUndefined()
    })
  })

  describe('when form day_substitution is empty array', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      date_shift_options: {
        ...dates,
        day_substitutions: [],
      },
    }

    it('should be an empty object', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options.day_substitutions).toEqual({})
    })
  })

  it('should convert form data to migration create request body', () => {
    const result = convertFormDataToMigrationCreateRequest(baseFormData, courseId, chosenMigrator)

    expect(result).toEqual({
      date_shift_options: {
        shift_dates: true,
        day_substitutions: {'0': '1'},
        ...dates,
      },
      course_id: '1',
      migration_type: 'course_copy_importer',
      ...commonFields,
    })
  })

  describe('when date_shift_options is undefined', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      date_shift_options: undefined,
    }

    it('should return date_shift_options without date and day_substitutions data', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options).toEqual({
        shift_dates: true,
      })
    })
  })

  describe('when date_shift_options dates are undefined', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      date_shift_options: {
        day_substitutions: [{from: 0, to: 1, id: 1}],
        old_start_date: undefined,
        new_start_date: undefined,
        old_end_date: undefined,
        new_end_date: undefined,
      },
    }

    it('should return date_shift_options with undefined dates', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options).toEqual({
        day_substitutions: {'0': '1'},
        shift_dates: true,
        old_start_date: undefined,
        new_start_date: undefined,
        old_end_date: undefined,
        new_end_date: undefined,
      })
    })
  })

  describe('when adjust_date is undefined', () => {
    const formData: submitMigrationFormData = {
      ...baseFormData,
      adjust_dates: undefined,
    }

    it('should return date_shift_options without shift_dates or remove_dates operation', () => {
      const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
      expect(result.date_shift_options).toEqual({
        day_substitutions: {'0': '1'},
        ...dates,
      })
    })
  })

  describe('settings', () => {
    describe('question bank', () => {
      const testQuestionBankNameRemoval = (
        questionBankName: string | null | undefined,
        expected: string | undefined,
      ) => {
        const formData: submitMigrationFormData = {
          ...baseFormData,
          settings: {question_bank_name: questionBankName},
        }

        const result = convertFormDataToMigrationCreateRequest(formData, courseId, chosenMigrator)
        expect(result.settings.question_bank_name).toBe(expected)
      }

      it('should remove empty question bank name', () => {
        testQuestionBankNameRemoval('', undefined)
      })

      it('should remove null question bank name', () => {
        testQuestionBankNameRemoval(null, undefined)
      })

      it('should remove undefined question bank name', () => {
        testQuestionBankNameRemoval(undefined, undefined)
      })

      it('should use question bank name when not empty', () => {
        testQuestionBankNameRemoval('Valid Name', 'Valid Name')
      })
    })
  })
})
