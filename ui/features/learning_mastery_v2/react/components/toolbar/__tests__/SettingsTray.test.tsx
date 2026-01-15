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
import {type MockedFunction} from 'vitest'
import {SettingsTray, SettingsTrayProps} from '../SettingsTray'
import {
  DEFAULT_GRADEBOOK_SETTINGS,
  DisplayFilter,
  ScoreDisplayFormat,
  SecondaryInfoDisplay,
} from '@canvas/outcomes/react/utils/constants'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert')

const makeProps = (props = {}): SettingsTrayProps => ({
  open: true,
  onDismiss: vi.fn(),
  gradebookSettings: DEFAULT_GRADEBOOK_SETTINGS,
  setGradebookSettings: vi.fn(),
  ...props,
})

describe('SettingsTray', () => {
  afterEach(() => {
    cleanup()
  })

  const mockShowFlashAlert = showFlashAlert as MockedFunction<typeof showFlashAlert>

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders when open is true', () => {
    const {getByTestId, getByText} = render(<SettingsTray {...makeProps({open: true})} />)
    expect(getByTestId('lmgb-settings-tray')).toBeInTheDocument()
    expect(getByText('Settings')).toBeInTheDocument()
    expect(getByTestId('lmgb-close-settings-button')).toBeInTheDocument()
  })

  it('does not render when open is false', () => {
    const {queryByTestId} = render(<SettingsTray {...makeProps({open: false})} />)
    expect(queryByTestId('lmgb-settings-tray')).not.toBeInTheDocument()
  })

  it('calls onDismiss when CloseButton is clicked', () => {
    const props = makeProps({open: true})
    const {getByTestId} = render(<SettingsTray {...props} />)
    getByTestId('lmgb-close-settings-button').querySelector('button')!.click()
    expect(props.onDismiss).toHaveBeenCalledTimes(1)
  })

  it('calls onDismiss when Cancel button is clicked', () => {
    const props = makeProps({open: true})
    const {getByText} = render(<SettingsTray {...props} />)
    getByText('Cancel').click()
    expect(props.onDismiss).toHaveBeenCalledTimes(1)
  })

  it('calls setGradebookSettings when Save button is clicked', async () => {
    const props = makeProps({open: true})
    const {getByText} = render(<SettingsTray {...props} />)
    getByText('Save').click()
    await waitFor(() => {
      expect(props.setGradebookSettings).toHaveBeenCalledWith(props.gradebookSettings)
    })
  })

  it('disables Save button when isSavingSettings is true', () => {
    const props = makeProps({open: true, isSavingSettings: true})
    const {getByText} = render(<SettingsTray {...props} />)
    const saveButton = getByText('Save').closest('button')
    expect(saveButton).toBeDisabled()
  })

  it('shows flash alert when setGradebookSettings fails', async () => {
    const props = makeProps({
      open: true,
      setGradebookSettings: vi.fn().mockReturnValue(Promise.resolve({success: false})),
    })
    const {getByText} = render(<SettingsTray {...props} />)
    getByText('Save').click()
    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith({
        type: 'error',
        message: 'There was an error saving your settings. Please try again.',
      })
    })
  })

  it('shows flash alert when setGradebookSettings succeeds', async () => {
    const props = makeProps({
      open: true,
      setGradebookSettings: vi.fn().mockReturnValue(Promise.resolve({success: true})),
    })
    const {getByText} = render(<SettingsTray {...props} />)
    getByText('Save').click()
    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith({
        type: 'success',
        message: 'Your settings have been saved.',
      })
      expect(props.onDismiss).toHaveBeenCalledTimes(1)
    })
  })

  it('resets form and dismisses when Cancel button is clicked', () => {
    const props = makeProps({
      open: true,
    })
    const {getByText} = render(<SettingsTray {...props} />)
    getByText('Cancel').click()
    expect(props.onDismiss).toHaveBeenCalledTimes(1)
  })

  describe('SecondaryInfoSelector', () => {
    it('renders SecondaryInfoSelector', () => {
      const {getByText} = render(<SettingsTray {...makeProps({open: true})} />)
      expect(getByText('Secondary info')).toBeInTheDocument()
    })

    it('updates secondaryInfoDisplay on change', () => {
      const props = makeProps({open: true})
      const {getByText, getByLabelText} = render(<SettingsTray {...props} />)
      getByLabelText('SIS ID').click()
      getByText('Save').click()
      expect(props.setGradebookSettings).toHaveBeenCalledWith({
        ...props.gradebookSettings,
        secondaryInfoDisplay: SecondaryInfoDisplay.SIS_ID,
      })
    })
  })

  describe('DisplayFilterSelector', () => {
    it('renders DisplayFilterSelector', () => {
      const {getByText} = render(<SettingsTray {...makeProps({open: true})} />)
      expect(getByText('Display')).toBeInTheDocument()
    })

    it('updates display filters on change', () => {
      const props = makeProps({open: true})
      const {getByLabelText, getByText} = render(
        <SettingsTray
          {...props}
          gradebookSettings={{...props.gradebookSettings, displayFilters: []}}
        />,
      )
      getByLabelText('Students with no results').click()
      getByText('Save').click()
      expect(props.setGradebookSettings).toHaveBeenCalledWith({
        ...props.gradebookSettings,
        displayFilters: [DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS],
      })
    })
  })

  describe('ScoreDisplayFormatSelector', () => {
    it('renders ScoreDisplayFormatSelector', () => {
      const {getByText} = render(<SettingsTray {...makeProps({open: true})} />)
      expect(getByText('Scoring')).toBeInTheDocument()
    })

    it('updates scoreDisplayFormat on change', async () => {
      const props = makeProps({
        open: true,
        setGradebookSettings: vi.fn().mockReturnValue(Promise.resolve({success: true})),
      })
      const {getByText, getByLabelText} = render(<SettingsTray {...props} />)
      getByLabelText('Icons + Descriptor').click()
      getByText('Save').click()
      await waitFor(() => {
        expect(props.setGradebookSettings).toHaveBeenCalledWith({
          ...props.gradebookSettings,
          scoreDisplayFormat: ScoreDisplayFormat.ICON_AND_LABEL,
        })
      })
    })
  })
})
