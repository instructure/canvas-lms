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

import {render, screen, fireEvent} from '@testing-library/react'
import ViewAssignTo, {ViewAssignToProps} from '../ViewAssignTo'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
jest.mock('@canvas/context-modules/differentiated-modules/react/DifferentiatedModulesTray', () => ({
  __esModule: true,
  default: jest.fn(() => <div data-testid="differentiated-modules-tray">Tray Content</div>),
}))

jest.mock('../../../hooks/useModuleContext', () => ({
  useContextModule: () => ({courseId: '123'}),
}))

jest.mock('../../../hooks/queries/useModuleItems', () => ({
  useModuleItems: jest.fn(() => ({
    data: {moduleItems: []},
    isLoading: false,
  })),
}))

describe('ViewAssignTo', () => {
  const moduleProps: ViewAssignToProps = {
    moduleId: '456',
    moduleName: 'Test Module',
    expanded: true,
    isMenuOpen: true,
    prerequisites: [],
  }

  const renderWithClient = (ui: React.ReactElement) => {
    return render(<MockedQueryClientProvider client={queryClient}>{ui}</MockedQueryClientProvider>)
  }

  it('renders the link text', () => {
    renderWithClient(<ViewAssignTo {...moduleProps} />)

    expect(screen.getByText('View Assign To')).toBeInTheDocument()
  })

  it('opens the tray when the link is clicked', () => {
    const {getByTestId} = renderWithClient(<ViewAssignTo {...moduleProps} />)

    expect(screen.queryByTestId('differentiated-modules-tray')).not.toBeInTheDocument()

    fireEvent.click(screen.getByText('View Assign To'))

    expect(getByTestId('differentiated-modules-tray')).toBeInTheDocument()
  })
})
