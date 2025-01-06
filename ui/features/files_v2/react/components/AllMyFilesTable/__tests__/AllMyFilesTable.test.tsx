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
import AllMyFilesTable from '../AllMyFilesTable'
import {render, screen} from '@testing-library/react'
import {setupFilesEnv} from '../../../../fixtures/fakeFilesEnv'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import {BrowserRouter} from 'react-router-dom'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'

const renderComponent = () => {
  const queryClient = new QueryClient()

  return render(
    <MockedQueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AllMyFilesTable />
      </BrowserRouter>
    </MockedQueryClientProvider>,
  )
}

describe('AllMyFilesTable', () => {
  beforeAll(() => {
    setupFilesEnv(true)
  })

  it('renders each context', () => {
    renderComponent()
    const firstRow = screen.getByText(filesEnv.contexts[0].name)
    const secondRow = screen.getByText(filesEnv.contexts[1].name)
    expect(firstRow).toBeInTheDocument()
    expect(secondRow).toBeInTheDocument()
  })

  it('disables top nav buttons', () => {
    renderComponent()
    const folderButton = screen.getByRole('button', {name: /folder/i})
    const uploadButton = screen.getByRole('button', {name: /upload/i})
    expect(folderButton).toBeDisabled()
    expect(uploadButton).toBeDisabled()
  })

  it('does not render All My Files button', () => {
    renderComponent()
    const allMyFilesButton = screen.queryByRole('button', {name: /all my files/i})
    expect(allMyFilesButton).not.toBeInTheDocument()
  })

  it('sorts contexts on click', () => {
    renderComponent()

    const rows = screen.getAllByRole('link')
    expect(rows[0].textContent).toContain('My Files')
    expect(rows[1].textContent).toContain('Course 1')
    screen.getByRole('button', {name: /name/i}).click()

    const newRows = screen.getAllByRole('link')
    expect(newRows[0].textContent).toContain('Course 1')
    expect(newRows[1].textContent).toContain('My Files')
  })
})
