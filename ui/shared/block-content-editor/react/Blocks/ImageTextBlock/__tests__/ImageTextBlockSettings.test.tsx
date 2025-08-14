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

import {ImageTextBlockSettings} from '../ImageTextBlockSettings'
import {renderBlock} from '../../__tests__/render-helper'
import {RenderResult, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

const getSettings = (settings: object) => ({
  settings: {...settings},
})

const color = '123456'

const toggleSection = async (component: RenderResult, name: RegExp | string) => {
  const button = component.getByRole('button', {name})
  await userEvent.click(button)
}

describe('ImageTextBlockSettings', () => {
  describe('include title', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, getSettings({includeBlockTitle: false}))
      const checkbox = component.getByLabelText(/Include block title/i)
      expect(checkbox).not.toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })

  describe('background color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(
        ImageTextBlockSettings,
        getSettings({backgroundColor: '000000'}),
      )
      await toggleSection(component, /Expand color settings/i)
      const input = component.getByLabelText(/Background color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('default text color', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, getSettings({textColor: '000000'}))
      await toggleSection(component, /Expand color settings/i)
      const input = component.getByLabelText(/Default text color/i) as HTMLInputElement
      await userEvent.clear(input)
      await userEvent.type(input, color)
      await waitFor(() => expect(input.value).toBe(color))
    })
  })

  describe('arrangement', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, getSettings({arrangement: 'left'}))
      const radioButton = component.getByLabelText(/Image on the right/i)
      expect(radioButton).not.toBeChecked()
      await userEvent.click(radioButton)
      expect(radioButton).toBeChecked()
    })
  })

  describe('text to image ratio', () => {
    it('integrates, changing the state', async () => {
      const component = renderBlock(ImageTextBlockSettings, getSettings({textToImageRatio: '1:1'}))
      const radioButton = component.getByLabelText(/2:1/i)
      expect(radioButton).not.toBeChecked()
      await userEvent.click(radioButton)
      expect(radioButton).toBeChecked()
    })
  })
})
