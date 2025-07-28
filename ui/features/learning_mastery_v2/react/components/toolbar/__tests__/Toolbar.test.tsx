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
import {render, waitFor} from '@testing-library/react'
import {Toolbar, ToolbarProps} from '../Toolbar'

const makeProps = (props = {}): ToolbarProps => ({
  courseId: '123',
  gradebookFilters: ['filter1', 'filter2'],
  showDataDependentControls: true,
  ...props,
})

describe('Toolbar', () => {
  it('renders the gradebook menu and title', () => {
    const {getByTestId, getByText} = render(<Toolbar {...makeProps()} />)
    expect(getByTestId('lmgb-gradebook-menu')).toBeInTheDocument()
    expect(getByText('Learning Mastery Gradebook')).toBeInTheDocument()
  })

  it('renders the ExportCSVButton', () => {
    const {getByTestId} = render(<Toolbar {...makeProps()} />)
    expect(getByTestId('export-button')).toBeInTheDocument()
    expect(getByTestId('export-button')).toHaveTextContent('Export')
  })

  it('renders the settings button', () => {
    const {getByTestId} = render(<Toolbar {...makeProps()} />)
    expect(getByTestId('lmgb-settings-button')).toBeInTheDocument()
  })

  it('opens and closes the SettingsTray when settings button is clicked', async () => {
    const {getByTestId, queryByTestId} = render(<Toolbar {...makeProps()} />)
    expect(queryByTestId('lmgb-settings-tray')).toBeNull()
    getByTestId('lmgb-settings-button').click()
    await waitFor(() => expect(getByTestId('lmgb-settings-tray')).toBeInTheDocument())
    getByTestId('lmgb-close-settings-button').querySelector('button')!.click()
    await waitFor(() => expect(queryByTestId('lmgb-settings-tray')).toBeNull())
  })
})
