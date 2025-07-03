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
  onCollapseAll: jest.fn(),
  onExpandAll: jest.fn(),
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
      <ContextModuleProvider {...contextModuleDefaultProps} courseId={courseId} externalTools={[]}>
        <ModulePageActionHeaderStudent {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModulePageActionHeaderStudent', () => {
  beforeEach(() => {
    queryClient.clear()
    // @ts-expect-error
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
})
