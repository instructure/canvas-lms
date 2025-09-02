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

import {SeparatorLineBlockSettings} from '../SeparatorLineBlockSettings'
import {renderBlock} from '../../__tests__/render-helper'
import userEvent from '@testing-library/user-event'
import {waitFor} from '@testing-library/react'

const color = '123456'

const defaultProps = {
  separatorColor: '#000000',
  thickness: 'medium',
  backgroundColor: '#ffffff',
}

describe('SeparatorLineBlockSettings', () => {
  describe('color settings', () => {
    it('renders with default values', () => {
      const component = renderBlock(SeparatorLineBlockSettings, defaultProps)
      const backgroundInput = component.getByLabelText(/Background/i) as HTMLInputElement
      expect(backgroundInput.value).toBe('ffffff')
    })

    it('integrates, changing the background color', async () => {
      const component = renderBlock(SeparatorLineBlockSettings, defaultProps)
      const input = component.getByLabelText(/Background/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('separator settings', () => {
    it('renders with default values', () => {
      const component = renderBlock(SeparatorLineBlockSettings, defaultProps)
      const separatorInput = component.getByLabelText(/Separator/i) as HTMLInputElement
      expect(separatorInput.value).toBe('000000')
      expect(component.getByRole('radio', {name: /Medium/i})).toBeChecked()
    })

    it('integrates, changing the separator color', async () => {
      const component = renderBlock(SeparatorLineBlockSettings, defaultProps)
      const input = component.getByLabelText(/Separator/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })

    it('integrates, changing the thickness', async () => {
      const component = renderBlock(SeparatorLineBlockSettings, defaultProps)
      const radio = component.getByRole('radio', {name: /Large/i})
      await userEvent.click(radio)
      expect(radio).toBeChecked()
    })
  })
})
