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
import {resetAndGetFilesEnv} from '../../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../../fixtures/fileContexts'
import {BrowserRouter} from 'react-router-dom'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import userEvent from '@testing-library/user-event'

const renderComponent = () => {
  return render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <MockedQueryClientProvider client={queryClient}>
        <BrowserRouter>
          <AllMyFilesTable />
        </BrowserRouter>
      </MockedQueryClientProvider>
    </FileManagementProvider>,
  )
}

describe('AllMyFilesTable', () => {
  let flashElements: any

  beforeAll(() => {
    const filesContexts = createFilesContexts({
      isMultipleContexts: true,
    })
    resetAndGetFilesEnv(filesContexts)
    window.ENV.context_asset_string = 'courses_1'
  })

  beforeEach(() => {
    flashElements = document.createElement('div')
    flashElements.setAttribute('id', 'flash_screenreader_holder')
    flashElements.setAttribute('role', 'alert')
    document.body.appendChild(flashElements)
  })

  afterEach(() => {
    document.body.removeChild(flashElements)
    flashElements = undefined
  })

  it('renders each context', () => {
    renderComponent()
    const firstRow = screen.getByText('My Files')
    const secondRow = screen.getByText('Course 1')
    expect(firstRow).toBeInTheDocument()
    expect(secondRow).toBeInTheDocument()
  })

  it('hides top nav upload buttons', () => {
    renderComponent()
    const folderButton = screen.queryByRole('button', {name: /folder/i})
    const uploadButton = screen.queryByRole('button', {name: /upload/i})
    expect(folderButton).not.toBeInTheDocument()
    expect(uploadButton).not.toBeInTheDocument()
  })

  it('does not render All My Files button', () => {
    renderComponent()
    const allMyFilesButton = screen.queryByRole('button', {name: /all my files/i})
    expect(allMyFilesButton).not.toBeInTheDocument()
  })

  it('sorts contexts on click', async () => {
    const user = userEvent.setup()
    renderComponent()

    const rows = screen.getAllByRole('link')
    expect(rows[0].textContent).toContain('My Files')
    expect(rows[1].textContent).toContain('Course 1')
    await user.click(screen.getByRole('button', {name: /name/i}))

    const newRows = screen.getAllByRole('link')
    expect(newRows[0].textContent).toContain('Course 1')
    expect(newRows[1].textContent).toContain('My Files')
  })

  it('updates screen reader alert on sort', async () => {
    const user = userEvent.setup()
    renderComponent()
    await user.click(screen.getByRole('button', {name: /name/i}))
    expect(screen.getByText('Sorted by name in ascending order')).toBeInTheDocument()
    await user.click(screen.getByRole('button', {name: /name/i}))
    expect(await screen.findByText('Sorted by name in descending order')).toBeInTheDocument()
  })
})
