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
import {setupServer} from 'msw/node'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleItemActionPanel from '../ModuleItemActionPanel'

type ComponentProps = React.ComponentProps<typeof ModuleItemActionPanel>

const server = setupServer()

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
    published: false,
  },
  masterCourseRestrictions: null,
  published: false,
  canBeUnpublished: true,
  masteryPathsData: null,
  setModuleAction: jest.fn(),
  setSelectedModuleItem: jest.fn(),
  setIsManageModuleContentTrayOpen: jest.fn(),
  setSourceModule: jest.fn(),
  moduleTitle: 'Test Module',
  ...overrides,
})

const setUp = (props: ComponentProps, courseId = 'test-course-id') => {
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
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

beforeEach(() => {
  // @ts-expect-error
  window.ENV = {
    TIMEZONE: 'UTC',
    CONTEXT_URL_ROOT: '/courses/1',
    MODULE_FILE_PERMISSIONS: {
      manage_files_edit: true,
      usage_rights_required: false,
    },
  }
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
          published: true,
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
          published: false,
        },
      }),
    )

    expect(screen.getByText('Unpublished')).toBeInTheDocument()
  })
})
