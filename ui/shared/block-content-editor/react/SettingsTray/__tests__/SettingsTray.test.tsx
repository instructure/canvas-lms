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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {SettingsTray, SettingsTrayProps} from '../SettingsTray'

describe('SettingsTray', () => {
  const defaultProps: SettingsTrayProps = {
    blockDisplayName: 'Text column',
    open: true,
    onDismiss: () => {},
    onClose: () => {},
    children: <p>Settings content</p>,
  }

  const renderSettingsTray = async (props: Partial<SettingsTrayProps>) => {
    return render(<SettingsTray {...defaultProps} {...props} />)
  }

  describe('when tray is open', () => {
    it('renders with the given blockDisplayName', async () => {
      await renderSettingsTray({})
      expect(screen.getByText(defaultProps.blockDisplayName)).toBeInTheDocument()
    })

    it('renders the children content', async () => {
      await renderSettingsTray({})
      expect(screen.getByText('Settings content')).toBeInTheDocument()
    })

    it('should call onDismiss when the close button is clicked', async () => {
      const onDismissMock = vi.fn()
      await renderSettingsTray({onDismiss: onDismissMock})

      const closeButton = screen.getByRole('button', {name: 'Close'})
      await userEvent.click(closeButton)

      expect(onDismissMock).toHaveBeenCalledTimes(1)
    })
  })

  describe('when tray is closed', () => {
    it('does not render the tray content', async () => {
      await renderSettingsTray({open: false})
      expect(screen.queryByText(defaultProps.blockDisplayName)).not.toBeInTheDocument()
    })
  })
})
