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
import {cleanup, render, waitFor} from '@testing-library/react'
import {Toolbar, ToolbarProps} from '../Toolbar'
import {DEFAULT_GRADEBOOK_SETTINGS} from '@canvas/outcomes/react/utils/constants'

const makeProps = (props = {}): ToolbarProps => ({
  courseId: '123',
  showDataDependentControls: true,
  gradebookSettings: DEFAULT_GRADEBOOK_SETTINGS,
  setGradebookSettings: vi.fn(),
  ...props,
})

describe('Toolbar', () => {
  afterEach(() => {
    cleanup()
  })

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
    // InstUI Tray remains in DOM with transition class, check for exited state
    await waitFor(() => {
      const tray = queryByTestId('lmgb-settings-tray')
      expect(tray?.classList.contains('transition--slide-right-exited')).toBe(true)
    })
  })

  it('hides data-dependent controls when showDataDependentControls is false', () => {
    const {queryByTestId} = render(<Toolbar {...makeProps({showDataDependentControls: false})} />)
    expect(queryByTestId('export-button')).toBeNull()
    expect(queryByTestId('lmgb-settings-button')).toBeNull()
  })

  it('shows data-dependent controls when showDataDependentControls is true', () => {
    const {getByTestId} = render(<Toolbar {...makeProps({showDataDependentControls: true})} />)
    expect(getByTestId('export-button')).toBeInTheDocument()
    expect(getByTestId('lmgb-settings-button')).toBeInTheDocument()
  })
})
