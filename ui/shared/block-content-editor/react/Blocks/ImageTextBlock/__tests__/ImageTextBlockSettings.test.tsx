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
import {fireEvent} from '@testing-library/react'

const getSettings = (settings: object) => ({
  settings: {...settings},
})

describe('ImageTextBlockSettings', () => {
  describe('include title', () => {
    it('integrates, changing the state', () => {
      const component = renderBlock(ImageTextBlockSettings, getSettings({includeBlockTitle: false}))
      const checkbox = component.getByLabelText(/Include block title/i)
      expect(checkbox).not.toBeChecked()
      fireEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })
})
