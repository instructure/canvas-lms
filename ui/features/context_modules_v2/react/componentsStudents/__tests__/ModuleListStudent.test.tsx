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

import React from 'react'
import {render, screen} from '@testing-library/react'
import ModulesListStudent from '../ModuleListStudent'
import * as useContextModuleHook from '../../hooks/useModuleContext'
import * as useModulesStudentHook from '../../hooks/queriesStudent/useModulesStudent'
import * as useHowManyHook from '../../hooks/queriesStudent/useHowManyModulesAreFetchingItems'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

jest.mock('../../hooks/useModuleContext')
jest.mock('../../hooks/queriesStudent/useModulesStudent')
jest.mock('../../hooks/queriesStudent/useHowManyModulesAreFetchingItems')

const mockUseContextModule = useContextModuleHook.useContextModule as jest.Mock
const mockUseModulesStudent = useModulesStudentHook.useModulesStudent as jest.Mock
const mockUseHowMany = useHowManyHook.useHowManyModulesAreFetchingItems as jest.Mock

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      gcTime: 0,
    },
  },
})

const renderModulesListStudent = () => {
  return render(
    <QueryClientProvider client={queryClient}>
      <ModulesListStudent />
    </QueryClientProvider>,
  )
}

describe('ModulesListStudent', () => {
  beforeEach(() => {
    mockUseContextModule.mockReturnValue({courseId: '123'})
    mockUseHowMany.mockReturnValue({
      moduleFetchingCount: 0,
      maxFetchingCount: 0,
      fetchComplete: false,
    })
  })

  it('shows a loading spinner when loading and no data', () => {
    mockUseModulesStudent.mockReturnValue({
      data: undefined,
      isLoading: true,
      error: null,
      isFetchingNextPage: false,
      hasNextPage: false,
    })

    renderModulesListStudent()
    expect(screen.getByText('Loading modules')).toBeInTheDocument()
  })

  it('shows error message if error is present', () => {
    mockUseModulesStudent.mockReturnValue({
      data: undefined,
      isLoading: false,
      error: new Error('Failed'),
      isFetchingNextPage: false,
      hasNextPage: false,
    })

    renderModulesListStudent()
    expect(screen.getByText('Error loading modules')).toBeInTheDocument()
  })

  it('shows no modules message when modules array is empty', () => {
    mockUseModulesStudent.mockReturnValue({
      data: {pages: [{modules: []}]},
      isLoading: false,
      error: null,
      isFetchingNextPage: false,
      hasNextPage: false,
    })

    renderModulesListStudent()
    expect(screen.getByText('No modules found')).toBeInTheDocument()
  })

  it('renders a module if one exists', () => {
    mockUseModulesStudent.mockReturnValue({
      data: {
        pages: [
          {
            modules: [
              {
                _id: 'module-1',
                name: 'Intro Module',
                completionRequirements: [],
                prerequisites: [],
                requireSequentialProgress: false,
                progression: {collapsed: false},
                requirementCount: 0,
                submissionStatistics: null,
              },
            ],
          },
        ],
      },
      isLoading: false,
      error: null,
      isFetchingNextPage: false,
      hasNextPage: false,
    })

    renderModulesListStudent()
    expect(screen.getByText('Intro Module')).toBeInTheDocument()
  })
})
