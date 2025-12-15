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

import React from 'react'
import {render, fireEvent, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import EditItemModal, {type EditItemModalProps} from '../EditItemModal'

const buildDefaultProps = (overrides: Partial<EditItemModalProps> = {}): EditItemModalProps => ({
  isOpen: true,
  onRequestClose: vi.fn(),
  itemName: 'Test Item',
  itemType: 'assignment',
  itemIndent: 1,
  itemId: '123',
  courseId: '1',
  moduleId: '1',
  ...overrides,
})

const setUp = (props: EditItemModalProps, courseId = 'test-course-id') => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    moduleGroupMenuTools: [],
    moduleMenuModalTools: [],
    moduleMenuTools: [],
    moduleIndexMenuModalTools: [],
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextProps}>
        <EditItemModal {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

const server = setupServer()

describe('EditItemModal', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    // @ts-expect-error
    window.ENV = {
      TIMEZONE: 'UTC',
    }

    server.use(
      http.post('/courses/:courseId/modules/items/:itemId', () => {
        return HttpResponse.json({
          id: '123',
          title: 'Updated Item',
          indent: 1,
        })
      }),
    )
  })

  it('renders with initial values', () => {
    const {getByLabelText} = setUp(buildDefaultProps())

    expect(getByLabelText('Title')).toHaveValue('Test Item')
    expect(getByLabelText('Indent')).toHaveValue('Indent 1 level')
  })

  it('updates title when typing', () => {
    setUp(buildDefaultProps())
    const titleInput = screen.getByTestId('edit-modal-title')
    fireEvent.change(titleInput, {target: {value: 'New Title'}})
    expect(titleInput).toHaveValue('New Title')
  })

  it('shows error if title is empty', () => {
    setUp(buildDefaultProps())

    const titleInput = screen.getByTestId('edit-modal-title')
    fireEvent.change(titleInput, {target: {value: ''}})
    fireEvent.click(screen.getByText('Update'))
    expect(screen.getByText('Name is required')).toBeInTheDocument()
  })

  it('removes name error when valid title is entered', () => {
    setUp(buildDefaultProps())

    const titleInput = screen.getByTestId('edit-modal-title')
    fireEvent.change(titleInput, {target: {value: ''}})
    fireEvent.click(screen.getByText('Update'))
    expect(screen.getByText('Name is required')).toBeInTheDocument()
    fireEvent.change(titleInput, {target: {value: 'Valid Title'}})
    expect(screen.queryByText('Name is required')).not.toBeInTheDocument()
  })

  it('updates indent when changed', () => {
    setUp(buildDefaultProps())

    const indentSelect = screen.getByRole('combobox', {name: 'Indent'})
    fireEvent.click(indentSelect)
    fireEvent.click(screen.getByText('Indent 2 levels'))
    expect(indentSelect).toHaveValue('Indent 2 levels')
  })

  it('calls onRequestClose when Cancel is clicked', () => {
    const props = buildDefaultProps()
    setUp(props)
    fireEvent.click(screen.getByText('Cancel'))
    expect(props.onRequestClose).toHaveBeenCalled()
  })

  describe('Master Course Restriction', () => {
    it('should disable title input when master course restriction of "all" is true', () => {
      const props = buildDefaultProps({
        masterCourseRestrictions: {
          all: true,
          content: false,
          availabilityDates: null,
          dueDates: null,
          points: null,
          settings: null,
        },
      })
      setUp(props)
      const titleInput = screen.getByTestId('edit-modal-title')
      expect(titleInput).toBeDisabled()
    })

    it('should disable title input when master course restriction of "content" is true', () => {
      const props = buildDefaultProps({
        masterCourseRestrictions: {
          all: null,
          content: true,
          availabilityDates: null,
          dueDates: null,
          points: null,
          settings: null,
        },
      })
      setUp(props)
      const titleInput = screen.getByTestId('edit-modal-title')
      expect(titleInput).toBeDisabled()
    })

    it('should not disable title input when master course restriction of "content" is falsey', () => {
      const props = buildDefaultProps({
        masterCourseRestrictions: {
          all: null,
          content: null,
          availabilityDates: true,
          dueDates: null,
          points: null,
          settings: null,
        },
      })
      setUp(props)
      const titleInput = screen.getByTestId('edit-modal-title')
      expect(titleInput).not.toBeDisabled()
    })

    it('should not disable title input when master course restrictions are missing', () => {
      const props = buildDefaultProps()
      setUp(props)
      const titleInput = screen.getByTestId('edit-modal-title')
      expect(titleInput).not.toBeDisabled()
    })
  })

  describe('External URL types', () => {
    const defaultProps = buildDefaultProps({
      itemType: 'external',
      itemURL: 'http://example.com',
      itemNewTab: true,
    })

    it('renders external URL field when itemType is external', () => {
      setUp(defaultProps)
      expect(screen.getByLabelText('URL')).toBeInTheDocument()
    })

    it('renders new Tab field when itemType is external', () => {
      setUp(defaultProps)
      expect(screen.getByLabelText('Load in a new tab')).toBeInTheDocument()
    })

    it('does not render external URL fields when itemType is not external', () => {
      setUp(buildDefaultProps())
      expect(screen.queryByLabelText('URL')).not.toBeInTheDocument()
    })

    it('does not render new Tab fields when itemType is not external', () => {
      setUp(buildDefaultProps())
      expect(screen.queryByLabelText('Load in a new tab')).not.toBeInTheDocument()
    })
  })
})
