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
import {render, fireEvent, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import AddItemModal from '../AddItemModal'

const setUp = (props = {}) => {
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
describe('CreateLearningObjectForm', () => {
  describe('Title validation', () => {
    beforeEach(() => {
      setUp()
    })

    it('shows error if name is empty in Create tab and prevents submit', () => {
      fireEvent.click(screen.getByRole('tab', {name: /Create Item/i}))
      const nameInput = screen.getByLabelText(/Name/i)
      fireEvent.change(nameInput, {target: {value: ''}})
      fireEvent.click(screen.getByRole('button', {name: /Add Item/i}))
      expect(screen.getByText('Name is required')).toBeInTheDocument()
    })

    it('removes error when valid name is entered', () => {
      fireEvent.click(screen.getByRole('tab', {name: /Create Item/i}))
      const nameInput = screen.getByLabelText(/Name/i)
      fireEvent.change(nameInput, {target: {value: ''}})
      fireEvent.click(screen.getByRole('button', {name: /Add Item/i}))
      expect(screen.getByText('Name is required')).toBeInTheDocument()
      fireEvent.change(nameInput, {target: {value: 'Valid Name'}})
      expect(screen.queryByText('Name is required')).not.toBeInTheDocument()
    })
  })
})
