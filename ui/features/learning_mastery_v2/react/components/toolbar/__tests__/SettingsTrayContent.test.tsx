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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {SettingsTrayContent, SettingsTrayContentProps} from '../SettingsTrayContent'
import {
  DEFAULT_GRADEBOOK_SETTINGS,
  DisplayFilter,
  ScoreDisplayFormat,
  SecondaryInfoDisplay,
} from '@canvas/outcomes/react/utils/constants'

const makeProps = (props = {}): SettingsTrayContentProps => ({
  settings: DEFAULT_GRADEBOOK_SETTINGS,
  onChange: vi.fn(),
  ...props,
})

describe('SettingsTrayContent', () => {
  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders all four selectors', () => {
    render(<SettingsTrayContent {...makeProps()} />)
    expect(screen.getByText('Secondary info')).toBeInTheDocument()
    expect(screen.getByText('Display')).toBeInTheDocument()
    expect(screen.getByText('Scoring')).toBeInTheDocument()
  })

  it('calls onChange with updated secondaryInfoDisplay when selector changes', async () => {
    const props = makeProps()
    render(<SettingsTrayContent {...props} />)
    await userEvent.click(screen.getByLabelText('SIS ID'))
    expect(props.onChange).toHaveBeenCalledWith({
      ...DEFAULT_GRADEBOOK_SETTINGS,
      secondaryInfoDisplay: SecondaryInfoDisplay.SIS_ID,
    })
  })

  it('calls onChange with updated displayFilters when selector changes', async () => {
    const props = makeProps({settings: {...DEFAULT_GRADEBOOK_SETTINGS, displayFilters: []}})
    render(<SettingsTrayContent {...props} />)
    await userEvent.click(screen.getByLabelText('Students with no results'))
    expect(props.onChange).toHaveBeenCalledWith({
      ...DEFAULT_GRADEBOOK_SETTINGS,
      displayFilters: [DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS],
    })
  })

  it('calls onChange with updated scoreDisplayFormat when selector changes', async () => {
    const props = makeProps()
    render(<SettingsTrayContent {...props} />)
    await userEvent.click(screen.getByLabelText('Icons + Descriptor'))
    expect(props.onChange).toHaveBeenCalledWith({
      ...DEFAULT_GRADEBOOK_SETTINGS,
      scoreDisplayFormat: ScoreDisplayFormat.ICON_AND_LABEL,
    })
  })
})
