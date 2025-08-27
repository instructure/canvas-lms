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
import {fireEvent, render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleActionMenu from '../ModuleActionMenu'
import {PAGE_SIZE, MODULE_ITEMS, MODULES} from '../../utils/constants'

// External tool data to be provided through context
const mockExternalTools = {
  moduleGroupMenuTools: [
    {
      id: 'tool1',
      title: 'External Tool 1',
      base_url: 'https://example.com/tool1',
    },
  ],
  moduleMenuModalTools: [
    {
      definition_type: 'ContextExternalTool',
      definition_id: 'tool2',
      name: 'External Tool 2',
      placements: {
        module_menu_modal: {
          url: 'https://example.com/tool2',
          title: 'External Tool 2',
        },
      },
    },
  ],
  moduleMenuTools: [
    {
      id: 'tool3',
      title: 'External Tool 3',
      base_url: 'https://example.com/tool3',
    },
  ],
  moduleIndexMenuModalTools: [],
}

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

const setUp = (permissions = {}, courseId = 'test-course-id', moduleId = 'test-module-id') => {
  const queryClient = createQueryClient()

  // Set up query data for modules
  queryClient.setQueryData([MODULES, courseId], {
    pages: [
      {
        modules: [
          {
            id: moduleId,
            name: 'Test Module',
            position: 1,
            published: true,
            moduleItems: [],
          },
        ],
        pageInfo: {
          hasNextPage: false,
          endCursor: null,
        },
      },
    ],
    pageParams: [undefined],
  })

  // Set up query data for module items
  queryClient.setQueryData([MODULE_ITEMS, moduleId, null], {
    moduleItems: [
      {
        id: '1',
        title: 'Test Item',
        content: {
          canDuplicate: true,
        },
      },
    ],
  })

  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    permissions: {
      ...contextModuleDefaultProps.permissions,
      ...permissions,
    },
    ...mockExternalTools,
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextProps}>
        <ModuleActionMenu
          expanded={true}
          isMenuOpen={false}
          setIsMenuOpen={() => {}}
          id={moduleId}
          name="Test Module"
          prerequisites={[]}
          setIsDirectShareOpen={() => {}}
          setIsDirectShareCourseOpen={() => {}}
          setModuleAction={() => {}}
          setIsManageModuleContentTrayOpen={() => {}}
          setSourceModule={() => {}}
        />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleActionMenu', () => {
  it('renders the menu trigger button', () => {
    setUp()
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    expect(menuButton).toBeInTheDocument()
    expect(menuButton).toHaveAttribute('data-testid', 'module-action-menu_test-module-id')
  })

  it('renders all menu items when user has all permissions', () => {
    setUp()
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Check that all menu items are rendered
    expect(screen.getByText('Edit')).toBeInTheDocument()
    expect(screen.getByText('Move Contents...')).toBeInTheDocument()
    expect(screen.getByText('Move Module...')).toBeInTheDocument()
    expect(screen.getByText('Assign To...')).toBeInTheDocument()
    expect(screen.getByText('Delete')).toBeInTheDocument()
    expect(screen.getByText('Duplicate')).toBeInTheDocument()
    expect(screen.getByText('Send To...')).toBeInTheDocument()
    expect(screen.getByText('Copy To...')).toBeInTheDocument()
  })

  it('renders external tool menu items', () => {
    setUp()
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Check that external tool menu items are rendered
    expect(screen.getByText('External Tool 1')).toBeInTheDocument()
    expect(screen.getByText('External Tool 2')).toBeInTheDocument()
    expect(screen.getByText('External Tool 3')).toBeInTheDocument()
  })

  it('only renders edit menu items when user can only edit', () => {
    setUp({
      canEdit: true,
      canDelete: false,
      canAdd: false,
      canDirectShare: false,
    })
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Should show edit-related items
    expect(screen.getByText('Edit')).toBeInTheDocument()
    expect(screen.getByText('Move Contents...')).toBeInTheDocument()
    expect(screen.getByText('Move Module...')).toBeInTheDocument()
    expect(screen.getByText('Assign To...')).toBeInTheDocument()

    // Should not show delete, duplicate, or share items
    expect(screen.queryByText('Delete')).not.toBeInTheDocument()
    expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
    expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
  })

  it('only renders delete menu item when user can only delete', () => {
    setUp({
      canEdit: false,
      canDelete: true,
      canAdd: false,
      canDirectShare: false,
    })
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Should show delete item
    expect(screen.getByText('Delete')).toBeInTheDocument()

    // Should not show other items
    expect(screen.queryByText('Edit')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
    expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
    expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
  })

  it('only renders duplicate menu item when user can add and module is expanded', () => {
    setUp({
      canEdit: false,
      canDelete: false,
      canAdd: true,
      canDirectShare: false,
    })
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Should show duplicate item (since module is expanded and items can be duplicated)
    expect(screen.getByText('Duplicate')).toBeInTheDocument()

    // Should not show other items
    expect(screen.queryByText('Edit')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
    expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Delete')).not.toBeInTheDocument()
    expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
  })

  it('only renders share menu items when user can direct share', () => {
    setUp({
      canEdit: false,
      canDelete: false,
      canAdd: false,
      canDirectShare: true,
    })
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Should show share items
    expect(screen.getByText('Send To...')).toBeInTheDocument()
    expect(screen.getByText('Copy To...')).toBeInTheDocument()

    // Should not show other items
    expect(screen.queryByText('Edit')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
    expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Delete')).not.toBeInTheDocument()
    expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
  })

  it('renders no menu items when user has no permissions', () => {
    setUp({
      canEdit: false,
      canDelete: false,
      canAdd: false,
      canDirectShare: false,
    })
    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    fireEvent.click(menuButton)

    // Should not show any standard menu items
    expect(screen.queryByText('Edit')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
    expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
    expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Delete')).not.toBeInTheDocument()
    expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
    expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
    expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()

    // Should still show external tool items
    expect(screen.getByText('External Tool 1')).toBeInTheDocument()
    expect(screen.getByText('External Tool 2')).toBeInTheDocument()
    expect(screen.getByText('External Tool 3')).toBeInTheDocument()
  })

  it('disables menu button when modules are loading', () => {
    const queryClient = createQueryClient()
    const courseId = 'test-course-id'
    const moduleId = 'test-module-id'

    // Don't set any query data to simulate loading state
    const contextProps = {
      ...contextModuleDefaultProps,
      courseId,
    }

    render(
      <QueryClientProvider client={queryClient}>
        <ContextModuleProvider {...contextProps}>
          <ModuleActionMenu
            expanded={true}
            isMenuOpen={false}
            setIsMenuOpen={() => {}}
            id={moduleId}
            name="Test Module"
            prerequisites={[]}
            setIsDirectShareOpen={() => {}}
            setIsDirectShareCourseOpen={() => {}}
            setModuleAction={() => {}}
            setIsManageModuleContentTrayOpen={() => {}}
            setSourceModule={() => {}}
          />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    expect(menuButton).toBeDisabled()
  })

  it('disables menu button when there is an error loading modules', () => {
    const courseId = 'test-course-id'
    const moduleId = 'test-module-id'

    // Create a query client that will return an error for the modules query
    const errorQueryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          gcTime: 0,
          queryFn: () => {
            throw new Error('Failed to load modules')
          },
        },
      },
    })

    const contextProps = {
      ...contextModuleDefaultProps,
      courseId,
    }

    render(
      <QueryClientProvider client={errorQueryClient}>
        <ContextModuleProvider {...contextProps}>
          <ModuleActionMenu
            expanded={true}
            isMenuOpen={false}
            setIsMenuOpen={() => {}}
            id={moduleId}
            name="Test Module"
            prerequisites={[]}
            setIsDirectShareOpen={() => {}}
            setIsDirectShareCourseOpen={() => {}}
            setModuleAction={() => {}}
            setIsManageModuleContentTrayOpen={() => {}}
            setSourceModule={() => {}}
          />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    const menuButton = screen.getByRole('button', {name: 'Module Options'})
    expect(menuButton).toBeDisabled()
  })
})
