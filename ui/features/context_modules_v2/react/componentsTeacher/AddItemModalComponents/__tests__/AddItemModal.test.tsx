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

import {render, screen, waitFor, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import AddItemModal from '../AddItemModal'

const renderWithProviders = (props: Partial<React.ComponentProps<typeof AddItemModal>> = {}) => {
  const queryClient = new QueryClient()

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextModuleDefaultProps}>
        <AddItemModal
          isOpen={true}
          onRequestClose={jest.fn()}
          moduleName="Test Module"
          moduleId="1"
          {...props}
        />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}
describe('Title validation', () => {
  it('shows error if name is empty in Create tab and prevents submit', async () => {
    renderWithProviders()

    await userEvent.click(screen.getByRole('tab', {name: /create item/i}))
    const nameInput = await screen.findByLabelText(/name/i)
    await userEvent.clear(nameInput)
    await userEvent.click(screen.getByRole('button', {name: /add item/i}))
    const createPanel = await screen.findByRole('tabpanel', {name: /create item/i})
    expect(
      await within(createPanel).findByText('Assignment name is required', {exact: true}),
    ).toBeInTheDocument()
  })

  it('removes error when a valid name is entered', async () => {
    renderWithProviders()

    await userEvent.click(screen.getByRole('tab', {name: /create item/i}))
    const nameInput = await screen.findByLabelText(/name/i)
    await userEvent.clear(nameInput)
    await userEvent.click(screen.getByRole('button', {name: /add item/i}))
    const createPanel = await screen.findByRole('tabpanel', {name: /create item/i})
    expect(
      await within(createPanel).findByText('Assignment name is required', {exact: true}),
    ).toBeInTheDocument()

    await userEvent.type(nameInput, 'Valid Name')
    await waitFor(() => {
      expect(
        within(createPanel).queryByText('Assignment name is required', {exact: true}),
      ).not.toBeInTheDocument()
    })
  })
})
