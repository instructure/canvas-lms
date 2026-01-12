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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleItemActionPanel from '../ModuleItemActionPanel'
import {http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'
import * as publishingModule from '@canvas/context-modules/react/publishing/publishingContext'

vi.mock('@canvas/context-modules/react/publishing/publishingContext', async () => {
  const actual = await vi.importActual('@canvas/context-modules/react/publishing/publishingContext')
  return {
    ...actual,
    usePublishing: vi.fn(() => ({
      publishingInProgress: false,
    })),
  }
})

type ComponentProps = React.ComponentProps<typeof ModuleItemActionPanel>

const server = setupServer()

const DEFAULT_COURSE_ID = 'test-course-id'
const buildDefaultProps = (overrides: Partial<ComponentProps> = {}): ComponentProps => ({
  moduleId: '1',
  itemId: '123',
  id: '123',
  title: 'Test Discussion',
  indent: 0,
  content: {
    _id: 'discussion1',
    id: 'discussion1',
    type: 'Discussion',
  },
  masterCourseRestrictions: null,
  published: false,
  canBeUnpublished: true,
  masteryPathsData: null,
  setModuleAction: vi.fn(),
  setSelectedModuleItem: vi.fn(),
  setIsManageModuleContentTrayOpen: vi.fn(),
  setSourceModule: vi.fn(),
  moduleTitle: 'Test Module',
  ...overrides,
})

const setUp = (props: ComponentProps, courseId = DEFAULT_COURSE_ID) => {
  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    moduleGroupMenuTools: [],
    moduleMenuModalTools: [],
    moduleMenuTools: [],
    moduleIndexMenuModalTools: [],
  }

  return render(
    <ContextModuleProvider {...contextProps}>
      <ModuleItemActionPanel {...props} />
    </ContextModuleProvider>,
  )
}

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
})
afterAll(() => server.close())

beforeEach(() => {
  fakeENV.setup({
    TIMEZONE: 'UTC',
    CONTEXT_URL_ROOT: '/courses/1',
    MODULE_FILE_PERMISSIONS: {
      manage_files_edit: true,
      usage_rights_required: false,
    },
  })
})

describe('ModuleItemActionPanel', () => {
  it('renders PublishCloud component for content type File', () => {
    setUp(
      buildDefaultProps({
        published: true,
        title: 'Test File',
        content: {
          _id: 'file1',
          id: 'file1',
          type: 'File',
          fileState: '',
        },
      }),
    )

    expect(screen.getByRole('button', {name: /Test File is Published/})).toBeInTheDocument()
  })

  it('renders IconButton for non File content type', () => {
    setUp(
      buildDefaultProps({
        published: false,
        title: 'Test Discussion',
        content: {
          _id: 'discussion1',
          id: 'discussion1',
          type: 'Discussion',
        },
      }),
    )

    expect(screen.getByText('Unpublished')).toBeInTheDocument()
  })

  it('disables and re-enables the publish button when clicked', async () => {
    const props = buildDefaultProps()

    // Mock API return value, the button will re-enable regardless of API success or failure
    server.use(
      http.put(
        `**/api/v1/courses/${DEFAULT_COURSE_ID}/modules/${props.moduleId}/items/${props.itemId}`,
        () => HttpResponse.json({success: true}),
      ),
    )

    setUp(props)

    const button = screen.getByTestId(`module-item-publish-button-${props.itemId}`)

    expect(button).toBeInTheDocument()
    expect(button).not.toBeDisabled()

    fireEvent.click(button)

    expect(button).toBeDisabled()

    await waitFor(() => {
      expect(button).not.toBeDisabled()
    })
  })

  it('toggles disabled state based on publishingContext (mocked)', () => {
    const props = buildDefaultProps()

    const mockUsePublishing = publishingModule.usePublishing as any

    // Initial state is not publishing
    mockUsePublishing.mockReturnValue({
      publishingInProgress: false,
      startPublishing: vi.fn(),
      stopPublishing: vi.fn(),
    })

    const {rerender} = setUp(props)

    const btn = screen.getByTestId(`module-item-publish-button-${props.itemId}`)
    expect(btn).toBeInTheDocument()
    expect(btn).not.toBeDisabled()

    // Mock publishing in progress
    mockUsePublishing.mockReturnValue({
      publishingInProgress: true,
    })

    rerender(
      <ContextModuleProvider {...contextModuleDefaultProps} courseId={DEFAULT_COURSE_ID}>
        <ModuleItemActionPanel {...props} />
      </ContextModuleProvider>,
    )

    expect(btn).toBeDisabled()

    // Mock publishing finished
    mockUsePublishing.mockReturnValue({
      publishingInProgress: false,
    })

    rerender(
      <ContextModuleProvider {...contextModuleDefaultProps} courseId={DEFAULT_COURSE_ID}>
        <ModuleItemActionPanel {...props} />
      </ContextModuleProvider>,
    )

    expect(btn).not.toBeDisabled()
  })
})
