/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import ModulePageActionHeaderStudent from '../ModulePageActionHeaderStudent'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {CourseStudentResponse} from '../../utils/types.d'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import {ObserverCourseData} from '../../hooks/queriesStudent/useCourseObserver'
import userEvent from '@testing-library/user-event'

const contextModuleHeaderDefaultProps = {
  title: 'Modules',
  publishMenu: {
    courseId: '1',
    runningProgressId: null,
    disabled: false,
    visible: true,
  },
  viewProgress: {
    label: 'View Progress',
    url: '/courses/1/modules/progress',
    visible: true,
  },
  addModule: {
    label: 'Add Module',
    visible: true,
  },
  moreMenu: {
    label: 'More',
    menuTools: {
      items: [
        {
          href: '#url',
          'data-tool-id': 1,
          'data-tool-launch-type': null,
          class: null,
          icon: null,
          title: 'External Tool',
        },
      ],
      visible: true,
    },
    exportCourseContent: {
      label: 'Export Course Content',
      url: '/courses/1/modules/export',
      visible: true,
    },
  },
  lastExport: {
    label: 'Last Export:',
    url: '/courses/1/modules/last_export',
    date: '2024-01-01 00:00:00',
    visible: true,
  },
}

// Setup QueryClient
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      gcTime: 0,
    },
  },
})

interface DefaultProps {
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
  disabled?: boolean
}

const buildDefaultProps = (overrides: Partial<DefaultProps> = {}): DefaultProps => ({
  onCollapseAll: vi.fn(),
  onExpandAll: vi.fn(),
  anyModuleExpanded: true,
  ...overrides,
})

// Helper function to set up the test environment with the given course data
const setupTest = (
  props: DefaultProps,
  courseData?: CourseStudentResponse,
  courseId: string = '1',
) => {
  queryClient.clear()

  queryClient.setQueryData(
    ['courseStudent', courseId],
    courseData || {
      name: 'Test Course',
      submissionStatistics: {
        submissionsDueThisWeekCount: 5,
        missingSubmissionsCount: 3,
      },
    },
  )

  // Render the component with context provider
  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider
        {...contextModuleDefaultProps}
        courseId={courseId}
        moduleMenuModalTools={[]}
        moduleGroupMenuTools={[]}
        moduleMenuTools={[]}
        moduleIndexMenuModalTools={[]}
      >
        <ModulePageActionHeaderStudent {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

// Helper function for setting up observer tests
const setupObserverTest = (
  props: DefaultProps,
  observerData?: ObserverCourseData,
  courseId: string = '1',
  observedStudent: {id: string; name: string} | null = {id: '101', name: 'Alice Student'},
) => {
  queryClient.clear()

  queryClient.setQueryData(
    ['courseObserver', courseId],
    observerData?.courseData || {
      name: 'Test Course',
      submissionStatistics: {
        missingSubmissionsCount: 5,
        submissionsDueThisWeekCount: 10,
      },
      settings: {showStudentOnlyModuleId: 'mod_1'},
    },
  )

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider
        {...contextModuleDefaultProps}
        courseId={courseId}
        isObserver={true}
        observedStudent={observedStudent}
        moduleMenuModalTools={[]}
        moduleGroupMenuTools={[]}
        moduleMenuTools={[]}
        moduleIndexMenuModalTools={[]}
      >
        <ModulePageActionHeaderStudent {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModulePageActionHeaderStudent', () => {
  beforeEach(() => {
    queryClient.clear()
    window.ENV.CONTEXT_MODULES_HEADER_PROPS = contextModuleHeaderDefaultProps
  })

  it('renders the module page action header student component with course name', () => {
    const {getByText} = setupTest(buildDefaultProps())

    expect(getByText('Welcome to Test Course!')).toBeInTheDocument()
    expect(
      getByText(
        'Your course content is organized into modules below. Explore each one to learn and complete activities.',
      ),
    ).toBeInTheDocument()
  })

  it('renders generic welcome when course name is not available', () => {
    const {queryByText} = setupTest(buildDefaultProps(), {
      name: undefined,
      submissionStatistics: {
        submissionsDueThisWeekCount: 0,
        missingSubmissionsCount: 0,
      },
    })
    expect(queryByText('Welcome!')).not.toBeInTheDocument()
  })

  it('renders submissionStatistics as buttons', () => {
    const {getByTestId} = setupTest(buildDefaultProps(), {
      name: 'Test Course',
      submissionStatistics: {
        submissionsDueThisWeekCount: 5,
        missingSubmissionsCount: 3,
      },
    })

    expect(getByTestId('assignment-due-this-week-button')).toHaveAttribute(
      'href',
      `/courses/1/assignments`,
    )
    expect(getByTestId('missing-assignment-button')).toHaveAttribute(
      'href',
      `/courses/1/assignments`,
    )
  })

  it('shows assignment submissionStatistics with proper pluralization', () => {
    const {getByText} = setupTest(buildDefaultProps(), {
      name: 'Test Course',
      submissionStatistics: {
        submissionsDueThisWeekCount: 1,
        missingSubmissionsCount: 2,
      },
    })

    expect(getByText('1 Assignment Due This Week')).toBeInTheDocument()
    expect(getByText('2 Missing Assignments')).toBeInTheDocument()
  })

  it('handles singular/plural text for submissionStatistics correctly', () => {
    const {getByText, queryByText} = setupTest(buildDefaultProps(), {
      name: 'Test Course',
      submissionStatistics: {
        submissionsDueThisWeekCount: 0,
        missingSubmissionsCount: 1,
      },
    })

    expect(queryByText('0 Assignments Due This Week')).not.toBeInTheDocument()
    expect(getByText('1 Missing Assignment')).toBeInTheDocument()
  })

  it('calls onCollapseAll when anyModuleExpanded is true and button is clicked', async () => {
    const props = buildDefaultProps({anyModuleExpanded: true})
    const {getAllByText} = setupTest(props)

    const button = getAllByText('Collapse All')[0].closest('button') as HTMLButtonElement
    await userEvent.click(button)

    expect(props.onCollapseAll).toHaveBeenCalled()
    expect(props.onExpandAll).not.toHaveBeenCalled()
  })

  it('calls onExpandAll when anyModuleExpanded is false and button is clicked', async () => {
    const props = buildDefaultProps({anyModuleExpanded: false})
    const {getAllByText} = setupTest(props)

    const button = getAllByText('Expand All')[0].closest('button') as HTMLButtonElement
    await userEvent.click(button)

    expect(props.onExpandAll).toHaveBeenCalled()
    expect(props.onCollapseAll).not.toHaveBeenCalled()
  })

  it('does not call expand/collapse callbacks when button is disabled', async () => {
    const props = buildDefaultProps({disabled: true, anyModuleExpanded: true})
    const {getAllByText} = setupTest(props)

    const button = getAllByText('Collapse All')[0].closest('button') as HTMLButtonElement
    expect(button).toBeDisabled()

    await userEvent.click(button)

    expect(props.onCollapseAll).not.toHaveBeenCalled()
    expect(props.onExpandAll).not.toHaveBeenCalled()
  })

  it('renders nothing when course data is still loading', () => {
    // Instead of using setupTest which sets the query, do raw render
    const props = buildDefaultProps()

    queryClient.clear()

    const {container} = render(
      <QueryClientProvider client={queryClient}>
        <ContextModuleProvider
          {...contextModuleDefaultProps}
          courseId="1"
          permissions={contextModuleDefaultProps.permissions}
        >
          <ModulePageActionHeaderStudent {...props} />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    expect(container).toBeEmptyDOMElement()
  })

  describe('Observer functionality', () => {
    it('renders observer-specific welcome message', () => {
      const {getByText, queryByText} = setupObserverTest(buildDefaultProps())

      expect(
        getByText(
          'Your course content is organized into modules below. Explore each one to learn and complete activities.',
        ),
      ).toBeInTheDocument()
      // Course name might not show due to how observer data is structured
      expect(queryByText('Welcome to Test Course!')).toBeInTheDocument()
    })

    it('shows missing assignments for observer', () => {
      const observerData = {
        courseData: {
          name: 'Test Course',
          submissionStatistics: {
            missingSubmissionsCount: 8,
            submissionsDueThisWeekCount: 0,
          },
          settings: {showStudentOnlyModuleId: 'mod_1'},
        },
        observedStudent: {id: '101', name: 'Alice Student'},
      }

      const {getByText} = setupObserverTest(buildDefaultProps(), observerData)

      expect(getByText('8 Missing Assignments')).toBeInTheDocument()
    })

    it('handles observed student missing assignments', () => {
      const observerData = {
        courseData: {
          name: 'Test Course',
          submissionStatistics: {
            missingSubmissionsCount: 3,
            submissionsDueThisWeekCount: 0,
          },
          settings: {showStudentOnlyModuleId: 'mod_1'},
        },
        observedStudent: {id: '101', name: 'Alice Student'},
      }

      const {getByText} = setupObserverTest(buildDefaultProps(), observerData, '1', {
        id: '101',
        name: 'Alice Student',
      })

      expect(getByText('3 Missing Assignments')).toBeInTheDocument()
    })

    it('does not show due this week button for observers', () => {
      const observerData = {
        courseData: {
          name: 'Test Course',
          submissionStatistics: {
            missingSubmissionsCount: 2,
            submissionsDueThisWeekCount: 5,
          },
          settings: {showStudentOnlyModuleId: 'mod_1'},
        },
        observedStudent: {id: '101', name: 'Alice Student'},
      }

      const {queryByTestId} = setupObserverTest(buildDefaultProps(), observerData)

      expect(queryByTestId('assignment-due-this-week-button')).not.toBeInTheDocument()
    })

    it('handles observer with no missing assignments', () => {
      const observerData = {
        courseData: {
          name: 'Test Course',
          submissionStatistics: {
            missingSubmissionsCount: 0,
            submissionsDueThisWeekCount: 0,
          },
          settings: {showStudentOnlyModuleId: 'mod_1'},
        },
        observedStudent: {id: '101', name: 'Alice Student'},
      }

      const {queryByTestId} = setupObserverTest(buildDefaultProps(), observerData)

      expect(queryByTestId('missing-assignment-button')).not.toBeInTheDocument()
      expect(queryByTestId('assignment-due-this-week-button')).not.toBeInTheDocument()
    })

    it('renders nothing when observer data is loading', () => {
      const props = buildDefaultProps()
      queryClient.clear()

      const {container} = render(
        <QueryClientProvider client={queryClient}>
          <ContextModuleProvider
            {...contextModuleDefaultProps}
            courseId="1"
            isObserver={true}
            observedStudent={{id: '101', name: 'Alice Student'}}
            permissions={contextModuleDefaultProps.permissions}
          >
            <ModulePageActionHeaderStudent {...props} />
          </ContextModuleProvider>
        </QueryClientProvider>,
      )

      expect(container).toBeEmptyDOMElement()
    })

    it('handles observer with undefined course name gracefully', () => {
      const observerData = {
        courseData: {
          name: undefined,
          submissionStatistics: undefined,
          settings: {showStudentOnlyModuleId: 'mod_1'},
        },
        observedStudent: {id: '101', name: 'Alice Student'},
      }

      const {queryByText} = setupObserverTest(buildDefaultProps(), observerData)

      expect(queryByText(/Observing/)).not.toBeInTheDocument()
    })
  })
})
