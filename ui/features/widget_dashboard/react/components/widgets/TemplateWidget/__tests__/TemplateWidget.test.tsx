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
import {render, screen, fireEvent} from '@testing-library/react'
import TemplateWidget from '../TemplateWidget'
import type {TemplateWidgetProps} from '../TemplateWidget'
import type {Widget} from '../../../../types'

const mockWidget: Widget = {
  id: 'test-widget',
  type: 'test',
  position: {col: 1, row: 1},
  size: {width: 2, height: 1},
  title: 'Test Widget',
}

type Props = Omit<TemplateWidgetProps, 'children'>

const buildDefaultProps = (overrides: Partial<Props> = {}): Props => {
  const defaultProps: Props = {
    widget: mockWidget,
  }
  return {...defaultProps, ...overrides}
}

const setup = (props: Props = buildDefaultProps(), children = <div>Test content</div>) => {
  return render(<TemplateWidget {...props}>{children}</TemplateWidget>)
}

describe('TemplateWidget', () => {
  it('renders with default props', () => {
    setup()

    expect(screen.getByTestId('widget-test-widget')).toBeInTheDocument()
    expect(screen.getByText('Test Widget')).toBeInTheDocument()
    expect(screen.getByText('Test content')).toBeInTheDocument()
  })

  it('renders with custom title', () => {
    const props = buildDefaultProps({title: 'Custom Title'})
    setup(props)

    expect(screen.getByText('Custom Title')).toBeInTheDocument()
    expect(screen.queryByText('Test Widget')).not.toBeInTheDocument()
  })

  it('renders without header when showHeader is false', () => {
    const props = buildDefaultProps({showHeader: false})
    setup(props)

    expect(screen.queryByText('Test Widget')).not.toBeInTheDocument()
    expect(screen.getByText('Test content')).toBeInTheDocument()
  })

  it('renders loading state', () => {
    const props = buildDefaultProps({isLoading: true})
    setup(props)

    expect(screen.getByText('Loading widget data...')).toBeInTheDocument()
    expect(screen.queryByText('Test content')).not.toBeInTheDocument()
  })

  it('renders error state', () => {
    const props = buildDefaultProps({error: 'Something went wrong'})
    setup(props)

    expect(screen.getByText('Something went wrong')).toBeInTheDocument()
    expect(screen.queryByText('Test content')).not.toBeInTheDocument()
  })

  it('renders error state with retry button', () => {
    const onRetry = jest.fn()
    const props = buildDefaultProps({error: 'Something went wrong', onRetry})
    setup(props)

    expect(screen.getByText('Something went wrong')).toBeInTheDocument()

    const retryButton = screen.getByTestId('test-widget-retry-button')
    expect(retryButton).toBeInTheDocument()

    fireEvent.click(retryButton)
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('renders header actions', () => {
    const headerActions = <button data-testid="header-action-button">Action</button>
    const props = buildDefaultProps({headerActions})
    setup(props)

    expect(screen.getByTestId('header-action-button')).toBeInTheDocument()
  })

  it('renders actions section', () => {
    const actions = <button data-testid="widget-action-button">Widget Action</button>
    const props = buildDefaultProps({actions})
    setup(props)

    expect(screen.getByTestId('widget-action-button')).toBeInTheDocument()
  })

  it('does not render actions when loading', () => {
    const actions = <button data-testid="widget-action-button">Widget Action</button>
    const props = buildDefaultProps({actions, isLoading: true})
    setup(props)

    expect(screen.queryByTestId('widget-action-button')).not.toBeInTheDocument()
  })

  it('does not render actions when error', () => {
    const actions = <button data-testid="widget-action-button">Widget Action</button>
    const props = buildDefaultProps({actions, error: 'Error occurred'})
    setup(props)

    expect(screen.queryByTestId('widget-action-button')).not.toBeInTheDocument()
  })

  it('applies correct widget test id based on widget id', () => {
    const customWidget = {...mockWidget, id: 'custom-id'}
    const props = buildDefaultProps({widget: customWidget})
    setup(props)

    expect(screen.getByTestId('widget-custom-id')).toBeInTheDocument()
  })

  it('renders complex children content', () => {
    const complexChildren = (
      <div>
        <p>Paragraph 1</p>
        <p>Paragraph 2</p>
        <button data-testid="child-button">Child Button</button>
      </div>
    )
    setup(buildDefaultProps(), complexChildren)

    expect(screen.getByText('Paragraph 1')).toBeInTheDocument()
    expect(screen.getByText('Paragraph 2')).toBeInTheDocument()
    expect(screen.getByTestId('child-button')).toBeInTheDocument()
  })
})
