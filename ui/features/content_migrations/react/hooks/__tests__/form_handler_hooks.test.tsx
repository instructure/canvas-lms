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

import {renderHook, act} from '@testing-library/react-hooks'
import {useSubmitHandler, useSubmitHandlerWithQuestionBank} from '../form_handler_hooks'
import type {onSubmitMigrationFormCallback, QuestionBankSettings} from '../../components/types'

describe('from handler hooks', () => {
  const mockOnSubmit: onSubmitMigrationFormCallback = jest.fn()
  const createMockFileInputRef = () =>
    ({
      current: {focus: jest.fn()},
    }) as unknown as React.RefObject<HTMLInputElement>

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('useSubmitHandlerWithQuestionBank', () => {
    it('should initialize with default values', () => {
      const {result} = renderHook(() => useSubmitHandlerWithQuestionBank(mockOnSubmit))

      expect(result.current.file).toBeNull()
      expect(result.current.fileError).toBe(false)
      expect(result.current.questionBankSettings).toBeNull()
    })

    describe('question banks', () => {
      it('should use question bank name', () => {
        const {result} = renderHook(() => useSubmitHandlerWithQuestionBank(mockOnSubmit))
        const settings: QuestionBankSettings = {question_bank_name: 'Valid Name'}

        act(() => {
          result.current.setQuestionBankSettings(settings)
        })

        act(() => {
          result.current.handleSubmit({settings: {}})
        })

        expect(result.current.questionBankSettings?.question_bank_name).toBe('Valid Name')
      })
    })

    describe('files', () => {
      it('should have true fileError on missing file submission', () => {
        const {result} = renderHook(() => useSubmitHandlerWithQuestionBank(mockOnSubmit))
        const inCorrectFormData = {settings: {}}

        act(() => {
          result.current.handleSubmit(inCorrectFormData)
        })

        expect(result.current.fileError).toBe(true)
        expect(mockOnSubmit).not.toHaveBeenCalled()
      })

      it('should have false fileError on existing file submission', () => {
        const {result} = renderHook(() => useSubmitHandlerWithQuestionBank(mockOnSubmit))
        const formData = {settings: {}}

        act(() => {
          result.current.setFile(new File(['content'], 'test.txt'))
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(result.current.fileError).toBe(false)
      })

      it('should move focus to fileInputRef on missing file submission', () => {
        const fileInputRef = createMockFileInputRef()
        const {result} = renderHook(() =>
          useSubmitHandlerWithQuestionBank(mockOnSubmit, fileInputRef),
        )
        const formData = {settings: {}}

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(fileInputRef.current?.focus).toHaveBeenCalled()
      })

      it('should not move focus to fileInputRef on existing file submission', () => {
        const fileInputRef = createMockFileInputRef()
        const {result} = renderHook(() =>
          useSubmitHandlerWithQuestionBank(mockOnSubmit, fileInputRef),
        )
        const formData = {settings: {}}

        act(() => {
          result.current.setFile(new File(['content'], 'test.txt'))
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(fileInputRef.current?.focus).not.toHaveBeenCalled()
      })
    })

    describe('formData', () => {
      it('should call onSubmit correctly on existing formData', () => {
        const {result} = renderHook(() => useSubmitHandlerWithQuestionBank(mockOnSubmit))
        const formData = {settings: {extra_info: 'extra'}}
        const file = new File(['content'], 'test.txt')

        act(() => {
          result.current.setFile(file)
          result.current.setQuestionBankSettings({question_bank_name: 'Valid Name'})
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(result.current.fileError).toBe(false)
        expect(mockOnSubmit).toHaveBeenCalledWith(
          {
            settings: {question_bank_name: 'Valid Name', extra_info: 'extra'},
            pre_attachment: {
              name: 'test.txt',
              size: 7,
              no_redirect: true,
            },
          },
          file,
        )
      })

      it('should not call onSubmit on missing formData', () => {
        const {result} = renderHook(() => useSubmitHandlerWithQuestionBank(mockOnSubmit))
        const formData = null
        const file = new File(['content'], 'test.txt')

        act(() => {
          result.current.setFile(file)
          result.current.setQuestionBankSettings({question_bank_name: 'Valid Name'})
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(result.current.fileError).toBe(true)
        expect(mockOnSubmit).not.toHaveBeenCalled()
      })
    })
  })

  describe('useSubmitHandler', () => {
    it('should initialize with default values', () => {
      const {result} = renderHook(() => useSubmitHandler(mockOnSubmit))

      expect(result.current.file).toBeNull()
      expect(result.current.fileError).toBe(false)
    })

    describe('files', () => {
      it('should have true fileError on missing file submission', () => {
        const {result} = renderHook(() => useSubmitHandler(mockOnSubmit))
        const inCorrectFormData = {settings: {}}

        act(() => {
          result.current.handleSubmit(inCorrectFormData)
        })

        expect(result.current.fileError).toBe(true)
        expect(mockOnSubmit).not.toHaveBeenCalled()
      })

      it('should have false fileError on existing file submission', () => {
        const {result} = renderHook(() => useSubmitHandler(mockOnSubmit))
        const formData = {settings: {}}

        act(() => {
          result.current.setFile(new File(['content'], 'test.txt'))
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(result.current.fileError).toBe(false)
      })

      it('should move focus to fileInputRef on missing file submission', () => {
        const fileInputRef = createMockFileInputRef()
        const {result} = renderHook(() =>
          useSubmitHandlerWithQuestionBank(mockOnSubmit, fileInputRef),
        )
        const formData = {settings: {}}

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(fileInputRef.current?.focus).toHaveBeenCalled()
      })

      it('should not move focus to fileInputRef on existing file submission', () => {
        const fileInputRef = createMockFileInputRef()
        const {result} = renderHook(() =>
          useSubmitHandlerWithQuestionBank(mockOnSubmit, fileInputRef),
        )
        const formData = {settings: {}}

        act(() => {
          result.current.setFile(new File(['content'], 'test.txt'))
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(fileInputRef.current?.focus).not.toHaveBeenCalled()
      })
    })

    describe('formData', () => {
      it('should call onSubmit correctly on existing formData', () => {
        const {result} = renderHook(() => useSubmitHandler(mockOnSubmit))
        const formData = {settings: {extra_info: 'extra'}}
        const file = new File(['content'], 'test.txt')

        act(() => {
          result.current.setFile(file)
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(result.current.fileError).toBe(false)
        expect(mockOnSubmit).toHaveBeenCalledWith(
          {
            settings: {extra_info: 'extra'},
            pre_attachment: {
              name: 'test.txt',
              size: 7,
              no_redirect: true,
            },
          },
          file,
        )
      })

      it('should not call onSubmit on missing formData', () => {
        const {result} = renderHook(() => useSubmitHandler(mockOnSubmit))
        const formData = null
        const file = new File(['content'], 'test.txt')

        act(() => {
          result.current.setFile(file)
        })

        act(() => {
          result.current.handleSubmit(formData)
        })

        expect(result.current.fileError).toBe(true)
        expect(mockOnSubmit).not.toHaveBeenCalled()
      })
    })
  })
})
