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

import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {contextModuleDefaultProps, ContextModuleProvider} from '../../../hooks/useModuleContext'
import CreateLearningObjectForm, {CreateLearningObjectFormProps} from '../CreateLearningObjectForm'
import {FormState} from '../../../utils/types'

const makeState = (overrides: Partial<FormState['newItem']> = {}): FormState =>
  ({
    newItem: {
      name: '',
      assignmentGroup: undefined,
      file: undefined,
      ...overrides,
    },
  }) as unknown as FormState

const buildProps = (
  overrides: Partial<CreateLearningObjectFormProps> = {},
): CreateLearningObjectFormProps => ({
  itemType: 'quiz',
  onChange: vi.fn(),
  nameError: null,
  dispatch: vi.fn(),
  state: makeState(),
  ...overrides,
  indentValue: 0,
  onIndentChange: () => {},
  moduleName: 'Test Module',
})

const renderWithContext = (
  contextProps: Record<string, any> = {},
  propsOverrides: Partial<CreateLearningObjectFormProps> = {},
) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false},
      mutations: {retry: false},
    },
  })

  const contextModuleProps = {
    ...contextModuleDefaultProps,
    ...contextProps,
  }

  const props = buildProps(propsOverrides)

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextModuleProps}>
        <CreateLearningObjectForm {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('CreateLearningObjectForm', () => {
  describe('Quiz Engine Selection for quiz itemType', () => {
    it('should SHOW quiz engine selector when NEW_QUIZZES_ENABLED is true but NEW_QUIZZES_BY_DEFAULT false', () => {
      // showQuizzesEngineSelection is true when NEW_QUIZZES_ENABLED is true and NEW_QUIZZES_BY_DEFAULT is false
      renderWithContext({
        NEW_QUIZZES_ENABLED: true,
        NEW_QUIZZES_BY_DEFAULT: false,
      })

      const quizEngineSelect = screen.getByTestId('create-item-quiz-engine-select')
      expect(quizEngineSelect).toBeInTheDocument()
    })

    it('should NOT show quiz engine when NEW_QUIZZES_ENABLED is false and NEW_QUIZZES_BY_DEFAULT is true', () => {
      // showQuizzesEngineSelection is false when NEW_QUIZZES_ENABLED is false or NEW_QUIZZES_BY_DEFAULT is true
      renderWithContext({
        NEW_QUIZZES_ENABLED: false,
        NEW_QUIZZES_BY_DEFAULT: true,
      })

      const quizEngineSelect = screen.queryByTestId('create-item-quiz-engine-select')
      expect(quizEngineSelect).not.toBeInTheDocument()
    })

    it('should NOT show quiz engine when NEW_QUIZZES_ENABLED is false and NEW_QUIZZES_BY_DEFAULT is false', () => {
      // showQuizzesEngineSelection is false when NEW_QUIZZES_ENABLED is false or NEW_QUIZZES_BY_DEFAULT is true
      renderWithContext({
        NEW_QUIZZES_ENABLED: false,
        NEW_QUIZZES_BY_DEFAULT: false,
      })

      const quizEngineSelect = screen.queryByTestId('create-item-quiz-engine-select')
      expect(quizEngineSelect).not.toBeInTheDocument()
    })

    it('should NOT show quiz engine selector when NEW_QUIZZES_ENABLED is true but NEW_QUIZZES_BY_DEFAULT is also true', () => {
      // showQuizzesEngineSelection is false when NEW_QUIZZES_BY_DEFAULT is true
      renderWithContext({
        NEW_QUIZZES_ENABLED: true,
        NEW_QUIZZES_BY_DEFAULT: true,
      })

      const quizEngineSelect = screen.queryByTestId('create-item-quiz-engine-select')
      expect(quizEngineSelect).not.toBeInTheDocument()
    })
  })
})
