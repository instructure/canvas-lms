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
import {render} from '@testing-library/react'
import {SettingsTray, SettingsTrayProps} from '../SettingsTray'

const makeProps = (props = {}): SettingsTrayProps => ({
  open: true,
  onDismiss: jest.fn(),
  ...props,
})

describe('SettingsTray', () => {
  beforeEach(() => {
    jest.clearAllMocks()
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
})
